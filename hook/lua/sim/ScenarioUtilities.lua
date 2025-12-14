do
    local _InitializeArmies = InitializeArmies
    function InitializeArmies()
        ScenarioInfo.IsSSL = not ScenarioInfo.Options.AutoTeams
            or not ScenarioInfo.Options.SpawnAreaType
            or ScenarioInfo.Options.SpawnAreaType == "none"

        if not ScenarioInfo.IsSSL then
            return _InitializeArmies()
        end
        return import("/mods/SSL/modules/SelectSpawnLocation.lua").InitializeArmies()
    end
end
