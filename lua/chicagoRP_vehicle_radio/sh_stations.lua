chicagoRP.radioplaylists = {
    {
        name = "ambient",
        printname = "Ambient FM"
    }, {
        name = "idm",
        printname = "IDM FM"
    }
}

chicagoRP.ambient = {
    {
        artist = "Aphex Twin",
        length = 440,
        song = "Blue Calx",
        url = "https://files.catbox.moe/m6q7g3.mp3"
    }, {
        artist = "Aphex Twin",
        length = 357,
        song = "Hexagon",
        url = "https://files.catbox.moe/a9mgh1.mp3"
    }, {
        artist = "Aphex Twin",
        length = 611,
        song = "Stone in Focus",
        url = "https://files.catbox.moe/w4ih54.mp3"
    }
}

chicagoRP.idm = {
    {
        artist = "Flying Lotus",
        length = 262,
        song = "Do the Astral Plane",
        url = "https://files.catbox.moe/sduxdr.mp3"
    }, {
        artist = "Autechre",
        length = 519,
        song = "Acroyear2",
        url = "https://files.catbox.moe/s6xq61.mp3"
    }
}

concommand.Add("chicagoRP_vehicleradio_ambienttable", function()
    if SERVER then
        local SysTime = SysTime
        local count = 5
        local StartTime = SysTime()

        table.Shuffle(chicagoRP.ambientplaylist)

        for i = 1, count do -- 0.232636 secs w/o shuffle, 0.246473 w shuffle
            PrintTable(chicagoRP.ambientplaylist)
        end

        local EndTime = SysTime()
        local TotalTime = EndTime - StartTime
        local AverageTime = TotalTime / count

        print("Total: " .. TotalTime .. " seconds. Average: " .. AverageTime .. " seconds.")
    end
end)

print("chicagoRP Vehicle Radio stations loaded!")