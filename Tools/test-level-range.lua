local oldDB = DQT.db
local oldLevel, oldGreenRange = UnitLevel, GetQuestGreenRange
local oldComplete, oldReady, oldActive = DQT.IsQuestComplete, DQT.IsQuestReadyForTurnIn, DQT.IsQuestActive
local level, states = 30, {}
UnitLevel=function() return level end
GetQuestGreenRange=function() return 5 end
DQT.IsQuestComplete=function() return false end
DQT.IsQuestReadyForTurnIn=function(_, id) return states[id] == "ready" end
DQT.IsQuestActive=function(_, id) return states[id] == "active" end
DQT.db={optionsVersion=1, filters={ignoreGrayChecklist=false, hideGrayDungeons=false, hideTrackedDungeons=false}}
DQT:InitializeOptions()
for _, key in ipairs({"ignoreGrayChecklist", "ignoreRedChecklist", "hideGrayDungeons", "hideRedDungeons", "hideTrackedDungeons"}) do assert(DQT:GetOption("filters." .. key), "Default level range migration: " .. key) end
local dungeonKey="level-range-test"
DQT.dungeons[dungeonKey]={name="Range Test",minLevel=1,recommendedLevel="25-34",factions={"Horde","Alliance"},quests={}}
for i, questLevel in ipairs({24,25,32,33,34,35}) do
    local id=997100+i
    DQT.dungeons[dungeonKey].quests[i]=id
    DQT.quests[id]={name="Range " .. i,dungeon=dungeonKey,minLevel=1,questLevel=questLevel,classicXp=100,
        pickup={name="NPC",zone="Zone"},turnIn={name="NPC",zone="Zone"},prerequisites={}}
end
local function Visible(i)
    for _, row in ipairs(DQT:GetDisplayDungeonStatus(dungeonKey).quests) do if row.questID == 997100+i then return true end end
    return false
end
assert(not Visible(1) and Visible(2), "Gray boundary follows green range")
assert(Visible(3) and Visible(4) and Visible(5) and not Visible(6), "Yellow/orange visible; red at +5 hidden")
assert(DQT:ShouldShowDungeon(DQT:GetDisplayDungeonStatus(dungeonKey)), "In-range dungeon visible")
DQT.dungeons[dungeonKey].recommendedLevel="35-40"
assert(not DQT:ShouldShowDungeon(DQT:GetDisplayDungeonStatus(dungeonKey)), "Red dungeon hidden")
DQT.dungeons[dungeonKey].recommendedLevel="18-24"
states[997101]="ready"
assert(Visible(1), "Ready gray quest remains accessible")
assert(not DQT:ShouldShowDungeon(DQT:GetDisplayDungeonStatus(dungeonKey)), "Gray dungeon hidden even with ready quest by default")
local found=false
for _, row in ipairs(DQT:GetGlobalTurnInPriority().quests) do if row.questID == 997101 then found=true end end
assert(found, "Hidden dungeon still contributes ready turn-ins")
DQT:SetOption("filters.hideTrackedDungeons", false)
assert(DQT:ShouldShowDungeon(DQT:GetDisplayDungeonStatus(dungeonKey)), "Opt-in active/ready protection works")
DQT:SetOption("filters.ignoreRedChecklist", false); assert(Visible(6))
DQT:InitializeOptions(); assert(not DQT:GetOption("filters.ignoreRedChecklist"), "Explicit opt-out survives reload")
DQT.db.optionsVersion=1
DQT:SetOption("filters.ignoreGrayChecklist", false)
DQT:InitializeOptions(); assert(not DQT:GetOption("filters.ignoreGrayChecklist"), "Recorded explicit choices survive defaults migration")
DQT:ResetFilters()
assert(DQT:GetOption("filters.ignoreGrayChecklist") and DQT:GetOption("filters.ignoreRedChecklist"), "Reset restores range defaults")
DQT.dungeons[dungeonKey].quests={}
DQT.dungeons[dungeonKey].recommendedLevel="35-40"
assert(not DQT:ShouldShowDungeon(DQT:GetDisplayDungeonStatus(dungeonKey)), "Red empty placeholders hidden")
DQT.dungeons[dungeonKey].recommendedLevel="18-24"
assert(not DQT:ShouldShowDungeon(DQT:GetDisplayDungeonStatus(dungeonKey)), "Gray empty placeholders hidden")
for i=1,6 do DQT.quests[997100+i]=nil end
DQT.dungeons[dungeonKey]=nil
DQT.db=oldDB
UnitLevel, GetQuestGreenRange=oldLevel, oldGreenRange
DQT.IsQuestComplete, DQT.IsQuestReadyForTurnIn, DQT.IsQuestActive=oldComplete, oldReady, oldActive
print("Passed level-range defaults: gray/red boundaries, migration, explicit overrides, placeholders, and ready turn-ins from hidden dungeons.")
