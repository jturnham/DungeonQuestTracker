local ui = DQT.UI
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
