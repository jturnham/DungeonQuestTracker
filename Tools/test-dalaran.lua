do
    local oldLog,oldFaction=C_QuestLog,UnitFactionGroup
    local complete,ready={},{}
    C_QuestLog={IsQuestFlaggedCompleted=function(id) return complete[id] end,IsOnQuest=function(id) return ready[id] end,ReadyForTurnIn=function(id) return ready[id] end}
    UnitFactionGroup=function() return "Horde" end
    local context=DQT:GetPlayerContext(); context.level=28; context.faction="Horde"
    for _,id in ipairs(DQT.dungeons["city-of-dalaran"].quests) do
        local quest=DQT:GetQuest(id)
        assert(quest.awaitingFinalVerification and quest.confidence=="needsReview" and not quest.verifiedForever,"Explicit provisional attunement")
        assert(DQT:GetQuestRewardXP(quest)==0 and quest.questLevelUnverified,"No invented XP or color filtering")
    end
    assert(DQT:GetQuestAvailability(DQT.quests[92434],context)=="locked","Horde preparation enforced")
    complete[544],complete[545],complete[93680]=true,true,true
    assert(DQT:GetQuestAvailability(DQT.quests[92434],context)=="available","Bel'varil companion quests do not gate attunement")
    complete[92434]=true
    assert(DQT:GetQuestAvailability(DQT.quests[96984],context)=="available","Horde key objective unlocked")
    context.faction="Alliance"
    assert(DQT:GetQuestAvailability(DQT.quests[96984],context)=="unavailable","Same-title Horde version excluded for Alliance")
    assert(DQT:GetQuestAvailability(DQT.quests[92458],context)=="available","Alliance optional referral does not block direct pickup")
    UnitFactionGroup=function() return "Alliance" end
    ready[92458]=true
    local found=false
    for _,entry in ipairs(DQT:GetGlobalTurnInPriority().quests) do if entry.questID==92458 then found=true end end
    assert(found,"Ready Dalaran objective included in global turn-ins")
    DQT.UI:ShowDungeon(DQT:GetDungeonQuestStatus("city-of-dalaran"))
    local labelled=false
    for _,row in ipairs(DQT.UI.frame.rows) do
        if row.tooltipText and row.tooltipText:find("awaiting final verification",1,true) then labelled=true end
    end
    assert(labelled,"Attunement verification caveat visible in quest tooltips")
    C_QuestLog,UnitFactionGroup=oldLog,oldFaction
    print("Dalaran provisional attunement: faction IDs, branches, gates, unknown XP and ready turn-ins passed.")
end
