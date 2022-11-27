RADIO_STANTIONS = {}

function VRADIO:IncludeStation(data)
    for k, v in pairs(data) do
        table.insert(RADIO_STANTIONS, {
            meta = v.meta,
            tracks = v.tracks
        })
    end
end

local files, directories = file.Find("vradio/stations/*.lua", "LUA")

for _, file in pairs(files) do
    VRADIO:IncludeFile("vradio/stations/" .. file)
end

for k, v in pairs(RADIO_STANTIONS) do
    RADIO_STANTIONS[k].soundScripts = {}

    for k2, v2 in pairs(v.tracks) do
        util.PrecacheSound(v2)
        local name = string.format("RadioStation.%s.%s", k, k2)
        RADIO_STANTIONS[k].soundScripts[k2] = name

        sound.Add({
            name = name,
            sound = v2,
            channel = CHAN_STREAM,
            volume = 1.0,
            pitch = {97, 103},
            level = 75
        })

        util.PrecacheSound(name)
    end
end

if CLIENT then
    CreateClientConVar("vehicles_radio", 0, true, true)
    CreateClientConVar("vehicles_radio_debug", 0, true, true)
    CreateClientConVar("vehicles_radio_autostop", 0, true, true)
    CreateClientConVar("vehicles_radio_hud_animation", 0, true, true)

    if GetConVar("vehicles_radio_debug"):GetBool() then
        PrintTable(RADIO_STANTIONS)
    end

    hook.Add("PopulateToolMenu", "VehicleRadioMenu", function()
        spawnmenu.AddToolMenuOption("Utilities", "User", "vehicles_radio_options", "Vehicle Radio", "", "", function(panel)
            panel:SetName("Vehicle Radio")

            panel:AddControl("Header", {
                Text = "",
                Description = "Configuration menu for the Vehicle Radio."
            })

            local ConVarsDefault = {
                vehicles_radio_autostop = "0",
                vehicles_radio_hud_animation = "0",
                vehicles_radio_debug = "0"
            }

            panel:AddControl("ComboBox", {
                MenuButton = 1,
                Folder = "VehicleRadio",
                Options = {
                    ["#preset.default"] = ConVarsDefault
                },
                CVars = table.GetKeys(ConVarsDefault)
            })

            panel:AddControl("Label", {
                Text = "List of installed stations."
            })

            local List = vgui.Create("DListView")
            List:SetTooltip(false)
            List:SetSize(100, 300)
            List:SetMultiSelect(false)
            List:AddColumn("Name")
            List:AddColumn("Tracks")

            if #RADIO_STANTIONS > 0 then
                for k, v in pairs(RADIO_STANTIONS) do
                    List:AddLine(v.meta.name, #v.tracks + 1)
                end
            else
                List:AddLine("No stations")
            end

            panel:AddItem(List)

            panel:AddControl("Checkbox", {
                Label = "Auto turn off on leave vehicle",
                Command = "vehicles_radio_autostop"
            })

            panel:AddControl("Checkbox", {
                Label = "HUD Animation",
                Command = "vehicles_radio_hud_animation"
            })

            panel:AddControl("Checkbox", {
                Label = "Debug Mode",
                Command = "vehicles_radio_debug"
            })
        end)
    end)
end