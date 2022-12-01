local HideHUD = false
local OpenMotherFrame = nil
local MusicTimer = MusicTimer or SysTime() + 1
SONG = SONG or nil
local music_list = music_list or {}
local music_left = music_left or {}
local next_song = next_song or ""
-- local co_MusicHandler
local debugmode = true

for _, v in ipairs(chicagoRP.radioplaylists) do
    if !IsValid(music_list[v.name]) or table.IsEmpty(music_list[v.name]) then
        music_list[v.name] = table.Copy(chicagoRP[v.name])
        music_left[v.name] = table.Copy(chicagoRP[v.name])
        table.Shuffle(music_list[v.name])

        PrintTable(music_list)
    end
end

hook.Add("HUDPaint", "chicagoRP_vehicleradio_HideHUD", function()
    if HideHUD then
        return false
    end
end)

local function find_next_song(tableinput, secondtableinput)
    if SONG then
        SONG:Stop()
    end
    
    if table.IsEmpty(secondtableinput) then
        secondtableinput = tableinput
    end
    
    for _, v in ipairs(secondtableinput) do
        next_song = table.remove(secondtableinput, 1)

        break
    end

    for _, v2 in ipairs(secondtableinput) do
        local g_station = nil
        print(v2.url)
        sound.PlayURL(v2.url, "noblock", function(station)
            if (IsValid(station)) then
                station:Play()
                SONG = station
                -- Keep a reference to the audio object, so it doesn't get garbage collected which will stop the sound
                g_station = station
            else
                LocalPlayer():ChatPrint( "Invalid URL!" )
            end
        end)

        break
    end

    for _, v in ipairs(secondtableinput) do
        MusicTimer = SysTime() + next_song.length + 1

        break
    end
    
    if debugmode == true then
        print(("CURRENT SONG: %s"):format(next_song))
        for _, v in ipairs(secondtableinput) do
            print(("SONG DURATION: %s"):format(string.ToMinutesSeconds(next_song.length)))

            break
        end
        
        PrintTable(music_left)
    end
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
            -- PlaySong()
            find_next_song(music_list[v.name], music_left[v.name])
        end
    end

    local debugStopSongButton = gameSettingsScrollPanel:Add("DButton")
    debugStopSongButton:SetText("STOP SONG")
    debugStopSongButton:Dock(TOP)
    debugStopSongButton:DockMargin(0, 10, 0, 0)
    debugStopSongButton:SetSize(200, 50)

    function debugStopSongButton:DoClick()
        SONG:Stop()
    end

    -- function gameSettingsScrollPanel:Paint(w, h)
    --     -- draw.RoundedBox(8, 0, 0, w, h, Color(200, 0, 0, 10))
    --     -- print(self:IsVisible())
    --     return nil
    -- end

    -- local gameSettingsScrollBar = gameSettingsScrollPanel:GetVBar() -- mr biden please legalize nuclear bombs
    -- gameSettingsScrollBar:SetHideButtons(true)
    -- gameSettingsScrollBar:SetPos(HorizontalScreenScale(525), VerticalScreenScale(185))
    -- function gameSettingsScrollBar:Paint(w, h)
    --     draw.RoundedBox(0, 0, 0, w, h, Color(42, 40, 35, 66))
    -- end
    -- function gameSettingsScrollBar.btnGrip:Paint(w, h)
    --     draw.RoundedBox(0, 0, 0, w, h, Color(76, 76, 74, 150))
    -- end

    OpenMotherFrame = motherFrame
end)

print("chicagoRP GUI loaded!")

-- to-do: