AbstractVictoryCondition = Class(AbstractVictoryCondition) {
    --- Monitors the victory condition.
    ---@param self AbstractVictoryCondition
    MonitoringThread = function(self)
        while ScenarioInfo.IsSpawnPhaze do
            WaitTicks(5)
        end

        while not IsGameOver() do
            self:EvaluateVictoryCondition()
            WaitTicks(4)
        end
    end,

}
