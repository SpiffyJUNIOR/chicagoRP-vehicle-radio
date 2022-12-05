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

net.Receive("chicagoRP_vehicleradio_receiveindex", function(len, ply)
    if !IsValid(ply) then return end
    if !IsValid(ply:GetVehicle()) then return end
    if !ply:InVehicle() then return end

    local enabled = net.ReadBool()

    if enabled == false then activeradio = false return end

    if enabled == true then
        activeradio = true
    end

    local stationname = net.ReadString()

    print(stationname)

    firstindex = music_list[stationname]
    secondindex = music_left[stationname]

    PlaySong(ply)

    PrintTable(firstindex)
    PrintTable(secondindex)
    print(firstindex)
    print(secondindex)

    print("station name received!")
end)

local function table_calculation()
    for _, v in ipairs(chicagoRP.radioplaylists) do
        if NextSongTime[v.name] <= SysTime() and !table.IsEmpty(music_left[v.name]) then
            print("attempted to remove song")

            table.remove(music_left[v.name], 1)

            for _, v2 in ipairs (music_left[v.name]) do
                StartPosition[v.name] = SysTime()
                NextSongTime[v.name] = StartPosition[v.name] + v2.length
                print("future StartPosition and NextSongTime set!")

                if radioactive == true then
                    PlaySong()
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
                print("initial StartPosition and NextSongTime set!")

                if radioactive == true then
                    PlaySong()
                end

                break
            end
        end
    end
end

local function PlaySong(ply)
    print("PlaySong ran!")

    if ply == nil then ply == Entity(1) end

    for _, v1 in ipairs(chicagoRP.radioplaylists) do
        for _, v in ipairs(music_left[v1.name]) do
            timestamp[v.name] = StartPosition - SysTime()
        end
    end

    for _, v2 in ipairs(secondindex) do
        net.Start("chicagoRP_vehicleradio_playsong")
        net.WriteString(v2.url)
        net.WriteString(v2.artist)
        net.WriteString(v2.songname)
        for _, v3 in ipairs(chicagoRP.radioplaylists) do
            net.WriteFloat(timestamp[v3.name]) -- how the fuck do we get timestamp[v.name]

            print("PlaySong timestamp loop ran!")

            break
        end
        net.Send(Entity(1)) -- get players somehow

        print("play song net sent")

        break
    end

    if debugmode == true then
        for _, v in ipairs(secondtableinput) do
            print(("CURRENT SONG: %s"):format(v2.artist .. " - " .. v.songname))
            print(("SONG DURATION: %s"):format(string.ToMinutesSeconds(timestamp[v.name])))

            break
        end
        
        -- PrintTable(music_left)
    end
end

local function find_next_song(tableinput, secondtableinput) -- make this a meta function
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
        for _, v in ipairs(secondtableinput) do
            print(("CURRENT SONG: %s"):format(v2.artist .. " - " .. v.songname))

            print(("SONG DURATION: %s"):format(string.ToMinutesSeconds(timestamp[v2.name])))

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
        -- if activeradio == (false or nil) then return end -- or MusicTimer > CurTime()
        -- PrintTable(firstindex)
        -- PrintTable(secondindex)
        -- if activeradio == true then
        --     find_next_song(firstindex, secondindex)
        -- end
    end
end

hook.Add("Tick", "chicagoRP_vehicleradio_coroutine", function()
    if !co_MusicHandler or !coroutine.resume(co_MusicHandler) then
        -- print("coroutine music handler created")
        co_MusicHandler = coroutine.create(MusicHandler)
        coroutine.resume(co_MusicHandler)
    end
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