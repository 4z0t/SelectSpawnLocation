local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local worldView = import('/lua/ui/game/worldview.lua').viewLeft
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Prefs = import('/lua/user/prefs.lua')
local Group = import('/lua/maui/group.lua').Group

local LayoutFor = import('/lua/maui/layouthelpers.lua').LayoutFor

local Markers = {}
local Timer = nil
local Credits = nil
function CreateCredits()
    Credits = UIUtil.CreateText(GetFrame(0), 'Mod by 4z0t', 16, "Arial", true)
    Credits:SetColor('ffffffff')
    Credits:DisableHitTest()
    --Credits:SetNeedsFrameUpdate(true)
    LayoutHelpers.AtLeftTopIn(Credits, GetFrame(0), 100, 500)
    Credits.text = UIUtil.CreateText(Credits, 'Markers by Eternal-', 16, "Arial", true)
    Credits.text:SetColor('ffffffff')
    Credits.text:DisableHitTest()
    LayoutHelpers.Below(Credits.text, Credits, 4)
end

function UpdateMarkers(SyncMarkers)
    ---@type WorldView
    local worldView = import("/lua/ui/game/worldview.lua").viewLeft
    if not worldView.spawnOverlay then
        worldView.spawnOverlay = Group(worldView)
        LayoutFor(worldView.spawnOverlay)
            :Fill(worldView)
            :EnableHitTest(true)
        worldView.spawnOverlay.HandleEvent = function(self, event)
            if event.Type == "ButtonPress" and event.Modifiers.Right then
                local pos = GetMouseWorldPos()
                SimCallback {
                    Func = "SelectSpawnLocation",
                    Args = {
                        Army = GetFocusArmy(),
                        Position = Vector(pos[1], pos[2], pos[3])
                    }
                }
            end
            return false
        end

    end

    if not Timer then
        CreateTimer()
    end
    if not Credits then
        CreateCredits()
    end
    -- LOG(repr(GetArmiesTable()))
    for strArmy, pos in SyncMarkers do
        if not Markers[strArmy] then
            Markers[strArmy] = createPositionMarker(GetArmy(strArmy), pos)
            -- Markers[strArmy] = CreateMarker(strArmy, pos)
        else
            Markers[strArmy].pos = { pos[1], pos[2], pos[3] }
        end
    end
end

function CreateTimer()
    Timer = UIUtil.CreateText(GetFrame(0), '', 16, "Arial Black", true)
    Timer:SetColor('ffffffff')
    Timer:DisableHitTest()
    Timer:SetNeedsFrameUpdate(true)
    LayoutHelpers.AtCenterIn(Timer, GetFrame(0), -400)
    Timer.OnFrame = function(self, delta)
        self:SetText('Choose your destiny: ' .. math.ceil((30 - GetGameTimeSeconds())))
    end

end

function createPositionMarker(armyData, postable)
    local pos = { postable[1], postable[2], postable[3] - 10 }

    -- Bitmap of marker
    local posMarker = Bitmap(GetFrame(0))
    LayoutHelpers.AtCenterIn(posMarker, GetFrame(0))
    LayoutHelpers.SetDimensions(posMarker, 150, 25)
    posMarker.pos = pos
    posMarker.Depth:Set(10)
    posMarker:SetNeedsFrameUpdate(true)
    posMarker:DisableHitTest()

    -- Nickname
    posMarker.nickname = UIUtil.CreateText(posMarker, armyData.nickname, 12)

    posMarker.nickname:SetColor('ffffffff')

    posMarker.nickname:SetDropShadow(true)
    LayoutHelpers.AtCenterIn(posMarker.nickname, posMarker)
    posMarker.nickname:DisableHitTest()

    -- Army color line below the nickname
    posMarker.separator = Bitmap(posMarker)
    posMarker.separator:SetTexture('/mods/Reveal positions/textures/clear.dds')
    posMarker.separator.Left:Set(posMarker.nickname.Left)
    posMarker.separator.Right:Set(posMarker.nickname.Right)

    posMarker.separator.Height:Set(1)

    LayoutHelpers.Below(posMarker.separator, posMarker.nickname, 1) --	  1	px
    posMarker.separator:SetSolidColor(armyData.color) --				    |line|
    posMarker.separator:DisableHitTest()

    -- Bitmap of faction icon
    posMarker.faction = Bitmap(posMarker)
    -- posMarker.faction:SetTexture('/mods/Reveal positions/textures/'..armyData.faction..'.tga')
    posMarker.faction:SetTexture(UIUtil.SkinnableFile(UIUtil.GetFactionIcon(armyData.faction)))

    LayoutHelpers.SetDimensions(posMarker.faction, 16, 16)

    LayoutHelpers.AtVerticalCenterIn(posMarker.faction, posMarker.nickname) --	 distance
    LayoutHelpers.LeftOf(posMarker.faction, posMarker.nickname, 4) --     |icon|   [4px]   |nickname|
    posMarker.faction:DisableHitTest()

    -- Fill the bitmap of faction icon by army color
    posMarker.color = Bitmap(posMarker.faction)
    LayoutHelpers.FillParent(posMarker.color, posMarker.faction)
    posMarker.color.Depth:Set(function()
        return posMarker.faction.Depth() - 1
    end)
    posMarker.color:SetSolidColor(armyData.color)
    posMarker.color:DisableHitTest()

    -- Ratings
    -- if isAlly == true then
    -- 	posMarker.rating = UIUtil.CreateText(posMarker, "", 0)
    -- else
    -- 	posMarker.rating = UIUtil.CreateText(posMarker, rating, 12)
    -- end
    -- LayoutHelpers.Below(posMarker.rating, posMarker.separator, 3)
    -- posMarker.rating.Left:Set(posMarker.nickname.Left)
    -- posMarker.rating.Right:Set(posMarker.nickname.Right)
    -- posMarker.rating:SetColor('white')
    -- posMarker.rating:DisableHitTest()

    -- Invisible button that fill bitmap of marker
    -- local posMarkerButton = Button(posMarker, '/mods/DynamicSpawns/textures/clear.dds',
    --                             '/mods/DynamicSpawns/textures/clear.dds', '/mods/DynamicSpawns/textures/clear.dds',
    --                             '/mods/DynamicSpawns/textures/clear.dds')
    -- LayoutHelpers.FillParent(posMarkerButton, posMarker.nickname)
    -- posMarkerButton.pos = pos
    -- posMarkerButton.Depth:Set(9)

    -- posMarkerButton:EnableHitTest(true)
    -- posMarkerButton.OnClick = function(self, event)
    --     posMarker:Destroy()
    --     posMarker = nil
    --     posMarkerButton:Destroy()
    --     posMarkerButton = nil
    -- end

    posMarker.OnFrame = function(self, delta)
        local worldView = import('/lua/ui/game/worldview.lua').viewLeft
        local pos = worldView:Project(self.pos)

        LayoutHelpers.AtLeftTopIn(self, worldView, pos.x - self.Width() / 2, pos.y - self.Height() / 2 + 1)

    end

    return posMarker
end

function CreateMarker(strArmy, pos)

    local Marker = UIUtil.CreateText(GetFrame(0), ArmyName(strArmy), 16, "Arial Black", true)
    LayoutHelpers.AtLeftTopIn(Marker, GetFrame(0))
    Marker:SetColor('ffffffff')
    Marker:DisableHitTest()
    Marker:SetNeedsFrameUpdate(true)
    Marker.pos = { pos[1], pos[2], pos[3] }
    Marker.OnFrame = function(self, delta)

        -- if markerpos then
        local worldView = import('/lua/ui/game/worldview.lua').viewLeft
        local pos = worldView:Project(self.pos)
        LayoutHelpers.AtLeftTopIn(self, worldView, pos.x - self.Width() / 2, pos.y - self.Height() / 2)

        -- end
    end
    return Marker
end

function Delete()
    for _, Marker in Markers do
        Marker:Destroy()
    end
    Timer:Destroy()
    Credits:Destroy()

    ---@type WorldView
    local worldView = import("/lua/ui/game/worldview.lua").viewLeft
    if not worldView.spawnOverlay then
        worldView.spawnOverlay:Destroy()
    end
end

function GetArmy(name)
    for _, Army in GetArmiesTable().armiesTable do
        if Army.name == name then
            return Army
        end
    end
end

function ArmyName(name)
    for _, Army in GetArmiesTable().armiesTable do
        if Army.name == name then
            return Army.nickname
        end
    end
    return "ERROR"
end
