util.AddNetworkString("chicagoRP_vehicleradio")
util.AddNetworkString("chicagoRP_vehicleradio_playsong")
util.AddNetworkString("chicagoRP_vehicleradio_receiveindex")

concommand.Add("chicagoRP_vehicleradio", function(ply)
    if !IsValid(ply) then return end
    net.Start("chicagoRP_vehicleradio")
    net.Send(ply)
end)

local firstindex = firstindex or nil
local secondindex = secondindex or nil

local StartPosition = StartPosition or {}
local NextSongTime = NextSongTime or {}
local timestamp = timestamp or {}
-- local timestamp = StartPosition - SysTime()

local music_list = music_list or {}
local music_left = music_left or {}
local next_song = next_song or ""

local debugmode = true
local co_MusicHandler

for _, v in ipairs(chicagoRP.radioplaylists) do -- entire table calc needs to be moved to serverside
    if !IsValid(music_list[v.name]) or table.IsEmpty(music_list[v.name]) then
        music_list[v.name] = music_list[v.name] or {}

        table.CopyFromTo(chicagoRP[v.name], music_list[v.name])
        
        table.Shuffle(music_list[v.name])

        print("music_list table regenerated")

        PrintTable(music_list)
    end

    if !IsValid(music_left[v.name]) or table.IsEmpty(music_left[v.name]) then
        music_left[v.name] = music_list[v.name] or {}

        table.CopyFromTo(music_list[v.name], music_left[v.name])

        print("music_left table generated")

        for _, v2 in ipairs (music_left[v.name]) do
            StartPosition[v.name] = SysTime()
            NextSongTime[v.name] = StartPosition[v.name] + v2.length + 1
            print("initial StartPosition and NextSongTime set!")
        end

        PrintTable(music_left)
    end
end

net.Receive("chicagoRP_vehicleradio_receiveindex", function(len, ply)
    if !IsValid(ply) then return end
    if !IsValid(ply:GetVehicle()) then return end
    if !ply:InVehicle() then return end

    local stationname = net.ReadString()

    print(stationname)

    firstindex = music_list[stationname]
    secondindex = music_left[stationname]

    PrintTable(firstindex)
    PrintTable(secondindex)

    print("station name received!")
end)

local function table_calculation()
    for _, v2 in ipairs (music_left[v.name]) do
        if NextSongTime[v.name] <= StartPosition[v.name] then
            table.remove(music_left[v.name], 1)
            StartPosition[v.name] = SysTime()
            NextSongTime[v.name] = StartPosition[v.name] + v2.length + 1
            print("song removed")
        end
        if table.IsEmpty(music_left[v.name]) then
            music_left[v.name] = music_list[v.name]
            print("music_left table regenerated")
        end
    end
end

local function find_next_song(tableinput, secondtableinput)
    if !IsValid(tableinput) then return end
    if !IsValid(secondtableinput) then return end

    print("find_next_song running!")

    for _, v1 in ipairs(music_left[v.name]) do
        timestamp[v1.name] = StartPosition - SysTime()
    end

    for _, v2 in ipairs(secondtableinput) do
        net.Start("chicagoRP_vehicleradio_playsong")
        net.WriteString(v2.url)
        net.WriteString(v2.artist)
        net.WriteString(v2.songname)
        net.WriteFloat(timestamp[v2.name]) -- how the fuck do we get timestamp[v.name]
        net.Send(Entity(1)) -- get players somehow

        print("play song net sent")

        break
    end
    
    if debugmode == true then
        print(("CURRENT SONG: %s"):format(next_song))
        PrintTable(next_song)
        for _, v in ipairs(secondtableinput) do
            print(("SONG DURATION: %s"):format(string.ToMinutesSeconds(next_song.length)))

            break
        end
        
        PrintTable(music_left)
    end
end

local function MusicHandler()
    while true do
        -- print("Song Start Time: " .. StartPosition)
        -- print("Next Song: " .. NextSongTime)
        -- print("TimeStamp: " .. timestamp)
        -- print("CurTime: " .. CurTime())
        -- print("SysTime: " .. SysTime())
        -- print("musichandler true")
        table_calculation()
        if !IsValid(firstindex) or !IsValid(secondindex) or !music_list then return end -- or MusicTimer > CurTime()
        PrintTable(firstindex)
        PrintTable(secondindex)

        find_next_song(firstindex, secondindex)
    end
end

hook.Add("Tick", "BGM", function()
    if !co_MusicHandler or !coroutine.resume(co_MusicHandler) then
        -- print("coroutine music handler created")
        co_MusicHandler = coroutine.create(MusicHandler)
        coroutine.resume(co_MusicHandler)
    end
    if IsValid(StartPosition) then
        print("Song Start Time: " .. StartPosition)
    end
    if IsValid(NextSongTime) then
        print("Next Song: " .. NextSongTime)
    end
    if IsValid(timestamp) then
        print("TimeStamp: " .. timestamp)
    end
    -- print("CurTime: " .. CurTime())
    -- print("SysTime: " .. SysTime())
end)

concommand.Add("print_musiclist", function(ply)
    for _, v in ipairs(chicagoRP.radioplaylists) do -- entire table calc needs to be moved to serverside
        print(music_list[v.name])
    end
end)

concommand.Add("print_musicleft", function(ply)
    for _, v in ipairs(chicagoRP.radioplaylists) do -- entire table calc needs to be moved to serverside
        print(music_left[v.name])
    end
end)

concommand.Add("print_timers", function(ply)
    print("Song Start Time: " .. StartPosition)
    print("Next Song: " .. NextSongTime)
    print("TimeStamp: " .. timestamp)
end)


print("chicagoRP Vehicle Radio server util loaded!")