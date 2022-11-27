VRADIO = {}

function VRADIO:IncludeFile(file)
    if SERVER then
        include(file)
        AddCSLuaFile(file)
    end

    if CLIENT then
        include(file)
    end
end

VRADIO:IncludeFile("vradio/main.lua")
VRADIO:IncludeFile("vradio/radio.lua")
VRADIO:IncludeFile("vradio/hud.lua")