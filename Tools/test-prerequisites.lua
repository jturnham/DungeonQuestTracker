do
    local oldLog, oldHistory, oldLevel = C_QuestLog, IsQuestFlaggedCompleted, UnitLevel
    local done, active = {}, {}
    UnitLevel = function() return 60 end
    IsQuestFlaggedCompleted = function(id) return done[id] or false end
    C_QuestLog = {
        IsQuestFlaggedCompleted=IsQuestFlaggedCompleted,
        IsOnQuest=function(id) return active[id] or false end,
        GetNumQuestLogEntries=function() return 0 end,
    }
    local context = {level=60,faction="Horde",class="PALADIN",race="Scourge"}
    assert(DQT:GetQuestAvailability(DQT.quests[2842],context) == "locked")
    done[2841] = true
    assert(DQT:GetQuestAvailability(DQT.quests[2842],context) == "locked", "Completed Rig Wars is not an active-log prerequisite")
    active[2841] = true
    assert(DQT:GetQuestAvailability(DQT.quests[2842],context) == "available")
    assert(DQT:GetQuestAvailability(DQT.quests[95042],context) == "locked")
    active[95036] = true
    assert(DQT:GetQuestAvailability(DQT.quests[95042],context) == "available")
    local gate = {relationship="required",questID=8960,anyOf={8960,9032}}
    assert(not DQT:IsPrerequisiteSatisfied(gate))
    done[9032] = true
    assert(DQT:IsPrerequisiteSatisfied(gate), "Horde branch alone unlocks a shared return")
    assert(DQT:GetQuestAvailability(DQT.quests[8961],context) == "available")
    local both = {prerequisites={{questID=1,relationship="required"},{questID=2,relationship="required"}}}
    done[1] = true
    assert(DQT:GetQuestAvailability(both,context) == "locked", "Separate required entries remain AND conditions")
    done[2] = true
    assert(DQT:GetQuestAvailability(both,context) == "available")
    assert(DQT:GetQuestAvailability(DQT.quests[3982],context) == "locked", "Gor'shak continuation is required, not a breadcrumb")
    done[3981] = true
    assert(DQT:GetQuestAvailability(DQT.quests[3982],context) == "available")
    assert(DQT.quests[7489].prerequisites[1].relationship == "breadcrumb", "Camp Mojache referral remains optional")
    local encoded = assert(DQT:EncodePartyQuest(8961,DQT.quests[8961]))
    local decoded = assert(DQT:DecodePartyQuest(8961,encoded))
    assert(decoded.prerequisites[1].anyOf[2] == 9032, "Party sync retains OR conditions")
    encoded = assert(DQT:EncodePartyQuest(2842,DQT.quests[2842]))
    decoded = assert(DQT:DecodePartyQuest(2842,encoded))
    assert(decoded.prerequisites[1].state == "active", "Party sync retains active-log gates")
    decoded.prerequisites[1].state = "invalid"
    assert(not DQT:ValidatePartyQuest(2842,decoded))
    C_QuestLog, IsQuestFlaggedCompleted, UnitLevel = oldLog, oldHistory, oldLevel
end
print("Prerequisites passed: required chains, optional referrals, active-log gates, OR/AND branches and bounded party sync.")
