local HideHUD = false
local OpenMotherFrame = nil
local currentStation = nil
local currentStationPrintName = nil
SONG = SONG or nil
local stationname = nil
local artistname = nil
local songname = nil
local ELEMENTS = {}
local IconSize = 48
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

if istable(chicagoRP.radioplaylists) then
    for k, v in ipairs(chicagoRP.radioplaylists) do
        radioIcon[k] = Material(v.icon, "smooth mips")
        print("not cached being constantly done")
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

    if ConVarExists("sv_simfphys_enabledamage") or SVMOD:GetAddonState() == true then
        if IsValid(ply:GetSimfphys()) and IsValid(ply:GetVehicle():GetParent()) then
           return ply:GetVehicle():GetParent()
        elseif SVMOD and SVMOD:IsVehicle(vehicle) then
            return vehicle:SV_GetDriverSeat():GetParent()
        else
            return ply:GetVehicle()
        end
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

local function GetPassengerTable(vehicle)
    local ply = LocalPlayer()
    if !IsValid(ply) then return end
    if !IsValid(vehicle) then return end
    if !ply:InVehicle() then return end

    local finaltable = nil

    if ConVarExists("sv_simfphys_enabledamage") then
        if IsValid(ply:GetSimfphys()) and IsValid(ply:GetVehicle():GetParent()) then
            return GetSimfphysPassengers(vehicle)
        end
    elseif SVMOD:GetAddonState() == true then
        if SVMOD:IsVehicle(vehicle) then
            return vehicle:SV_GetAllPlayers()
        end
    else return vehicle:GetDriver() end
end

local function IsDriver(vehicle, ply)
    if !IsValid(ply) then return end
    print(IsValid(vehicle))
    if !IsValid(vehicle) then return end
    print(ply:InVehicle())
    if !ply:InVehicle() then return end

    local driver = false

    if ConVarExists("sv_simfphys_enabledamage") or SVMOD:GetAddonState() == true then
        if IsValid(ply:GetSimfphys()) and IsValid(ply:GetVehicle():GetParent()) then
            driver = ply:IsDrivingSimfphys()
            print(ply:IsDrivingSimfphys())
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
    print("PlaySong Net received!")

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

    print("play song net received")

    local stopsong = net.ReadBool()

    if SONG then
        SONG:Stop()
        print("bitchslapped that weak song, say goodbye to your aux cord privileges")
    end

    if stopsong == true then return end

    print("PlaySong Net passed checks!")

    local stationname = net.ReadString()
    local url = net.ReadString()
    local artist = net.ReadString()
    local netsongname = net.ReadString()
    local timestamp = net.ReadFloat()

    currentStation = stationname

    print("URL: " .. url)
    print("Artist: " .. artist)
    print("Song: " .. netsongname)
    print("TimeStamp: " .. timestamp)

    local realtimestamp = math.Round(timestamp, 2) + 0.35
    local musicvolume = GetConVar("cl_chicagoRP_vehicleradio_volume"):GetFloat()

    print(realtimestamp)

    -- local g_station = nil
    sound.PlayURL(url, "noblock", function(station) -- add fade in/out
        if (IsValid(station)) then
            station:Play()
            station:SetVolume(0)
            SONG = station
            station:GetVolume()
            timer.Simple(0.35, function()
                if IsValid(station) then
                    station:SetTime(realtimestamp, false) -- fucking desync wtf???
                    station:SetVolume(musicvolume)
                    print(station:GetTime())
                end
            end)
            print("song playing")
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

    print("song stopped and index emptied")
end

local function MusicFloat(value, min, max, default)
    local value = tonumber(value)
    print("MusicFloat", value, min, max, default)

    return isnumber(value) and math.Clamp(tonumber(value), min, max) or default
end

cvars.AddChangeCallback("cl_chicagoRP_vehicleradio_volume", function(convar_name, value_old, value_new)
    local value = tonumber(value_new)
    local value_new = isnumber(value) and value or 1
    local value_new1 = MusicFloat(value_new, 0, 0.25, 0.05)
    local new_volume = tonumber(value_new1)

    timer.Simple(0, function()
        if SONG then
            SONG:SetVolume(new_volume)
        end
    end)
end)

net.Receive("chicagoRP_vehicleradio_stopsong", function()
    StopSong()

    print("stop song net received")
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

    print("station name sent!")
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
    print(bool)
    table.insert(ELEMENTS, {
        x = x,
        y = y,
        radius = radius,
        alpha = alpha,
        disable = bool
    })
end

local function UpdateElementsSize()
    if #ELEMENTS > 12 + 1 then
        IconSize = 48 - (minIconReduction - minIconReduction / (#ELEMENTS + 1 - 12 - 1))
    else
        IconSize = 48
    end
end

local function drawStationCircle(x, y, radius, color, k)
    local filled = circles.New(CIRCLE_FILLED, radius, x, y)
    filled:SetDistance(1)
    filled:SetMaterial(true)
    filled:SetColor(color)

    filled()

    surface.SetDrawColor(255, 255, 255, 255)
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

net.Receive("chicagoRP_vehicleradio", function()
    local ply = LocalPlayer()
    if IsValid(OpenMotherFrame) then OpenMotherFrame:Close() return end
    if !IsValid(ply) then return end
    if !IsValid(ply:GetVehicle()) then return end
    if !ply:InVehicle() then return end
    print(IsDriver(ply:GetVehicle(), ply))
    print("nigward")
    if (!IsDriver(ply:GetVehicle(), ply)) then return end
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
    motherFrame:SetDraggable(true)
    motherFrame:ShowCloseButton(true)
    motherFrame:SetTitle("Vehicle Radio")
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

    local stations = table.GetKeys(chicagoRP.radioplaylists)
    local count = #stations

    if count > 0 then
        local arcdegrees = 360 / count -- fix radio pos with this
        local radius = 300
        local d = 360
        ElementsDestroy()

        for i = 1, count do
            local rad = math.rad(d + arcdegrees * 0.50)
            local x = cx + math.cos(rad) * radius
            local y = cy - math.sin(rad) * radius
            d = d - arcdegrees
            if i == (count - 1) then
                ElementsAdd(x, y, IconSize, 100, true)
            else
                ElementsAdd(x, y, IconSize, 100, false)
            end
        end
    else
        notification.AddLegacy("You have not installed radio stations", 0, 3)
        surface.PlaySound("buttons/button14.wav")
    end

    UpdateElementsSize()

    function motherFrame:OnClose()
        if IsValid(self) then
            chicagoRP.PanelFadeOut(motherFrame, 0.15)
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
            -- draw.SimpleText(stationname, "VehiclesRadioVGUIFont", cx, cy - 40, whitecolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleTextOutlined(stationname, "VehiclesRadioVGUIFont", cx, cy - 40, whitecolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, blackcolor)
        end
        if isstring(artistname) and isstring(songname) then
            -- draw.SimpleText(artistname, "VehiclesRadioVGUIFont", cx, cy, whitecolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            -- draw.SimpleText(songname, "VehiclesRadioVGUIFont", cx, cy + 40, whitecolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleTextOutlined(artistname, "VehiclesRadioVGUIFont", cx, cy, whitecolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, blackcolor)
            draw.SimpleTextOutlined(songname, "VehiclesRadioVGUIFont", cx, cy + 40, whitecolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, blackcolor)
        end
    end

    local artistcachedname = nil

    for k, v in ipairs(ELEMENTS) do
        print(v.disable)
        if v.disable == false then
            local x = v.x
            local y = v.y

            print(k)

            x = cx - (cx - v.x)
            y = cy - (cy - v.y)

            -- print(chicagoRP.radioplaylists[k])

            local radius = v.radius
            local stationcachedname = chicagoRP.radioplaylists[k].printname
            print(cx - (cx - v.x))
            print(cy - (cy - v.y))

            local stationButton = motherFrame:Add("DButton")
            stationButton:SetText("")
            stationButton:SetSize(radius * 2.2, radius * 2.2)
            stationButton:SetPos(x - (radius * 2.2) / 2, y - (radius * 2.2) / 2)

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
                local buf, step = self.__hoverBuf or 0, RealFrameTime() * 1
                local Outlinebuf, Outlinestep = self.__hoverOutlineBuf or 0, RealFrameTime() * 1
                DisableClipping(true)

                if hovered then
                    v.radius = Lerp(math.min(RealFrameTime() * 5, 1), v.radius, IconSize * 1.1)

                    stationname = stationcachedname
                    artistname = artistcachedname
                    songname = songcachedname

                    -- print("X: " .. x)
                    -- print("Y: " .. y)
                    -- print("Radius: " .. radius)
                else
                    v.radius = Lerp(math.min(RealFrameTime() * 5, 1), v.radius, IconSize * 1.0)
                end

                -- print("CursorX: " .. cursorx)
                -- print("CursorY: " .. cursory)

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

                drawStationCircle(w / 2, h / 2, v.radius * 1.2, graynormal, k)

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
                    print("sendinfo Net Sent!")
                end

                if currentStation == chicagoRP.radioplaylists[k].name then return end

                timer.Simple(1.0, function()
                    print(IsValid(self))
                    print(self:IsHovered())
                    print(istable(chicagoRP.radioplaylists[k]))
                    print(chicagoRP.radioplaylists[k].name)
                    if IsValid(self) and self:IsHovered() and istable(chicagoRP.radioplaylists[k]) then
                        SendStation(chicagoRP.radioplaylists[k].name)
                        currentStation = chicagoRP.radioplaylists[k].name
                        currentStationPrintName = chicagoRP.radioplaylists[k].printname
                    end
                end)
            end

            net.Receive("chicagoRP_vehicleradio_receiveinfo", function()
                local artist = net.ReadString()
                local song = net.ReadString()

                artistcachedname = artist
                songcachedname = song
            end)
        elseif v.disable == true then
            print("RADIO OFF BUTTON")

            local x = v.x
            local y = v.y
            local radius = v.radius

            print(k)

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

    for _, v in ipairs(chicagoRP.radioplaylists) do
        local categoryButton = gameSettingsScrollPanel:Add("DButton")
        categoryButton:SetText(v.name)
        categoryButton:Dock(TOP)
        categoryButton:DockMargin(0, 10, 0, 0)
        categoryButton:SetSize(200, 50)

        function categoryButton:DoClick()
            timer.Simple(0.5, function()
                SendStation(v.name)
            end)
        end
    end

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

print("chicagoRP GUI loaded!")

-- bugs:
-- SetTime randomly desyncs for absolutely no fucking reason whatsoever (https://github.com/SpiffyJUNIOR/chicagoRP-vehicle-radio/issues/1) MUST FIX, HIGH PRIORITY!!!
-- previous stations song continuing to play when switching (fucking annoying as shit, fix this)
-- radio off button appears at end of wheel rather than bottom of the screen

-- to-do:
-- keep hover on station if currentstation == k or whatever
-- send station and song info to client when entering car
-- make radio open button hold open
-- add radio wheel hover like GTA 5
-- add random chance of album being inserted
-- add DJ/commerical support
-- make layout pos and size match GTA 5's