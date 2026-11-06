do
    local t=DQT.Travel
    local old={db=DQT.db,build=GetBuildInfo,guid=UnitGUID,time=GetTime,taxi=UnitOnTaxi,zone=GetRealZoneText,dead=UnitIsDeadOrGhost,
        nodes=t.nodes,ids=t.ids,adj=t.adjacency,selection=t.taxiSelection,timer=C_Timer,position=DQT.PickupMap.GetPlayerPosition}
    local now,onTaxi,zone=100,false,"A"
    GetBuildInfo=function() return "1.60.1","70790" end
    UnitGUID=function() return "Timing A" end
    GetTime=function() return now end
    UnitOnTaxi=function() return onTaxi end
    UnitIsDeadOrGhost=function() return false end
    GetRealZoneText=function() return zone end
    DQT.db={travel={recordFlightTimes=true,preferMeasuredTime=true,includeFutureSteps=true}}
    t.nodes={a={id="a",name="A",zone="A",faction="Horde"},b={id="b",name="B",zone="B",faction="Horde"},c={id="c",name="C",zone="C",faction="Horde"}}
    t.ids={"a","b","c"}
    local ab={from="a",to="b",fare=10,mode="flight"}
    local bc={from="b",to="c",fare=10,mode="flight"}
    local ac={from="a",to="c",fare=1,mode="flight"}
    t.adjacency={a={ab,ac},b={bc},c={}}
    local records=t:TimingRecords()
    records['a>b']={count=1,total=100,minimum=100,maximum=100}
    records['b>c']={count=1,total=100,minimum=100,maximum=100}
    records['a>c']={count=1,total=500,minimum=500,maximum=500}
    local function Context() return {faction="Horde",class="WARRIOR",known={a=true,b=true,c=true},flights=true,transports=true,preferTime=true,timingRecords=t:TimingRecords(),cache={}} end
    local route=assert(t:Route("A","C",Context()))
    assert(route.timed and route.hops==2 and route.seconds==200 and route.fare==20,"Timing and fares are distinct; fastest measured path can have more legs")
    assert(route.minimumSeconds==0,"A measured average is not a guaranteed future minimum")
    assert(t:Describe(route):find("Walking and waiting",1,true),"Timing is explicitly partial")
    records['a>b']=nil; records['a>c']=nil
    route=assert(t:Route("A","C",Context()))
    assert(route.hops==1 and route.timingFallback and not route.seconds,"Missing times fall back without hiding the connection")
    records['a>c']={count=1,total=0/0,minimum=5,maximum=10}
    assert(not t:EdgeTiming(ac),"Malformed saved times rejected")
    records['a>c']={count=1.5,total=150,minimum=100,maximum=100}
    assert(not t:EdgeTiming(ac),"Fractional sample counts rejected")
    records['a>c']=nil
    t.taxiSelection={from="a",targets={[2]="b"},direct={[2]=true},time=now}
    t:StartFlight(2); assert(t.pendingFlight)
    onTaxi=true; now=101; t:PollFlight()
    for value=102,200 do now=value;t:PollFlight() end
    onTaxi=false; zone="B"; now=201; t:PollFlight()
    assert(records['a>b'].total==100 and not t.pendingFlight and not t.events.scripts.OnUpdate,"Measure only in-flight elapsed time; remove idle polling")
    t.taxiSelection={from="a",targets={[2]="b"},direct={[2]=true},time=now}; t:StartFlight(2)
    onTaxi=true; now=202; t:PollFlight()
    for value=203,301 do now=value;t:PollFlight() end
    onTaxi=false; zone="C"; now=302; t:PollFlight()
    assert(records['a>b'].count==1,"Interrupted/wrong-destination flights discarded")
    t.taxiSelection={from="a",targets={[2]="b"},direct={[2]=true},time=now};t:StartFlight(2)
    onTaxi=true;now=303;t:PollFlight();now=310;t:PollFlight()
    assert(not t.pendingFlight and records['a>b'].count==1,"Long polling stalls must not inflate flight times")
    onTaxi=false
    GetBuildInfo=function() return "1.60.1","70791" end
    assert(not t:EdgeTiming(ab),"Measurements are scoped to the client build")
    GetBuildInfo=old.build
    GetBuildInfo=function() return "1.60.1","70790" end
    local context={hearthUsed=true,hearthReadyAt=3600,provenElapsed=0,hearth={name="B",zone="B"},faction="Horde",known={},cache={}}
    t:Consume({seconds=8000,minimumSeconds=0},context)
    assert(not t:Route("C","B",context),"Observed/estimated time cannot grant a second hearth")
    t:Consume({minimumSeconds=3599},context)
    assert(not t:Route("C","B",context),"Do not round the hour cooldown down")
    t:Consume({minimumSeconds=1},context)
    assert(t:Route("C","B",context).hearth,"Second hearth allowed only after proven minimum elapsed time")
    local timed=Context(); timed.preferTime=false; ac.minimumSeconds=3600; ac.minimumDurationSource="https://example.com/fixed-duration"; ac.minimumDurationConfirmed=true
    route=t:Route("A","C",timed)
    assert(route.minimumSeconds==3600,"Explicit sourced fixed minimum is distinct from observations")
    ac.minimumDurationConfirmed=nil; assert(select(2,t:EdgeTiming(ac))==0,"Unconfirmed floor is never used")
    local callbacks={}; C_Timer={After=function(delay,fn) callbacks[#callbacks+1]={delay,fn} end}
    t.hearthRefreshDeadline=nil; t:ScheduleHearthRefresh(100); t:ScheduleHearthRefresh(100)
    assert(#callbacks==1 and callbacks[1][1]>100,"Cooldown refresh scheduled once without idle polling")
    zone="A"; DQT.PickupMap.GetPlayerPosition=function() return {x=12.5,y=30,mapID=123} end
    t:ObserveApproach("a")
    assert(t:Approach("a").coordinates=="12.50, 30.00","Record same-map player approach without inventing a flight-master coordinate")
    assert(#t:TransportStops({edges={ab}})==1,"Only positioned recorded approaches produce markers")
    t:ClearTimings(); assert(not next(records),"Measurements can be cleared without clearing flight knowledge")
    t.taxiSelection={from="a",targets={[2]="b"},direct={},time=now}; t:StartFlight(2)
    assert(not t.pendingFlight,"A selected multi-leg or unclassified taxi route cannot be recorded as one edge")
    DQT.db,GetBuildInfo,UnitGUID,GetTime,UnitOnTaxi,GetRealZoneText,UnitIsDeadOrGhost,C_Timer=old.db,old.build,old.guid,old.time,old.taxi,old.zone,old.dead,old.timer
    DQT.PickupMap.GetPlayerPosition=old.position
    t.nodes,t.ids,t.adjacency,t.taxiSelection=old.nodes,old.ids,old.adj,old.selection
    t.hearthRefreshDeadline=nil
end

do
    local oldDB,oldState,oldQuests=DQT.db,DQT.GetQuestState,DQT.quests
    DQT.db={travel={includeFutureSteps=true}}
    DQT.quests={
        [1]={name="Preparation",objectives="Do the task",faction="Horde",turnIn={name="NPC",zone="Zone"},routeObjectives={{name="Known objective",zone="Zone",coordinates="10, 20",sourceReviewed=true,source="https://example.com/quest=1"}}},
        [2]={name="Later pickup",faction="Horde",pickup={name="Next NPC",zone="Other"},turnIn={name="Next NPC",zone="Other"},prerequisites={{questID=1,relationship="required"}}},
        [3]={name="Active-log gate",faction="Horde",prerequisites={{questID=1,relationship="required",state="active"}}},
    }
    DQT.GetQuestState=function(_,id) return id==1 and "active" or "locked" end
    local plan={progress={{questID=1,state="active"}},blocked={{questID=2}}}
    local future=DQT.Travel:FutureSteps(plan,{faction="Horde",class="WARRIOR"})
    assert(future[1].kind=="objective" and future[1].location.name=="Known objective" and future[2].kind=="turnIn" and future[3].kind=="pickup","Objective, return and future pickup follow dependencies")
    for _,step in ipairs(future) do assert(step.hypothetical and not step.stop,"Future previews are not actionable/map stops") end
    assert(not plan.stops and not plan.readyReturns,"Preview never mutates immediate plan or completion state")
    DQT.GetQuestState=function() return "locked" end
    DQT.quests[1].prerequisites={{questID=2,relationship="required"}}
    assert(#DQT.Travel:FutureSteps(plan,{faction="Horde",class="WARRIOR"})<20,"Cycles terminate without simulated completion")
    DQT.db.travel.includeFutureSteps=false; assert(#DQT.Travel:FutureSteps(plan,{})==0,"Future previews are opt-in")
    DQT.db,DQT.GetQuestState,DQT.quests=oldDB,oldState,oldQuests
end
print("Travel planning passed: build-scoped measured routes, safe fallback, flight observations, approach positions, conditional chains and conservative hearth cooldowns")
