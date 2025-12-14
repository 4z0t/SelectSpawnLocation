---@type ScenarioOption[]
AIOpts = {}
do
    local TableInsert = table.insert
    TableInsert(AIOpts,
        {
            default = 2,
            label = "=====Select Spawn Location=====",
            help = "Select Spawn Location options section",
            key = "=====Select Spawn Location=====",
            values = {
                {
                    text = "<LOC _Off>Off",
                    help = "Disabled",
                    key = 'false',
                },
                {
                    text = "<LOC _On>On",
                    help = "Enabled",
                    key = 'true',
                },
            },
        })
    TableInsert(AIOpts,
        {
            default = 2,
            label = "Preparation time",
            help = "Time players have to choose spawn location",
            key = "PreparationTime",
            value_text = "%s",
            value_help = "%s seconds",
            values = {
                '15', '30', '45', '60',
            },
        })

    TableInsert(AIOpts,
        {
            default = 1,
            label = "Spawn area type",
            help = "Spawn areas type",
            key = "SpawnAreaType",
            values = {
                {
                    text = "Auto areas",
                    help = "Computes based on spawn positions odd vs even",
                    key = 'auto',
                },
                {
                    text = "Top vs Bottom",
                    help = "2 areas on top and bottom of the map",
                    key = 'tvsb',
                },
                {
                    text = "Right vs Left",
                    help = "2 areas on right and left of the map",
                    key = 'rvsl',
                },
                {
                    text = "Top Left vs Bottom Right",
                    help = "",
                    key = 'tlvsbr',
                },
                {
                    text = "Top Right vs Bottom Left",
                    help = "",
                    key = 'trvsbl',
                },
                {
                    text = "Whole map",
                    help = "Let the chaos begin!",
                    key = 'whole',
                },
            }
        })

end
