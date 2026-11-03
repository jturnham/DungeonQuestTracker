do
    local travel=DQT.Travel
    local old={db=DQT.db,guid=UnitGUID,bind=GetBindLocation,zone=GetRealZoneText,time=GetTime,item=C_Item,container=C_Container}
    local character,bind,zone,count,start,duration,enabled="Hearth A","Unknown Inn","Hillsbrad Foothills",1,0,0,1
    DQT.db={travel={useHearthstone=true,useFlights=false,useTransports=false}}
    UnitGUID=function() return character end
    GetBindLocation=function() return bind end
    GetRealZoneText=function() return zone end
    GetTime=function() return 100 end
    C_Item={GetItemCount=function(_,bank) assert(bank==false); return count end}
    C_Container={GetItemCooldown=function(id) assert(id==6948); return start,duration,enabled end}
    local function Context() return travel:Context("Horde","WARRIOR") end
    assert(not Context().hearth,"An unknown inn must never be guessed")
    assert(travel:RecordHearth())
    assert(Context().hearth.zone==zone,"Explicit existing bind confirmation")
    character="Hearth B"
    assert(not Context().hearth,"Bind mapping must be character-specific")
    character="Hearth A"
    bind="Another Inn"
    assert(not Context().hearth,"Rebinding invalidates the previous label")
    bind="Unknown Inn"
    count=0; assert(not Context().hearth,"Bank/missing item cannot be used")
    count=1; start=50; duration=3600
    assert(not Context().hearth,"Do not wait out the hour cooldown speculatively")
    start=0; duration=0; enabled=0
    assert(not Context().hearth,"Disabled cooldown cannot be used")
    enabled=1; duration=0/0
    assert(not Context().hearth,"Malformed cooldown cannot be used")
    duration=0
    local context=Context()
    local route=assert(travel:Route("Undercity",zone,context))
    assert(route.hearth and route.hops==1 and route.fare==0)
    assert(travel:Describe(route):find("hour cooldown",1,true))
    assert(not travel:Route(zone,zone,context),"Do not waste hearth within its zone")
    local function Stop(value) return {location={zone=value}} end
    local plan={readyReturns={},progress={},stops={Stop(zone),Stop("Undercity"),Stop(zone)},destination=Stop("Undercity")}
    local itinerary=travel:BuildItinerary(plan,"Undercity",context)
    local uses=0
    for _,step in ipairs(itinerary) do if step.route and step.route.hearth then uses=uses+1 end end
    assert(uses==1,"One consumable across the full itinerary, not one per leg")
    assert(not context.hearthUsed,"Rebuilding must not consume the real capability")
    plan.readyReturns={Stop(zone)}
    plan.stops={Stop("Undercity"),Stop(zone)}
    uses=0
    for _,step in ipairs(travel:BuildItinerary(plan,"Undercity",context)) do
        if step.route and step.route.hearth then uses=uses+1 end
    end
    assert(uses==1,"Ready prerequisite returns share the same hearth reservation as pickups")
    local ordered=travel:OrderZones({zone,"Undercity"},nil,"Durotar",travel:ForkContext(context))
    assert(ordered[1]==zone and not context.hearthUsed,"Speculative ordering has its own consumed state")
    start=90; duration=3600
    assert(not Context().hearth,"Actual use is reflected on refresh")
    start=0; duration=0
    DQT.db.travel.useHearthstone=false
    assert(not Context().hearth,"Option disables planning")
    DQT.db.travel.useHearthstone=true
    C_Container.GetItemCooldown=function() error("unsupported") end
    assert(not Context().hearth,"Unsupported APIs must fail closed")
    DQT.db,UnitGUID,GetBindLocation,GetRealZoneText,GetTime,C_Item,C_Container=old.db,old.guid,old.bind,old.zone,old.time,old.item,old.container
    print("Hearth routing: optional bind, ownership, cooldown, character isolation and single-use itinerary passed")
end
