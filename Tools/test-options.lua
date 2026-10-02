local savedDB, savedGlobalDB = DQT.db, DungeonQuestTrackerDB
local savedLevel, savedFaction, savedClass = UnitLevel, UnitFactionGroup, UnitClass
local savedCompleted, savedReady, savedActive = DQT.IsQuestComplete, DQT.IsQuestReadyForTurnIn, DQT.IsQuestActive
local savedGray = GetQuestGreenRange
local states, level = {}, 30
local function ResetBaseline()
    DQT:ResetFilters()
    for _, key in ipairs({"ignoreGrayChecklist", "ignoreRedChecklist", "hideGrayDungeons", "hideRedDungeons", "hideTrackedDungeons"}) do
        DQT:SetOption("filters." .. key, false)
    end
end
UnitLevel = function() return level end
UnitFactionGroup = function() return "Horde" end
UnitClass = function() return "Warrior", "WARRIOR" end
GetQuestGreenRange = function() return 5 end
DQT.IsQuestComplete = function(_, id) return states[id] == "completed" end
DQT.IsQuestReadyForTurnIn = function(_, id) return states[id] == "ready" end
DQT.IsQuestActive = function(_, id) return states[id] == "active" end
DQT.db = {filters={showCompleted=false, showUnavailable=true}, minimap={}, partyQuestCache={}}
DungeonQuestTrackerDB = DQT.db
DQT:InitializeOptions()
assert(DQT:GetOption("filters.showCompleted") and not DQT:GetOption("filters.showUnavailable"), "Dormant default migration")
assert(DQT:GetOption("party.respond") and not DQT:GetOption("party.autoBroadcast"))
assert(DQT:SetOption("filters.lowLevelGap", 200) and DQT:GetOption("filters.lowLevelGap") == 60)
assert(DQT:SetOption("filters.lowLevelGap", -2) and DQT:GetOption("filters.lowLevelGap") == 0)
assert(not DQT:SetOption("filters.lowLevelGap", "invalid"))
assert(not DQT:SetOption("filters.showCompleted", "false"))
assert(not DQT:SetOption("notAnOption", true))
DQT:SetOption("filters.showCompleted", false)
DQT:InitializeOptions()
assert(not DQT:GetOption("filters.showCompleted"), "Reload preserves chosen values")
ResetBaseline()
local key = "options-test"
DQT.dungeons[key] = {name="Options Test", minLevel=10, recommendedLevel="10-20", factions={"Horde"}, quests={}}
for i=1,10 do
    local id = 999100+i
    DQT.dungeons[key].quests[i] = id
    DQT.quests[id] = {name="Test " .. i, dungeon=key, minLevel=1, questLevel=30, classicXp=100,
        pickup={name="NPC",zone="Zone"}, turnIn={name="NPC",zone="Zone"}, prerequisites={}}
end
local function Quest(i) return DQT.quests[999100+i] end
states[999101], states[999102], states[999103] = "completed", "ready", "active"
Quest(2).questLevel, Quest(3).questLevel, Quest(4).questLevel = 10, 10, 10
Quest(5).faction = "Alliance"
Quest(6).classes = {"MAGE"}
Quest(7).breadcrumbOnly = true
Quest(8).pickupType, Quest(9).pickupType = "drop", "object"
Quest(10).prerequisites = {{questID=999104,relationship="required"}}
local function Visible(i)
    for _, row in ipairs(DQT:GetDisplayDungeonStatus(key).quests) do if row.questID == 999100+i then return true end end
    return false
end
assert(Visible(1) and not Visible(5) and not Visible(6), "Default visibility")
DQT:SetOption("filters.showCompleted", false); assert(not Visible(1))
DQT:SetOption("filters.showUnavailable", true); assert(Visible(5) and Visible(6))
DQT:SetOption("filters.showClassRestricted", false); assert(not Visible(6))
DQT:SetOption("filters.includeBreadcrumbs", false); assert(not Visible(7))
DQT:SetOption("filters.includeItemQuests", false); assert(not Visible(8) and not Visible(9))
DQT:SetOption("filters.ignoreGrayChecklist", true)
assert(Visible(2) and not Visible(3) and Visible(4), "Gray ready and blocking prerequisites protected")
Quest(10).prerequisites = {}
assert(not Visible(4), "Unneeded gray prerequisite can hide")
Quest(4).prerequisites = {{questID=998001,relationship="required",external=true}}
DQT:SetOption("filters.ignoreGrayChecklist", false)
DQT:SetOption("filters.showLowLevelLocked", false); assert(not Visible(4))
ResetBaseline()
DQT:SetOption("filters.hideLowDungeons", true)
DQT:SetOption("filters.lowLevelGap", 5)
assert(DQT:ShouldShowDungeon(DQT:GetDisplayDungeonStatus(key)), "Active/ready dungeon protected from level filters")
DQT:SetOption("filters.hideTrackedDungeons", true)
assert(not DQT:ShouldShowDungeon(DQT:GetDisplayDungeonStatus(key)))
DQT:SetOption("filters.lowLevelGap", 10)
assert(DQT:ShouldShowDungeon(DQT:GetDisplayDungeonStatus(key)), "Level gap boundary inclusive")
ResetBaseline()
level=5
DQT:SetOption("filters.hideHighDungeons", true); DQT:SetOption("filters.highLevelGap", 4)
assert(DQT:ShouldShowDungeon(DQT:GetDisplayDungeonStatus(key)))
DQT:SetOption("filters.hideTrackedDungeons", true)
assert(not DQT:ShouldShowDungeon(DQT:GetDisplayDungeonStatus(key)))
level=30
ResetBaseline()
DQT:SetOption("filters.onlyMissing", true); DQT:SetOption("filters.onlyReady", true)
assert(DQT:ShouldShowDungeon(DQT:GetDisplayDungeonStatus(key)), "Combined filters require both")
states[999102] = "completed"
assert(not DQT:ShouldShowDungeon(DQT:GetDisplayDungeonStatus(key)))
states[999102] = "ready"
DQT:SetOption("filters.includeItemQuests", false); DQT:SetOption("filters.ignoreGrayChecklist", true)
local found = false
for _, row in ipairs(DQT:GetGlobalTurnInPriority().quests) do if row.questID == 999102 then found=true end end
assert(found, "Checklist filters do not suppress planner")
DQT:SetOption("filters.ignoreGrayTurnIns", true)
for _, row in ipairs(DQT:GetGlobalTurnInPriority().quests) do assert(row.questID ~= 999102, "Explicit gray planner filter") end
ResetBaseline()
for i=1,10 do Quest(i).questLevel=10 end
DQT:SetOption("filters.hideGrayDungeons", true)
assert(DQT:ShouldShowDungeon(DQT:GetDisplayDungeonStatus(key)))
DQT:SetOption("filters.hideTrackedDungeons", true)
assert(not DQT:ShouldShowDungeon(DQT:GetDisplayDungeonStatus(key)))
ResetBaseline()
DQT.Minimap:Refresh()
DQT:SetOption("minimap.hide", true); assert(not DQT.Minimap.button:IsShown())
DQT:SetOption("minimap.hide", false); assert(DQT.Minimap.button:IsShown())
DQT.db.minimap.angle=10; DQT:ResetMinimapPosition(); assert(DQT.db.minimap.angle == 225)
DQT.UI:ShowDungeonList()
DQT.UI:ShowOptions()
assert(DQT.UI.currentView == "options" and DQT.UI.frame.optionsContent:GetHeight() > 470)
for _, control in ipairs(DQT.UI.frame.optionControls) do
    local option = control.option
    if option.key == "filters.onlyMissing" then control:SetChecked(true); control.scripts.OnClick(control); assert(DQT:GetOption(option.key)) end
    if option.key == "filters.lowLevelGap" then control:SetText("99"); control.scripts.OnEnterPressed(control); assert(DQT:GetOption(option.key) == 60) end
end
DQT.UI:CloseOptions(); assert(DQT.UI.currentView == "list")
local oldShare, oldGroup, oldPopup, oldDialogs = DQT.ShareDungeonQuests, DQT.IsGrouped, StaticPopup_Show, StaticPopupDialogs
local shares = 0
DQT.ShareDungeonQuests=function() shares=shares+1 end
DQT.IsGrouped=function() return true end
DQT:SetOption("party.confirmShareAll", true)
StaticPopupDialogs={}
StaticPopup_Show=function(which, _, _, data) assert(which == "DQT_CONFIRM_SHARE_ALL" and data == key) end
DQT.UI:RequestShareAll(key); assert(shares == 0, "Confirmation waits for acceptance")
StaticPopupDialogs.DQT_CONFIRM_SHARE_ALL.OnAccept(nil,key); assert(shares == 1)
StaticPopup_Show=nil
DQT.UI:RequestShareAll(key); assert(shares == 1, "No confirmation API fails closed")
DQT:SetOption("party.confirmShareAll", false)
DQT.UI:RequestShareAll(key); assert(shares == 2)
DQT.ShareDungeonQuests, DQT.IsGrouped, StaticPopup_Show, StaticPopupDialogs = oldShare, oldGroup, oldPopup, oldDialogs
local oldGroupAPI, oldChat, oldClock, oldNormalize = IsInGroup, C_ChatInfo, GetTime, DQT.NormalizePartySender
local partyMessages, clock = {}, 500
IsInGroup=function() return true end
GetTime=function() return clock end
DQT.NormalizePartySender=function(_, sender) return sender end
C_ChatInfo={SendAddonMessage=function(_, payload) partyMessages[#partyMessages+1]=payload end}
DQT.partyResponseTimes=DQT.partyResponseTimes or {}; DQT.partyResponseTimes[key]=nil
DQT:SetOption("party.respond", false)
DQT:HandleAddonMessage("DQT1", "REQ|" .. key, "PARTY", "Peer")
assert(#partyMessages == 0, "Party responses disabled")
DQT:SetOption("party.respond", true)
DQT:HandleAddonMessage("DQT1", "REQ|" .. key, "PARTY", "Peer")
assert(#partyMessages > 0, "Party responses enabled")
partyMessages={}
DQT:SetOption("party.autoBroadcast", false)
DQT:OpenDungeon(key); assert(#partyMessages == 0, "Auto broadcast defaults off")
DQT:SetOption("party.autoBroadcast", true)
DQT:OpenDungeon(key); assert(#partyMessages > 0, "Opening a dungeon broadcasts when enabled")
local messageCount=#partyMessages
DQT:OpenDungeon(key); assert(#partyMessages == messageCount, "Auto broadcasts throttled")
clock=clock+5
DQT:OpenDungeon(key); assert(#partyMessages > messageCount)
DQT.autoBroadcastTimes[key], DQT.partyResponseTimes[key] = nil, nil
IsInGroup, C_ChatInfo, GetTime, DQT.NormalizePartySender = oldGroupAPI, oldChat, oldClock, oldNormalize
for i=1,10 do DQT.quests[999100+i]=nil end
DQT.dungeons[key]=nil
DQT.db, DungeonQuestTrackerDB = savedDB, savedGlobalDB
UnitLevel, UnitFactionGroup, UnitClass, GetQuestGreenRange = savedLevel, savedFaction, savedClass, savedGray
DQT.IsQuestComplete, DQT.IsQuestReadyForTurnIn, DQT.IsQuestActive = savedCompleted, savedReady, savedActive
DQT.UI:ShowDungeonList()
print("Passed Options: migration, persistence, quest/list filters, protected ready/blocking quests, independent planner, minimap, navigation, sharing confirmation, party responses and auto-broadcast cooldown.")
