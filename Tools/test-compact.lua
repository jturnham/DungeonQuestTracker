local ui, oldDB, oldGlobalDB = DQT.UI, DQT.db, DungeonQuestTrackerDB
DQT.db = {optionsVersion=2, filters={ignoreGrayChecklist=false, ignoreRedChecklist=false, hideGrayDungeons=false, hideRedDungeons=false}, display={}, minimap={}, partyQuestCache={}}
DungeonQuestTrackerDB = DQT.db
DQT:InitializeOptions()
ui.searchText = ""
ui:ShowDungeonList()
local frame = ui.frame
assert(frame.compactButton:GetWidth() == 24 and frame.compactButton:GetHeight() == 24, "Compact toggle has a larger target")
assert(frame.optionsButton:GetWidth() == 16 and frame.optionsButton:GetHeight() == 16, "Options icon fits title bar")
assert(frame.optionsButton.points[1][2] == frame.compactButton and frame.optionsButton.points[1][3] == "LEFT", "Options sits beside compact toggle")
assert(frame.version.points[1][2] == frame.optionsButton, "Version stays clear of title controls")
if frame.CloseButton then
    assert(frame.compactButton.points[1][2] == frame.CloseButton, "Compact toggle next to Close")
else
    assert(frame.compactButton.points[1][1] == "TOPRIGHT" and frame.compactButton.points[1][4] == -30, "Close-area fallback anchor")
end
assert(frame:GetWidth() == 780 and not DQT:GetOption("display.compact"))
local fullHeight = frame.dungeonContent:GetHeight()
frame.compactButton.scripts.OnClick(frame.compactButton)
assert(DQT:GetOption("display.compact") and ui.currentView == "list")
assert(frame:GetWidth() == 520 and frame:GetHeight() == 500)
assert(frame.dungeonContent:GetHeight() < fullHeight, "Compact list is denser")
local card = frame.dungeonCards[1]
assert(not card.art:IsShown() and not card.bg:IsShown() and not card.meta:IsShown() and not card.summary:IsShown() and not card.party:IsShown())
assert(card.name:IsShown() and card.name:GetWidth() <= card:GetWidth())
assert(not frame.syncOption:IsShown(), "Sync remains available in Options without crowding compact search")
frame.search:SetText("wailing")
assert(frame.dungeonCards[1].name:GetText() == "Wailing Caverns", "Compact search works")
frame.search:SetText("")
local key = "compact-test"
DQT.dungeons[key] = {name="Compact Test", minLevel=10, recommendedLevel="20-30", factions={"Horde","Alliance"}, quests={}}
for i=1,20 do
    local id = 998100+i
    DQT.dungeons[key].quests[i] = id
    DQT.quests[id] = {name=i == 1 and string.rep("Long quest name ", 16) or "Compact quest " .. i,
        dungeon=key, questLevel=30, minLevel=1, classicXp=100,
        pickup={name="NPC",zone="Zone"}, turnIn={name="NPC",zone="Zone"}, prerequisites={}}
end
ui.expandedQuests[998101] = true
DQT:OpenDungeon(key)
local row = frame.rows[1]
assert(not row.status:IsShown() and not row.icon:IsShown() and not row.toggle:IsShown() and not row.share:IsShown())
assert(not row.detail:IsShown() and not row.reason:IsShown() and not row.party:IsShown())
assert(not row.title:GetText():find("#",1,true), "Compact quest names omit IDs")
assert(row.title:GetWidth() <= row:GetWidth() and row:GetHeight() > 24, "Long compact names wrap")
row.scripts.OnClick(row)
assert(ui.expandedQuests[998101] == true, "Compact clicks preserve full expansion state")
assert(frame.checklistContent:GetHeight() > frame.content:GetHeight(), "Compact checklist scrolls")
frame.checklistScroll:SetVerticalScroll(40)
ui:RefreshCurrentDungeon()
assert(frame.checklistScroll:GetVerticalScroll() == 40)
frame.compactButton.scripts.OnClick(frame.compactButton)
assert(frame:GetWidth() == 780 and ui.currentDungeonKey == key)
assert(row.status:IsShown() and row.share:IsShown() and row.detail:IsShown())
assert(row.title:GetText():find("#998101",1,true) and row.detail:GetWidth() == 660, "Full row restored")
local originalPlanner = DQT.GetGlobalTurnInPriority
DQT.GetGlobalTurnInPriority = function()
    local quests={}
    for i=1,20 do quests[i]={quest=DQT.quests[998100+i],effectiveXp=100,dungeon=DQT.dungeons[key]} end
    return {quests=quests,context={level=30},xpToLevel=1000}
end
ui:ShowTurnIns()
frame.compactButton.scripts.OnClick(frame.compactButton)
assert(ui.currentView == "turnins" and frame:GetWidth() == 520)
assert(not frame.turnInRows[1].detail:IsShown())
assert(frame.turnInRows[1].title:GetText() == DQT.quests[998101].name)
assert(frame.turnInRows[1].tooltipTitle:find("100 XP",1,true))
assert(frame.turnInContent:GetHeight() > frame.content:GetHeight())
frame.turnInScroll:SetVerticalScroll(30)
ui:RefreshCurrentDungeon(); assert(frame.turnInScroll:GetVerticalScroll() == 30)
ui:ShowOptions()
assert(frame:GetWidth() == 780 and DQT:GetOption("display.compact"), "Options stays full-width without changing preference")
ui:CloseOptions()
assert(frame:GetWidth() == 520 and ui.currentView == "turnins")
DQT:InitializeOptions()
assert(DQT:GetOption("display.compact"), "Compact preference survives reload normalization")
frame.compactButton.scripts.OnClick(frame.compactButton)
assert(frame:GetWidth() == 780 and frame.turnInRows[1].detail:IsShown())
DQT.GetGlobalTurnInPriority = function() return {quests={},context={},xpToLevel=0} end
DQT:SetOption("display.compact", true)
assert(frame.turnInRows[1].title:GetWidth() <= frame.turnInContent:GetWidth(), "Compact empty state fits")
DQT.GetGlobalTurnInPriority = originalPlanner
for i=1,20 do DQT.quests[998100+i]=nil; ui.expandedQuests[998100+i]=nil end
DQT.dungeons[key]=nil
DQT.db, DungeonQuestTrackerDB = oldDB, oldGlobalDB
ui:ShowDungeonList()
assert(frame:GetWidth() == 780 and frame.dungeonCards[1].art:IsShown(), "Full cards restored")
print("Passed compact mode: persistence, title-bar toggle, text-only layouts, search, wrapping, scrolling, expanded-row restoration, turn-in order and full-width Options.")
