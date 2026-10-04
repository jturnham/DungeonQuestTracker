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
for _, key in ipairs({"ignoreGrayChecklist", "ignoreRedChecklist", "hideGrayDungeons", "hideRedDungeons"}) do assert(DQT:GetOption("filters." .. key), "Default level range migration: " .. key) end
assert(not DQT:GetOption("filters.hideTrackedDungeons"), "Current quests protected by default")
DQT.db={optionsVersion=2, filters={hideTrackedDungeons=true}}
DQT:InitializeOptions()
assert(not DQT:GetOption("filters.hideTrackedDungeons"), "Previous strict default migrates to current-quest protection")
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
assert(DQT:ShouldShowDungeon(DQT:GetDisplayDungeonStatus(dungeonKey)), "Ready quest keeps gray dungeon visible")
DQT:SetOption("filters.hideTrackedDungeons", true)
assert(not DQT:ShouldShowDungeon(DQT:GetDisplayDungeonStatus(dungeonKey)), "Explicit strict filter still hides gray dungeon")
local found=false
for _, row in ipairs(DQT:GetGlobalTurnInPriority().quests) do if row.questID == 997101 then found=true end end
assert(found, "Hidden dungeon still contributes ready turn-ins")
DQT:SetOption("filters.hideTrackedDungeons", false)
assert(DQT:ShouldShowDungeon(DQT:GetDisplayDungeonStatus(dungeonKey)), "Opt-in active/ready protection works")
states[997101], states[997106] = nil, "active"
DQT.dungeons[dungeonKey].recommendedLevel="35-40"
assert(Visible(6) and DQT:ShouldShowDungeon(DQT:GetDisplayDungeonStatus(dungeonKey)), "Active red quest keeps row and dungeon visible")
DQT:SetOption("filters.hideTrackedDungeons", true)
DQT.db.optionsVersion=2
DQT:InitializeOptions()
assert(DQT:GetOption("filters.hideTrackedDungeons") and not Visible(6), "Explicit strict choice survives migration")
DQT:SetOption("filters.hideTrackedDungeons", false)
states[997106]=nil
DQT:SetOption("filters.ignoreRedChecklist", false); assert(Visible(6))
DQT:InitializeOptions(); assert(not DQT:GetOption("filters.ignoreRedChecklist"), "Explicit opt-out survives reload")
DQT.db.optionsVersion=1
DQT:SetOption("filters.ignoreGrayChecklist", false)
DQT:InitializeOptions(); assert(not DQT:GetOption("filters.ignoreGrayChecklist"), "Recorded explicit choices survive defaults migration")
DQT:ResetFilters()
assert(DQT:GetOption("filters.ignoreGrayChecklist") and DQT:GetOption("filters.ignoreRedChecklist"), "Reset restores range defaults")
local oldFaction = UnitFactionGroup
UnitFactionGroup=function() return "Horde" end
level, states[1013] = 18, "active"
local sfk=DQT:GetDisplayDungeonStatus("shadowfang-keep")
local bookVisible=false
for _, row in ipairs(sfk.quests) do if row.questID == 1013 then bookVisible=true end end
assert(bookVisible and DQT:ShouldShowDungeon(sfk), "Shadowfang Keep and active Book of Ur remain visible below quest range")
DQT:SetOption("filters.onlyMissing", true)
sfk.counts.missing, sfk.counts.locked = 0, 0
assert(DQT:ShouldShowDungeon(sfk), "Unfinished filter includes active Book of Ur without missing quests")
sfk.counts.active, sfk.counts.ready = 0, 1
assert(DQT:ShouldShowDungeon(sfk), "Unfinished filter includes ready quests")
sfk.counts.ready = 0
assert(not DQT:ShouldShowDungeon(sfk), "Unfinished filter excludes completed-only checklist")
DQT:SetOption("filters.onlyMissing", false)
UnitFactionGroup=oldFaction
level, states[1013] = 30, nil
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
