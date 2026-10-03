do
    for _, key in ipairs({"razorfen-downs","uldaman","ragefire-chasm","hall-of-thanes","ruins-of-lordaeron","wailing-caverns","deadmines","shadowfang-keep","the-stockade","blackfathom-deeps","gnomeregan","razorfen-kraul","scarlet-monastery-graveyard","scarlet-monastery-library","scarlet-monastery-armory","scarlet-monastery-cathedral"}) do
        assert(DQT.dungeons[key] and #DQT.dungeons[key].quests > 0, "Missing beta dungeon: " .. key)
    end
    local function Contains(key,id)
        for _, value in ipairs(DQT.dungeons[key].quests) do if value == id then return true end end
        return false
    end
    for _, id in ipairs({95663,95682,95737,95809,98824,98823}) do
        assert(Contains("excavation-site-wetlands",id), "Wetlands chain not included")
        assert(not DQT.quests[id].foreverXp and not DQT.quests[id].classicXp, "No fabricated new-dungeon XP")
    end
    for _, pair in ipairs({{95809,95647},{98824,95810},{98823,95664},{95682,95663},{3525,3523},{2240,2398},{2439,2279},{2440,2280}}) do
        assert(DQT.quests[pair[1]].followUpOf == pair[2], "Wrong continuation")
    end
    assert(DQT.quests[6521].dungeon == "razorfen-downs" and Contains("razorfen-downs",6521), "Malcin belongs to Downs")
    assert(DQT.quests[95647].prerequisites[1].relationship == "breadcrumb", "Optional Caitlin lead-in must not lock direct pickup")
    assert(DQT.quests[6563].foreverXp == 1750 and DQT.quests[6563].xpReported, "Outside BFD objective has no fabricated bonus")
    local reports = 0
    for _, quest in pairs(DQT.quests) do if quest.xpReported then reports=reports+1 end end
    assert(reports == 16, "Quest-specific reports only; no inferred multiplier")
    local oldLog, oldFaction = C_QuestLog, UnitFactionGroup
    C_QuestLog = {IsOnQuest=function(id) return id == 98823 or id == 6521 end, ReadyForTurnIn=function(id) return id == 98823 or id == 6521 end, IsQuestFlaggedCompleted=function() return false end}
    UnitFactionGroup = function() return "Horde" end
    local found = {}
    for _, entry in ipairs(DQT:GetGlobalTurnInPriority().quests) do found[entry.questID]=true end
    assert(found[98823] and found[6521], "Ready follow-ups reach global planner")
    C_QuestLog, UnitFactionGroup = oldLog, oldFaction
end
print("Passed beta catalog: available dungeons, Wetlands continuations, distinct reported XP and ready follow-ups")
