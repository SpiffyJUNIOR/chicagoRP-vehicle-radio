function VRADIO:GetCar(veh)
    if simfphys and IsValid(veh:GetParent()) and simfphys.IsCar(veh:GetParent()) then return veh:GetParent() end

    return veh
end

local ELEMENTS = {}
local VisibleVGUI = false
local VisibleVolume = false
local AlphaVolume = 0
local IconSize = 64
local minIconReduction = 20
local Alpha = 0
local Volume = 2
local VolumeSlider = 50
local VolumeSliderSize = 0
local VolumeHit = 0
local MovementMul = 0
local HoverIndex

concommand.Add("+vehicles_radio_gui", function(ply, cmd, args)
    VRADIO:OpenVGUI()
end)

concommand.Add("-vehicles_radio_gui", function(ply, cmd, args)
    VRADIO:CloseVGUI()
end)

concommand.Add("vehicles_radio_turnoff", function(ply, cmd, args)
    if IsValid(ply) and ply:InVehicle() then
        veh = VRADIO:GetCar(ply:GetVehicle())
        VRADIO:Stop(veh)
    end
end)

surface.CreateFont("VehiclesRadioVGUIFont", {
    font = "Roboto",
    dc = false,
    size = 36,
    weight = 500,
    blursize = 0,
    scanlines = 0,
    antialias = true
})

local circles = include("circles.lua")

local GrayTransparent = Color(0, 0, 0, 170)

local FilledCircle = circles.New(CIRCLE_FILLED, 64, 0, 0)
FilledCircle:SetDistance(1)
FilledCircle:SetColor(GrayTransparent)

local function ElementsDestroy()
    ELEMENTS = {}
end

local function ElementsAdd(x, y, radius, alpha)
    table.insert(ELEMENTS, {
        x = x,
        y = y,
        radius = radius,
        alpha = alpha
    })
end

local function ElementHoverIndex()
    for k, v in pairs(ELEMENTS) do
        if v.hover then return k end
    end
end

function VRADIO:OpenVGUI()
    local ply = LocalPlayer()

    if IsValid(ply) and ply:Alive() and ply:InVehicle() then
        local stations = table.GetKeys(RADIO_STANTIONS)
        local count = #stations

        if count > 0 then
            local scrw, scrh = ScrW(), ScrH()
            local arcdegrees = 360 / count
            local radius = 300
            local d = 360
            VisibleVGUI = true
            gui.EnableScreenClicker(true)
            ElementsDestroy()

            for i = 1, count do
                local rad = math.rad(d + arcdegrees * 0.66)
                local x = scrw / 2 + math.cos(rad) * radius
                local y = scrh / 2 - math.sin(rad) * radius
                ElementsAdd(x, y, IconSize, 100)
                d = d - arcdegrees
            end
        else
            notification.AddLegacy("You have not installed radio stations", 0, 3)
            surface.PlaySound("buttons/button14.wav")
        end
    end
end

function VRADIO:CloseVGUI()
    local ply = LocalPlayer()
    VisibleVGUI = false

    if IsValid(ply) and ply:Alive() and ply:InVehicle() then
        local veh = VRADIO:GetCar(ply:GetVehicle())
        local index = HoverIndex

        if index then
            surface.PlaySound("vehicles_radio/radio_noise.wav")
            VRADIO:Play(veh, index, Volume)
        end
    end

    gui.EnableScreenClicker(false)
end

function VRADIO:UpdateElementsSize()
    if #ELEMENTS > 12 then
        IconSize = 64 - (minIconReduction - minIconReduction / (#ELEMENTS - 12))
    else
        IconSize = 64
    end
end

local worldPanel = vgui.GetWorldPanel()

function worldPanel.OnMouseWheeled(self, scrollDelta)
    ply = LocalPlayer()

    if IsValid(ply) and ply:InVehicle() and VisibleVGUI then
        local veh = VRADIO:GetCar(ply:GetVehicle())
        VisibleVolume = true
        VolumeHit = 2
        VolumeSliderSize = VolumeSliderSize + VolumeHit

        timer.Create("VehiclesRadioVGUIVolumeShow", 0.5, 1, function()
            VisibleVolume = false
        end)

        if scrollDelta == 1 then
            Volume = math.Clamp(Volume + 1, 0, 10)
        end

        if scrollDelta == -1 then
            Volume = math.Clamp(Volume - 1, 0, 10)
        end

        VRADIO:SetVolume(veh, Volume)
    end
end

hook.Add("HUDPaint", "VehiclesRadioVGUI", function()
    local ply = LocalPlayer()

    if IsValid(ply) and ply:InVehicle() then
        local cx = ScrW() / 2
        local cy = ScrH() / 2
        local cursorx, cursory = input.GetCursorPos()
        local isAnimation = GetConVar("vehicles_radio_hud_animation"):GetBool()

        if isAnimation and !VisibleVolume then
            if VisibleVGUI then
                MovementMul = Lerp(FrameTime() * 5, MovementMul, 1.2)
            else
                MovementMul = Lerp(FrameTime() * 5, MovementMul, 0)
            end
        end

        if (isAnimation and MovementMul > 0.1 or VisibleVGUI) and !VisibleVolume then
            VRADIO:UpdateElementsSize()
            HoverIndex = nil

            for k, v in pairs(ELEMENTS) do
                local x = v.x
                local y = v.y
                local clampedMul = 1

                if isAnimation then
                    x = cx - (cx - v.x) * math.min(MovementMul, 1)
                    y = cy - (cy - v.y) * math.min(MovementMul, 1)
                    clampedMul = math.min(MovementMul, 1)
                end

                local radius = v.radius
                local stationname = RADIO_STANTIONS[k].meta.name
                draw.NoTexture()

                if cursorx > x - radius and cursorx < x + radius and cursory > y - radius and cursory < y + radius then
                    HoverIndex = k
                    v.radius = Lerp(math.min(FrameTime() * 5, 1), v.radius, IconSize * 1.2)

                    if !VisibleVolume and clampedMul >= 1 then
                        draw.SimpleText(stationname, "VehiclesRadioVGUIFont", cx + 1, cy + 1, Color(0, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        draw.SimpleText(stationname, "VehiclesRadioVGUIFont", cx, cy, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end

                    surface.SetDrawColor(155, 155, 155, v.alpha * clampedMul)
                else
                    surface.SetDrawColor(55, 55, 55, v.alpha * clampedMul)
                    v.radius = IconSize
                end

                drawFilledCircle(x, y, v.radius, v.radius)
                local mat = Material(RADIO_STANTIONS[k].meta.icon)
                surface.SetDrawColor(255, 255, 255, 255 * clampedMul)
                surface.SetMaterial(mat)
                surface.DrawTexturedRectRotated(x, y, IconSize * 2, IconSize * 2, isAnimation and 520 * (1.2 - MovementMul) or 0)
            end
        end

        if VisibleVGUI and VisibleVolume then
            MovementMul = 1
            local icon = Material("gui/vehicles_radio_icons/volume_100.png")
            local percent = (Volume / 10) * 100
            local width = 125 + 64 + VolumeSliderSize
            local value = (percent / 100) * width
            local height = 65 + VolumeSliderSize

            if percent == 100 then
                icon = Material("gui/vehicles_radio_icons/volume_100.png")
            elseif percent > 0 and percent < 50 then
                icon = Material("gui/vehicles_radio_icons/volume_50.png")
            elseif percent == 0 and percent < 50 then
                icon = Material("gui/vehicles_radio_icons/volume_0.png")
            end

            VolumeHit = Lerp(math.min(FrameTime() * 5, 1), VolumeHit, 0)
            VolumeSlider = Lerp(math.min(FrameTime() * 5, 1), VolumeSlider, value)
            VolumeSliderSize = Lerp(math.min(FrameTime() * 5, 1), VolumeSliderSize, 0)
            draw.RoundedBox(25, cx - height / 2, cy - width / 2, height, width, Color(55, 55, 55, 100))
            render.SetScissorRect(cx - height / 2, cy + width / 2 - VolumeSlider, cx - height / 2 + width, cy - width / 2 + width, true)
            draw.RoundedBox(25, cx - height / 2, cy - width / 2, height, width, Color(255, 255, 255, 100))
            render.SetScissorRect(0, 0, 0, 0, false)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(icon)
            surface.DrawTexturedRectUV(cx - 30, cy + 27, 64, 64, 0, 0, 1, 1)
        end
    else
        MovementMul = 0
    end
end)