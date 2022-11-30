if table.IsEmpty(MusicList) then
    for v in ipairs(chicagoRP.radioplaylists) do
        local musicname = table.CopyFromTo(chicagoRP[v.name]playlist, MusicList)
    end
end

local function FindNextSong()
    if SONG then
        SONG:Stop()
    end
    
    if table.IsEmpty(MusicLeft) then
        MusicLeft = MusicList
    end
    
    for i, song in RandomPairs(MusicLeft) do
        NextSong = table.remove(MusicLeft, i)
        
        break
    end
    
    SONG = sound.PlayURL(url, "noblock", function())
    
    MusicTimer = CurTime() + SONG::GetLength() + 1
    
    if debugmode then
        print(("CURRENT SONG: %s"):format(NextSong))
        print(("SONG DURATION: %s"):format(string.ToMinutesSeconds(SoundDuration(NextSong))))
        
        PrintTable(MusicLeft)
    end
end