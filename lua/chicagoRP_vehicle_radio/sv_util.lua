util.AddNetworkString("chicagoRP_vehicleradio")
util.AddNetworkString("chicagoRP_vehicleradio_sendinfo")
util.AddNetworkString("chicagoRP_vehicleradio_receiveinfo")
util.AddNetworkString("chicagoRP_vehicleradio_receiveindex")
util.AddNetworkString("chicagoRP_vehicleradio_playsong")
util.AddNetworkString("chicagoRP_vehicleradio_stopsong")

local firstindex = firstindex or nil -- might cause issues with multiple players
local secondindex = secondindex or nil -- might cause issues with multiple players

local StartPosition = StartPosition or {}
local NextSongTime = NextSongTime or {}
local timestamp = timestamp or {}

local music_list = music_list or {}
local music_left = music_left or {}

local activeradio = activeradio or false -- might cause issues with multiple players
local debugmode = true

local scriptenabled = GetConVar("sv_chicagoRP_vehicleradio_enable"):GetBool()
local randomstation = GetConVar("sv_chicagoRP_vehicleradio_randomstation"):GetBool()

local function GetRealVehicle(vehicle, ply)
    if !IsValid(ply) then return end
    if !IsValid(vehicle) then return end
    if !ply:InVehicle() then return end

    if ConVarExists("sv_simfphys_enabledamage") or SVMOD:GetAddonState() == true then -- no GetSimfphysState function so we do convar check
        if IsValid(ply:GetSimfphys()) and IsValid(ply:GetVehicle():GetParent()) then
           return ply:GetVehicle():GetParent()
        elseif SVMOD and SVMOD:IsVehicle(vehicle) then
            return vehicle:SV_GetDriverSeat():GetParent()
        else
            return ply:GetVehicle()
        end
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

    print(parent)
    PrintTable(children)

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

    local finaltable = nil

    if ConVarExists("sv_simfphys_enabledamage") then -- no GetSimfphysState function so we do convar check
        if IsValid(ply:GetSimfphys()) and IsValid(ply:GetVehicle():GetParent()) then
            return GetSimfphysPassengers(vehicle, ply)
        end
    elseif SVMOD:GetAddonState() == true then
        if SVMOD:IsVehicle(vehicle) then
            return vehicle:SV_GetAllPlayers()
        end
    else return vehicle:GetDriver() end
end

for _, v in ipairs(chicagoRP.radioplaylists) do
    -- if !IsValid(chicagoRP[v.name]) then goto skip end -- replace with continue/return before release

    if !IsValid(music_list[v.name]) or table.IsEmpty(music_list[v.name]) then
        music_list[v.name] = music_list[v.name] or {}

        music_list[v.name] = table.Copy(chicagoRP[v.name])

        print("Source table generated!")

        PrintTable(music_list)
    end

    if !IsValid(music_left[v.name]) or table.IsEmpty(music_left[v.name]) then
        music_left[v.name] = music_left[v.name] or {}

        music_left[v.name] = table.Copy(music_list[v.name])

        table.Shuffle(music_left[v.name])

        print("music_left table generated!")

        for _, v2 in ipairs (music_left[v.name]) do
            StartPosition[v.name] = SysTime()
            NextSongTime[v.name] = StartPosition[v.name] + v2.length
            print("Inital StartPosition and NextSongTime set!")

            break
        end
        -- ::skip:: -- dunno if proper usage but higher likelyhood that it works properly compared to simply doing return end
        -- PrintTable(music_left)
    end
end

local function PlaySong(ply)
    print("PlaySong ran!")

    if secondindex == nil then return end

    if !scriptenabled then return end

    if ply == nil then ply = Entity(1) end

    -- for _, v1 in ipairs(music_left[secondindex]) do
    --     -- for _, v in ipairs(music_left[v1.name]) do
    --     --     timestamp[v1.name] = math.abs(StartPosition[v1.name] - SysTime())
    --     --     -- PrintTable(timestamp)
    --     --     -- print(StartPosition[v1.name])
    --     --     -- print(SysTime())
    --     -- end
    --     timestamp[secondindex] = math.abs(StartPosition[secondindex] - SysTime())
    --     PrintTable(timestamp)
    --     print(StartPosition[v1.name])
    -- end

    if StartPosition[secondindex] - SysTime() == 0 then
        print(StartPosition[secondindex])
        print("timestamp = 0")
        timestamp[secondindex] = 0
    else
        print(StartPosition[secondindex])
        print(SysTime())
        print("timestamp > 0")
        timestamp[secondindex] = math.abs(StartPosition[secondindex] - SysTime())
    end

    PrintTable(timestamp)
    print(StartPosition[secondindex])

    PrintTable(music_left[secondindex])

    for _, v2 in ipairs(music_left[secondindex]) do
        -- if !IsValid(music_left[secondindex]) then print("music_left list invalid!") goto skip end

        net.Start("chicagoRP_vehicleradio_playsong")
        net.WriteBool(false)
        net.WriteString(secondindex)
        net.WriteString(v2.url)
        net.WriteString(v2.artist)
        net.WriteString(v2.song)
        print(timestamp[secondindex])
        net.WriteFloat(timestamp[secondindex])
        net.Send(ply) -- get players somehow

        print("PlaySong Net sent!")

        -- ::skip:: -- dunno if proper usage but higher likelyhood that it works properly compared to simply doing return end

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
        -- if !IsValid(chicagoRP[v.name]) then goto skip end

        if NextSongTime[v.name] <= SysTime() and !table.IsEmpty(music_left[v.name]) then
            table.remove(music_left[v.name], 1)

            for _, v2 in ipairs (music_left[v.name]) do
                StartPosition[v.name] = SysTime()
                NextSongTime[v.name] = StartPosition[v.name] + v2.length
                -- timestamp[v.name] = math.abs(StartPosition[v.name] - SysTime())
                print("Future StartPosition and NextSongTime set!")

                if activeradio == false or firstindex == nil then break end

                if activeradio == true and v.name == firstindex then
                    print("Song played after previous ended")

                    PlaySong()

                    break
                end

                break
            end

            print("Song removed")
        end
        if table.IsEmpty(music_left[v.name]) then
            music_left[v.name] = table.Copy(music_list[v.name])

            table.Shuffle(music_left[v.name])

            print("Table regenerated")

            for _, v2 in ipairs (music_left[v.name]) do
                StartPosition[v.name] = SysTime()
                NextSongTime[v.name] = StartPosition[v.name] + v2.length
                -- timestamp[v.name] = math.abs(StartPosition[v.name] - SysTime())
                print("Regenerated StartPosition and NextSongTime set!")

                if activeradio == false or firstindex == nil then break end

                if activeradio == true and v.name == firstindex then
                    print("Song played after table regen")

                    PlaySong()

                    break
                end

                break
            end
        end
        -- ::skip:: -- dunno if proper usage but higher likelyhood that it works properly compared to simply doing return end
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

    print("receiveindex received")

    local enabled = net.ReadBool()

    if enabled == false then
        activeradio = false
        firstindex = nil
        secondindex = nil
    end

    if enabled == false then return end -- fucking syntax

    if enabled == true then
        activeradio = true
    end

    local stationname = net.ReadString()

    firstindex = stationname
    secondindex = stationname

    actualvehicle:SetNW2String("currentstation", stationname)

    for k, v in ipairs(passengertable) do
        PrintTable(passengertable)
        print(v)
        PlaySong(v)
    end

    -- PrintTable(firstindex)
    -- PrintTable(secondindex)

    print("station name received!")
end)

net.Receive("chicagoRP_vehicleradio_sendinfo", function(len, ply)
    print("fetchinfo received!")

    local station = net.ReadString()

    for _, v2 in ipairs(music_left[station]) do
        -- if !IsValid(music_left[station]) then print("music_left list invalid!") goto skip end

        net.Start("chicagoRP_vehicleradio_receiveinfo")
        net.WriteString(v2.artist)
        net.WriteString(v2.song)
        net.Send(ply)

        print("fetchinfo Net sent!")

        -- ::skip:: -- dunno if proper usage but higher likelyhood that it works properly compared to simply doing return end

        break
    end
end)

local function MusicHandler()
    -- print("SysTime: " .. SysTime())
    -- print("musichandler working")
    table_calculation()
end

hook.Add("Tick", "chicagoRP_vehicleradio_tablelogicloop", MusicHandler)

hook.Add("PlayerEnteredVehicle", "chicagoRP_vehicleradio_leftvehicle", function(ply, veh, role)
    local actualvehicle = GetRealVehicle(veh, ply)
    local stationname = actualvehicle:GetNW2String("currentstation")

    print(stationname)
    print("PlayerEnteredVehicle Cached^^^")

    if !scriptenabled then return end

    if !IsValid(stationname) and randomstation then
        for _, v in RandomPairs(chicagoRP.radioplaylists) do
            stationname = v.name

            -- print("AEUFKHBJJHEGBFHSJFJBHSDF")

            -- print(stationname)
            -- print("PlayerEnteredVehicle RandomPairs^^^")

            break
        end
    end

    if stationname == nil then return end

    firstindex = stationname
    secondindex = stationname

    print("SecondIndex " .. secondindex)

    activeradio = true

    PlaySong(ply)
end)

hook.Add("PlayerLeaveVehicle", "chicagoRP_vehicleradio_leftvehicle", function(ply, veh)
    if !scriptenabled then return end

    net.Start("chicagoRP_vehicleradio")
    net.WriteBool(false)
    net.Send(ply)

    if activeradio == true then
        activeradio = false
        net.Start("chicagoRP_vehicleradio_stopsong")
        net.Send(ply)
    end
end)

concommand.Add("chicagoRP_vehicleradio", function(ply) -- how we close/open this based on bind being held?
    if !IsValid(ply) then return end
    net.Start("chicagoRP_vehicleradio")
    net.WriteBool(true)
    net.Send(ply)
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
        -- if !IsValid(chicagoRP[v.name]) then goto skip end

        print(NextSongTime[v.name] <= SysTime())
        print(StartPosition[v.name])
        print("StartPosition^^^^^")
        print(NextSongTime[v.name])
        print("NextSongTime^^^^^")
        -- ::skip:: -- dunno if proper usage but higher likelyhood that it works properly compared to simply doing return end
    end
end)


print("chicagoRP Vehicle Radio server util loaded!")