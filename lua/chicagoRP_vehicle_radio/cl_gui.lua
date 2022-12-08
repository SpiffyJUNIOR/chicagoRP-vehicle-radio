local HideHUD = false
local OpenMotherFrame = nil
local SONG = SONG or nil

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

    math.Round(timestamp, 2)

    local g_station = nil
    print(url)
    sound.PlayURL(url, "noblock", function(station)
        if (IsValid(station)) then
            station:Play()
            station:SetVolume(0)
            print(timestamp)
            print(station:IsBlockStreamed())
            SONG = station
            station:GetVolume()
            timer.Simple(0.1, function()
                station:SetTime(200, true)
                station:SetVolume(1.0)
                print(station:GetTime())
            end)
            print("song playing")
            g_station = station -- keep a reference to the audio object, so it doesn't get garbage collected which will stop the sound (garryism moment)
        else
            LocalPlayer():ChatPrint("Invalid URL!")
        end
    end)
end)

local function SendStation(enableradio, name)
    net.Start("chicagoRP_vehicleradio_receiveindex")
    net.WriteBool(enableradio)

    if enableradio == false then net.SendToServer() return end

    net.WriteString(name)
    net.SendToServer()

    print("station name sent!")

    print(enableradio)

    print(name)
end

net.Receive("chicagoRP_vehicleradio", function()
    local ply = LocalPlayer()
    if IsValid(OpenMotherFrame) then return end
    if !IsValid(ply) then return end
    if !IsValid(ply:GetVehicle()) then return end
    if !ply:InVehicle() then return end

    local screenwidth = ScrW()
    local screenheight = ScrH()
    local motherFrame = vgui.Create("DFrame")
    motherFrame:SetSize(300, 500)
    motherFrame:SetVisible(true)
    motherFrame:SetDraggable(true)
    motherFrame:ShowCloseButton(true)
    motherFrame:SetTitle("Vehicle Radio")
    motherFrame:ParentToHUD()
    HideHUD = true

    surface.PlaySound("chicagoRP_settings/back.wav")

    motherFrame:SetAlpha(0)
    motherFrame:AlphaTo(255, 0.15, 0)

    motherFrame:MakePopup()
    motherFrame:SetKeyboardInputEnabled(false)
    motherFrame:SetMouseInputEnabled(true) -- enable mouse input but not keyboard input
    motherFrame:Center()

    function motherFrame:Paint(w, h)
        chicagoRP.BlurBackground(self)
        draw.RoundedBox(8, 0, 0, w, h, Color(0, 0, 0, 0))
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

    local gameSettingsScrollPanel = vgui.Create("DScrollPanel", motherFrame)
    gameSettingsScrollPanel:Dock(FILL)

    for _, v in ipairs(chicagoRP.radioplaylists) do
        local categoryButton = gameSettingsScrollPanel:Add("DButton")
        categoryButton:SetText(v.name)
        categoryButton:Dock(TOP)
        categoryButton:DockMargin(0, 10, 0, 0)
        categoryButton:SetSize(200, 50)

        function categoryButton:DoClick()
            SendStation(true, v.name)
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
        SendStation(false)
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

    local debugTIMESongButton = gameSettingsScrollPanel:Add("DButton")
    debugTIMESongButton:SetText("SET SONG TIME")
    debugTIMESongButton:Dock(TOP)
    debugTIMESongButton:DockMargin(0, 10, 0, 0)
    debugTIMESongButton:SetSize(200, 50)

    function debugVOLSongButton:DoClick()
        if IsValid(SONG) then
            SONG:GetTime()
            SONG:SetTime(30, true)
            print("got + set time")
        end
    end

    OpenMotherFrame = motherFrame
end)

print("chicagoRP GUI loaded!")

-- to-do: