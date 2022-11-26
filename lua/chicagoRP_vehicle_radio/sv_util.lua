util.AddNetworkString("chicagoRP_vehicleradio")

concommand.Add("chicagoRP_vehicleradio", function(ply)
    if !IsValid(ply) then return end
    net.Start("chicagoRP_vehicleradio")
    net.Send(ply)
end)

print("chicagoRP Vehicle Radio server util loaded!")