do
    assert(DQT.quests[92432].foreverXp==650 and DQT.quests[92459].foreverXp==270,"Exact-ID published Dalaran referral rewards")
    assert(DQT.quests[92432].pickup.name=="Emissary Jacques" and DQT.quests[92432].pickup.coordinates=="48.3, 60.0","Known referral pickup is no longer unknown")
    for _,id in ipairs({96984,92458,96986,96988,96987,92489,92456,92457}) do
        assert(DQT.quests[id].detailsSourceReviewed and not DQT.quests[id].verifiedForever,"Source-reviewed details do not claim a local client observation")
    end
    assert(DQT.quests[97287].verification.conflict,"Keep unresolved Horde follow-up access warning")
    assert(DQT.quests[95697].pickup.name=="Borstan" and DQT.quests[98823].pickup.name=="Bashana Runetotem","Reviewed contact names have no stale beta warning")
    local oldComplete,oldActive,oldContext=DQT.IsQuestComplete,DQT.IsQuestActive,DQT.GetPlayerContext
    local oldState=DQT.GetQuestState
    local done,active,ready={},{},{}
    local player={level=20,faction="Horde",class="WARRIOR",race="Orc"}
    DQT.GetPlayerContext=function() return player end
    DQT.IsQuestComplete=function(_,id) return done[id] or false end
    DQT.IsQuestActive=function(_,id) return active[id] or ready[id] or false end
    DQT.GetQuestState=function(self,id,quest,context)
        if done[id] then return "completed" end
        if ready[id] then return "ready" end
        if active[id] then return "active" end
        local availability,reason=self:GetQuestAvailability(quest,context or player)
        return availability=="available" and "missing" or availability,reason
    end
    assert(DQT:GetQuestAvailability(DQT.quests[92422],player)=="locked")
    assert(DQT:GetQuestAvailability(DQT.quests[356],player)=="available")
    assert(DQT:GetQuestAvailability(DQT.quests[99156],player)=="locked")
    done[356]=true
    assert(DQT:GetQuestAvailability(DQT.quests[99156],player)=="available")
    assert(DQT:GetQuestAvailability(DQT.quests[92422],player)=="locked","The first patrol alone does not unlock Rath'mael")
    active[99156]=true
    assert(DQT:GetQuestAvailability(DQT.quests[92422],player)=="locked","Accepting Riptear is not completing it")
    done[99156]=true
    assert(DQT:GetQuestAvailability(DQT.quests[92422],player)=="available")
    assert(DQT:GetQuestAvailability(DQT.quests[95216],player)=="locked")
    done[367],done[368],done[369]=true,true,true
    assert(DQT:GetQuestAvailability(DQT.quests[95216],player)=="locked","A New Plague is not A Recipe For Death")
    done[447]=true
    assert(DQT:GetQuestAvailability(DQT.quests[450],player)=="available")
    assert(DQT:GetQuestAvailability(DQT.quests[451],player)=="locked")
    done[450]=true
    assert(DQT:GetQuestAvailability(DQT.quests[451],player)=="available")
    assert(DQT:GetQuestAvailability(DQT.quests[95216],player)=="locked")
    done[451]=true
    assert(DQT:GetQuestAvailability(DQT.quests[95216],player)=="available")
    done={}; active={}
    local route=DQT:GetDungeonPickupRoute("ruins-of-lordaeron",nil,player)
    local function Has(list,id)
        for _,entry in ipairs(list) do
            if entry.questID==id then return true end
            for _,quest in ipairs(entry.quests or {}) do if quest.questID==id then return true end end
        end
    end
    assert(Has(route.stops,356) and Has(route.stops,447),"Routes must offer the first available preparation steps")
    assert(not Has(route.stops,92422) and not Has(route.stops,95216),"Locked dungeon quests cannot be immediate pickups")
    ready[99156]=true
    route=DQT:GetDungeonPickupRoute("ruins-of-lordaeron",nil,player)
    assert(Has(route.readyReturns,99156),"Ready preparation gets a real return stop")
    assert(DQT.quests[356].minLevel==6 and DQT.quests[447].minLevel==9,"Dungeon minimum must not be imposed on outdoor preparation")
    for _,id in ipairs({356,99156,447,450,451}) do
        local xp,source=DQT:GetQuestRewardXP(DQT.quests[id])
        assert(xp==0 and source=="unknown","Do not invent preparation XP")
    end
    assert(DQT.quests[92422].followUpOf==99156 and DQT.quests[95216].followUpOf==451,"Chains remain visually associated")
    player.faction="Alliance"
    assert(DQT:GetQuestAvailability(DQT.quests[99156],player)=="unavailable")
    DQT.IsQuestComplete,DQT.IsQuestActive,DQT.GetPlayerContext,DQT.GetQuestState=oldComplete,oldActive,oldContext,oldState
    print("Launch review passed: both patrol steps, complete Recipe chain, duplicate-name isolation, real preparation routes/returns, faction/level gates and unknown XP")
end
