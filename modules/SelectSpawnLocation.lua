local ScenarioUtils = import("/lua/sim/scenarioutilities.lua")
local DrawLine = DrawLine


local lineGroundOffset = 10

---@class SpawnArea
---@field color Color
---@field [1] number
---@field [2] number
---@field [3] number
---@field [4] number
local SpawnArea = Class()
{
    ---@param self SpawnArea
    ---@param color Color
    ---@param x number
    ---@param y number
    ---@param z number
    ---@param w number
    __init = function(self, color, x, y, z, w)
        self.color = color
        self[1] = x
        self[2] = y
        self[3] = z
        self[4] = w
    end,

    ---@param self SpawnArea
    Render = function(self)
        local box = {
            { self[1], GetSurfaceHeight(self[1], self[2]) + lineGroundOffset, self[2] },
            { self[1], GetSurfaceHeight(self[1], self[4]) + lineGroundOffset, self[4] },
            { self[3], GetSurfaceHeight(self[3], self[4]) + lineGroundOffset, self[4] },
            { self[3], GetSurfaceHeight(self[3], self[2]) + lineGroundOffset, self[2] },
        }

        DrawLine(box[1], box[2], self.color)
        DrawLine(box[2], box[3], self.color)
        DrawLine(box[3], box[4], self.color)
        DrawLine(box[1], box[4], self.color)
    end,

    ---@param self SpawnArea
    ---@param pos Vector
    IsInArea = function(self, pos)
        return pos[1] > self[1] and pos[1] < self[3] and pos[3] > self[2] and pos[3] < self[4]
    end,

    ---@param self SpawnArea
    ---@return Vector
    GetCenter = function(self)
        local mx, my = (self[1] + self[3]) * 0.5, (self[2] + self[4]) * 0.5
        return Vector(mx, GetTerrainHeight(mx, my), my)
    end
}


---@param data { Position : Vector, Army : number }
function SelectSpawnLocation(data)
    if not ScenarioInfo.IsSpawnPhaze then
        return
    end

    if not data or not data.Position or not OkayToMessWithArmy(data.Army) then
        return
    end

    local armyId = data.Army

    local teamId = ScenarioInfo.ArmyToTeam[armyId]
    ---@type SpawnArea
    local area = ScenarioInfo.SpawnAreas[teamId]
    if not area then return end

    if not area:IsInArea(data.Position) then
        if GetCurrentCommandSource() == GetFocusArmy() then
            print("Invalid spawn position")
        end
        return
    end

    ScenarioInfo.SpawnLocations[armyId] = data.Position
end

function CreateSpawnAreas(teams)
    if table.getsize(teams) ~= 2 then error("invalid team count") end

    local function GetFocusArmyTeam()
        local fa = GetFocusArmy()
        return ScenarioInfo.ArmyToTeam[fa]
    end

    local t1, t2
    for team in teams do
        if not t1 then
            t1 = team
        elseif not t2 then
            t2 = team
        end
    end

    local faTeam = GetFocusArmyTeam()


    local c1
    local c2
    if faTeam == t1 then
        c1 = "ff00ff00"
        c2 = "ffff0000"
    else
        c1 = "ffff0000"
        c2 = "ff00ff00"
    end

    local terrainSymmetry = ScenarioInfo.Options.SpawnAreaType
    local x1, y1, x2, y2 = unpack(ScenarioInfo.MapData.PlayableRect)
    local msizeX, msizeY = x2 - x1, y2 - y1
    local msizeX25, msizeY25 = 2 * msizeX / 5, 2 * msizeY / 5
    local msizeX13, msizeY13 = msizeX / 3, msizeY / 3

    if terrainSymmetry == 'lvsr' then
        return {
            [t1] = SpawnArea(c1, x1, y1, x1 + msizeX13, y2),
            [t2] = SpawnArea(c2, x2 - msizeX13, y1, x2, y2),
        }
    elseif terrainSymmetry == 'tvsb' then
        return {
            [t1] = SpawnArea(c1, x1, y1, x2, y1 + msizeY13),
            [t2] = SpawnArea(c2, x1, y2 - msizeY13, x2, y2),
        }
    elseif terrainSymmetry == 'tlvsbr' then
        return {
            [t1] = SpawnArea(c1, x1, y1, x1 + msizeX25, y1 + msizeY25),
            [t2] = SpawnArea(c2, x2 - msizeX25, y2 - msizeY25, x2, y2),
        }
    elseif terrainSymmetry == 'trvsbl' then
        return {
            [t1] = SpawnArea(c1, x2 - msizeX25, y1, x2, y1 + msizeY25),
            [t2] = SpawnArea(c2, x1, y2 - msizeY25, x2 + msizeX25, y2),
        }
    elseif terrainSymmetry == 'none' then
        error("Unsupported")
    end

    error("invalid type")

end

local time = 300


function RenderLines()
    for teamId, area in ScenarioInfo.SpawnAreas do
        area:Render()
    end
end

function RenderMarkers()

    local tblArmy = ListArmies()
    local focusArmy = GetFocusArmy()

    Sync.Markers = {}
    for iArmy, strArmy in pairs(tblArmy) do
        local armyIsCiv = ScenarioInfo.ArmySetup[strArmy].Civilian

        if armyIsCiv then continue end
        local markerpos = ScenarioInfo.SpawnLocations[iArmy]

        if IsAlly(iArmy, focusArmy) or (iArmy == focusArmy) then
            Sync.Markers[strArmy] = markerpos
        end

    end

end

function MainThread()
    LOG("MAIN THREAD")
    while true do
        RenderLines()
        RenderMarkers()
        WaitTicks(1)
    end
end

function SpawnACUs(tblGroups)
    local tblArmy = ListArmies()
    local civOpt = ScenarioInfo.Options.CivilianAlliance
    local bCreateInitial = ShouldCreateInitialArmyUnits()

    for iArmy, strArmy in pairs(tblArmy) do
        local armyIsCiv = ScenarioInfo.ArmySetup[strArmy].Civilian
        if (not armyIsCiv and bCreateInitial) or (armyIsCiv and civOpt ~= 'removed') then
            local commander = (not ScenarioInfo.ArmySetup[strArmy].Civilian)
            local cdrUnit
            tblGroups[strArmy], cdrUnit = ScenarioUtils.CreateInitialArmyGroup(strArmy, commander)
            if commander and cdrUnit and ArmyBrains[iArmy].Nickname then
                cdrUnit:SetCustomName(ArmyBrains[iArmy].Nickname)
                cdrUnit:SetPosition(ScenarioInfo.SpawnLocations[iArmy], true)
            end
        end
    end
end

function DefaultSpawnLocations(areas, armyToTeam)
    local positions = {}
    for _, army in ScenarioInfo.ArmySetup do
        if army.Civilian then
            continue
        end
        local team = armyToTeam[army.ArmyIndex]
        local area = areas[team]
        positions[army.ArmyIndex] = area:GetCenter()
    end
    return positions
end

-- armyId -> teamId
function SplitPlayersByTeams()
    local armyToTeam = {}
    local teams = {}
    for _, army in ScenarioInfo.ArmySetup do
        if army.Civilian then
            continue
        end
        armyToTeam[army.ArmyIndex] = army.Team
        teams[army.Team] = teams[army.Team] or {}
        table.insert(teams[army.Team], army.ArmyIndex)
    end
    return armyToTeam, teams
end

function PreparationPhaze(tblGroups)
    LOG("render started")
    local armyToTeam, teams = SplitPlayersByTeams()
    ScenarioInfo.ArmyToTeam = armyToTeam
    local areas = CreateSpawnAreas(teams)
    ScenarioInfo.SpawnAreas = areas
    ScenarioInfo.SpawnLocations = DefaultSpawnLocations(areas, armyToTeam)
    local mainThread = ForkThread(MainThread)
    WaitTicks(time)

    SpawnACUs(tblGroups)
    LOG("COMS SPAWNED")
    KillThread(mainThread)

    Sync.DeleteMarkers          = true
    ScenarioInfo.IsSpawnPhaze   = false
    ScenarioInfo.SpawnAreas     = nil
    ScenarioInfo.ArmyToTeam     = nil
    ScenarioInfo.SpawnLocations = nil
end

function InitializeArmies()
    ScenarioInfo.IsSpawnPhaze = true

    LOG("DYNAMICSPAWN")
    local tblGroups = {}
    local tblArmy = ListArmies()

    local civOpt = ScenarioInfo.Options.CivilianAlliance

    for iArmy, strArmy in pairs(tblArmy) do
        local tblData = Scenario.Armies[strArmy]

        tblGroups[strArmy] = {}

        if not tblData then continue end

        SetArmyEconomy(strArmy, tblData.Economy.mass, tblData.Economy.energy)

        local armyIsCiv = ScenarioInfo.ArmySetup[strArmy].Civilian

        if armyIsCiv and civOpt ~= 'neutral' and strArmy ~= 'NEUTRAL_CIVILIAN' then -- give enemy civilians darker color
            SetArmyColor(strArmy, 255, 48, 48) -- non-player red color for enemy civs
        end

        local wreckageGroup = ScenarioUtils.FindUnitGroup('WRECKAGE', Scenario.Armies[strArmy].Units)
        if wreckageGroup then
            local platoonList, tblResult, treeResult = ScenarioUtils.CreatePlatoons(strArmy, wreckageGroup)
            for num, unit in tblResult do
                ScenarioUtils.CreateWreckageUnit(unit)
            end
        end

        for iEnemy, strEnemy in tblArmy do
            local enemyIsCiv = ScenarioInfo.ArmySetup[strEnemy].Civilian
            local a, e = iArmy, iEnemy
            local state = 'Enemy'

            if a == e then continue end

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
    ForkThread(PreparationPhaze, tblGroups)
    return tblGroups
end
