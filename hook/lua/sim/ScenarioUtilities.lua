
local MarkerUnits = {}
local oldInitializeArmies = InitializeArmies
function InitializeArmies()
    -- LOG(repr(ScenarioInfo.Options))
    -- if table.getn(ScenarioInfo.Options.RandomPositionGroups) ~= 2 then
    --     return oldInitializeArmies()
    -- end
    if not ScenarioInfo.Options.AutoTeams then
        return oldInitializeArmies()
    end

    LOG("DYNAMICSPAWN")
    local tblGroups = {}
    local tblArmy = ListArmies()

    local civOpt = ScenarioInfo.Options.CivilianAlliance

    local bCreateInitial = ShouldCreateInitialArmyUnits()
    local msizeX, msizeY = GetMapSize()

    -- LOG(repr(ScenarioInfo))

    for iArmy, strArmy in pairs(tblArmy) do
        local tblData = Scenario.Armies[strArmy]

        tblGroups[strArmy] = {}

        if tblData then

            ----[ If an actual starting position is defined, overwrite the        ]--
            ----[ randomly generated one.                                         ]--

            -- LOG('*DEBUG: InitializeArmies, army = ', strArmy)

            SetArmyEconomy(strArmy, tblData.Economy.mass, tblData.Economy.energy)

            -- GetArmyBrain(strArmy):InitializePlatoonBuildManager()
            -- LoadArmyPBMBuilders(strArmy)
            if GetArmyBrain(strArmy).SkirmishSystems then
                GetArmyBrain(strArmy):InitializeSkirmishSystems()
            end

            local armyIsCiv = ScenarioInfo.ArmySetup[strArmy].Civilian

            if armyIsCiv and civOpt ~= 'neutral' and strArmy ~= 'NEUTRAL_CIVILIAN' then -- give enemy civilians darker color
                SetArmyColor(strArmy, 255, 48, 48) -- non-player red color for enemy civs
            end

            MarkerUnits[strArmy] = CreateUnitHPR('uec0001', strArmy, msizeX / 2,
                                       GetSurfaceHeight(msizeX / 2, msizeY / 2) + 1, msizeY / 2, 0, 0, 0);
            MarkerUnits[strArmy]:SetSpeedMult(0)
            MarkerUnits[strArmy]:SetCanBeKilled(false)
            MarkerUnits[strArmy]:SetImmobile(true)
            MarkerUnits[strArmy]:SetIntelRadius('Vision', 0)
            MarkerUnits[strArmy]:SetIntelRadius('Radar', 0)
            MarkerUnits[strArmy]:SetIntelRadius('Omni', 0)
            -- MarkerUnits[strArmy] :HideBone(0, true)
            -- MarkerUnits[strArmy] .Big = import('/lua/sim/Entity.lua').Entity({Owner = MarkerUnits[strArmy] ,})
            -- MarkerUnits[strArmy] .Big:SetMesh(MarkerUnits[strArmy] :GetBlueprint().Display.MeshBlueprint, true)
            -- MarkerUnits[strArmy] .Big:SetScale(0.3)
            -- MarkerUnits[strArmy] .Big:AttachBoneTo(0, MarkerUnits[strArmy] , 0)

            -- flag
            -- if (not armyIsCiv and bCreateInitial) or (armyIsCiv and civOpt ~= 'removed') then
            --     local commander = (not ScenarioInfo.ArmySetup[strArmy].Civilian)
            --     local cdrUnit
            --     tblGroups[strArmy], cdrUnit = CreateInitialArmyGroup(strArmy, commander)
            --     if commander and cdrUnit and ArmyBrains[iArmy].Nickname then
            --         cdrUnit:SetCustomName(ArmyBrains[iArmy].Nickname)
            --     end
            -- end

            local wreckageGroup = FindUnitGroup('WRECKAGE', Scenario.Armies[strArmy].Units)
            if wreckageGroup then
                local platoonList, tblResult, treeResult = CreatePlatoons(strArmy, wreckageGroup)
                for num, unit in tblResult do
                    CreateWreckageUnit(unit)
                end
            end

            ----[ irumsey                                                         ]--
            ----[ Temporary defaults.  Make sure some fighting will break out.    ]--
            for iEnemy, strEnemy in tblArmy do
                local enemyIsCiv = ScenarioInfo.ArmySetup[strEnemy].Civilian
                local a, e = iArmy, iEnemy
                local state = 'Enemy'

                if a ~= e then
                    if armyIsCiv or enemyIsCiv then
                        if civOpt == 'neutral' or strArmy == 'NEUTRAL_CIVILIAN' or strEnemy == 'NEUTRAL_CIVILIAN' then
                            state = 'Neutral'
                        end

                        if ScenarioInfo.Options['RevealCivilians'] == 'Yes' and ScenarioInfo.ArmySetup[strEnemy].Human then
                            ForkThread(function()
                                WaitSeconds(.1)
                                local real_state = IsAlly(a, e) and 'Ally' or IsEnemy(a, e) and 'Enemy' or 'Neutral'

                                GetArmyBrain(e):SetupArmyIntelTrigger(
                                    {
                                        Category = categories.ALLUNITS,
                                        Type = 'LOSNow',
                                        Value = true,
                                        OnceOnly = true,
                                        TargetAIBrain = GetArmyBrain(a),
                                        CallbackFunction = function()
                                            SetAlliance(a, e, real_state)
                                        end
                                    })
                                SetAlliance(a, e, 'Ally')
                            end)
                        end
                    end

                    if state then
                        SetAlliance(a, e, state)
                    end
                end
            end
        end
    end
    ForkThread(PreparationPhaze, tblGroups)
    return tblGroups
end

local AllyState = false

function AreaType(Atype)
    LOG(GetFocusArmy())
    for iArmy, strArmy in pairs(ListArmies()) do
        if (iArmy == GetFocusArmy()) or IsAlly(iArmy, GetFocusArmy()) then
            AllyState = true
        end
        break
    end

    local msizeX, msizeY = GetMapSize()
    if Atype then
        LOG(Atype)
        if Atype == 'lvsr' then
            return {
                t1 = {0, 0, msizeX / 3, msizeY},
                t2 = {2 * msizeX / 3, 0, msizeX, msizeY}
            }
        elseif Atype == 'tvsb' then
            return {
                t1 = {0, 0, msizeX, msizeY / 3},
                t2 = {0, 2 * msizeY / 3, msizeX, msizeY}
            }

        elseif Atype == 'pvsi' then
            return {
                t1 = {3 * msizeX / 5, 0, msizeX, 2 * msizeY / 5},
                t2 = {0, 3 * msizeY / 5, 2 * msizeX / 5, msizeY}
            }
        end

    else
        -- TODO
        local ArmyPos = ScenarioInfo.Env.Scenario.MasterChain['_MASTERCHAIN_'].Markers
        local team = 1
        local p1
        local p2
        local p3
        local p4
        for id, team in ScenarioInfo.Options.RandomPositionGroups do
            if team == 1 then
                p1 = ArmyPos['ARMY_' .. team[1]]
                p3 = ArmyPos['ARMY_' .. team[2]]
            else
                p2 = ArmyPos['ARMY_' .. team[1]]
                p4 = ArmyPos['ARMY_' .. team[2]]
            end
            team = team + 1
        end
        local v1 = Vector(p1[1] - p3[1], 0, p1[3] - p3[3])
        local v2 = Vector(p2[1] - p4[1], 0, p2[3] - p4[3])
        local v1l = VDist2(0, 0, v1.x, v1.z)
        local v2l = VDist2(0, 0, v2.x, v2.z)
        local dot = VDot(v1, v2) / v1l / v2l
        LOG(dot)

        if dot > 0 then

        else -- center type

        end
    end

end

local Markers = {}
local time = 300

function comparepositions(pos1, pos2)
    local counter = 0
    for i = 1, 3 do
        if pos1[i] == pos2[i] then
            counter = counter + 1
        end
    end
    if counter == 3 then
        return true
    else
        return false
    end
end

function PreparationPhaze(tblGroups)
    LOG("render started")
    --LOG(repr(ScenarioInfo))
    local Areas = AreaType(ScenarioInfo.Options.AutoTeams)
    local renderThread = ForkThread(RenderMarkers, Areas)
    local renderLinesThread = ForkThread(RenderLines, Areas)
    WaitTicks(time) -- 30 seconds

    local tblArmy = ListArmies()
    local civOpt = ScenarioInfo.Options.CivilianAlliance
    local bCreateInitial = ShouldCreateInitialArmyUnits()

    for iArmy, strArmy in pairs(tblArmy) do
        local armyIsCiv = ScenarioInfo.ArmySetup[strArmy].Civilian
        if (not armyIsCiv and bCreateInitial) or (armyIsCiv and civOpt ~= 'removed') then
            local commander = (not ScenarioInfo.ArmySetup[strArmy].Civilian)
            local cdrUnit
            tblGroups[strArmy], cdrUnit = CreateInitialArmyGroup(strArmy, commander)
            if commander and cdrUnit and ArmyBrains[iArmy].Nickname then
                cdrUnit:SetCustomName(ArmyBrains[iArmy].Nickname)
                local markerPos = MarkerUnits[strArmy]:GetNavigator():GetGoalPos()
                if not comparepositions(markerPos, MarkerUnits[strArmy]:GetPosition()) then
                    cdrUnit:SetPosition(Vector(markerPos[1], markerPos[2], markerPos[3]), true)
                else
                    local midpos = SetMiddle(Areas, markerPos,
                                       AllyState == (IsAlly(iArmy, GetFocusArmy()) or  (iArmy == GetFocusArmy())))
                    cdrUnit:SetPosition(Vector(midpos[1], midpos[2], midpos[3]), true)
                end
            end
        end
    end
    LOG("COMS SPAWNED")
    KillThread(renderThread)
    KillThread(renderLinesThread)

    for _, MarkerUnit in MarkerUnits do
        MarkerUnit:Destroy()
    end
    ResumeThread(ScenarioInfo.GameOverThread)
    Sync.DeleteMarkers = true
end
-- flag
function RenderLines(Areas)
    local c1
    local c2
    if AllyState then
   
        c1 = "ff00ff00"
        c2 = "ffff0000"
    else
        c1 = "ffff0000"
        c2 = "ff00ff00"
    
    end
    local A1 = {{Areas.t1[1], GetSurfaceHeight(Areas.t1[1], Areas.t1[2]) + 10, Areas.t1[2]},
                {Areas.t1[1], GetSurfaceHeight(Areas.t1[1], Areas.t1[4]) + 10, Areas.t1[4]},
                {Areas.t1[3], GetSurfaceHeight(Areas.t1[3], Areas.t1[4]) + 10, Areas.t1[4]},
                {Areas.t1[3], GetSurfaceHeight(Areas.t1[3], Areas.t1[2]) + 10, Areas.t1[2]}}
    local A2 = {{Areas.t2[1], GetSurfaceHeight(Areas.t2[1], Areas.t2[2]) + 10, Areas.t2[2]},
                {Areas.t2[1], GetSurfaceHeight(Areas.t2[1], Areas.t2[4]) + 10, Areas.t2[4]},
                {Areas.t2[3], GetSurfaceHeight(Areas.t2[3], Areas.t2[4]) + 10, Areas.t2[4]},
                {Areas.t2[3], GetSurfaceHeight(Areas.t2[3], Areas.t2[2]) + 10, Areas.t2[2]}}

    while true do
        WaitTicks(1)

        DrawLine(A1[1], A1[2], c1)
        DrawLine(A1[2], A1[3], c1)
        DrawLine(A1[3], A1[4], c1)
        DrawLine(A1[1], A1[4], c1)

        DrawLine(A2[1], A2[2], c2)
        DrawLine(A2[2], A2[3], c2)
        DrawLine(A2[3], A2[4], c2)
        DrawLine(A2[1], A2[4], c2)
    end
end

function AreaTest()

end

function isInArea(Areas, pos, state)
    local Area
    if state then
        Area = Areas.t1
    else
        Area = Areas.t2
    end
    if pos[1] > Area[1] and pos[1] < Area[3] and pos[3] > Area[2] and pos[3] < Area[4] then
        return true
    end
    return false
end

function SetMiddle(Areas, pos, state)
    local Area
    if state then
        Area = Areas.t1
    else
        Area = Areas.t2
    end
    return {(Area[1] + Area[3]) / 2, GetSurfaceHeight((Area[1] + Area[3]) / 2, (Area[2] + Area[4]) / 2),
            (Area[2] + Area[4]) / 2}
end

function RenderMarkers(Areas)
    -- LOG(repr(ScenarioInfo.Env.Scenario.MasterChain['_MASTERCHAIN_'].Markers))
    local ArmyPos = ScenarioInfo.Env.Scenario.MasterChain['_MASTERCHAIN_'].Markers

    local tblArmy = ListArmies()
    local focusArmy = GetFocusArmy()
    -- LOG(repr(tblArmy))
    --LOG(repr(ScenarioInfo))
    -- LOG(repr(GetFocusArmy()))
    while true do
        Sync.Markers = {}
        for iArmy, strArmy in pairs(tblArmy) do
            local armyIsCiv = ScenarioInfo.ArmySetup[strArmy].Civilian

            if not armyIsCiv then
                local markerpos = MarkerUnits[strArmy]:GetNavigator():GetGoalPos()

                --if focusArmy == iArmy then
                -- LOG(iArmy)
                -- LOG(AllyState)
                -- LOG('state: ',(AllyState == (IsAlly(iArmy, focusArmy)) or  (iArmy == focusArmy)))
                if not isInArea(Areas, markerpos, AllyState == (IsAlly(iArmy,focusArmy) or  (iArmy == focusArmy)))  then
                    -- SimCallback( {
                    --     Func = "ClearCommands",
                    --     Args = { 
                    --         units = {MarkerUnits[strArmy]},
                    --         -- unit_orders = unitOrders,
                    --         -- unit_id     = unit:GetEntityId(),
                    --         From = focusArmy
                    --     }
                    -- }, false)


                    IssueClearCommands({MarkerUnits[strArmy]})

                    markerpos = MarkerUnits[strArmy]:GetNavigator():GetGoalPos()
                end
                --end

                if IsAlly(iArmy, focusArmy) or  (iArmy == focusArmy) then
                    
                    if comparepositions(markerpos, MarkerUnits[strArmy]:GetPosition()) then
                        Sync.Markers[strArmy] = SetMiddle(Areas, markerpos, AllyState)
                    else
                        Sync.Markers[strArmy] = markerpos
                    end
                end
            end
        end
        WaitTicks(1)
    end

end
