local HideHUD = false
local OpenMotherFrame = nil
local currentStation = nil
local currentStationPrintName = nil
SONG = SONG or nil
local stationname = nil
local artistname = nil
local songname = nil
local ELEMENTS = {}
local IconSize = 40
local minIconReduction = 20
local Dynamic = 0
local enabled = GetConVar("cl_chicagoRP_vehicleradio_enable"):GetBool()
local reddebug = Color(200, 10, 10, 150)
local graynormal = Color(20, 20, 20, 150)
local whitecolor = Color(255, 255, 255, 255)
local blackcolor = Color(0, 0, 0, 255)
local gradientLeftColor = Color(230, 45, 40, 170)
local gradientRightColor = Color(245, 135, 70, 170)
local blurMat = Material("pp/blurscreen")
local gradientLeftMat = Material("vgui/gradient-l") -- gradient-d, gradient-r, gradient-u, gradient-l, gradient_down, gradient_up
local gradientRightMat = Material("vgui/gradient-r") -- gradient-d, gradient-r, gradient-u, gradient-l, gradient_down, gradient_up
local radioIcon = radioIcon or {}
local radioOffMat = Material("chicagorp_vehicleradio/radiooff.png", "smooth mips")
AddCSLuaFile("circles.lua")
local circles = include("circles.lua")

local function isempty(s)
    return s == nil or s == ''
end

local function CreateIcons()
    if istable(chicagoRP.radioplaylists) then -- fix this, make local function that returns end if materials already exist
        for k, v in ipairs(chicagoRP.radioplaylists) do
            if isempty(radioIcon[k]) then
                radioIcon[k] = Material(v.icon, "smooth mips")
            end
        end
    end
end

local function BlurBackground(panel)
    if (!IsValid(panel) or !panel:IsVisible()) then return end
    local layers, density, alpha = 1, 1, 100
    local x, y = panel:LocalToScreen(0, 0)
    local FrameRate, Num, Dark = 1 / RealFrameTime(), 5, 0

    surface.SetDrawColor(255, 255, 255, alpha)
    surface.SetMaterial(blurMat)

    for i = 1, Num do
        blurMat:SetFloat("$blur", (i / layers) * density * Dynamic)
        blurMat:Recompute()
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(-x, -y, ScrW(), ScrH())
    end

    surface.SetDrawColor(0, 0, 0, Dark * Dynamic)
    surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
    Dynamic = math.Clamp(Dynamic + (1 / FrameRate) * 7, 0, 1)
end

local function GetRealVehicle(vehicle)
    local ply = LocalPlayer()
    if !IsValid(ply) then return end
    if !IsValid(vehicle) then return end
    if !ply:InVehicle() then return end

    if simfphys or SVMOD:GetAddonState() == true then
        if IsValid(ply:GetSimfphys()) and IsValid(ply:GetVehicle():GetParent()) then
           return ply:GetVehicle():GetParent()
        elseif SVMOD and SVMOD:IsVehicle(vehicle) then
            return vehicle:SV_GetDriverSeat():GetParent()
        else
            return ply:GetVehicle()
        end
    else
        return ply:GetVehicle()
    end
end

local function GetSimfphysPassengers(vehicle)
    local ply = LocalPlayer()
    if !IsValid(ply) then return end
    if !IsValid(vehicle) then return end
    if !ply:InVehicle() then return end
    if !IsValid(ply:GetVehicle():GetParent()) then return end

    local plytable = {}
    local parent = vehicle:GetParent()
    local children = parent:GetChildren()
    local count = #children

    for i = 1, count do
        local passenger = children[i]:GetDriver()
        if IsValid(passenger) then
            table.insert(plytable, passenger)
        end
    end

    return plytable
end

local function GetPassengerTable(vehicle, ply)
    if !IsValid(ply) then return end
    if !IsValid(vehicle) then return end
    if !ply:InVehicle() then return end

    if simfphys and IsValid(ply:GetSimfphys()) and IsValid(ply:GetVehicle():GetParent()) then -- no GetSimfphysState function so we do convar check
        print("simfphys vehicle")
        return GetSimfphysPassengers(vehicle, ply)
    elseif SVMOD and SVMOD:GetAddonState() == true and SVMOD:IsVehicle(vehicle) then
        print("svmod vehicle")
        return vehicle:SV_GetAllPlayers()
    else
        print("regular vehicle")
        return vehicle:GetDriver()
    end
end

local function IsDriver(vehicle, ply)
    if !IsValid(ply) then return end
    if !IsValid(vehicle) then return end
    if !ply:InVehicle() then return end

    local driver = false

    if simfphys or SVMOD:GetAddonState() == true then
        if IsValid(ply:GetSimfphys()) and IsValid(ply:GetVehicle():GetParent()) then
            driver = ply:IsDrivingSimfphys()
            if driver == true then
                return driver
            elseif driver == nil or driver == false then
                driver = false
                return driver
            end
        elseif SVMOD and SVMOD:IsVehicle(vehicle) then
            driver = vehicle:SV_GetDriverSeat():GetDriver()
            if driver != nil and driver == ply then
                driver = true
                return driver
            elseif driver == nil or driver != ply then
                driver = false
                return driver
            end
        else driver = true return driver end
    end
end

net.Receive("chicagoRP_vehicleradio_playsong", function()
    local ply = LocalPlayer()
    -- print("PlaySong Net received!")

    -- print(IsValid(ply))
    -- print("Player Valid^^^")
    -- print(IsValid(ply:GetVehicle()))
    -- print("Vehicle Valid^^^")
    -- print(ply:InVehicle())
    -- print("Player InVehicle^^^")
    -- print(enabled)
    -- print("Script Enabled^^^")
    if !IsValid(ply) then return end
    -- if !IsValid(ply:GetVehicle()) then return end -- broken for some stupid reason
    -- if !ply:InVehicle() then return end -- broken for some stupid reason
    if !enabled then return end

    local stopsong = net.ReadBool()

    if SONG then
        SONG:Stop()
    end

    if stopsong == true then return end

    local stationname = net.ReadString()
    local url = net.ReadString()
    local artist = net.ReadString()
    local netsongname = net.ReadString()
    local timestamp = net.ReadFloat()

    currentStation = stationname
    print(currentStation)

    print("Song: " .. artist .. " - " .. netsongname)
    print("TimeStamp: " .. timestamp)

    local realtimestamp = math.Round(timestamp, 2) + 0.35
    local musicvolume = GetConVar("cl_chicagoRP_vehicleradio_volume"):GetFloat()

    print(realtimestamp)

    -- local g_station = nil
    sound.PlayURL(url, "noblock", function(station) -- add fade in/out
        if IsValid(station) and !IsValid(SONG) then
            station:Play()
            station:SetVolume(0)
            SONG = station
            station:GetVolume()
            if realtimestamp == 0.35 then
                if IsValid(station) then
                    station:SetVolume(musicvolume)
                    print(station:GetTime())
                end
            elseif realtimestamp >= 0.35 then
                timer.Simple(0.35, function()
                    if IsValid(station) then
                        station:SetTime(realtimestamp, false) -- fucking desync wtf???
                        station:SetVolume(musicvolume)
                        print(station:GetTime())
                    end
                end)
            end
            -- g_station = station -- keep a reference to the audio object, so it doesn't get garbage collected which will stop the sound (garryism moment)
        else
            LocalPlayer():ChatPrint("Invalid URL!")
        end
    end)
end)

local function StopSong()
    local ply = LocalPlayer()
    if !IsValid(ply) then return end
    if !enabled then return end

    net.Start("chicagoRP_vehicleradio_receiveindex")
    net.WriteBool(false)
    net.SendToServer()

    if SONG then
        SONG:Stop()
    end

    currentStation = nil
    stationname = nil
    artistname = nil
    songname = nil
end

local function MusicFloat(value, min, max, default)
    local value = tonumber(value)

    return isnumber(value) and math.Clamp(tonumber(value), min, max) or default
end

cvars.AddChangeCallback("cl_chicagoRP_vehicleradio_volume", function(convar_name, value_old, value_new)
    local value = tonumber(value_new)
    local value_new = isnumber(value) and value or 1

    timer.Simple(0, function()
        if SONG then
            SONG:SetVolume(value_new)
        end
    end)
end)

net.Receive("chicagoRP_vehicleradio_stopsong", function()
    StopSong()
end)

local function SendStation(name)
    local ply = LocalPlayer()
    if !IsValid(ply) then return end
    if !IsValid(ply:GetVehicle()) then return end
    if !ply:InVehicle() then return end
    if !enabled then return end

    net.Start("chicagoRP_vehicleradio_receiveindex")
    net.WriteBool(true)
    net.WriteString(name)
    net.SendToServer()
end

surface.CreateFont("VehiclesRadioVGUIFont", {
    font = "ChaletComprime-CologneSixty", -- replace later with GPL compatible font
    size = 36,
    weight = 500,
    blursize = 0,
    scanlines = 0,
    antialias = true
})

local function ElementsDestroy()
    ELEMENTS = {}
end

local function ElementsAdd(x, y, radius, alpha, bool)
    table.insert(ELEMENTS, {
        x = x,
        y = y,
        radius = radius,
        alpha = alpha,
        disable = bool
    })
end

local function UpdateElementsSize()
    if #ELEMENTS > 13 then
        IconSize = 40 - (minIconReduction - minIconReduction / (#ELEMENTS - 13)) -- (minIconReduction - minIconReduction / (#ELEMENTS - 12))
    else
        IconSize = 40
    end
end

local function drawStationCircle(x, y, radius, alpha, color, k)
    local filled = circles.New(CIRCLE_FILLED, radius, x, y)
    filled:SetDistance(1)
    filled:SetMaterial(true)
    filled:SetColor(color)

    filled()

    surface.SetDrawColor(255, 255, 255, alpha)
    surface.SetMaterial(radioIcon[k])
    surface.DrawTexturedRectRotated(x, y, IconSize * 2, IconSize * 2, 0)
end

local function drawOutlineCircle(x, y, radius, thickness, color, material)
    if material == nil then material = true end

    local outlined = circles.New(CIRCLE_OUTLINED, radius, x, y, thickness)
    outlined:SetDistance(1)
    outlined:SetColor(color)
    outlined:SetMaterial(material)

    outlined()
end

hook.Add("HUDShouldDraw", "chicagoRP_vehicleradio_HideHUD", function()
    if HideHUD == true then
        return false
    end
end)

-- hook.Add("PlayerButtonUp", "chicagoRP_vehicleradio_ButtonReleaseCheck", function(ply, button) -- SWAG MESSIAH............
--     if button == KEY_SLASH and IsFirstTimePredicted() and IsValid(OpenMotherFrame) then
--         print("button up")
--         chicagoRP.PanelFadeIn(motherFrame, 0.15)
--         timer.Simple(0.15, function()
--             if IsValid(OpenMotherFrame) then
--                 OpenMotherFrame:Close()
--             end
--         end)
--     end
-- end)

-- hook.Add("PlayerButtonDown", "chicagoRP_vehicleradio_ButtonPressCheck", function(ply, button) -- SWAG MESSIAH............
--     if button == KEY_SLASH and IsFirstTimePredicted() then
--         print("button down")
--         net.Start("chicagoRP_vehicleradio")
--         net.WriteBool(true)
--         net.Send(ply)
--     end
-- end)

net.Receive("chicagoRP_vehicleradio", function()
    local ply = LocalPlayer()
    if IsValid(OpenMotherFrame) then OpenMotherFrame:Close() return end
    if !IsValid(ply) then return end
    if !IsValid(ply:GetVehicle()) then return end
    if !ply:InVehicle() then return end
    print(IsDriver(ply:GetVehicle(), ply))
    if (!IsDriver(ply:GetVehicle(), ply)) then return end
    if !input.IsKeyDown(KEY_SLASH) then return end
    if !enabled then return end

    local closebool = net.ReadBool()

    if closebool == false then return end

    local screenwidth = ScrW()
    local screenheight = ScrH()
    local cx = screenwidth / 2
    local cy = screenheight / 2
    local vehicle = ply:GetVehicle()
    local motherFrame = vgui.Create("DFrame")
    motherFrame:SetSize(screenwidth, screenheight)
    motherFrame:SetVisible(true)
    motherFrame:SetDraggable(false)
    motherFrame:ShowCloseButton(true)
    motherFrame:SetTitle("")
    motherFrame:ParentToHUD()
    HideHUD = true
    stationname = currentStationPrintName or nil
    artistname = artistname or nil
    songname = songname or nil

    chicagoRP.PanelFadeIn(motherFrame, 0.15)

    motherFrame:MakePopup()
    motherFrame:SetKeyboardInputEnabled(false)
    motherFrame:SetMouseInputEnabled(true)
    motherFrame:Center()

    local hoverindex = nil
    local stationcachedname = nil
    local artistcachedname = nil
    local songcachedname = nil

    for _, v2 in ipairs(chicagoRP.radioplaylists) do
        if currentStation == v2.name then
            stationcachedname = v2.printname
            print("stationname set")

            break
        end
    end

    print(currentStation)
    print("intial currentStation")

    if !isempty(currentStation) then
        net.Start("chicagoRP_vehicleradio_sendinfo")
        net.WriteString(currentStation)
        net.SendToServer()
    else
        stationcachedname = "Radio Off"
    end

    net.Receive("chicagoRP_vehicleradio_receiveinfo", function()
        local artist = net.ReadString()
        local song = net.ReadString()

        artistcachedname = artist
        songcachedname = song
        artistname = artistcachedname
        songname = songcachedname
    end)

    stationname = stationcachedname

    local stations = table.GetKeys(chicagoRP.radioplaylists)
    local count = #stations + 1

    -- local arcdegrees = 360 / count -- fix radio pos with this
    -- local radius = 300
    -- local d = 360
    -- ElementsDestroy()

    -- for i = 1, count do
    --     local rad = math.rad(d + arcdegrees * 0.50)
    --     local x = math.Round(cx + math.cos(rad) * radius)
    --     local y = math.Round(cy - math.sin(rad) * radius)
    --     d = d - arcdegrees
    --     if i == (count) then
    --         ElementsAdd(x, y, IconSize, 100, true)
    --     else
    --         ElementsAdd(x, y, IconSize, 100, false)
    --     end
    --     -- ElementsAdd(x, y, IconSize, 100, false)
    -- end

    if count > 0 then
        local arcdegrees = 360 / count - 1 -- 300
        local radius = 300
        local d = 250 -- 280
        ElementsDestroy()

        for i = 1, count do
            if i != (count) then
                local rad = math.rad(d + arcdegrees * -0.50)
                local x = math.Round(cx + math.cos(rad) * radius)
                local y = math.Round(cy - math.sin(rad) * radius)
                d = d - arcdegrees
                ElementsAdd(x, y, IconSize, 100, false)
            elseif i == (count) then
                local Offrad = math.rad(360 + 270 / 1 * 1)
                local Offx = math.Round(cx + math.cos(Offrad) * 300)
                local Offy = math.Round(cy - math.sin(Offrad) * 300)
                ElementsAdd(Offx, Offy, IconSize, 100, true)
            end
            -- ElementsAdd(x, y, IconSize, 100, false)
        end
    else
        notification.AddLegacy("You have not installed radio stations", 0, 3)
        surface.PlaySound("buttons/button14.wav")
    end

    CreateIcons()
    UpdateElementsSize()

    function motherFrame:OnClose()
        if !isempty(currentStation) then
            net.Start("chicagoRP_vehicleradio_sendinfo")
            net.WriteString(currentStation)
            net.SendToServer()
        else
            stationcachedname = "Radio Off"
        end

        if IsValid(self) then
            chicagoRP.PanelFadeOut(motherFrame, 0.15)
        end

        if !isempty(hoverindex) and currentStation != chicagoRP.radioplaylists[hoverindex].name then
            SendStation(chicagoRP.radioplaylists[hoverindex].name)
            currentStation = chicagoRP.radioplaylists[hoverindex].name
            currentStationPrintName = chicagoRP.radioplaylists[hoverindex].printname
        end

        if SONG then
            SONG:Stop()
        end

        HideHUD = false
    end

    function motherFrame:OnKeyCodePressed(key)
        if key == KEY_ESCAPE or key == KEY_Q then
            surface.PlaySound("chicagoRP_settings/back.wav")
            timer.Simple(0.15, function()
                if IsValid(self) then
                    self:Close()
                end
            end)
        end
    end

    function motherFrame:Paint(w, h)
        BlurBackground(self)
        -- print(stationname)
        -- print(IsValid(stationname))
        -- print(isstring(stationname))
        if isstring(stationname) then
            draw.SimpleTextOutlined(stationname, "VehiclesRadioVGUIFont", cx, cy - 30, whitecolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, blackcolor) -- (- 50)
        end
        if isstring(artistname) and isstring(songname) then
            draw.SimpleTextOutlined(artistname, "VehiclesRadioVGUIFont", cx, cy - 10, whitecolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, blackcolor)
            draw.SimpleTextOutlined(songname, "VehiclesRadioVGUIFont", cx, cy + 30, whitecolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, blackcolor)
        end
    end

    local currenthover = currentStation

    for k, v in ipairs(ELEMENTS) do
        if v.disable == false then
            local x = v.x
            local y = v.y

            x = cx - (cx - v.x)
            y = cy - (cy - v.y)

            local radius = v.radius
            -- local stationcachedname = chicagoRP.radioplaylists[k].printname

            local stationButton = motherFrame:Add("DButton")
            stationButton:SetText("")
            stationButton:SetSize(radius * 2.2, radius * 2.2)
            stationButton:SetPos(x - (radius * 2.2) / 2, y - (radius * 2.2) / 2)

            local stationtostations = chicagoRP.radioplaylists[k].name

            -- first one
            -- radius: from 48 to 52
            -- cursorX: from 0 to 760
            -- cursorY: from 0 to 230
            -- X: 810
            -- Y: 280

            -- second one
            -- radius: from 48 to 52
            -- cursorX: from 0 to 1065
            -- cursorY: from 0 to 235
            -- X: 1110
            -- Y: 280

            -- third one
            -- radius: from 48 to 52
            -- cursorX: from 0 to 1212
            -- cursorY: from 0 to 492
            -- X: 1260
            -- Y: 540

            -- make hovering similar to gta radio UI
            -- if 1216 > 1260 - (48 / 2) and 1216 < 1260 + (48 / 2) and 493 > 540 - (48 / 2) and 493 < 540 + (48 / 2) then
            -- if cursorx > x - (radius / 2) and cursorx < x + (radius / 2) and cursory > y - (radius / 2) and cursory < y + (radius / 2) then
            function stationButton:Paint(w, h) -- 230, 45, 40 and 245, 135, 70
                local hovered = self:IsHovered()
                local hoveredpanel = vgui.GetHoveredPanel()
                local buf, step = self.__hoverBuf or 0, RealFrameTime() * 3
                local Outlinebuf, Outlinestep = self.__hoverOutlineBuf or 0, RealFrameTime() * 3
                local iconalpha = 100
                DisableClipping(true)

                self.value = chicagoRP.radioplaylists[k].name

                print(vgui.GetHoveredPanel())
                print(currentStation)
                print(currenthover)

                if hovered then
                    hoverindex = k
                end

                if (hovered or (hoveredpanel == motherframe and currenthover == stationtostations)) then
                    v.radius = Lerp(math.min(RealFrameTime() * 5, 1), v.radius, IconSize * 1.1)
                    iconalpha = Lerp(math.min(FrameTime() * 5, 1), iconalpha, iconalpha * 2.55)

                    print(self.value)
                    print(currentStation)

                    stationname = chicagoRP.radioplaylists[k].printname
                    artistname = artistcachedname
                    songname = songcachedname
                    -- currenthover is ambient, but currentstation is still atmospheric_drum_and_bass
                elseif !hovered and currenthover != stationtostations then
                    v.radius = Lerp(math.min(RealFrameTime() * 5, 1), v.radius, IconSize * 1.0)
                    -- NOT hovered and currentStation NOT self and currenthover NOT self
                end

                -- print("CursorX: " .. cursorx)
                -- print("CursorY: " .. cursory)

                if (hovered or (hoveredpanel == motherframe and currenthover == stationtostations)) and buf < 1 then
                    buf = math.min(1, step + buf) 
                    -- IS hovered
                    -- NOT hovered, currentstation IS equal to self's playlist.name, hoveredpanel IS motherframe
                elseif !hovered and currenthover != stationtostations and buf > 0 then
                    buf = math.max(0, buf - step) -- not hovered AND (currentstation NOT equal to self's playlist.name OR other button hovered)
                end

                self.__hoverBuf = buf
                buf = math.EaseInOut(buf, 0.2, 0.2)
                local alpha, clr = Lerp(buf, 150, 100), Lerp(buf, 20, 40)

                graynormal.r = clr
                graynormal.g = clr
                graynormal.b = clr
                graynormal.a = alpha

                drawStationCircle(w / 2, h / 2, v.radius * 1.2, iconalpha, graynormal, k)

                if (hovered or (hoveredpanel == motherframe and currenthover == stationtostations)) and buf < 1 then
                    Outlinebuf = math.min(1, Outlinestep + Outlinebuf)
                elseif !hovered and currenthover != stationtostations and buf > 0 then
                    Outlinebuf = math.max(0, Outlinebuf - Outlinestep)
                end

                self.__hoverOutlineBuf = Outlinebuf
                Outlinebuf = math.EaseInOut(Outlinebuf, 0.5, 0.5)
                local alphaOutline = Lerp(Outlinebuf, 0, 170)

                gradientLeftColor.a = alphaOutline
                gradientRightColor.a = alphaOutline

                drawOutlineCircle(w / 2, h / 2, v.radius * 1.2, 4, gradientLeftColor, gradientLeftMat)
                drawOutlineCircle(w / 2, h / 2, v.radius * 1.2, 4, gradientRightColor, gradientRightMat)

                return nil
            end

            function stationButton:OnCursorEntered()
                surface.PlaySound("chicagorp_settings/hover.wav")

                if istable(chicagoRP.radioplaylists[k]) then
                    net.Start("chicagoRP_vehicleradio_sendinfo")
                    net.WriteString(chicagoRP.radioplaylists[k].name)
                    net.SendToServer()
                end

                print(currentStation)
                print(chicagoRP.radioplaylists[k].name)

                if currentStation == chicagoRP.radioplaylists[k].name then -- if alternative_metal == alternative_metal then hover on alternative_metal
                    currenthover = chicagoRP.radioplaylists[k].name
                elseif currentStation != chicagoRP.radioplaylists[k].name then -- if alternative_metal != ambient hover on ambient
                    currenthover = chicagoRP.radioplaylists[k].name
                end

                if currentStation == chicagoRP.radioplaylists[k].name then return end

                timer.Simple(1.0, function()
                    -- print(IsValid(self))
                    -- print(self:IsHovered())
                    -- print(istable(chicagoRP.radioplaylists[k]))
                    -- print(chicagoRP.radioplaylists[k].name)
                    if IsValid(self) and self:IsHovered() and istable(chicagoRP.radioplaylists[k]) then
                        SendStation(chicagoRP.radioplaylists[k].name)
                        currentStation = chicagoRP.radioplaylists[k].name
                        currentStationPrintName = chicagoRP.radioplaylists[k].printname

                        if SONG then
                            SONG:Stop()
                        end
                    end
                end)
            end

            function stationButton:OnCursorExited()
                if currentStation == chicagoRP.radioplaylists[k].name then -- if alternative_metal == alternative_metal then hover on alternative_metal
                    currenthover = chicagoRP.radioplaylists[k].name
                elseif currentStation != chicagoRP.radioplaylists[k].name then -- if alternative_metal != atmospheric_drum_and_bass then hover on alternative_metal
                    currenthover = currentStation
                end
            end
        elseif v.disable == true then
            local x = v.x
            local y = v.y
            local radius = v.radius

            x = cx - (cx - v.x)
            y = cy - (cy - v.y)

            -- print(chicagoRP.radioplaylists[k])

            local radioOffButton = motherFrame:Add("DButton")
            radioOffButton:SetText("")
            radioOffButton:SetSize(radius * 2.2, radius * 2.2)
            radioOffButton:SetPos(x - (radius * 2.2) / 2, y - (radius * 2.2) / 2)

            function radioOffButton:Paint(w, h)
                local hovered = self:IsHovered()
                local buf, step = self.__hoverBuf or 0, RealFrameTime() * 1
                local Outlinebuf, Outlinestep = self.__hoverOutlineBuf or 0, RealFrameTime() * 1
                DisableClipping(true)

                if hovered then
                    radius = Lerp(math.min(RealFrameTime() * 5, 1), radius, IconSize * 1.1)

                    stationname = "Radio Off"
                    artistname = nil
                    songname = nil
                else
                    radius = Lerp(math.min(RealFrameTime() * 5, 1), radius, IconSize * 1.0)
                end

                if hovered and buf < 1 then
                    buf = math.min(1, step + buf)
                elseif !hovered and buf > 0 then
                    buf = math.max(0, buf - step)
                end

                self.__hoverBuf = buf
                buf = math.EaseInOut(buf, 0.2, 0.2)
                local alpha, clr = Lerp(buf, 150, 100), Lerp(buf, 20, 40)

                graynormal.r = clr
                graynormal.g = clr
                graynormal.b = clr
                graynormal.a = alpha

                local filled = circles.New(CIRCLE_FILLED, radius * 1.2, w / 2, h / 2)
                filled:SetDistance(1)
                filled:SetMaterial(true)
                filled:SetColor(graynormal)

                filled()

                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetMaterial(radioOffMat)
                surface.DrawTexturedRectRotated(w / 2, h / 2, IconSize * 2, IconSize * 2, 0)

                if hovered and Outlinebuf < 1 then
                    Outlinebuf = math.min(1, Outlinestep + Outlinebuf)
                elseif !hovered and Outlinebuf > 0 then
                    Outlinebuf = math.max(0, Outlinebuf - Outlinestep)
                end

                self.__hoverOutlineBuf = Outlinebuf
                Outlinebuf = math.EaseInOut(Outlinebuf, 0.5, 0.5)
                local alphaOutline = Lerp(Outlinebuf, 0, 170)

                gradientLeftColor.a = alphaOutline
                gradientRightColor.a = alphaOutline

                drawOutlineCircle(w / 2, h / 2, radius * 1.2, 4, gradientLeftColor, gradientLeftMat)
                drawOutlineCircle(w / 2, h / 2, radius * 1.2, 4, gradientRightColor, gradientRightMat)
            end

            function radioOffButton:OnCursorEntered()
                surface.PlaySound("chicagorp_settings/hover.wav")

                stationname = "Radio Off"
                artistname = nil
                songname = nil

                timer.Simple(1.0, function()
                    if IsValid(self) and self:IsHovered()then
                        StopSong()
                    end
                end)
            end
        end
    end

    local gameSettingsScrollPanel = vgui.Create("DScrollPanel", motherFrame)
    gameSettingsScrollPanel:Dock(LEFT)
    gameSettingsScrollPanel:SetSize(200, 50)

    local debugStopSongButton = gameSettingsScrollPanel:Add("DButton")
    debugStopSongButton:SetText("STOP SONG")
    debugStopSongButton:Dock(TOP)
    debugStopSongButton:DockMargin(0, 10, 0, 0)
    debugStopSongButton:SetSize(200, 50)

    function debugStopSongButton:DoClick()
        StopSong()
    end

    local debugPrintSongButton = gameSettingsScrollPanel:Add("DButton")
    debugPrintSongButton:SetText("SONG PRINT")
    debugPrintSongButton:Dock(TOP)
    debugPrintSongButton:DockMargin(0, 10, 0, 0)
    debugPrintSongButton:SetSize(200, 50)

    function debugPrintSongButton:DoClick()
        print(SONG)
        if istable(SONG) then
            PrintTable(SONG)
        end
    end
    OpenMotherFrame = motherFrame
end)

print("chicagoRP Vehicle Radio GUI loaded!")

-- bugs:
-- SetTime randomly desyncs for absolutely no fucking reason whatsoever (https://github.com/SpiffyJUNIOR/chicagoRP-vehicle-radio/issues/1) MUST FIX, HIGH PRIORITY!!!
-- previous stations song continuing to play when switching (test fix)
-- song and artist name don't immediately switch to currentstation's one on UI open if you hover on other station then exit UI (test fix)

-- to-do:
-- keep hover on station if currentstation == k and nothing else is hovered (test)
-- make icons transparent when not hovered (test)
-- make radio open button hold open (test)
-- add random chance of album being inserted (test)
-- make timer.Simple only run if timestamp is < 0.35 (test)
-- add radio wheel hover like GTA 5 (idk how to hover something based off radius, maybe try limiting where mouse can go?)
-- make layout pos and size match GTA 5's
-- add DJ/commerical support (delayed until everything else is finished)

















