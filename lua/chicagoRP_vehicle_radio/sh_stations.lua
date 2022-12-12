chicagoRP.radioplaylists = {
    {
        icon = "chicagorp_vehicleradio/industrial_metal.png",
        name = "alternative_metal",
        printname = "Liberty City Metal"
    }, {
        icon = "chicagorp_vehicleradio/ambient.png",
        name = "ambient",
        printname = "Ambient FM"
    }, {
        icon = "chicagorp_vehicleradio/idm.png",
        name = "idm",
        printname = "IDM FM"
    }, {
        icon = "chicagorp_vehicleradio/industrial_metal.png",
        name = "industrial_metal",
        printname = "Industrial Noise FM"
    }, {
        icon = "chicagorp_vehicleradio/new_wave.png",
        name = "new_wave",
        printname = "Poppin' FM"
    }, {
        icon = "chicagorp_vehicleradio/new_wave.png",
        name = "synthpop",
        printname = "Non Stop 80's"
    }
}

chicagoRP.alternative_metal = {
    {
        artist = "Deftones",
        length = 308, -- 262
        song = "Be Quiet and Drive (Far Away)",
        url = "https://files.catbox.moe/8xtxol.mp3"
    }, {
        artist = "System of a Down",
        length = 216, -- 519
        song = "Toxicity",
        url = "https://files.catbox.moe/3yizkl.mp3"
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
        artist = "Autechre",
        length = 519, -- 519
        song = "Acroyear2",
        url = "https://files.catbox.moe/s6xq61.mp3"
    }
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

chicagoRP.synthpop = {
    {
        artist = "Depeche Mode",
        length = 372, -- 262
        song = "Enjoy the Silence",
        url = "https://files.catbox.moe/x1ncso.mp3"
    }, {
        artist = "MGMT",
        length = 261, -- 519
        song = "Time to Pretend",
        url = "https://files.catbox.moe/zr32zq.mp3"
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