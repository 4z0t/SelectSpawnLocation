---@type ScenarioOption[]
AIOpts = {}
do
    local TableInsert = table.insert

    TableInsert(AIOpts,
        {
            default = 1,
            label = "=====Select Spawn Location=====",
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
