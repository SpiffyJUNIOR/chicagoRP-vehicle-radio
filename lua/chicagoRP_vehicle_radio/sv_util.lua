util.AddNetworkString("chicagoRP_vehicleradio")
util.AddNetworkString("chicagoRP_vehicleradio_sendinfo")
util.AddNetworkString("chicagoRP_vehicleradio_receiveinfo")
util.AddNetworkString("chicagoRP_vehicleradio_receiveindex")
util.AddNetworkString("chicagoRP_vehicleradio_playsong")
util.AddNetworkString("chicagoRP_vehicleradio_stopsong")

local StartPosition = StartPosition or {}
local NextSongTime = NextSongTime or {}
local timestamp = timestamp or {}
-- local LastSongArtist = LastSongArtist or {}
-- local LastSongName = LastSongName or {}

-- local DJTalking = DJTalking or {}
-- local NoInterupt = NoInterupt or {}

local music_list = music_list or {}
local music_left = music_left or {}

local debugmode = true

local scriptenabled = GetConVar("sv_chicagoRP_vehicleradio_enable"):GetBool()
-- local djenabled = GetConVar("sv_chicagoRP_vehicleradio_DJ"):GetBool()
local randomstation = GetConVar("sv_chicagoRP_vehicleradio_randomstation"):GetBool()

local function isempty(s)
    return s == nil or s == ''
end

local function GetRealVehicle(vehicle, ply)
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

local function GetSimfphysPassengers(vehicle, ply)
    if !IsValid(ply) then return end
    if !IsValid(vehicle) then return end
    if !ply:InVehicle() then return end
    if !IsValid(ply:GetVehicle():GetParent()) then return end

    local plytable = {}
    local parent = vehicle:GetParent()
    local children = parent:GetChildren()
    local count = #children

    -- print(parent)
    -- PrintTable(children)

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
        local regulartable = {}
        -- table.insert(regulartable, vehicle:GetDriver())
        for i = 1, 8 do
            if IsValid(vehicle:GetPassenger(i)) then
                table.insert(regulartable, vehicle:GetPassenger(i))
            end
        end
        print(regulartable)
        PrintTable(regulartable)
        return regulartable
    end
end

for _, v in ipairs(chicagoRP.radioplaylists) do
    if !IsValid(music_list[v.name]) or table.IsEmpty(music_list[v.name]) then
        music_list[v.name] = music_list[v.name] or {}

        music_list[v.name] = table.Copy(chicagoRP[v.name])

        print("Source table generated!")

        PrintTable(music_list)
    end

    if !IsValid(music_left[v.name]) or table.IsEmpty(music_left[v.name]) then
        music_left[v.name] = music_left[v.name] or {}

        music_left[v.name] = table.Copy(music_list[v.name])

        for _, v2 in ipairs (music_left[v.name]) do
            local numbergen = math.random(0, 100)

            if !isempty(v2.chance) and numbergen >= v2.chance and !isempty(v2.playlist) and istable(chicagoRP[v2.playlist]) then
                for k, v3 in ipairs (chicagoRP[v2.playlist]) do -- fuck we actually need k indexed for this :skull:
                    table.insert(music_left[v.name], k, v)
                end
            elseif (numbergen =< v2.chance) or isempty(v2.chance) then
                table.remove(music_left[v.name], 1)
            end

            break -- if nobody got me i know break got me :pray:
        end

        table.Shuffle(music_left[v.name])

        print("music_left table generated!")

        for _, v2 in ipairs (music_left[v.name]) do
            StartPosition[v.name] = SysTime()
            NextSongTime[v.name] = StartPosition[v.name] + v2.length
            print("Inital StartPosition and NextSongTime set!")

            -- DJTalking[v.name] = false
            -- NoInterupt[v.name] = false

            break
        end
    end
end

local function PlaySong(ply)
    -- print("PlaySong ran!")

    local vehicle = ply:GetVehicle()
    local actualvehicle = GetRealVehicle(vehicle, ply)
    local secondindex = actualvehicle:GetNW2String("currentstation")

    if secondindex == nil or !scriptenabled then return end

    print(secondindex)

    if StartPosition[secondindex] - SysTime() != 0 then
        timestamp[secondindex] = math.abs(StartPosition[secondindex] - SysTime())
    else
        timestamp[secondindex] = 0
    end

    -- PrintTable(timestamp)
    -- print(StartPosition[secondindex])

    -- PrintTable(music_left[secondindex])

    for _, v2 in ipairs(music_left[secondindex]) do
        net.Start("chicagoRP_vehicleradio_playsong")
        net.WriteBool(false)
        net.WriteString(secondindex)
        net.WriteString(v2.url)
        net.WriteString(v2.artist)
        net.WriteString(v2.song)
        print(timestamp[secondindex])
        net.WriteFloat(timestamp[secondindex])
        net.Send(ply) -- get players somehow

        -- print("PlaySong Net sent!")

        break
    end

    -- if debugmode == true then
    --     for _, v in ipairs(music_left[secondindex]) do
    --         print(("CURRENT SONG: %s"):format(v.artist .. " - " .. v.song))
    --         print(("SONG DURATION: %s"):format(string.ToMinutesSeconds(v.length)))

    --         break
    --     end

    --     -- PrintTable(music_left)
    -- end
end

local function table_calculation()
    if !scriptenabled then return end

    for _, v in ipairs(chicagoRP.radioplaylists) do
        if NextSongTime[v.name] <= SysTime() + 2 and !table.IsEmpty(music_left[v.name]) then
            -- table.remove(music_left[v.name], 1)

            -- local LastSongArtist[v.name] = nil
            -- local LastSongName[v.name] = nil

            for _, v2 in ipairs (music_left[v.name]) do
                local numbergen = math.random(0, 100)

                LastSongArtist[v.name] = v2.artist
                LastSongName[v.name] = v2.song

                if !isempty(v2.chance) and (numbergen >= v2.chance) and !isempty(v2.playlist) and istable(chicagoRP[v2.playlist]) then
                    for k, v3 in ipairs (chicagoRP[v2.playlist]) do -- fuck we actually need k indexed for this :skull:
                        table.insert(music_left[v.name], k, v)
                        -- NoInterupt[v.name] = true
                        -- DJTalking[v.name] = false
                    end
                elseif (numbergen =< v2.chance) or isempty(v2.chance) then
                    table.remove(music_left[v.name], 1)
                    -- NoInterupt[v.name] = false
                    -- DJTalking[v.name] = true
                end

                -- local djtable = table.Shuffle(chicagoRP_DJ[v.name])

                -- for _, v5 in ipairs(djtable) do
                --     if DJTalking[v.name] = false and NoInterupt[v.name] = false and LastSongArtist[v.name] == v5.artist and LastSongName[v.name] == v5.song then
                --         table.insert(music_left[v.name], 1, v) -- hell

                --         break
                --     end
                -- end

                -- instead of doing entire seperate functions and operations for DJ: shuffle DJ table, loop through it, and do table.insert into music_left then break end

                StartPosition[v.name] = SysTime()
                NextSongTime[v.name] = StartPosition[v.name] + v2.length
                print("Future Song StartPosition and NextSongTime set!")

                for _, v4 in ipairs (player.GetAll()) do
                    local vehicle = v4:GetVehicle()

                    if !IsValid(vehicle) then break end

                    local actualvehicle = GetRealVehicle(vehicle, v4)
                    local secondindex = actualvehicle:GetNW2String("currentstation")

                    if v4:GetNW2Bool("activeradio") == false or secondindex == nil then break end

                    if v4:GetNW2Bool("activeradio") == true and v.name == secondindex then
                        print("Song played after previous ended")

                        PlaySong(v4)
                    end
                end

                break
            end

            -- print("Song removed")
        end
        if table.IsEmpty(music_left[v.name]) then
            music_left[v.name] = table.Copy(music_list[v.name])

            table.Shuffle(music_left[v.name])

            print("Table regenerated")

            for _, v2 in ipairs (music_left[v.name]) do
                local numbergen = math.random(0, 100)

                if !isempty(v2.chance) and numbergen >= v2.chance and !isempty(v2.playlist) and istable(chicagoRP[v2.playlist]) then
                    for k, v3 in ipairs (chicagoRP[v2.playlist]) do -- fuck we actually need k indexed for this :skull:
                        table.insert(music_left[v.name], k, v)
                        -- NoInterupt[v.name] = true
                    end
                elseif (numbergen =< v2.chance) or isempty(v2.chance) then
                    table.remove(music_left[v.name], 1)
                    -- NoInterupt[v.name] = false
                end

                StartPosition[v.name] = SysTime()
                NextSongTime[v.name] = StartPosition[v.name] + v2.length
                print("Regenerated StartPosition and NextSongTime set!")

                for _, v3 in ipairs (player.GetAll()) do
                    local vehicle = v3:GetVehicle()

                    if !IsValid(vehicle) then break end

                    local actualvehicle = GetRealVehicle(vehicle, v3)
                    local secondindex = actualvehicle:GetNW2String("currentstation")

                    if v3:GetNW2Bool("activeradio") == false or secondindex == nil then break end

                    if v3:GetNW2Bool("activeradio") == true and v.name == secondindex then
                        -- print("Song played after previous ended")

                        PlaySong(v3)
                    end
                end

                break
            end
        end
    end
end

net.Receive("chicagoRP_vehicleradio_receiveindex", function(len, ply)
    -- if !IsValid(ply) then return end
    -- if !IsValid(ply:GetVehicle()) then return end
    -- if !ply:InVehicle() then return end
    if !scriptenabled then return end

    local vehicle = ply:GetVehicle()
    local actualvehicle = GetRealVehicle(vehicle, ply)
    local passengertable = GetPassengerTable(vehicle, ply)

    -- print("receiveindex received")

    local enabled = net.ReadBool()

    if enabled == false then
        ply:SetNW2Bool("activeradio", false)
        if IsValid(actualvehicle) then
            actualvehicle:SetNW2String("currentstation", nil)
            print("receiveindex actualvehicle worked")
        end
    end

    if enabled == false then return end -- fucking syntax

    if enabled == true then
        ply:SetNW2Bool("activeradio", true)
    end

    local stationname = net.ReadString()

    actualvehicle:SetNW2String("currentstation", stationname)

    if istable(passengertable) then
        for _, v in ipairs(passengertable) do
            -- PrintTable(passengertable)
            -- print(v)
            PlaySong(v)
        end
    elseif IsValid(passengertable) then
        PlaySong(passengertable)
    else
        print("passengertable empty!")
    end

    -- print("station name received!")
end)

net.Receive("chicagoRP_vehicleradio_sendinfo", function(len, ply)
    -- print("fetchinfo received!")

    local station = net.ReadString()

    for _, v2 in ipairs(music_left[station]) do
        net.Start("chicagoRP_vehicleradio_receiveinfo")
        net.WriteString(v2.artist)
        net.WriteString(v2.song)
        net.Send(ply)

        -- print("fetchinfo Net sent!")

        break
    end
end)

hook.Add("PlayerEnteredVehicle", "chicagoRP_vehicleradio_leftvehicle", function(ply, veh, role)
    local actualvehicle = GetRealVehicle(veh, ply)
    local stationname = actualvehicle:GetNW2String("currentstation")

    if !scriptenabled then return end

    print(stationname)
    print(isstring(stationname))
    print(IsValid(stationname))
    print(stationname == nil)
    print(isempty(stationname))

    if isempty(stationname) and randomstation then
        for _, v in RandomPairs(chicagoRP.radioplaylists) do
            stationname = v.name

            break
        end
    end

    if stationname == nil then return end

    actualvehicle:SetNW2String("currentstation", stationname)

    ply:SetNW2Bool("activeradio", true)

    PlaySong(ply)
end)

hook.Add("PlayerLeaveVehicle", "chicagoRP_vehicleradio_leftvehicle", function(ply, veh)
    if !scriptenabled then return end

    net.Start("chicagoRP_vehicleradio")
    net.WriteBool(false)
    net.Send(ply)

    if ply:GetNW2Bool("activeradio") == true then
        -- local actualvehicle = GetRealVehicle(veh, ply)

        ply:SetNW2Bool("activeradio", false)
        -- actualvehicle:SetNW2String("currentstation", nil)

        net.Start("chicagoRP_vehicleradio_stopsong")
        net.Send(ply)
    end
end)

local function MusicHandler()
    table_calculation()
end

hook.Add("Tick", "chicagoRP_vehicleradio_tablelogicloop", MusicHandler)

concommand.Add("chicagoRP_vehicleradio", function(ply) -- how we close/open this based on bind being held?
    if !IsValid(ply) then return end
    -- net.Start("chicagoRP_vehicleradio")
    -- net.WriteBool(true)
    -- net.Send(ply)
end)

concommand.Add("print_musiclist", function(ply)
    for _, v in ipairs(chicagoRP.radioplaylists) do
        PrintTable(music_list[v.name])
    end
    PrintTable(music_list)
    print("music_list printed")
end)

concommand.Add("print_musicleft", function(ply)
    for _, v in ipairs(chicagoRP.radioplaylists) do
        PrintTable(music_left[v.name])
    end
    PrintTable(music_left)
    print("music_left printed")
end)

concommand.Add("print_timers", function(ply)
    PrintTable(StartPosition)
    print("StartPosition^^^^^")
    PrintTable(NextSongTime)
    print("NextSongTime^^^^^")
    PrintTable(timestamp)
    print("TimeStamp^^^^^")
    print("timers printed")
    print("SysTime: " .. SysTime())
    for _, v in ipairs(chicagoRP.radioplaylists) do
        print(NextSongTime[v.name] <= SysTime())
        print(StartPosition[v.name])
        print("StartPosition^^^^^")
        print(NextSongTime[v.name])
        print("NextSongTime^^^^^")
    end
end)

concommand.Add("getrealvehicle", function(ply)
    local vehicle = ply:GetVehicle()
    if vehicle == nil then return end

    print(GetRealVehicle(vehicle, ply))
end)

concommand.Add("getradio", function(ply)
    local vehiclett = ply:GetVehicle()
    if vehiclett == nil then return end
    local actualvehicle = GetRealVehicle(vehiclett, ply)

    if actualvehicle == nil then return end

    local stationname = actualvehicle:GetNW2String("currentstation")
    print(isempty(stationname))
    print(stationname)
    print(ply:GetNW2Bool("activeradio"))
end)

print("chicagoRP Vehicle Radio server util loaded!")