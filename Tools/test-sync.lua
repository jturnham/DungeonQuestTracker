local oldDB = DQT.db
DQT.db = {partyDataSync=false, partyQuestCache={}}
DQT:InitializeQuestDataSync()
local id, original = 5723, DQT.quests[5723]
local encoded = assert(DQT:EncodePartyQuest(id, original))
local decoded = assert(DQT:DecodePartyQuest(id, encoded))
assert(decoded.name == original.name and decoded.pickup.name == original.pickup.name)
assert(not decoded.foreverXp, "XP is never transmitted")
assert(not DQT:DecodePartyQuest(id, encoded .. "&name=override"), "Duplicate fields rejected")
assert(not DQT:DecodePartyQuest(id, encoded .. "&p1.questID=bad&p1.relationship=required"), "Invalid chain ID rejected")
assert(not DQT:DecodePartyQuest(id, encoded .. "&evil=loadstring"), "Unknown fields rejected")
DQT.quests[id] = nil
DQT:HandleQuestDataMessage("CAT", "ragefire-chasm|5723", "Peer-Realm")
assert(next(DQT.dataTransfers.pending) == nil, "Sync defaults off")
DQT:SetQuestDataSync("on")
DQT:HandleQuestDataMessage("CAT", "ragefire-chasm|5723", "Peer-Realm")
assert(DQT.dataTransfers.pending["Peer-Realm:5723"], "Missing quest requested")
local total = math.ceil(#encoded/150)
for part=total,1,-1 do
    DQT:HandleQuestDataMessage("DATA", id .. "|" .. part .. "|" .. total .. "|" .. encoded:sub((part-1)*150+1,part*150), "Peer-Realm")
end
local cached = assert(DQT:GetQuest(id))
assert(cached.partySupplied and cached.source == "Peer-Realm" and cached.sourceVersion == DQT.version)
local xp, source = DQT:GetQuestRewardXP(cached)
assert(xp == 0 and source:match("unverified"), "Party XP excluded")
DQT:InitializeQuestDataSync()
assert(DQT:GetQuest(id).partySupplied, "Validated cache survives reload")
DQT.quests[id] = original
assert(DQT:GetQuest(id) == original, "Bundled data wins")
DQT:InitializeQuestDataSync()
assert(not DQT.db.partyQuestCache[id], "Bundled cache duplicate pruned")
local fakeID = 999001
decoded.name, decoded.dungeon = "Party test quest", "city-of-dalaran"
DQT.db.partyQuestCache[fakeID] = decoded
DQT:InitializeQuestDataSync()
assert(#DQT:GetDungeon("city-of-dalaran").quests == 1, "Empty dungeon accepts supplemental quests")
assert(#DQT.dungeons["city-of-dalaran"].quests == 0, "Bundled dungeon unchanged")
DQT:SetQuestDataSync("off")
assert(#DQT:GetDungeon("city-of-dalaran").quests == 0 and not DQT:GetQuest(fakeID), "Disabled sync hides cache")
DQT:SetQuestDataSync("on")
DQT:ResetQuestDataTransfers()
local originalSend = DQT.SendQuestDataMessage
local sent = 0
DQT.SendQuestDataMessage = function(_, message) assert(#message <= 255); sent=sent+1; return true end
DQT:HandleQuestDataMessage("GET", "ragefire-chasm|5723", "Peer-Realm")
assert(#DQT.dataTransfers.queue == total, "Only requested record queued")
DQT:HandleQuestDataMessage("GET", "ragefire-chasm|5723", "Peer-Realm")
assert(#DQT.dataTransfers.queue == total, "Repeated request throttled")
DQT:TickQuestData(0.1); assert(sent == 0)
DQT:TickQuestData(0.1); assert(sent == 1, "Queue sends at five messages per second")
DQT:TickQuestData(10); assert(sent == 2, "No catch-up burst")
assert(not DQT:QueueQuestData(string.rep("x",256), "Peer-Realm"))
DQT:SetQuestDataSync("clear")
assert(next(DQT.db.partyQuestCache) == nil and #DQT.dataTransfers.queue == 0)
local oldTime = GetTime
local clock = 100
GetTime = function() return clock end
DQT:ResetQuestDataTransfers()
local ids = {}
for i=1,100 do ids[#ids+1] = tostring(999000+i) end
DQT:HandleQuestDataMessage("CAT", "ragefire-chasm|" .. table.concat(ids, ","), "Peer-Realm")
local pendingCount = 0; for _ in pairs(DQT.dataTransfers.pending) do pendingCount=pendingCount+1 end
assert(pendingCount == 16, "Pending requests bounded")
DQT:HandleQuestDataMessage("DATA", "999100|1|1|name=unsolicited", "Peer-Realm")
assert(not DQT.db.partyQuestCache[999100], "Unsolicited records ignored")
DQT:HandleQuestDataMessage("DATA", "999001|1|41|name=oversized", "Peer-Realm")
assert(not DQT.db.partyQuestCache[999001], "Excessive part count rejected")
clock = 281
DQT:TickQuestData(0.2)
assert(next(DQT.dataTransfers.pending) == nil, "Incomplete transfers expire")
DQT:ResetQuestDataTransfers()
for i=1,512 do assert(DQT:QueueQuestData("GET|ragefire-chasm|5723", "Peer-Realm")) end
assert(not DQT:QueueQuestData("GET|ragefire-chasm|5723", "Peer-Realm"), "Outgoing queue bounded")
GetTime = oldTime
DQT.SendQuestDataMessage = originalSend
DQT.db = oldDB
DQT:ResetQuestDataTransfers()
for questID, quest in pairs(DQT.quests) do
    assert(quest.confidence and quest.sourceURLs and quest.verification and quest.shareability, "Missing metadata " .. questID)
    assert(not quest.faction or quest.faction == "Horde" or quest.faction == "Alliance")
    for _, prerequisite in ipairs(quest.prerequisites or {}) do
        assert(not prerequisite.questID or DQT.quests[prerequisite.questID] or prerequisite.external)
    end
end
print("Passed sync: opt-in, bounded safe records, out-of-order reassembly, reload, bundled authority, dungeon overlays, unverified XP, throttling and clear.")
