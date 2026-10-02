do
    local oldLog, oldHistory, oldFaction, oldLevel = C_QuestLog, IsQuestFlaggedCompleted, UnitFactionGroup, UnitLevel
    local oldTitle, oldCount = GetQuestLogTitle, GetNumQuestLogEntries
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
    -- Legacy logs with IDs are safe; ambiguous title-only entries cannot identify a chain step.
    C_QuestLog = nil
    GetNumQuestLogEntries = function() return 1 end
    GetQuestLogTitle = function() return "Hidden Enemies", 16, nil, false, nil, 1, nil, 5730 end
    assert(DQT:IsQuestReadyForTurnIn(5730, "Hidden Enemies"), "Legacy exact ID ready")
    assert(not DQT:IsQuestReadyForTurnIn(5729, "Hidden Enemies"), "Legacy different ID not ready")
    GetQuestLogTitle = function() return "Hidden Enemies", 16, nil, false, nil, 1 end
    assert(not DQT:IsQuestActive(5729, "Hidden Enemies"), "Ambiguous title-only chain not guessed")
    C_QuestLog, IsQuestFlaggedCompleted, UnitFactionGroup, UnitLevel = oldLog, oldHistory, oldFaction, oldLevel
    GetQuestLogTitle, GetNumQuestLogEntries = oldTitle, oldCount
end
print("Passed follow-ups: required chains, faction branches, completed/ready states, dungeon planner association and same-name ID isolation.")
