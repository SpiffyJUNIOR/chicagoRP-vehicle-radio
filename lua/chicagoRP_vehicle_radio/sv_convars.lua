local CVarFlags = {FCVAR_ARCHIVE, FCVAR_NOTIFY}

CreateConVar("sv_chicagoRP_vehicleradio_enable", 1, CVarFlags, "helptext", 0, 1)
-- CreateConVar("sv_chicagoRP_vehicleradio_DJ", 1, CVarFlags, "helptext", 0, 1)
CreateConVar("sv_chicagoRP_vehicleradio_randomstation", 1, CVarFlags, "helptext", 0, 1)

print("chicagoRP Vehicle Radio server convars loaded!")