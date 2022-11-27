if CLIENT then
    VEHICLES_RADIOS = VEHICLES_RADIOS or {}

    function VRADIO:SetVolume(veh, volume)
        net.Start("VehicleRadioSendData")
        net.WriteInt(1, 32)
        net.WriteEntity(veh)
        net.WriteInt(volume, 32)
        net.SendToServer()
    end

    function VRADIO:Stop(veh)
        net.Start("VehicleRadioSendData")
        net.WriteInt(0, 32)
        net.WriteEntity(veh)
        net.SendToServer()

        if GetConVar("vehicles_radio_debug"):GetBool() then
            notification.AddLegacy("Radio off", 3, 5)
            print("Radio off")
        end
    end

    function VRADIO:Play(veh, index, volume)
        local trackconut = table.GetKeys(RADIO_STANTIONS[index].tracks)
        local trackindex = 0

        if veh.vradioCurStation and veh.vradioCurStation == index then
            if veh.vradioCurTrack == #trackconut - 1 then
                trackindex = 0
            else
                trackindex = veh.vradioCurTrack + 1
            end
        else
            trackindex = math.random(0, #trackconut - 1)
        end

        local track = RADIO_STANTIONS[index].tracks[trackindex]

        if track then
            net.Start("PlayVehicleRadio")
            net.WriteEntity(veh)
            net.WriteString(track)
            net.WriteInt(volume, 32)
            net.WriteInt(index, 32)
            net.WriteInt(trackindex, 32)
            net.SendToServer()
        else
            notification.AddLegacy("Track not found", 1, 5)
        end
    end

    hook.Add("Think", "ThinkVehiclesRadio", function()
        for k, v in pairs(VEHICLES_RADIOS) do
            if IsValid(Entity(k)) and Entity(k):IsVehicle() then
                local veh = Entity(k)
                local pos = veh:GetPos()
                v:SetPos(pos)

                if v:GetLength() > 0 and v:GetTime() >= v:GetLength() and not veh.vradioSended and veh.vradioCurStation then
                    VRADIO:Play(veh, veh.vradioCurStation, veh.vradioCurVolume or 100)
                    veh.vradioSended = true
                end
            else
                v:Stop()
                VEHICLES_RADIOS[k] = nil
            end
        end
    end)

    local function GetURL(url)
    end

    function VRADIO:GetConverterLink(url)
        if string.StartWith(string.lower(url), "https://www.youtube.com") or string.StartWith(string.lower(url), "http://www.youtube.com") then
            --return "https://ytbapi.com/dl.php?link=" .. url ..  "&format=mp3&text=ffffff&color=3880f3"
            notification.AddLegacy("Fuck your YouTube", 3, 15)
        end

        return false
    end

    net.Receive("BroadcastVehicleRadioData", function()
        local datatype = net.ReadInt(32)
        local veh = net.ReadEntity()

        if IsValid(veh) and IsValid(VEHICLES_RADIOS[veh:EntIndex()]) then
            if datatype == 0 then
                VEHICLES_RADIOS[veh:EntIndex()]:Stop()
                VEHICLES_RADIOS[veh:EntIndex()] = nil
                veh.vradioCurStation = nil
                veh.vradioCurTrack = nil
                veh.vradioCurVolume = nil
            elseif datatype == 1 then
                local volume = net.ReadInt(32)
                VEHICLES_RADIOS[veh:EntIndex()]:SetVolume(volume)
                veh.vradioCurVolume = volume
            end
        end
    end)

    net.Receive("BroadcastVehicleRadio", function()
        local veh = net.ReadEntity()
        local track = net.ReadString()
        local volume = net.ReadInt(32)
        local index = net.ReadInt(32)
        local trackindex = net.ReadInt(32)
        local flags = "3d"
        local isURL = string.sub(track, 1, 7) == "http://" or string.sub(track, 1, 8) == "https://"

        if IsValid(veh) and veh:IsVehicle() then
            if IsValid(VEHICLES_RADIOS[veh:EntIndex()]) then
                VEHICLES_RADIOS[veh:EntIndex()]:Stop()
                VEHICLES_RADIOS[veh:EntIndex()] = nil
            end

            if isURL then
                local converterLink = VRADIO:GetConverterLink(track)

                if converterLink then
                    print(converterLink)

                    http.Fetch(converterLink, function(body, size, headers, code)
                        SetClipboardText(body)
                    end)
                    --PrintTable(headers)
                else
                    sound.PlayURL(track, flags, function(station, errorID, errorName)
                        if IsValid(station) then
                            station:Play()
                            station:SetPos(veh:GetPos())
                            station:SetVolume(volume)
                            VEHICLES_RADIOS[veh:EntIndex()] = station
                            veh.vradioCurStation = index
                            veh.vradioCurTrack = trackindex
                            veh.vradioCurVolume = volume

                            if GetConVar("vehicles_radio_debug"):GetBool() then
                                notification.AddLegacy("Playing URL: " .. track, 3, 5)
                                print("Playing URL: " .. track)
                            end
                        else
                            notification.AddLegacy("Radio Playback error " .. errorName, 1, 5)
                            print("Radio Playback error " .. errorName)
                        end
                    end)
                end
            else
                sound.PlayFile("sound/" .. track, "3d", function(station, errorID, errorName)
                    if IsValid(station) then
                        station:Play()
                        station:SetPos(veh:GetPos())
                        station:SetVolume(volume)
                        VEHICLES_RADIOS[veh:EntIndex()] = station
                        veh.vradioCurStation = index
                        veh.vradioCurTrack = trackindex
                        veh.vradioCurVolume = volume

                        if GetConVar("vehicles_radio_debug"):GetBool() then
                            notification.AddLegacy("Playing File: " .. track, 3, 5)
                            print("Playing File: " .. track)
                        end
                    else
                        notification.AddLegacy("Radio Playback error " .. errorName, 1, 5)
                        print("Radio Playback error " .. errorName)
                    end
                end)
            end
        end

        veh.vradioSended = nil
    end)

    net.Receive("LeaveVehicleRadio", function(len)
        local ply = LocalPlayer()
        local veh = net.ReadEntity()

        if IsValid(ply) and ply:IsPlayer() then
            if IsValid(veh) and veh:IsVehicle() and GetConVar("vehicles_radio_autostop"):GetBool() then
                VRADIO:Stop(veh)
            end
        end
    end)
end

if SERVER then
    util.AddNetworkString("BroadcastVehicleRadio")
    util.AddNetworkString("BroadcastVehicleRadioData")
    util.AddNetworkString("VehicleRadioSendData")
    util.AddNetworkString("PlayVehicleRadio")
    util.AddNetworkString("StopVehicleRadio")
    util.AddNetworkString("LeaveVehicleRadio")

    net.Receive("PlayVehicleRadio", function(len, ply)
        local veh = net.ReadEntity()

        if IsValid(veh) and veh:IsVehicle() then
            local track = net.ReadString()
            local volume = net.ReadInt(32)
            local index = net.ReadInt(32)
            local trackindex = net.ReadInt(32)
            net.Start("BroadcastVehicleRadio")
            net.WriteEntity(veh)
            net.WriteString(track)
            net.WriteInt(volume, 32)
            net.WriteInt(index, 32)
            net.WriteInt(trackindex, 32)
            net.Broadcast()
        end
    end)

    net.Receive("VehicleRadioSendData", function(len, ply)
        local datatype = net.ReadInt(32)
        local veh = net.ReadEntity()

        if IsValid(veh) and veh:IsVehicle() then
            if datatype == 0 then
                net.Start("BroadcastVehicleRadioData")
                net.WriteInt(datatype, 32)
                net.WriteEntity(veh)
                net.Broadcast()
            elseif datatype == 1 then
                local volume = net.ReadInt(32)
                net.Start("BroadcastVehicleRadioData")
                net.WriteInt(datatype, 32)
                net.WriteEntity(veh)
                net.WriteInt(volume, 32)
                net.Broadcast()
            end
        end
    end)

    hook.Add("PlayerLeaveVehicle", "VehicleRadioLeave", function(ply, veh)
        if IsValid(veh) and IsValid(VRADIO:GetCar(veh)) then
            net.Start("LeaveVehicleRadio")
            net.WriteEntity(VRADIO:GetCar(veh))
            net.Send(ply)
        end
    end)
end