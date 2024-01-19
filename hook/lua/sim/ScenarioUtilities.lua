do
    local _InitializeArmies = InitializeArmies
    function InitializeArmies()
        if not ScenarioInfo.Options.AutoTeams then
            return _InitializeArmies()
        end
        return import("/mods/SSL/modules/SelectSpawnLocation.lua").InitializeArmies()
    end
end
