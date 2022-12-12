local ELEMENTS = {}
local VisibleVGUI = false
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
local circles = include("circles.lua")
local GrayTransparent = Color(0, 0, 0, 170)

surface.CreateFont("VehiclesRadioVGUIFont", {
    font = "Roboto",
    dc = false,
    size = 36,
    weight = 500,
    blursize = 0,
    scanlines = 0,
    antialias = true
})

local function drawFilledCircle(x, y, radius, color)
    local FilledCircle = circles.New(CIRCLE_FILLED, radius, x, y)
    FilledCircle:SetDistance(1)
    FilledCircle:SetColor(color)
end

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

-- local worldPanel = vgui.GetWorldPanel() -- gets worldpanel made in HUDPaint

-- function worldPanel.OnMouseWheeled(self, scrollDelta)
--     ply = LocalPlayer()

--     if IsValid(ply) and ply:InVehicle() and VisibleVGUI then
--         local veh = VRADIO:GetCar(ply:GetVehicle())
--         VisibleVolume = true
--         VolumeHit = 2
--         VolumeSliderSize = VolumeSliderSize + VolumeHit

--         timer.Create("VehiclesRadioVGUIVolumeShow", 0.5, 1, function()
--             VisibleVolume = false
--         end)

--         if scrollDelta == 1 then
--             Volume = math.Clamp(Volume + 1, 0, 10)
--         end

--         if scrollDelta == -1 then
--             Volume = math.Clamp(Volume - 1, 0, 10)
--         end

--         VRADIO:SetVolume(veh, Volume)
--     end
-- end

hook.Add("HUDPaint", "VehiclesRadioVGUI", function() -- this is worldpanel
    local ply = LocalPlayer()

    if IsValid(ply) and ply:InVehicle() then
        local ScreenWidth = ScrW() / 2
        local ScreenHeight = ScrH() / 2
        local CursorX, CursorY = input.GetCursorPos() -- only works on windows :troll:

        if (MovementMul > 0.1 or VisibleVGUI) then
            VRADIO:UpdateElementsSize()
            HoverIndex = nil

            for k, v in pairs(ELEMENTS) do
                local stationButton = vgui.Create("DButton", motherFrame)

                local x = v.x
                local y = v.y
                local radius = v.radius
                local clampedMul = 1
                
                stationButton:SetPos(x, y)
                stationButton:SetSize(radius, radius)

                local stationname = chicagoRP.radioplaylists[k].printname
                draw.NoTexture()

                if CursorX > x - radius and CursorX < x + radius and CursorY > y - radius and CursorY < y + radius then
                    HoverIndex = k
                    v.radius = Lerp(math.min(RealFrameTime() * 5, 1), v.radius, IconSize * 1.2)

                    if clampedMul >= 1 then
                        draw.SimpleText(stationname, "VehiclesRadioVGUIFont", ScreenWidth + 1, ScreenHeight + 1, Color(0, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        draw.SimpleText(stationname, "VehiclesRadioVGUIFont", ScreenWidth, ScreenHeight, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end

                    surface.SetDrawColor(155, 155, 155, v.alpha * clampedMul)
                else
                    surface.SetDrawColor(55, 55, 55, v.alpha * clampedMul)
                    v.radius = IconSize
                end

                drawFilledCircle(x, y, v.radius, GrayTransparent)
                local mat = Material(chicagoRP.radioplaylists[k].icon)
                surface.SetDrawColor(255, 255, 255, 255 * clampedMul)
                surface.SetMaterial(mat)
                surface.DrawTexturedRectRotated(x, y, IconSize * 2, IconSize * 2, 0)
            end
        end

        -- if VisibleVGUI and VisibleVolume then
        --     MovementMul = 1
        --     local icon = Material("gui/vehicles_radio_icons/volume_100.png")
        --     local percent = (Volume / 10) * 100
        --     local width = 125 + 64 + VolumeSliderSize
        --     local value = (percent / 100) * width
        --     local height = 65 + VolumeSliderSize

        --     if percent == 100 then
        --         icon = Material("gui/vehicles_radio_icons/volume_100.png")
        --     elseif percent > 0 and percent < 50 then
        --         icon = Material("gui/vehicles_radio_icons/volume_50.png")
        --     elseif percent == 0 and percent < 50 then
        --         icon = Material("gui/vehicles_radio_icons/volume_0.png")
        --     end

        --     VolumeHit = Lerp(math.min(RealFrameTime() * 5, 1), VolumeHit, 0)
        --     VolumeSlider = Lerp(math.min(RealFrameTime() * 5, 1), VolumeSlider, value)
        --     VolumeSliderSize = Lerp(math.min(RealFrameTime() * 5, 1), VolumeSliderSize, 0)
        --     draw.RoundedBox(25, ScreenWidth - height / 2, ScreenHeight - width / 2, height, width, Color(55, 55, 55, 100))
        --     render.SetScissorRect(ScreenWidth - height / 2, ScreenHeight + width / 2 - VolumeSlider, ScreenWidth - height / 2 + width, ScreenHeight - width / 2 + width, true)
        --     draw.RoundedBox(25, ScreenWidth - height / 2, ScreenHeight - width / 2, height, width, Color(255, 255, 255, 100))
        --     render.SetScissorRect(0, 0, 0, 0, false)
        --     surface.SetDrawColor(255, 255, 255, 255)
        --     surface.SetMaterial(icon)
        --     surface.DrawTexturedRectUV(ScreenWidth - 30, ScreenHeight + 27, 64, 64, 0, 0, 1, 1)
        -- end
    else
        MovementMul = 0
    end
end)