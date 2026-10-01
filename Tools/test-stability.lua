local messages, sent = {}, {}
function DQT:Print(message) table.insert(messages, tostring(message)) end
local modern = C_QuestLog
C_QuestLog = nil
GetBuildInfo = nil
UnitName = nil
DQT:Debug(1221)
assert(not DQT:HandleAddonMessage("DQT1", "REQ|gnomeregan", "PARTY", "Tester"))
assert(not DQT:IsQuestReadyForTurnIn(1221, "Blueleaf Tubers"))

function GetNumQuestLogEntries() return 1 end
function GetQuestLogTitle() return "Blueleaf Tubers", 26, nil, false, false, -1, nil, 1221 end
assert(DQT:GetQuestLogIndexByQuestID(1221) == 1)
assert(not DQT:IsQuestReadyForTurnIn(1221, "Blueleaf Tubers"), "Failed (-1) quest is not ready")
function GetNumQuestLeaderBoards() return 1 end
function GetQuestLogLeaderBoard() return "Tubers", "item", true end
assert(DQT:IsQuestReadyForTurnIn(1221, "Blueleaf Tubers"), "Legacy completed objectives")
GetNumQuestLeaderBoards, GetQuestLogLeaderBoard = nil, nil
C_QuestLog = {
    GetLogIndexForQuestID = function() error("Unsupported beta API") end,
    ReadyForTurnIn = function() error("Unsupported beta API") end,
}
assert(DQT:GetQuestLogIndexByQuestID(1221) == 1, "Legacy fallback after API error")
assert(not DQT:IsQuestReadyForTurnIn(1221, "Blueleaf Tubers"))
assert(DQT.lastAPIError:match("Unsupported beta API"))

local clock = 10
function GetTime() return clock end
function IsInGroup() return true end
function GetNumSubgroupMembers() return 1 end
function UnitFullName(unit)
    if unit == "player" then return "Owner", "TestRealm" end
    if unit == "party1" then return "Tester", "TestRealm" end
end
function GetNormalizedRealmName() return "TestRealm" end
assert(DQT:NormalizePartySender("Tester") == "Tester-TestRealm")
assert(DQT:NormalizePartySender("Tester-TestRealm") == "Tester-TestRealm")
assert(DQT:NormalizePartySender("Owner-TestRealm") == nil)
assert(DQT:NormalizePartySender("Stranger-OtherRealm") == nil)
C_ChatInfo = { SendAddonMessage = function(prefix, message, channel)
    assert(#message <= 255, "Addon payload exceeds limit")
    assert(channel == "PARTY")
    table.insert(sent, message)
end }
assert(DQT:RequestPartyDungeonStatus("gnomeregan"))
local firstCount = #sent
assert(not DQT:RequestPartyDungeonStatus("gnomeregan"), "Repeated request must be throttled")
assert(#sent == firstCount)
clock = clock + 5
assert(DQT:RequestPartyDungeonStatus("gnomeregan"))
-- Force a larger-than-current checklist to exercise multi-message reassembly.
local savedQuests = DQT.dungeons.gnomeregan.quests
local synthetic = {}
for id in pairs(DQT.quests) do table.insert(synthetic, id) end
DQT.dungeons.gnomeregan.quests = synthetic
sent = {}
assert(DQT:SendDungeonStatus("gnomeregan"))
assert(#sent > 1, "Large checklist should be chunked")
for _, message in ipairs(sent) do DQT:HandleAddonMessage("DQT1", message, "PARTY", "Tester") end
local entry = DQT.partyStatus.gnomeregan["Tester-TestRealm"]
local count = 0
for _ in pairs(entry.quests) do count = count + 1 end
assert(count == #DQT:GetDungeonQuestStatus("gnomeregan").quests, "Chunk reassembly lost quests")
for _, message in ipairs(sent) do DQT:HandleAddonMessage("DQT1", message, "PARTY", "Tester-TestRealm") end
local senders = 0
for _ in pairs(DQT.partyStatus.gnomeregan) do senders = senders + 1 end
assert(senders == 1, "Short and realm names must not duplicate respondents")
DQT:HandleAddonMessage("DQT1", "STATUS|not-a-dungeon|1:ready", "PARTY", "Tester")
assert(not DQT.partyStatus["not-a-dungeon"])
DQT:HandleAddonMessage("DQT1", "STATUS|gnomeregan|1221:INVALID,999999:ready", "PARTY", "Tester")
assert(not entry.quests[999999])
clock = clock + 121
assert(DQT:GetPartyQuestSummary("gnomeregan", 1221) == "Party: not checked", "Expired status")
DQT.dungeons.gnomeregan.quests = savedQuests

QuestLogPushQuest, GetQuestLogPushable = nil, nil
local ok, reason = DQT:ShareQuest(1221, "Blueleaf Tubers")
assert(not ok and reason == "Shareability API unavailable")
function GetQuestLogPushable() return false end
ok, reason = DQT:ShareQuest(1221, "Blueleaf Tubers")
assert(not ok and reason == "Not shareable")
function GetQuestLogPushable() return true end
function QuestLogPushQuest() error("Sharing unavailable") end
ok, reason = DQT:ShareQuest(1221, "Blueleaf Tubers")
assert(not ok and reason == "Quest sharing API failed")
function QuestLogPushQuest(index) assert(index == 1) end
assert(DQT:ShareQuest(1221, "Blueleaf Tubers"))
function IsInGroup() return false end
assert(DQT:ShareDungeonQuests("gnomeregan") == 0)
assert(messages[#messages]:match("Join a party"))

DungeonQuestTrackerDB = { minimap = { angle = "corrupt" } }
DQT.Minimap:Refresh()
local button = DQT.Minimap.button
GameTooltip, GetCursorPosition = nil, nil
button.scripts.OnEnter(button)
button.scripts.OnLeave(button)
button.scripts.OnDragStart(button)
button.scripts.OnUpdate(button)
button.scripts.OnDragStop(button)
local oldMinimap = Minimap
Minimap = nil
DQT.Minimap.button = nil
DQT.Minimap:Refresh()
Minimap = oldMinimap
C_QuestLog = modern
print("Passed compatibility: missing/throwing APIs, legacy ready fallback, failed quests, sender normalization, cooldowns, 255-byte chunks, stale/malformed messages, sharing errors and minimap guards.")
