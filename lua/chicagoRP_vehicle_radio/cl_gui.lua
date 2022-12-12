local HideHUD = false
local OpenMotherFrame = nil
local SONG = SONG or nil
AddCSLuaFile("circles.lua")
local circles = include("circles.lua")

-- PrintTable(circles)

hook.Add("HUDPaint", "chicagoRP_vehicleradio_HideHUD", function()
    if HideHUD then
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
    local songname = net.ReadString()
    local timestamp = net.ReadFloat()

    print("URL: " .. url)
    print("Artist: " .. artist)
    print("Next Song: " .. songname)
    print("TimeStamp: " .. timestamp)

    local realtimestamp = math.Round(timestamp, 2) + 0.35

    if timestamp == 0 then -- silly, might be made useless because of timer.Simple delay
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
                station:SetTime(realtimestamp, false) -- fucking desync wtf???
                station:SetVolume(1.0)
                print(station:GetTime())
            end)
            print("song playing")
            g_station = station -- keep a reference to the audio object, so it doesn't get garbage collected which will stop the sound (garryism moment)
        else
            LocalPlayer():ChatPrint("Invalid URL!")
        end
    end)
    -- timer.Create("StationSetTime", 0, 0, function()
    --     if station:GetTime() > 0.35 then
    --         timer.Remove("StationSetTime")
    --         station:SetTime(30, false)    
    --     end
    -- end)
end)

local function SendStation(name) -- maybe create actual stopsong function
    net.Start("chicagoRP_vehicleradio_receiveindex")
    net.WriteBool(enableradio)

    if enableradio == false then net.SendToServer() return end

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

local ELEMENTS = {}
local IconSize = 48
local minIconReduction = 20
local Alpha = 0
local MovementMul = 0
local reddebug = Color(200, 10, 10, 150)
local graynormal = Color(55, 55, 55, 0)
local grayhovered = Color(155, 155, 155, 0)
local whitecolor = Color(255, 255, 255, 255)
local HoverIndex

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

local function ElementHoverIndex()
    for k, v in pairs(ELEMENTS) do
        if v.hover then return k end
    end
end

local function UpdateElementsSize()
    if #ELEMENTS > 12 then
        IconSize = 48 - (minIconReduction - minIconReduction / (#ELEMENTS - 12))
    else
        IconSize = 48
    end
end

local function drawFilledCircle(x, y, radius, color)
    local filled = circles.New(CIRCLE_FILLED, radius, x, y)
    filled:SetDistance(1)
    filled:SetMaterial(true)
    filled:SetColor(color)

    filled()
end

local function HoverSound()
    local createdsound = CreateSound(game.GetWorld(), "chicagorp_settings/hover.wav", 0)
    if createdsound then
        createdsound:SetSoundLevel(0)
        createdsound:Stop()
        createdsound:Play()
    end
    return hoverslide
end

net.Receive("chicagoRP_vehicleradio", function() -- if not driver then return end
    local ply = LocalPlayer()
    if IsValid(OpenMotherFrame) then OpenMotherFrame:Close() return end
    if !IsValid(ply) then return end
    if !IsValid(ply:GetVehicle()) then return end
    if !ply:InVehicle() then return end

    local screenwidth = ScrW()
    local screenheight = ScrH()
    local motherFrame = vgui.Create("DFrame") -- switch to circles library, use code from freddy15's solution as an example
    motherFrame:SetSize(screenwidth, screenheight)
    motherFrame:SetVisible(true)
    motherFrame:SetDraggable(true)
    motherFrame:ShowCloseButton(true)
    motherFrame:SetTitle("Vehicle Radio")
    motherFrame:ParentToHUD()
    HideHUD = true

    surface.PlaySound("chicagoRP_settings/back.wav")

    chicagoRP.PanelFadeIn(motherFrame, 0.15)

    motherFrame:MakePopup()
    motherFrame:SetKeyboardInputEnabled(false)
    motherFrame:SetMouseInputEnabled(true) -- enable mouse input but not keyboard input
    motherFrame:Center()

    local stations = table.GetKeys(chicagoRP.radioplaylists)
    local count = #stations + 1

    if count > 0 then
        local scrw, scrh = ScrW(), ScrH()
        local arcdegrees = 360 / count
        local radius = 300
        local d = 360
        ElementsDestroy()

        for i = 1, count do
            local rad = math.rad(d + arcdegrees * 0.50) -- why not power of 1 or 2?
            local x = scrw / 2 + math.cos(rad) * radius
            local y = scrh / 2 - math.sin(rad) * radius
            ElementsAdd(x, y, IconSize, 100)
            d = d - arcdegrees
        end
    else
        notification.AddLegacy("You have not installed radio stations", 0, 3)
        surface.PlaySound("buttons/button14.wav")
    end

    function motherFrame:Paint(w, h)
        chicagoRP.BlurBackground(self)
        -- draw.RoundedBox(8, 0, 0, w, h, Color(0, 0, 0, 0))
        local cx = ScrW() / 2
        local cy = ScrH() / 2
        local cursorx, cursory = input.GetCursorPos()
        -- local filledCircle = circles.New(CIRCLE_FILLED, 64, 400, 255)
        -- filledCircle:SetDistance(1)
        -- filledCircle:SetMaterial(true)
        -- filledCircle:SetColor(reddebug)
        -- filledCircle()
        UpdateElementsSize()
        HoverIndex = nil
        if IsValid(SONG) then
            SONG:GetTime()
        end
    end

    function motherFrame:OnClose()
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

    hook.Add("PlayerLeaveVehicle", "chicagoRP_vehicleradio_leavevehicle", function(ply, veh)
        motherFrame:AlphaTo(50, 0.15, 0)
        surface.PlaySound("chicagoRP_settings/back.wav")
        timer.Simple(0.15, function()
            if IsValid(motherFrame) then
                motherFrame:Close()
            end
        end)
    end)

    for k, v in pairs(ELEMENTS) do
        local x = v.x
        local y = v.y
        local clampedMul = 1

        x = cx - (cx - v.x) * math.min(1, 1)
        y = cy - (cy - v.y) * math.min(1, 1)

        local radius = v.radius
        local stationname = chicagoRP.radioplaylists[k].printname
        local artistname = artistname or nil
        local stationname = stationname or nil

        local stationButton = parent:Add("DButton")
        stationButton:SetText("")
        stationButton:SetPos(x, y)
        stationButton:SetSize(radius, radius)

        -- draw.NoTexture()

        print("CursorX: " .. cursorx)
        print("CursorY: " .. cursory)

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
        function stationButton:Paint(w, h)
            if self:IsHovered() then -- we need an OnCursorEntered function for this
                v.radius = Lerp(math.min(RealFrameTime() * 5, 1), v.radius, IconSize * 1.1)

                timer.Simple(0.5, function()
                    if IsValid(self) and self:IsHovered() and IsValid(chicagoRP.radioplaylists[k]) then
                        net.Start("chicagoRP_vehicleradio_sendinfo")
                        net.WriteString(chicagoRP.radioplaylists[k].name)
                        net.SendToServer()
                        SendStation(chicagoRP.radioplaylists[k].name)
                    end
                end)

                if IsValid(stationname) then
                    draw.SimpleText(stationname, "VehiclesRadioVGUIFont", cx - 20, cy, whitecolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                else
                    draw.SimpleText("Radio Off", "VehiclesRadioVGUIFont", cx - 20, cy, whitecolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end

                if IsValid(stationname) and IsValid(artistname) and IsValid(songname) then
                    draw.SimpleText(artistname, "VehiclesRadioVGUIFont", cx, cy, whitecolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(songname, "VehiclesRadioVGUIFont", cx + 20, cy, whitecolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
                -- for grabbing artist/song, we send net with stationname to server immediately on hover, send back the info, then store it in local

                print("X: " .. x)
                print("Y: " .. y)
                print("Radius: " .. radius)
            else
                v.radius = IconSize
            end

            drawFilledCircle(x, y, v.radius * 1.2, graytransparent)
            if IsValid(chicagoRP.radioplaylists[k]) then
                local mat = Material(chicagoRP.radioplaylists[k].icon)
                surface.SetDrawColor(255, 255, 255, 255 * clampedMul)
                surface.SetMaterial(mat)
                surface.DrawTexturedRectRotated(x, y, IconSize * 2, IconSize * 2, 0)
            else
                local mat = Material("chicagorp_vehicleradio/ambient.png")
                surface.SetDrawColor(255, 255, 255, 255 * clampedMul)
                surface.SetMaterial(mat)
                surface.DrawTexturedRectRotated(x, y, IconSize * 2, IconSize * 2, 0)
            end

            return nil
        end

        net.Receive("chicagoRP_vehicleradio_receiveinfo", function()
            local artist = net.ReadString()
            local song = net.ReadString()

            artistname = artist
            songname = song
        end)

        function stationButton:OnCursorEntered()
            if IsValid(k) then
                HoverIndex = k
            else
                HoverIndex = true
            end
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