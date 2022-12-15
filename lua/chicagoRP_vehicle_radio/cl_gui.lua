local HideHUD = false
local OpenMotherFrame = nil
local currentStation = nil
local currentStationPrintName = nil
local SONG = SONG or nil
local stationname = nil
local artistname = nil
local songname = nil
local ELEMENTS = {}
local IconSize = 48
local minIconReduction = 20
local Dynamic = 0
local reddebug = Color(200, 10, 10, 150)
local graynormal = Color(20, 20, 20, 150)
local grayhovered = Color(40, 40, 40, 100)
local whitecolor = Color(255, 255, 255, 255)
local gradientLeftColor = Color(230, 45, 40, 170)
local gradientRightColor = Color(245, 135, 70, 170)
local blurMat = Material("pp/blurscreen")
local gradientLeftMat = Material("vgui/gradient-l") -- gradient-d, gradient-r, gradient-u, gradient-l, gradient_down, gradient_up
local gradientRightMat = Material("vgui/gradient-r") -- gradient-d, gradient-r, gradient-u, gradient-l, gradient_down, gradient_up
AddCSLuaFile("circles.lua")
local circles = include("circles.lua")

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

hook.Add("HUDPaint", "chicagoRP_vehicleradio_HideHUD", function()
    if HideHUD == true then
        return false
    end
end)

net.Receive("chicagoRP_vehicleradio_playsong", function()
    local ply = LocalPlayer()
    if !IsValid(ply) then return end
    if !IsValid(ply:GetVehicle()) then return end
    if !ply:InVehicle() then return end

    print("play song net received")

    local stopsong = net.ReadBool()

    if IsValid(SONG) then
        SONG:Stop()
        print("bitchslapped that weak song, say goodbye to your aux cord privileges")
    end

    if stopsong == true then return end

    local url = net.ReadString()
    local artist = net.ReadString()
    local netsongname = net.ReadString()
    local timestamp = net.ReadFloat()

    print("URL: " .. url)
    print("Artist: " .. artist)
    print("Song: " .. netsongname)
    print("TimeStamp: " .. timestamp)

    local realtimestamp = math.Round(timestamp, 2) + 0.35

    if timestamp <= 0 then -- silly, might be made useless because of timer.Simple delay
        realtimestamp = 0
    end

    print(realtimestamp)

    local g_station = nil
    sound.PlayURL(url, "noblock", function(station) -- add fade in/out
        if (IsValid(station)) then
            station:Play()
            station:SetVolume(0)
            SONG = station
            station:GetVolume()
            timer.Simple(0.35, function()
                if IsValid(station) then
                    station:SetTime(realtimestamp, false) -- fucking desync wtf???
                    station:SetVolume(1.0)
                    -- SONG:SetTime(realtimestamp, false) -- or this (don't work :skull:)
                    print(station:GetTime())
                end
            end)
            print("song playing")
            g_station = station -- keep a reference to the audio object, so it doesn't get garbage collected which will stop the sound (garryism moment)
        else
            LocalPlayer():ChatPrint("Invalid URL!")
        end
    end)
end)

local function SendStation(name) -- maybe create actual stopsong function
    net.Start("chicagoRP_vehicleradio_receiveindex")
    net.WriteBool(true)
    net.WriteString(name)
    net.SendToServer()

    print("station name sent!")
end

local function StopSong()
    net.Start("chicagoRP_vehicleradio_receiveindex")
    net.WriteBool(false)
    net.SendToServer()

    print("song stopped and index emptied")
end

surface.CreateFont("VehiclesRadioVGUIFont", {
    font = "Roboto",
    dc = false,
    size = 36,
    weight = 500,
    blursize = 0,
    scanlines = 0,
    antialias = true
})

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

local function UpdateElementsSize()
    if #ELEMENTS > 12 then
        IconSize = 48 - (minIconReduction - minIconReduction / (#ELEMENTS - 12))
    else
        IconSize = 48
    end
end

local function drawStationCircle(x, y, radius, color, k) -- nice af function, saves lots of trouble
    local filled = circles.New(CIRCLE_FILLED, radius, x, y)
    filled:SetDistance(1)
    filled:SetMaterial(true)
    filled:SetColor(color)

    filled()

    local mat = Material(chicagoRP.radioplaylists[k].icon) -- cache these you fucking retard
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(mat)
    surface.DrawTexturedRectRotated(x, y, IconSize * 2, IconSize * 2, 0)
end

local function drawOutlineCircle(x, y, radius, thickness, color, material) -- nice af function, saves lots of trouble
    if material == nil then material = true end

    local outlined = circles.New(CIRCLE_OUTLINED, radius, x, y, thickness)
    outlined:SetDistance(1)
    outlined:SetColor(color)
    outlined:SetMaterial(material)

    outlined()
end

net.Receive("chicagoRP_vehicleradio", function() -- if not driver then return end
    local ply = LocalPlayer()
    if IsValid(OpenMotherFrame) then OpenMotherFrame:Close() return end
    if !IsValid(ply) then return end
    if !IsValid(ply:GetVehicle()) then return end
    if !ply:InVehicle() then return end

    local screenwidth = ScrW()
    local screenheight = ScrH()
    local cx = screenwidth / 2
    local cy = screenheight / 2
    local motherFrame = vgui.Create("DFrame") -- switch to circles library, use code from freddy15's solution as an example
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
    motherFrame:SetMouseInputEnabled(true) -- enable mouse input but not keyboard input
    motherFrame:Center()

    local stations = table.GetKeys(chicagoRP.radioplaylists)
    local count = #stations

    if count > 0 then
        local arcdegrees = 360 / count
        local radius = 300
        local d = 360
        ElementsDestroy()

        for i = 1, count do
            local rad = math.rad(d + arcdegrees * 0.50)
            local x = cx + math.cos(rad) * radius
            local y = cy - math.sin(rad) * radius
            ElementsAdd(x, y, IconSize, 100)
            d = d - arcdegrees
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
            self:AlphaTo(50, 0.15, 0)
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
        if IsValid(SONG) then
            SONG:GetTime()
        end
        -- print(stationname)
        -- print(IsValid(stationname))
        -- print(isstring(stationname))
        if isstring(stationname) then
            draw.SimpleText(stationname, "VehiclesRadioVGUIFont", cx, cy - 40, whitecolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        if isstring(artistname) and isstring(songname) then
            draw.SimpleText(artistname, "VehiclesRadioVGUIFont", cx, cy, whitecolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(songname, "VehiclesRadioVGUIFont", cx, cy + 40, whitecolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    hook.Add("PlayerLeaveVehicle", "chicagoRP_vehicleradio_leavevehicle", function(ply, veh)
        motherFrame:AlphaTo(50, 0.15, 0)
        surface.PlaySound("chicagoRP_settings/back.wav")
        timer.Simple(0.15, function()
            if IsValid(motherFrame) then
                motherFrame:Close()
            end
        end)
    end)

    local artistcachedname = nil

    for k, v in ipairs(ELEMENTS) do
        local x = v.x
        local y = v.y

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
                v.radius = IconSize
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

            drawOutlineCircle(w / 2, h / 2, v.radius * 1.2, 50, gradientLeftColor, gradientLeftMat)
            drawOutlineCircle(w / 2, h / 2, v.radius * 1.2, 50, gradientRightColor, gradientRightMat)

            -- draw.RoundedBox(8, 0, 0, w, h, Color(200, 0, 0, 10)) -- debug square
            -- if !hovered then
            --     drawStationCircle(w / 2, h / 2, v.radius * 1.2, graynormal, k)
            -- elseif hovered then
            --     drawStationCircle(w / 2, h / 2, v.radius * 1.2, grayhovered, k)
            -- end

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

            timer.Simple(0.5, function()
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
    end

    local gameSettingsScrollPanel = vgui.Create("DScrollPanel", motherFrame)
    gameSettingsScrollPanel:Dock(LEFT)
    gameSettingsScrollPanel:SetSize(200, 50)

    for _, v in ipairs(chicagoRP.radioplaylists) do -- get driver + passengers, sendtoserver for each player, then send back to client
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
        if IsValid(SONG) then
            SONG:Stop()
            print("bitchslapped that wack ass song")
        end
        StopSong()
    end

    local debugVOLSongButton = gameSettingsScrollPanel:Add("DButton")
    debugVOLSongButton:SetText("SONG VOLUME")
    debugVOLSongButton:Dock(TOP)
    debugVOLSongButton:DockMargin(0, 10, 0, 0)
    debugVOLSongButton:SetSize(200, 50)

    function debugVOLSongButton:DoClick()
        if IsValid(SONG) then
            SONG:GetVolume()
            SONG:SetVolume(math.random(0.1, 0.9))
            print("got vol")
        end
    end

    OpenMotherFrame = motherFrame
end)

print("chicagoRP GUI loaded!")

-- to-do:
-- fix out of range timestamp caused by math.abs
-- fix previous stations song continuing to play
-- find GTA 5 radio font
-- add proper sound networking (simfphys and svmod support, MAYBE vcmod but it has bad documentation + i can't test it)
-- add random station upon entering vehicle
-- add volume convar + disable convar + disable random station convar
-- add random chance of album being inserted
-- add DJ/commerical support
-- fix HUDPaint not returning false
-- make layout pos and size match GTA 5's
-- SetTime randomly desyncs for absolutely no fucking reason whatsoever (https://github.com/SpiffyJUNIOR/chicagoRP-vehicle-radio/issues/1) MUST FIX, HIGH PRIORITY!!!
