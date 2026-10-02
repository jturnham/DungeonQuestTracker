do
    local oldLog, oldHistory, oldFaction, oldLevel = C_QuestLog, IsQuestFlaggedCompleted, UnitFactionGroup, UnitLevel
    local oldTitle, oldCount, oldClass, oldRace = GetQuestLogTitle, GetNumQuestLogEntries, UnitClass, UnitRace
    local history, activeID, faction = {}, nil, "Horde"
    UnitFactionGroup = function() return faction end
    UnitLevel = function() return 18 end
    IsQuestFlaggedCompleted = function(id) return history[id] or false end
    C_QuestLog = {
        IsQuestFlaggedCompleted = IsQuestFlaggedCompleted,
        IsOnQuest = function(id) return id == activeID end,
        ReadyForTurnIn = function(id) return id == activeID end,
        GetNumQuestLogEntries = function() return activeID and 1 or 0 end,
        GetInfo = function() return {questID=activeID,title="Hidden Enemies",isComplete=true} end,
    }
    GetQuestLogTitle, GetNumQuestLogEntries = nil, nil
    assert(DQT:GetQuestState(5729, DQT.quests[5729]) == "locked", "Follow-up requires boss quest turn-in")
    history[5728] = true
    assert(DQT:GetQuestState(5729, DQT.quests[5729]) == "missing", "First follow-up unlocked")
    assert(DQT:GetQuestState(5730, DQT.quests[5730]) == "locked", "Final report requires Neeru step")
    activeID = 5729
    assert(DQT:GetQuestState(5729, DQT.quests[5729]) == "ready", "Follow-up ready")
    assert(DQT:GetQuestState(5730, DQT.quests[5730]) == "locked", "Same name cannot mark final step ready")
    local plan = DQT:GetGlobalTurnInPriority()
    assert(#plan.quests == 1 and plan.quests[1].questID == 5729 and plan.quests[1].dungeonKey == "ragefire-chasm", "Follow-up tied to originating dungeon in planner")
    history[5729], activeID = true, 5730
    assert(DQT:GetQuestState(5729, DQT.quests[5729]) == "completed", "Completed follow-up retained")
    assert(DQT:GetQuestState(5730, DQT.quests[5730]) == "ready", "Final return ready")
    history[5730], activeID = true, nil
    assert(DQT:GetQuestState(5730, DQT.quests[5730]) == "completed", "Final completion tracked")
    history[6981] = true
    assert(DQT:GetQuestState(3369, DQT.quests[3369]) == "missing", "Horde WC follow-up unlocked")
    assert(DQT:GetQuestAvailability(DQT.quests[3370]) == "unavailable", "Alliance branch unavailable to Horde")
    faction = "Alliance"
    assert(DQT:GetQuestState(3370, DQT.quests[3370]) == "missing", "Alliance WC follow-up unlocked")
    assert(DQT:GetQuestAvailability(DQT.quests[3369]) == "unavailable", "Horde branch unavailable to Alliance")
    -- Every catalogued continuation must remain ready in the global planner,
    -- even when its dungeon or checklist row is hidden by display filters.
    local oldOptions = DQT.db
    DQT.db = { filters = { ignoreGrayTurnIns = false, hideGrayDungeons = true, onlyMissing = true } }
    UnitLevel = function() return 60 end
    for id, quest in pairs(DQT.quests) do
        if quest.followUpOf then
            faction = quest.faction or "Horde"
            UnitClass = function() return "Test class", (quest.classes and quest.classes[1]) or "WARRIOR" end
            UnitRace = function() return "Test race", (quest.races and quest.races[1]) or "Human" end
            activeID, history = id, {}
            C_QuestLog.GetInfo = function() return {questID=id,title=quest.name,isComplete=true} end
            local readyPlan = DQT:GetGlobalTurnInPriority()
            local matches = 0
            for _, item in ipairs(readyPlan.quests) do
                if item.questID == id then matches = matches + 1 end
            end
            assert(matches == 1, "Each ready follow-up appears exactly once: " .. id)
            assert(DQT:GetQuestState(quest.followUpOf, DQT.quests[quest.followUpOf]) ~= "ready", "Same-name predecessor cannot inherit readiness: " .. id)
            activeID, history[id] = nil, true
            assert(DQT:GetQuestState(id, quest) == "completed", "Follow-up completion tracked: " .. id)
        end
    end
    faction, activeID, history = "Horde", 97291, {}
    C_QuestLog.GetInfo = function() return {questID=activeID,title="Unending Torment",isComplete=true} end
    local tormentPlan = DQT:GetGlobalTurnInPriority()
    assert(#tormentPlan.quests == 1 and tormentPlan.quests[1].questID == 97291 and tormentPlan.quests[1].dungeonKey == "ruins-of-lordaeron", "Unending Torment continuation belongs to Ruins of Lordaeron")
    C_QuestLog.ReadyForTurnIn = function() return false end
    C_QuestLog.GetInfo = function() return {questID=activeID,title="Unending Torment",isComplete=false} end
    assert(DQT:GetQuestState(97291, DQT.quests[97291]) == "active", "Incomplete continuation stays active")
    assert(#DQT:GetGlobalTurnInPriority().quests == 0, "Incomplete continuation is not offered for turn-in")
    assert(DQT.quests[6522].pickupType == "drop" and DQT.quests[6521].followUpOf == 6522, "RFK scroll and Malcin steps have distinct correct IDs")
    for _, key in ipairs({"deadmines", "shadowfang-keep", "blackfathom-deeps"}) do
        local found = 0
        for _, id in ipairs(DQT.dungeons[key].quests) do if id == 1806 then found = found + 1 end end
        assert(found == 1, "Shared Paladin reward inherits dungeon membership without duplication: " .. key)
    end
    for _, id in ipairs({97289,97290,97291,97292}) do
        local xp, source = DQT:GetQuestRewardXP(DQT.quests[id])
        assert(xp == 0 and source == "unknown", "Do not invent follow-up rewards: " .. id)
    end
    DQT.db = oldOptions
    -- Legacy logs with IDs are safe; ambiguous title-only entries cannot identify a chain step.
    C_QuestLog = nil
    GetNumQuestLogEntries = function() return 1 end
    GetQuestLogTitle = function() return "Hidden Enemies", 16, nil, false, nil, 1, nil, 5730 end
    assert(DQT:IsQuestReadyForTurnIn(5730, "Hidden Enemies"), "Legacy exact ID ready")
    assert(not DQT:IsQuestReadyForTurnIn(5729, "Hidden Enemies"), "Legacy different ID not ready")
    GetQuestLogTitle = function() return "Hidden Enemies", 16, nil, false, nil, 1 end
    assert(not DQT:IsQuestActive(5729, "Hidden Enemies"), "Ambiguous title-only chain not guessed")
    C_QuestLog, IsQuestFlaggedCompleted, UnitFactionGroup, UnitLevel = oldLog, oldHistory, oldFaction, oldLevel
    GetQuestLogTitle, GetNumQuestLogEntries, UnitClass, UnitRace = oldTitle, oldCount, oldClass, oldRace
end
print("Passed follow-ups: all catalogued continuations, active/completed/ready states, global deduplication, hidden dungeon independence, shared origins, Unending Torment ID isolation and unknown XP.")
