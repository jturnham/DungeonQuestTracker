do
    local maps=DQT.PickupMap
    local oldMap,oldWorld,oldBase,oldPin,oldMixins,oldOpen,oldCombat=C_Map,WorldMapFrame,MapCanvasDataProviderMixin,MapCanvasPinMixin,CreateFromMixins,OpenWorldMap,InCombatLockdown
    local oldProvider,oldCache=maps.provider,maps.cache
    local oldRoot,oldNames,oldPlan=maps.root,maps.mapNames,maps.plan
    maps.provider=nil; maps.cache={}; maps.root=nil; maps.mapNames=nil; maps.plan=nil
    local hierarchyCalls=0
    local children={{name="Ironforge",mapID=87,mapType=4},{name="Stormwind",mapID=84,mapType=4},{name="Badlands",mapID=1418,mapType=3},
        {name="Duplicate",mapID=1,mapType=3},{name="Duplicate",mapID=2,mapType=3}}
    C_Map={GetBestMapForUnit=function() return 87 end,GetMapInfo=function(id) return {parentMapID=id==87 and 947 or 0} end,
        GetMapChildrenInfo=function(id) assert(id==947); hierarchyCalls=hierarchyCalls+1; return children end}
    assert(maps:ResolveMap("Ironforge")==87 and maps:ResolveMap("Stormwind City")==84,"Client map discovery and city alias")
    assert(not maps:ResolveMap("Duplicate") and not maps:ResolveMap("Missing"),"Ambiguous/unknown maps omitted")
    for i=1,10 do maps:ResolveMap("Missing"); maps:ResolveMap("Ironforge") end
    assert(hierarchyCalls==1,"Map hierarchy indexed once, including negative lookups")
    local indexedRoot=maps.root
    maps.root=nil
    assert(maps:ResolveMap("Ironforge")==87 and hierarchyCalls==2 and maps.root==indexedRoot,"Changed root invalidates map index")
    local savedChildren=children
    children={}; maps.root=nil
    assert(maps:ResolveMap("Ironforge")==87,"Unavailable hierarchy preserves known locations")
    children=savedChildren
    assert(maps:ResolveMap("Ironforge")==87,"Map discovery retries after startup data becomes available")
    local plan={key="gnomeregan",automaticStart=true,startZone="Ironforge",stops={
        {x=50,y=25,location={zone="Ironforge",name="Test"},quests={}},
        {location={zone="Ironforge",name="No coordinates"},quests={}},
        {x=10,y=20,location={zone="Badlands",name="Other"},quests={}},
        {x=101,y=20,location={zone="Ironforge",name="Invalid"},quests={}}}}
    local pins=maps:GetPins(plan,87)
    assert(#pins==1 and pins[1].index==1 and pins[1].x==0.5 and pins[1].y==0.25,"Normalized coordinates, numbering, map isolation")
    assert(#maps:GetPins(plan)==2,"Unpositioned/invalid stops excluded")
    local sharedPlan={stops={plan.stops[1],
        {x=50,y=25,location={zone="Ironforge",name="Second giver"},quests={{quest={name="Second quest"}}}},
        {x=50.3,y=25.2,location={zone="Ironforge",name="Nearby giver"},quests={{preparation=true,quest={name="Preparation quest"}}}},
        {x=51,y=25,location={zone="Ironforge",name="Separate giver"},quests={}},
        {x=50,y=25,location={zone="Badlands",name="Other zone"},quests={}}}}
    local shared=maps:GetPins(sharedPlan)
    assert(#shared==3 and #shared[1].stops==3 and shared[1].stops[2].index==2,"Co-located and overlapping stops share a pin; separate locations/maps do not")
    local oldTooltip=GameTooltip
    local lines={}
    GameTooltip={SetOwner=function() end,SetText=function(_,text) lines[#lines+1]=text end,
        AddLine=function(_,text) lines[#lines+1]=text end,Show=function() end}
    DQTFPickupPinMixin.OnMouseEnter({pickup=shared[1]})
    local tooltip=table.concat(lines,"\n")
    assert(tooltip:find("Stop 1: Test",1,true) and tooltip:find("Stop 2: Second giver",1,true)
        and tooltip:find("Second quest",1,true) and tooltip:find("Stop 3: Nearby giver",1,true)
        and tooltip:find("Preparation: Preparation quest",1,true),"Shared tooltip includes numbered giver sections and all quests")
    assert(not tooltip:find("Separate giver",1,true),"Tooltip excludes unrelated stops")
    local label
    DQTFPickupPinMixin.OnAcquired({number={SetText=function(_,text) label=text end},SetPosition=function() end},shared[1])
    assert(label=="1+","Shared pin signals additional pickups")
    GameTooltip=oldTooltip
    WorldMapFrame=nil
    assert(not maps:Attach(),"Missing canvas fallback")
    InCombatLockdown=function() return true end
    assert(not maps:OpenStop(plan.stops[1]),"No map opening in combat")
    local acquired,opened={},nil
    MapCanvasDataProviderMixin={GetMap=function(self) return self.map end}
    MapCanvasPinMixin={}
    CreateFromMixins=function(base) local out={}; for k,v in pairs(base) do out[k]=v end; return out end
    WorldMapFrame={AddDataProvider=function(self,p) p.map=self end,GetMapID=function() return 87 end,IsShown=function() return true end,
        RemoveAllPinsByTemplate=function() acquired={} end,AcquirePin=function(_,_,pin)
            local frame=setmetatable({SetPassThroughButtons=function() error("Protected map click API") end},
                {__index=DQTFPickupPinMixin})
            frame:CheckMouseButtonPassthrough("RightButton")
            acquired[#acquired+1]=pin
        end}
    OpenWorldMap=function(id) opened=id end
    InCombatLockdown=function() return false end
    local oldRoute=DQT.GetDungeonPickupRoute
    local routeCalls=0
    DQT.GetDungeonPickupRoute=function(_,key,startZone)
        assert(startZone==nil,"Automatic map routes re-evaluate the player's current zone")
        routeCalls=routeCalls+1; return plan
    end
    maps:SetRoute(plan)
    assert(maps.startZone==nil,"Automatic start is not accidentally converted to a manual start")
    assert(#acquired==1 and maps:OpenStop(plan.stops[1]) and opened==87,"Provider refresh and clickable map opening")
    for i=1,10 do maps.provider:RefreshAllData() end
    assert(routeCalls==0,"UI plan reused across map redraws")
    maps:InvalidateRoute()
    maps.provider:RefreshAllData()
    maps.provider:RefreshAllData()
    assert(routeCalls==1,"Invalidated map plan rebuilt once, then reused")
    local bestMap=C_Map.GetBestMapForUnit
    C_Map.GetBestMapForUnit=function() return nil end
    maps.provider:OnShow()
    assert(#acquired==1,"Reopening map retains pins while player map is unavailable")
    C_Map.GetBestMapForUnit=bestMap
    local getMapID=WorldMapFrame.GetMapID
    WorldMapFrame.GetMapID=function() return 1418 end
    maps.provider:OnMapChanged()
    assert(#acquired==1 and acquired[1].mapID==1418,"Changing map replaces pins with the new zone's pickups")
    WorldMapFrame.GetMapID=getMapID
    maps.provider:OnMapChanged()
    assert(#acquired==1 and acquired[1].mapID==87,"Returning to a zone restores its pins")
    print("Map redraw route scans: 10 redraws reuse the UI plan; 1 rebuild after invalidation.")
    plan.stops={}
    maps.provider:RefreshAllData()
    assert(#acquired==0,"Collected pickups remove old pins")
    local oldTimer,oldPoint,oldTomTom,oldOption=C_Timer,UiMapPoint,TomTom,DQT.GetOption
    local pending,nativeWaypoint,waypointSets=nil,nil,0
    local function Point(id,x,y)
        return {uiMapID=id,position={GetXY=function() return x,y end}}
    end
    UiMapPoint={CreateFromCoordinates=Point}
    C_Map.GetUserWaypoint=function() return nativeWaypoint end
    C_Map.SetUserWaypoint=function(point) nativeWaypoint=point; waypointSets=waypointSets+1 end
    C_Map.ClearUserWaypoint=function() nativeWaypoint=nil end
    C_Map.CanSetUserWaypointOnMap=function(id) return id==87 end
    C_Timer={After=function(_,callback) assert(not pending,"Tracker refresh is coalesced"); pending=callback end}
    DQT.GetOption=function(_,key) return key=="travel.useTomTom" end
    TomTom=nil
    local first,second={key="first",x=50,y=25,location={name="First giver",zone="Ironforge"},quests={{quest={name="First quest"}}}},
        {key="second",x=60,y=25,location={name="Second giver",zone="Ironforge"},quests={}}
    plan.key,plan.dungeon="test",{name="Test dungeon"}
    plan.stops={first,second}
    plan.itinerary={{kind="travel",toZone="Ironforge"},{kind="pickup",stop=first},{kind="pickup",stop=second}}
    maps:SetRoute(plan)
    maps:TrackRoute(plan.key,plan)
    assert(maps.tracker:IsShown() and nativeWaypoint and waypointSets==1,"Tracker opens with native fallback when TomTom is absent")
    assert(maps.tracker.steps:GetText():find("First quest",1,true),"Tracker includes quest names at its next stop")
    maps:RefreshTracker(plan)
    assert(waypointSets==1,"Unchanged native waypoint is reused")
    nativeWaypoint.position={x=0.5,y=0.25}
    maps:RefreshTracker(plan)
    assert(waypointSets==1,"Forever's plain coordinate table matches the existing waypoint")
    plan.stops={second}
    plan.itinerary={{kind="pickup",stop=second}}
    local callsBeforeRefresh=routeCalls
    maps:InvalidateRoute()
    maps:InvalidateRoute()
    local run=pending
    pending=nil
    run()
    assert(routeCalls==callsBeforeRefresh+1,"Visible map and tracker share one rebuilt route per burst")
    assert(nativeWaypoint.position:GetXY()==0.6 and waypointSets==2,"Route invalidation advances the tracker without reopening the menu")
    local userWaypoint={uiMapID=87,position={x=0.1,y=0.2}}
    nativeWaypoint=userWaypoint
    maps:TrackRoute(nil)
    assert(nativeWaypoint==userWaypoint and not maps.tracker:IsShown(),"Closing tracker preserves the player's replacement pin")
    local uid={}
    TomTom={AddWaypoint=function(_,id,x,y) assert(id==87 and x==0.6 and y==0.25); return uid end,
        RemoveWaypoint=function(_,removed) assert(removed==uid); uid=nil end}
    maps:TrackRoute(plan.key,plan)
    assert(maps.trackerWaypoint.uid==uid and nativeWaypoint==userWaypoint,"TomTom is preferred when enabled")
    maps:TrackRoute(nil)
    assert(not uid and nativeWaypoint==userWaypoint,"Closing tracker removes its TomTom waypoint only")
    TomTom,UiMapPoint=nil,nil
    maps:TrackRoute(plan.key,plan)
    assert(maps.tracker:IsShown() and maps.trackerStop==second and not maps.trackerWaypoint,
        "Text and map focus still work when neither waypoint API is available")
    maps:TrackRoute(nil)
    C_Timer,UiMapPoint,TomTom,DQT.GetOption=oldTimer,oldPoint,oldTomTom,oldOption
    DQT.GetDungeonPickupRoute=oldRoute
    C_Map,WorldMapFrame,MapCanvasDataProviderMixin,MapCanvasPinMixin,CreateFromMixins,OpenWorldMap,InCombatLockdown=oldMap,oldWorld,oldBase,oldPin,oldMixins,oldOpen,oldCombat
    maps.provider,maps.cache=oldProvider,oldCache
    maps.root,maps.mapNames,maps.plan=oldRoot,oldNames,oldPlan
    maps.key,maps.startZone=nil,nil
    print("Pickup map discovery, numbering, lifecycle and compatibility tests passed.")
end
