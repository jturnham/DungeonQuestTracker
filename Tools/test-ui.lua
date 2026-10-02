local ui = DQT.UI
local originalGetQuest = DQT.GetQuest
local chain = {
    [900001] = {name="Initial quest"},
    [900002] = {name="First follow-up", followUpOf=900001},
    [900003] = {name="Second follow-up", followUpOf=900002},
    [900004] = {name="Unrelated quest"},
}
DQT.GetQuest = function(self, id) return chain[id] or originalGetQuest(self, id) end
local function Entry(id) return {questID=id, quest=chain[id], state="missing"} end
local input = {Entry(900001), Entry(900004), Entry(900003), Entry(900002)}
local grouped = ui:GroupChecklistQuests(input)
assert(grouped[1].questID == 900001 and grouped[2].questID == 900002 and grouped[3].questID == 900003 and grouped[4].questID == 900004, "Chains render together in prerequisite order")
assert(grouped[3].chainDepth == 2 and grouped[3].visibleParent == 900002, "Follow-up nesting")
assert(input[2].questID == 900004 and not input[1].chainDepth, "Grouping does not mutate source status")
local filtered = ui:GroupChecklistQuests({Entry(900003), Entry(900004)})
assert(filtered[1].chainRoot == 900001 and not filtered[1].visibleParent, "Filtered ancestors retain chain identity")
chain[900001].followUpOf = 900003
assert(#ui:GroupChecklistQuests(input) == 4, "Malformed cycles do not hang or lose rows")
DQT.GetQuest = originalGetQuest
local oldDB = DQT.db
DQT.db = {filters={ignoreGrayChecklist=false, ignoreRedChecklist=false, hideGrayDungeons=false, hideRedDungeons=false}}
ui.searchText = "  wAiLiNg  "
ui:ShowDungeonList()
assert(ui.frame.dungeonCards[1].name.text == "Wailing Caverns", "Case-insensitive search")
assert(not ui.frame.dungeonCards[2]:IsShown(), "Search hides pooled cards")
ui.searchText = "no such dungeon"
ui:ShowDungeonList()
assert(ui.frame.listEmpty:IsShown(), "Search empty state")
ui.searchText = ""
ui:ShowDungeonList()
assert(not ui.frame.listEmpty:IsShown(), "Clearing search removes empty state")
ui.frame.dungeonScroll:SetVerticalScroll(120)
ui:RefreshCurrentDungeon()
assert(ui.frame.dungeonScroll:GetVerticalScroll() == 120, "List refresh preserves scroll")
local card = ui.frame.dungeonCards[1]
local dungeonKey
for key, dungeon in pairs(DQT.dungeons) do
    if dungeon.name == card.name.text then dungeonKey = key end
end
local originalName = DQT.dungeons[dungeonKey].name
DQT.dungeons[dungeonKey].name = string.rep("Long dungeon name ", 100)
ui:ShowDungeonList()
assert(ui.frame.dungeonCards[1]:GetHeight() > 124, "Long card expands")
DQT.dungeons[dungeonKey].name = originalName
local originalPlanner = DQT.GetGlobalTurnInPriority
DQT.GetGlobalTurnInPriority = function()
    local quests = {}
    for i = 1, 12 do
        quests[i] = { quest = { name = string.rep("Long quest name ", 100), turnIn = {name = "NPC", zone = "Zone"} }, effectiveXp = 100 }
    end
    return { quests = quests, context = {}, xpToLevel = 0 }
end
ui:ShowTurnIns()
assert(ui.frame.turnInRows[1]:GetHeight() > 56, "Long turn-in expands")
ui.frame.turnInScroll:SetVerticalScroll(100)
ui:RefreshCurrentDungeon()
assert(ui.frame.turnInScroll:GetVerticalScroll() == 100, "Turn-in refresh preserves scroll")
DQT.GetGlobalTurnInPriority = originalPlanner
ui:ShowDungeonList()
print("Passed UI: search, pooled cards, empty states, long text and refresh scroll preservation.")
DQT.db = oldDB
