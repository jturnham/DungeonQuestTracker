local placeholders = 0
for key, dungeon in pairs(DQT.dungeons) do
    if dungeon.placeholder then
        placeholders = placeholders + 1
        assert(#dungeon.quests == 0, "Placeholder must not invent quests: " .. key)
        assert(dungeon.entryLevelUnverified and dungeon.source, "Placeholder provenance missing")
        assert(#dungeon.factions == 2, "Placeholder must support both factions")
        assert(dungeon.provisionalData and dungeon.betaAvailability=="not-tested", "Untested placeholder must be visibly provisional")
    end
    assert(type(dungeon.provisionalData)=="boolean" and dungeon.betaAvailability,"Dungeon beta provenance missing: "..key)
end
assert(placeholders == 2, "Blackmaw Hold and Shaper's Terrace remain placeholders")
assert(#DQT.dungeons["the-drowned-city"].quests == 15)
assert(DQT.quests[95775].foreverXp == 8450 and DQT.quests[95775].followUpOf == 95770)
assert(DQT.quests[95776].foreverXp == 9500 and DQT.quests[95776].followUpOf == 95773)
assert(DQT.quests[95787].followUpOf == 95786 and not DQT.quests[95787].foreverXp)
assert(#DQT.dungeons["kroldok-stronghold"].quests == 7 and DQT.quests[96771].foreverXp == 11500)
assert(DQT.quests[94968].faction == "Horde" and DQT.quests[94982].faction == "Alliance")
assert(DQT.quests[96772].dungeon == "alcaz-prison" and DQT.quests[96772].xpPublished)
local first, second = DQT:GetOrderedDungeonKeys(), DQT:GetOrderedDungeonKeys()
for index, key in ipairs(first) do assert(key == second[index], "Dungeon order must be stable") end
for _, id in ipairs({92753,92819,95036,95042,95111}) do
    assert(DQT.quests[id] and (not DQT.quests[id].foreverXp or (DQT.quests[id].xpGuide or DQT.quests[id].xpPublished)), "New rewards require explicit source provenance")
end
assert(DQT.quests[92819].followUpOf == 92753)
assert(DQT.quests[95111].followUpOf == 95036)
for _, key in ipairs({"deadmines","shadowfang-keep","blackfathom-deeps"}) do
    local count = 0
    for _, id in ipairs(DQT.dungeons[key].quests) do if id == 95036 then count = count + 1 end end
    assert(count == 1, "Shared Paladin quest membership: " .. key)
end
for _, key in ipairs({"zul-farrak","maraudon","sunken-temple","blackrock-depths","dire-maul-east","dire-maul-west","dire-maul-north","lower-blackrock-spire","upper-blackrock-spire","scholomance","stratholme-main-gate","stratholme-service-gate"}) do
    assert(#DQT.dungeons[key].quests > 0 and not DQT.dungeons[key].placeholder, "Classic quest coverage missing: " .. key)
    assert(DQT.dungeons[key].provisionalData and DQT.dungeons[key].notes:find("Classic-source quest data",1,true),"Unreviewed Forever changes retain a specific Classic-data warning: "..key)
end
do
    local ui, search, db = DQT.UI, DQT.UI.searchText, DQT.db
    DQT.db={display={compact=false}}
    ui.searchText="blackrock"
    for _,compact in ipairs({false,true}) do
        DQT.db.display.compact=compact
        ui:ShowDungeonList()
        for i=1,3 do assert(ui.frame.dungeonCards[i].name:GetText():find("[Provisional]",1,true),"Both card layouts show provisional label") end
        ui:ShowDungeon(DQT:GetDisplayDungeonStatus("blackrock-depths"))
        assert(ui.frame.subtitle:GetText():find("[Provisional]",1,true),"Both checklist layouts show provisional label")
    end
    ui.searchText,DQT.db=search,db
end
local classQuests = {[8422]="WARLOCK",[8425]="WARRIOR",[9053]="DRUID",[8413]="SHAMAN",[8253]="MAGE",[8232]="HUNTER",[8257]="PRIEST",[8236]="ROGUE",[8418]="PALADIN"}
for id, class in pairs(classQuests) do
    local quest = assert(DQT.quests[id], "Missing Sunken Temple class quest")
    assert(quest.classes and #quest.classes == 1 and quest.classes[1] == class, "Class restriction missing: " .. id)
    assert(quest.minLevel == 50 and quest.classicSourceOnly and not quest.foreverXp, "Classic provenance/level missing")
end
assert(not DQT.quests[9030], "Unused low-level variant must not be imported")
assert(DQT.quests[8951].classes and DQT.quests[8951].classes[1] == "DRUID", "Dungeon-set variants must retain their class")
assert(DQT.quests[8951].followUpOf == 9015, "Dungeon-set return must link to The Challenge")
local oldLevel, oldFaction, oldClass = UnitLevel, UnitFactionGroup, UnitClass
local oldLog = C_QuestLog
UnitLevel = function() return 60 end
UnitFactionGroup = function() return "Horde" end
UnitClass = function() return "Warrior", "WARRIOR" end
C_QuestLog = {
    IsOnQuest=function(id) return id == 2768 end,
    ReadyForTurnIn=function(id) return id == 2768 end,
    IsQuestFlaggedCompleted=function() return false end,
}
local status = DQT:GetDungeonQuestStatus("zul-farrak")
local found = false
for _, row in ipairs(status.quests) do
    if row.questID == 2768 then assert(row.state == "ready"); found = true end
end
assert(found, "Level-60 character must retain owned dungeon quests above the former beta range")
found = false
for _, row in ipairs(DQT:GetGlobalTurnInPriority().quests) do if row.questID == 2768 then found = true end end
assert(found, "High-level ready quest must appear in global turn-ins")
UnitLevel, UnitFactionGroup, UnitClass, C_QuestLog = oldLevel, oldFaction, oldClass, oldLog
print("Dungeon review tests passed: Classic coverage, new Forever quests, stable order and uncapped turn-ins.")
