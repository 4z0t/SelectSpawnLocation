do
    local _CollectDefeatedBrains = CollectDefeatedBrains
    CollectDefeatedBrains = function(aliveBrains, condition, delay)
        if ScenarioInfo.IsSpawnPhaze then return {} end
        CollectDefeatedBrains = _CollectDefeatedBrains
        return CollectDefeatedBrains(aliveBrains, condition, delay)
    end
end
