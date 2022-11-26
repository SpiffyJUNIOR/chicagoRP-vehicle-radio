AddCSLuaFile()

for i, f in pairs(file.Find("chicagoRP_vehicle_radio/*.lua", "LUA")) do
    if string.Left(f, 3) == "sv_" then
        if SERVER then 
            include("chicagoRP_vehicle_radio/" .. f) 
        end
    elseif string.Left(f, 3) == "cl_" then
        if CLIENT then
            include("chicagoRP_vehicle_radio/" .. f)
        else
            AddCSLuaFile("chicagoRP_vehicle_radio/" .. f)
        end
    elseif string.Left(f, 3) == "sh_" then
        AddCSLuaFile("chicagoRP_vehicle_radio/" .. f)
        include("chicagoRP_vehicle_radio/" .. f)
    else
        print("chicagoRP Vehicle Radio detected unaccounted for lua file '" .. f .. "' - check prefixes!")
    end
    print("chicagoRP Vehicle Radio successfully loaded!")
end
