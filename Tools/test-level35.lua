DQT = {}
local player = { faction = "Horde", class = "WARRIOR", race = "Orc", level = 30 }
local completed, ready = {}, {}
local methods = {}
local function widget()
    return setmetatable({ shown = true, height = 470, scroll = 0, scripts = {} }, {
        __index = function(_, key) return methods[key] or function() end end,
    })
end
function methods:CreateTexture() return widget() end
function methods:CreateFontString() return widget() end
function methods:Hide() self.shown = false end
function methods:Show() self.shown = true end
function methods:IsShown() return self.shown end
function methods:SetShown(value) self.shown = value end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:SetHeight(height) self.height = height end
function methods:GetHeight() return self.height end
function methods:SetText(text) self.text = text end
function methods:GetStringHeight() return math.max(12, math.ceil(#(self.text or "") / 80) * 12) end
function methods:SetVerticalScroll(value) self.scroll = value end
function methods:GetVerticalScroll() return self.scroll end
function methods:SetScript(event, callback) self.scripts[event] = callback end
function methods:SetScrollChild(child) self.child = child end
function CreateFrame() local frame = widget(); frame.TitleBg = widget(); return frame end
UIParent = widget()
Minimap = widget()
SlashCmdList = {}
function UnitFactionGroup() return player.faction end
function UnitClass() return player.class, player.class end
function UnitRace() return player.race, player.race end
function UnitLevel() return player.level end
function UnitXP() return 25000 end
function UnitXPMax() return 40000 end
function IsQuestFlaggedCompleted(id) return completed[id] or false end
C_QuestLog = {
    IsQuestFlaggedCompleted = IsQuestFlaggedCompleted,
    ReadyForTurnIn = function(id) return ready[id] or false end,
    IsOnQuest = function(id) return ready[id] or false end,
}

-- RUN TESTS
local keys = DQT:GetOrderedDungeonKeys()
assert(#keys == 15, "Expected 15 dungeons")
local listed, newCount = {}, 0
for _, key in ipairs(keys) do
    assert(not listed[key], "Duplicate dungeon key")
    listed[key] = true
    for _, id in ipairs(DQT.dungeons[key].quests) do
        local quest = assert(DQT:GetQuest(id), "Missing quest " .. id)
        assert(quest.name and quest.pickup, "Incomplete quest " .. id)
        if quest.source and quest.source:match("wowhead.com/forever/quest=") then
            assert(quest.turnIn and quest.objectives, "Incomplete new quest " .. id)
        end
        assert(quest.minLevel <= 35, "Pickup above requested range: " .. id)
        assert(DQT:GetDungeon(quest.dungeon), "Invalid primary dungeon " .. id)
    end
end
for id, quest in pairs(DQT.quests) do
    if quest.source and quest.source:match("wowhead.com/forever/quest=") then newCount = newCount + 1 end
end
for _, faction in ipairs({ "Alliance", "Horde" }) do
    player.faction = faction
    for index = 8, #keys do
        assert(DQT:DungeonHasVisibleQuests(keys[index]), "New dungeon hidden for " .. faction .. ": " .. keys[index])
        assert(DQT:GetDungeonQuestStatus(keys[index]), "Missing status")
    end
    assert(#DQT:GetDungeonQuestStatus("excavation-site-wetlands").quests == 0)
    assert(#DQT:GetDungeonQuestStatus("city-of-dalaran").quests == 0)
end
player.faction = "Horde"
player.race = "Scourge"
assert(DQT:GetQuestAvailability(DQT:GetQuest(1049)) == "unavailable", "Undead Compendium restriction")
player.race = "Orc"
assert(DQT:GetQuestAvailability(DQT:GetQuest(1049)) == "available")
assert(DQT:GetQuestAvailability(DQT:GetQuest(1113)) == "locked", "Guano prerequisite")
completed[1109] = true
assert(DQT:GetQuestAvailability(DQT:GetQuest(1113)) == "available")
completed[1109] = nil
player.class = "MAGE"
assert(DQT:GetQuestAvailability(DQT:GetQuest(1838)) == "unavailable", "Warrior restriction")
player.class = "WARRIOR"
completed[1102] = true
assert(DQT:GetQuestState(1102, DQT:GetQuest(1102)) == "completed")
ready[1113], ready[1740] = true, true
player.class = "WARLOCK"
local plan = DQT:GetGlobalTurnInPriority()
assert(#plan.quests == 2, "Shared quests must appear once in global turn-ins")
local seen = {}
for _, item in ipairs(plan.quests) do
    assert(not seen[item.questID], "Duplicate turn-in")
    seen[item.questID] = true
end
assert(DQT:GetQuestRewardXP(DQT:GetQuest(1221)) == 7875, "Reported Forever XP")
local _, source = DQT:GetQuestRewardXP(DQT:GetQuest(2841))
assert(source == "Classic", "Unconfirmed reward must be labelled as an estimate")
player.class = "WARRIOR"
for _, row in ipairs(DQT:GetDungeonQuestStatus("shadowfang-keep").quests) do
    assert(row.questID ~= 1740 and row.questID ~= 1654, "Unrelated class quests hidden")
end

DQT.UI:ShowDungeonList()
assert(DQT.UI.frame.dungeonContent.height > 470, "Dungeon list should scroll")
DQT.UI:ShowDungeon(DQT:GetDungeonQuestStatus("city-of-dalaran"))
assert(DQT.UI.frame.emptyMessage.shown and DQT.UI.frame.emptyMessage.text:match("No quests recorded"))
player.faction = "Alliance"
DQT.UI:ShowDungeon(DQT:GetDungeonQuestStatus("scarlet-monastery-graveyard"))
assert(DQT.UI.frame.emptyMessage.text:match("for your faction"))
local status = DQT:GetDungeonQuestStatus("gnomeregan")
DQT.UI.expandedQuests = {}
for _, row in ipairs(status.quests) do DQT.UI.expandedQuests[row.questID] = true end
DQT.UI:ShowDungeon(status)
assert(DQT.UI.frame.checklistContent.height > 470, "Expanded checklist should scroll")
assert(DQT.UI.frame.checklistScroll.shown)
assert(DQT.UI.frame.rows[1].height >= 104, "Expanded row sizing")
DQT.UI:ShowTurnIns()
assert(not DQT.UI.frame.checklistScroll.shown and DQT.UI.frame.turnInScroll.shown)
DQT.UI:ShowDungeonList()
assert(not DQT.UI.frame.checklistScroll.shown and DQT.UI.frame.dungeonScroll.shown)
print("Passed: " .. newCount .. " new quests, data references, faction/class/race/chain states, completed/ready tracking, deduplication, empty dungeons and scrolling/navigation.")
