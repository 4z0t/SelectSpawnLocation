local _MonitoringThread = AbstractVictoryCondition.MonitoringThread ---@diagnostic disable-line: undefined-global
AbstractVictoryCondition = Class(AbstractVictoryCondition) {
    --- Monitors the victory condition.
    ---@param self AbstractVictoryCondition
    MonitoringThread = function(self)
        while ScenarioInfo.IsSpawnPhase do
            WaitTicks(5)
        end

        return _MonitoringThread(self)
    end,
}
