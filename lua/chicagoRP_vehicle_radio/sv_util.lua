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
local MusicTimer = MusicTimer or SysTime() + 1
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

        PrintTable(music_list)
    end

    if !IsValid(music_left[v.name]) or table.IsEmpty(music_left[v.name]) then
        music_left[v.name] = music_list[v.name] or {}

        table.CopyFromTo(music_list[v.name], music_left[v.name])

        PrintTable(music_left)
    end
end

net.Receive("chicagoRP_vehicleradio_receiveindex", function(ply)
    if !IsValid(ply) then return end
    if !IsValid(ply:GetVehicle()) then return end
    if !ply:InVehicle() then return end

    local stationname = net.ReadString()

    firstindex = music_list[stationname]
    secondindex = music_left[stationname]
end)

local function find_next_song(tableinput, secondtableinput)
    local nextsonglength = nextsonglength or 0
    
    if table.IsEmpty(secondtableinput) then
        secondtableinput = tableinput
    end
    
    for _, v in ipairs(secondtableinput) do
        next_song = table.remove(secondtableinput, 1)
        nextsonglength = next_song.length

        break
    end

    net.Start("chicagoRP_vehicleradio_playsong")
    net.ReadString(url)
    net.ReadString(artist)
    net.ReadString(songname)
    net.ReadInt(number, 16) -- timestamp
    net.Send(Entity(1)) -- get players somehow

    MusicTimer = SysTime() + nextsonglength + 1
    
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
        print(MusicTimer)
        print(CurTime())
        print("musichandler true")
        if !IsValid(firstindex) or !IsValid(secondindex) or !music_list then return end -- or MusicTimer > CurTime()

        find_next_song(firstindex, secondindex)
    end
end

hook.Add("Tick", "BGM", function()
    if !co_MusicHandler or !coroutine.resume(co_MusicHandler) then
        print("coroutine music handler created")
        co_MusicHandler = coroutine.create(MusicHandler)
        coroutine.resume(co_MusicHandler)
    end
end)

print("chicagoRP Vehicle Radio server util loaded!")