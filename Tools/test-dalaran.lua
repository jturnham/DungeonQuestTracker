do
    local oldLog,oldFaction=C_QuestLog,UnitFactionGroup
    local complete,ready,active={},{},{}
    C_QuestLog={IsQuestFlaggedCompleted=function(id) return complete[id] end,IsOnQuest=function(id) return active[id] or ready[id] end,ReadyForTurnIn=function(id) return ready[id] end}
    UnitFactionGroup=function() return "Horde" end
    local context=DQT:GetPlayerContext(); context.level=28; context.faction="Horde"
    assert(not DQT.quests[556] and not DQT.quests[557],"Unrelated outdoor quests excluded from bundled dungeon catalog")
    local oldDB=DQT.db
    DQT.db={options={}}
    local function GraveState(expected)
        local matches=0
        for _,row in ipairs(DQT:GetDisplayDungeonStatus("city-of-dalaran",context).quests) do
            assert(row.questID~=556 and row.questID~=557,"Unrelated outdoor quests absent from checklist")
            if row.questID==96986 then
                matches=matches+1
                assert(row.state==expected,"Grave Knight checklist state")
            end
        end
        assert(matches==1,"Grave Knight visible once with default filters at level 28")
    end
    GraveState("missing")
    active[96986]=true
    GraveState("active")
    active[96986]=nil
    ready[96986]=true
    GraveState("ready")
    ready[96986]=nil
    complete[96986]=true
    DQT:SetOption("filters.showCompleted",true)
    GraveState("completed")
    complete[96986]=nil
    DQT.db=oldDB
    local function HasPickup(route,id)
        for _,stop in ipairs(route.stops) do
            for _,entry in ipairs(stop.quests) do if entry.questID==id then return true end end
        end
        return false
    end
    local route=DQT:GetDungeonPickupRoute("city-of-dalaran",nil,context)
    assert(HasPickup(route,96986) and HasPickup(route,96988),"Horde external pickups routed at level 28")
    local inside=false
    for _,entry in ipairs(route.inside) do if entry.questID==96987 then inside=true end end
    assert(inside,"Sewer pickup separated from external preparation")
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
    assert(DQT:GetQuestAvailability(DQT.quests[97287],context)=="locked","Horde continuation requires dungeon quest")
    complete[96984]=true
    assert(DQT:GetQuestAvailability(DQT.quests[97287],context)=="available","Horde continuation unlocked")
    for _,id in ipairs({96986,96988,96987}) do
        assert(DQT:GetQuestAvailability(DQT.quests[id],context)=="available","Independent Horde dungeon pickups do not require a personal key")
        ready[id]=true
    end
    ready[97287]=true
    local hordeReady={}
    for _,entry in ipairs(DQT:GetGlobalTurnInPriority().quests) do hordeReady[entry.questID]=true end
    for _,id in ipairs({96986,96988,96987,97287}) do assert(hordeReady[id],"New Horde ready turn-in tracked") end
    context.faction="Alliance"
    assert(DQT:GetQuestAvailability(DQT.quests[96984],context)=="unavailable","Same-title Horde version excluded for Alliance")
    assert(DQT:GetQuestAvailability(DQT.quests[92458],context)=="available","Alliance optional referral does not block direct pickup")
    assert(DQT:GetQuestAvailability(DQT.quests[92459],context)=="locked","Alliance continuation requires dungeon quest")
    complete[92458]=true
    assert(DQT:GetQuestAvailability(DQT.quests[92459],context)=="available","Alliance continuation unlocked")
    for _,id in ipairs({92489,92456,92457}) do
        assert(DQT:GetQuestAvailability(DQT.quests[id],context)=="available","Independent Alliance dungeon pickups available at 28")
    end
    UnitFactionGroup=function() return "Alliance" end
    route=DQT:GetDungeonPickupRoute("city-of-dalaran",nil,context)
    assert(HasPickup(route,92489) and HasPickup(route,92456) and HasPickup(route,92457),"Alliance external pickups routed at level 28")
    complete[92458]=nil
    ready[92458]=true
    for _,id in ipairs({92489,92456,92457,92459}) do ready[id]=true end
    local found=false
    local allianceReady={}
    for _,entry in ipairs(DQT:GetGlobalTurnInPriority().quests) do
        allianceReady[entry.questID]=true
        if entry.questID==92458 then found=true end
    end
    for _,id in ipairs({92489,92456,92457,92459}) do assert(allianceReady[id],"New Alliance ready turn-in tracked") end
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
