util.AddNetworkString("chicagoRP_vehicleradio")
util.AddNetworkString("chicagoRP_vehicleradio_playsong")
util.AddNetworkString("chicagoRP_vehicleradio_receiveindex")

local firstindex = firstindex or nil
local secondindex = secondindex or nil

local StartPosition = StartPosition or {}
local NextSongTime = NextSongTime or {}
local timestamp = timestamp or {}

local music_list = music_list or {}
local music_left = music_left or {}
local next_song = next_song or ""

local activeradio = activeradio or false
local debugmode = true
local co_MusicHandler

for _, v in ipairs(chicagoRP.radioplaylists) do -- entire table calc needs to be moved to serverside
    if !IsValid(music_list[v.name]) or table.IsEmpty(music_list[v.name]) then
        music_list[v.name] = music_list[v.name] or {}

        music_list[v.name] = table.Copy(chicagoRP[v.name])

        print("music_list table generated")

        PrintTable(music_list)
    end

    if !IsValid(music_left[v.name]) or table.IsEmpty(music_left[v.name]) then
        music_left[v.name] = music_left[v.name] or {}

        music_left[v.name] = table.Copy(music_list[v.name])

        table.Shuffle(music_left[v.name])

        print("music_left table generated")

        for _, v2 in ipairs (music_left[v.name]) do
            StartPosition[v.name] = SysTime()
            NextSongTime[v.name] = StartPosition[v.name] + v2.length
            print("initial StartPosition and NextSongTime set!")

            break
        end

        -- PrintTable(music_left)
    end
end

local function PlaySong(ply)
    print("PlaySong ran!")

    if ply == nil then ply = Entity(1) end

    for _, v1 in ipairs(chicagoRP.radioplaylists) do
        -- for _, v in ipairs(music_left[v1.name]) do
        --     timestamp[v1.name] = math.abs(StartPosition[v1.name] - SysTime())
        --     -- PrintTable(timestamp)
        --     -- print(StartPosition[v1.name])
        --     -- print(SysTime())
        -- end
        timestamp[v1.name] = math.abs(StartPosition[v1.name] - SysTime())
        PrintTable(timestamp)
        print(StartPosition[v1.name])
    end

    PrintTable(music_left[secondindex])

    for _, v2 in ipairs(music_left[secondindex]) do
        print(v2.url)
        print(v2.artist)
        print(v2.song)
        -- print(IsValid(v2.url))
        -- print(IsValid(v2.artist))
        -- print(IsValid(v2.song))
        net.Start("chicagoRP_vehicleradio_playsong")
        net.WriteBool(false)
        net.WriteString(v2.url)
        net.WriteString(v2.artist)
        net.WriteString(v2.song)
        for _, v3 in ipairs(chicagoRP.radioplaylists) do
            print(timestamp[v3.name])
            net.WriteFloat(timestamp[v3.name]) -- how the fuck do we get timestamp[v.name]

            print("PlaySong timestamp loop ran!")

            break
        end
        net.Send(Entity(1)) -- get players somehow

        print("play song net sent")

        break
    end

    if debugmode == true then
        for _, v in ipairs(music_left[secondindex]) do
            print(("CURRENT SONG: %s"):format(v.artist .. " - " .. v.song))
            print(("SONG DURATION: %s"):format(string.ToMinutesSeconds(v.length)))

            break
        end

        -- PrintTable(music_left)
    end
end

local function table_calculation()
    for _, v in ipairs(chicagoRP.radioplaylists) do
        if NextSongTime[v.name] <= SysTime() and !table.IsEmpty(music_left[v.name]) then
            print("attempted to remove song")

            table.remove(music_left[v.name], 1)

            for _, v2 in ipairs (music_left[v.name]) do
                StartPosition[v.name] = SysTime()
                NextSongTime[v.name] = StartPosition[v.name] + v2.length
                -- timestamp[v.name] = math.abs(StartPosition[v.name] - SysTime())
                print("future StartPosition and NextSongTime set!")

                if activeradio == true then
                    local timesran = (timesran or 0) + 1
                    print(timesran)
                    
                    PlaySong()

                    break
                end

                break
            end

            print("song removed")
        end
        if table.IsEmpty(music_left[v.name]) then
            music_left[v.name] = table.Copy(music_list[v.name])

            table.Shuffle(music_left[v.name])

            print("music_left table regenerated")

            for _, v2 in ipairs (music_left[v.name]) do
                StartPosition[v.name] = SysTime()
                NextSongTime[v.name] = StartPosition[v.name] + v2.length
                -- timestamp[v.name] = math.abs(StartPosition[v.name] - SysTime())
                print("initial StartPosition and NextSongTime set!")

                if activeradio == true then
                    local timesran = (timesran or 0) + 1
                    print(timesran)

                    PlaySong()

                    break
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

    print("receiveindex received")

    local enabled = net.ReadBool()

    if enabled == false then activeradio = false return end

    if enabled == true then
        activeradio = true
        print("activeradio set to true")
        print(activeradio)
    end

    local stationname = net.ReadString()

    print(stationname)

    firstindex = stationname
    secondindex = stationname

    PlaySong(ply)

    -- PrintTable(firstindex)
    -- PrintTable(secondindex)
    print(firstindex)
    print(secondindex)

    print("station name received!")
end)

local function MusicHandler()
    -- print("SysTime: " .. SysTime())
    -- print("musichandler working")
    table_calculation()
end

hook.Add("Tick", "chicagoRP_vehicleradio_tablelogicloop", MusicHandler)

hook.Add("PlayerLeaveVehicle", "chicagoRP_vehicleradio_leftvehicle", function(ply, veh)
    if activeradio == true then
        activeradio = false
        net.Start("chicagoRP_vehicleradio_playsong")
        net.WriteBool(true)
        net.Send(Entity(1))
    end
end)

concommand.Add("chicagoRP_vehicleradio", function(ply)
    if !IsValid(ply) then return end
    net.Start("chicagoRP_vehicleradio")
    net.Send(ply)
end)

concommand.Add("print_musiclist", function(ply)
    for _, v in ipairs(chicagoRP.radioplaylists) do -- entire table calc needs to be moved to serverside
        PrintTable(music_list[v.name])
    end
    PrintTable(music_list)
    print("music_list printed")
end)

concommand.Add("print_musicleft", function(ply)
    for _, v in ipairs(chicagoRP.radioplaylists) do -- entire table calc needs to be moved to serverside
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


print("chicagoRP Vehicle Radio server util loaded!")