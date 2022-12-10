chicagoRP.radioplaylists = {
    {
        name = "ambient",
        printname = "Ambient FM"
    }, {
        name = "idm",
        printname = "IDM FM"
    }, {
        name = "industrial_metal",
        printname = "Industrial Noise FM"
    }, {
        name = "new_wave",
        printname = "Poppin' FM"
    }
}

chicagoRP.ambient = {
    {
        artist = "Aphex Twin",
        length = 440, -- 440
        song = "Blue Calx",
        url = "https://files.catbox.moe/m6q7g3.mp3"
    }, {
        artist = "Aphex Twin",
        length = 357, -- 357
        song = "Hexagon",
        url = "https://files.catbox.moe/a9mgh1.mp3"
    }, {
        artist = "Aphex Twin",
        length = 611, -- 611
        song = "Stone in Focus",
        url = "https://files.catbox.moe/w4ih54.mp3"
    }
}

chicagoRP.idm = {
    {
        artist = "Flying Lotus",
        length = 262, -- 262
        song = "Do the Astral Plane",
        url = "https://files.catbox.moe/sduxdr.mp3"
    }, {
        artist = "COUNTDOWN",
        length = 100, -- 519
        song = "CONTDOWN BBY",
        url = "https://files.catbox.moe/10m6if.mp3"
    }
    -- , {
    --     artist = "Autechre",
    --     length = 519, -- 519
    --     song = "Acroyear2",
    --     url = "https://files.catbox.moe/s6xq61.mp3"
    -- }
}

chicagoRP.industrial_metal = {
    {
        artist = "Strapping Young Lad",
        length = 337, -- 337
        song = "Detox",
        url = "https://files.catbox.moe/4vhe6k.mp3"
    }, {
        artist = "Strapping Young Lad",
        length = 343, -- 343
        song = "Love?",
        url = "https://files.catbox.moe/1wzdc4.mp3"
    }, {
        artist = "Strapping Young Lad",
        length = 402, -- 402
        song = "Skeksis",
        url = "https://files.catbox.moe/zu9jfn.mp3"
    }
}

chicagoRP.new_wave = {
    {
        artist = "David Bowie",
        length = 456, -- 456
        song = "Let's Dance",
        url = "https://files.catbox.moe/txe0bk.mp3"
    }, {
        artist = "New Order",
        length = 356, -- 356
        song = "Your Slient Face",
        url = "https://files.catbox.moe/80hgkv.mp3"
    }, {
        artist = "Talking Heads",
        length = 349, -- 349
        song = "Born Under Punches (The Heat Goes On)",
        url = "https://files.catbox.moe/4rfuv4.mp3"
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