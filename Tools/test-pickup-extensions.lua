do
    local oldDB,oldQuests,oldDungeon=DQT.db,DQT.quests,DQT.dungeons["zul-farrak"]
    local oldState,oldComplete,oldContext=DQT.GetQuestState,DQT.IsQuestComplete,DQT.GetPlayerContext
    local oldMap,oldZone,oldWorld=C_Map,GetRealZoneText,WorldMapFrame
    local maps=DQT.PickupMap
    local oldPlan,oldKey,oldFocus=maps.plan,maps.key,maps.focusKey
    local oldOpen=maps.OpenStop
    DQT.db={pickups={},filters={ignoreGrayChecklist=true},display={}}
    local context={level=60,faction="Horde",class="WARRIOR",race="Orc"}
    DQT.GetPlayerContext=function() return context end
    local states={}
    DQT.GetQuestState=function(_,id) return states[id] or "missing","Test" end
    DQT.IsQuestComplete=function(_,id) return states[id]=="completed" end
    GetRealZoneText=function() return "Test Zone" end
    C_Map={GetBestMapForUnit=function() return 10 end,
        GetMapInfo=function(id) return (id==10 or id==11) and {name="Test Zone",mapID=id,mapType=3} end,
        GetPlayerMapPosition=function() return {GetXY=function() return 0.95,0.5 end} end}
    for key in pairs(DQT.dungeons) do
        assert(DQT.pickupRouteDungeons[key] and DQT:GetDungeonPickupRoute(key),"Pickup coverage: "..key)
    end
    DQT.quests={}
    local dungeon={name="Zul'Farrak",quests={},provisionalData=true,
        entrance={name="Test entrance",zone="Test Zone",mapID=10,coordinates="5, 50",source="https://example.test/entrance"}}
    DQT.dungeons["zul-farrak"]=dungeon
    local function Quest(id,x)
        local q={name="Quest "..id,questLevel=60,minLevel=1,prerequisites={},
            pickup={name="Giver "..id,zone="Test Zone",coordinates=x..", 50",mapID=10},
            turnIn={name="Return "..id,zone="Test Zone",coordinates=x..", 50",mapID=10}}
        DQT.quests[id]=q; dungeon.quests[#dungeon.quests+1]=id
        return q
    end
    Quest(800001,10); Quest(800002,50); Quest(800003,90)
    DQT.db.pickups.finishAtEntrance=true
    local plan=DQT:GetDungeonPickupRoute("zul-farrak")
    assert(plan.stops[1].x==90 and plan.stops[3].x==10 and plan.destination.x==5,"Exact same-map origin and endpoint produce minimum line route")
    assert(plan.startReason:find("map position",1,true),"Position-based start is explicit")
    local pins=maps:GetPins(plan,10)
    assert(#pins==4 and pins[4].entrance,"Entrance has its own pin")
    local oldPosition=C_Map.GetPlayerMapPosition
    C_Map.GetPlayerMapPosition=function() error("Unavailable position") end
    assert(not maps:GetPlayerPosition() and DQT:GetDungeonPickupRoute("zul-farrak").stops[1],"Throwing position API falls back to recorded stops")
    C_Map.GetPlayerMapPosition=oldPosition
    C_Map.GetPlayerMapPosition=function() return {GetXY=function() return 0/0,0.5 end} end
    assert(not maps:GetPlayerPosition(),"Invalid player coordinates never enter the planner")
    C_Map.GetPlayerMapPosition=oldPosition
    assert(not maps:ResolveLocation({zone="Test Zone",mapID=999}),"Unknown explicit map never falls through to wrong zone/floor")
    Quest(800004,20).questLevel=1
    Quest(800005,30).classes={"WARRIOR"}
    Quest(800006,40).breadcrumbOnly=true
    local function Has(list,id)
        for _,item in ipairs(list) do
            if item.questID==id then return true end
            for _,entry in ipairs(item.quests or {}) do if entry.questID==id then return true end end
        end
        return false
    end
    DQT.db.pickups.includeGray,DQT.db.pickups.includeClass,DQT.db.pickups.includeBreadcrumbs=false,false,false
    plan=DQT:GetDungeonPickupRoute("zul-farrak")
    assert(not Has(plan.stops,800004) and not Has(plan.stops,800005) and not Has(plan.stops,800006),"Route filters independently exclude gray/class/breadcrumb quests")
    assert(plan.excluded==3 and DQT.db.filters.ignoreGrayChecklist,"Checklist filters not mutated")
    local child=Quest(800007,60)
    child.prerequisites={{questID=800004,relationship="required"}}
    states[800007]="locked"
    plan=DQT:GetDungeonPickupRoute("zul-farrak")
    assert(Has(plan.stops,800004) and Has(plan.blocked,800007),"Required gray preparation overrides optional route exclusions")
    states[800004]="ready"
    plan=DQT:GetDungeonPickupRoute("zul-farrak")
    assert(Has(plan.progress,800004) and not Has(plan.stops,800004),"Ready prerequisite is a turn-in task, not a pickup")
    local turnInPin=false
    for _,pin in ipairs(maps:GetPins(plan,10)) do if pin.turnIn then turnInPin=true end end
    assert(turnInPin,"Ready prerequisite has a distinct turn-in marker")
    states[800004]="active"
    assert(DQT:GetDungeonPickupRoute("zul-farrak").progress[1].state=="active","Active prerequisite keeps its objective task")
    local floor=Quest(800008,75)
    floor.pickup.mapID=11
    plan=DQT:GetDungeonPickupRoute("zul-farrak")
    local onFloor=maps:GetPins(plan,11)
    assert(#onFloor==1 and onFloor[1].stop.quests[1].questID==800008,"Explicit floors isolate pins")
    local alternative=Quest(800009,65)
    alternative.pickup={name="Remote",zone="Other Zone"}
    alternative.pickupAlternatives={{name="Local alternative",zone="Test Zone",mapID=10,coordinates="65, 50",faction="Horde"}}
    plan=DQT:GetDungeonPickupRoute("zul-farrak")
    assert(Has(plan.stops,800009),"Recorded local alternative giver selected")
    for _,stop in ipairs(plan.stops) do
        if stop.quests[1].questID==800009 then assert(stop.location.name=="Local alternative") end
    end
    local inside=Quest(800010,80)
    inside.pickup={name="Inside giver",zone="Dire Maul"}
    assert(Has(DQT:GetDungeonPickupRoute("zul-farrak").inside,800010),"Shared instance-zone names never become outdoor pickups")
    for id=800011,800020 do Quest(id,id-799950) end
    local large,repeatPlan=DQT:GetDungeonPickupRoute("zul-farrak"),DQT:GetDungeonPickupRoute("zul-farrak")
    assert(#large.stops==#repeatPlan.stops and #large.stops>7,"Larger routes use bounded heuristic")
    for i,stop in ipairs(large.stops) do assert(stop.key==repeatPlan.stops[i].key,"Large-route tie breaks are stable") end
    WorldMapFrame=nil
    local opened
    maps.OpenStop=function(_,stop) opened=stop; return true end
    DQT.UI.currentDungeonKey="zul-farrak"
    for _,compact in ipairs({false,true}) do
        DQT.db.display.compact=compact
        DQT.UI:ShowPickups()
        assert(DQT.UI.frame.pickupNext:IsShown() and DQT.UI.frame.pickupReset:IsShown(),"Route tools in both layouts")
        DQT.UI.frame.pickupNext.scripts.OnClick()
        assert(opened and opened.key==DQT.UI.pickupPlan.stops[1].key,"Next-stop focus uses a fresh plan")
        DQT.UI.frame.pickupRefresh.scripts.OnClick()
    end
    DQT.UI.frame.pickupReset.scripts.OnClick()
    assert(DQT:GetOption("pickups.includeGray") and not DQT:GetOption("pickups.finishAtEntrance"),"Route reset restores only route defaults")
    assert(DQT.db.filters.ignoreGrayChecklist,"Route reset retains checklist settings")
    DQT.UI.currentDungeonKey="the-drowned-city"
    DQT.UI:ShowPickups()
    assert(DQT.UI.frame.turnInRows[1].title:GetText()=="No quests recorded yet.","Empty catalogues distinguish unknown coverage from no missing quests")
    DQT.db,DQT.quests,DQT.dungeons["zul-farrak"]=oldDB,oldQuests,oldDungeon
    DQT.GetQuestState,DQT.IsQuestComplete,DQT.GetPlayerContext=oldState,oldComplete,oldContext
    C_Map,GetRealZoneText,WorldMapFrame=oldMap,oldZone,oldWorld
    maps.plan,maps.key,maps.focusKey,maps.OpenStop=oldPlan,oldKey,oldFocus,oldOpen
end
print("Pickup extensions passed: all catalogues, independent filters, exact origin, entrance, maps/floors, alternatives, prerequisite actions and controls.")
