do
    local travel=DQT.Travel
    assert(#DQT.travelData.nodes==67 and #DQT.travelData.edges==288,"Versioned flight dataset must be reviewed when its size changes")
    local seen={}
    for _,edge in ipairs(DQT.travelData.edges) do
        assert(travel.nodes[edge.from] and travel.nodes[edge.to],"Unresolved flight node")
        assert(edge.fare>=0 and edge.fare==math.floor(edge.fare) and edge.source:match("^https://"),"Flight fare/provenance")
        local key=edge.from..">"..edge.to..":"..tostring(edge.faction)
        assert(not seen[key],"Duplicate directed flight edge"); seen[key]=true
    end
    local oldDB,oldGUID,oldTime=DQT.db,UnitGUID,GetTime
    local oldFaction,oldClass=UnitFactionGroup,UnitClass
    local oldNum,oldName,oldType,oldCost=NumTaxiNodes,TaxiNodeName,TaxiNodeGetType,TaxiNodeCost
    local oldQuotes=travel.quotes
    local character="Character A"
    UnitGUID=function() return character end
    UnitFactionGroup=function() return "Horde" end
    UnitClass=function() return "Warrior","WARRIOR" end
    GetTime=function() return 100 end
    DQT.db={travel={},travelCharacters={}}
    local from,to="Undercity|Horde","Tarren Mill|Horde"
    local context=travel:Context("Horde","WARRIOR")
    assert(not travel:Route("Undercity","Hillsbrad Foothills",context),"Unknown flights are excluded by default")
    travel:SetKnown(from,true); travel:SetKnown(to,true)
    local route=assert(travel:Route("Undercity","Hillsbrad Foothills",travel:Context("Horde","WARRIOR")))
    assert(route.fare==330 and route.hops==1,"Published copper base fare remains separate from timing")
    character="Character B"
    assert(not travel:Character()[from],"Flight knowledge is character-specific")
    character="Character A"
    assert(travel:Character()[from],"Returning character retains learned flights")
    travel:SetKnown(to,false)
    DQT.db.travel.allowUnknownFlights=true
    assert(not travel:Route("Undercity","Hillsbrad Foothills",travel:Context("Horde","WARRIOR")),"Explicitly unlearned nodes cannot be assumed")
    travel:SetKnown(to,nil)
    route=assert(travel:Route("Undercity","Hillsbrad Foothills",travel:Context("Horde","WARRIOR")))
    assert(route.assumed,"Assumed routes are visibly marked")
    local boat=assert(travel:Route("Undercity","Orgrimmar",travel:Context("Horde","WARRIOR")))
    assert(boat.edges[1].mode=="zeppelin" and boat.fare==0,"Sourced zeppelin edges do not require learned flights")
    assert(not travel:Route("Undercity","Stormwind City",travel:Context("Horde","WARRIOR")),"No faction crossover")
    local tram=assert(travel:Route("Ironforge","Stormwind City",travel:Context("Alliance","WARRIOR")))
    assert(tram.edges[1].mode=="tram" and tram.fare==0,"Alliance transport route is usable without assuming flights")
    local order=travel:OrderZones({"Stormwind City","Orgrimmar"},nil,"Undercity",travel:Context("Horde","WARRIOR"))
    assert(order[1]=="Orgrimmar" and order[2]=="Stormwind City","Reachable transport destination precedes unresolved zones without dropping either")
    NumTaxiNodes=function() return 3 end
    TaxiNodeName=function(index) return ({"Undercity, Tirisfal","Tarren Mill, Hillsbrad","Unknown localised name"})[index] end
    TaxiNodeGetType=function(index) return index==1 and "CURRENT" or "REACHABLE" end
    TaxiNodeCost=function() return 297 end
    travel:ObserveTaxi()
    assert(travel:Character()[to]==true,"Taxi map confirms reachable flight points")
    route=travel:Route("Undercity","Hillsbrad Foothills",travel:Context("Horde","WARRIOR"))
    assert(route.quotedFare==297 and route.fare==330,"Recent quoted fare does not replace base data")
    GetTime=function() return 500 end
    assert(not travel:Route("Undercity","Hillsbrad Foothills",travel:Context("Horde","WARRIOR")).quotedFare,"Quotes expire")
    NumTaxiNodes=function() error("Unsupported taxi API") end
    assert(pcall(travel.ObserveTaxi,travel),"Unavailable taxi APIs are harmless")
    travel:SetKnown(to,false)
    local returnStop={key="return",location={name="Return NPC",zone="Undercity"}}
    local pickupStop={key="pickup",location={name="Pickup NPC",zone="Hillsbrad Foothills"}}
    local itinerary=travel:BuildItinerary({progress={{stop=returnStop}},stops={pickupStop}},"Orgrimmar",travel:Context("Horde","WARRIOR"))
    assert(itinerary[1].kind=="travel" and itinerary[2].stop==returnStop and itinerary[#itinerary].stop==pickupStop,"Ready returns precede pickups with explicit travel/return legs")
    local unresolved=false
    for _,step in ipairs(itinerary) do if step.kind=="travel" and not step.route then unresolved=true end end
    assert(unresolved,"Disconnected/unlearned legs are explicit, not fabricated")

    local nodes,ids,adj=travel.nodes,travel.ids,travel.adjacency
    travel.nodes={a={id="a",name="A",zone="A",faction="Horde"},b={id="b",name="B",zone="B",faction="Horde"},c={id="c",name="C",zone="C",faction="Horde"}}
    travel.ids={"a","b","c"}
    travel.adjacency={a={{from="a",to="b",fare=10,mode="flight"}},b={{from="b",to="c",fare=20,mode="flight"}},c={}}
    local fixture={faction="Horde",known={a=true,b=true,c=true},flights=true,transports=true,cache={}}
    route=assert(travel:Route("A","C",fixture))
    assert(route.fare==30 and route.hops==2 and #route.edges==2,"Multi-hop path and summed fares")
    assert(not travel:Route("C","A",fixture),"Reverse flights are never inferred")
    travel.adjacency.a[#travel.adjacency.a+1]={from="a",to="c",fare=50,mode="flight"}
    fixture.cache={}
    route=travel:Route("A","C",fixture)
    assert(route.hops==1 and route.fare==50,"Fewest legs is the explicit objective, not cheapest fare or fastest time")
    travel.nodes,travel.ids,travel.adjacency=nodes,ids,adj

    local ui=DQT.UI
    ui.currentDungeonKey="ragefire-chasm"; ui.currentView="pickups"
    for _,compact in ipairs({false,true}) do
        DQT.db.display={compact=compact}
        ui:ShowTravelOptions()
        assert(ui.frame.travelRows[1]:IsShown(),"Manual flight knowledge screen in both layouts")
        assert(ui.frame.travelRows[1].label:GetWidth()<=ui.frame.travelRows[1]:GetWidth()-66,"Flight knowledge labels leave room for controls")
    end
    local row=ui.frame.travelRows[1]
    row.known:SetChecked(true); row.known.scripts.OnClick(row.known)
    assert(travel:Character()[row.nodeID]==true,"Manual known state")
    row.clear.scripts.OnClick()
    assert(travel:Character()[row.nodeID]==nil,"Manual restore unknown")
    ui:CloseTravelOptions()
    assert(ui.currentView=="pickups","Back from flight knowledge returns to route")

    DQT.db,UnitGUID,GetTime=oldDB,oldGUID,oldTime
    UnitFactionGroup,UnitClass=oldFaction,oldClass
    NumTaxiNodes,TaxiNodeName,TaxiNodeGetType,TaxiNodeCost=oldNum,oldName,oldType,oldCost
    travel.quotes=oldQuotes
end

do
    local maps=DQT.PickupMap
    local oldDB,oldMap,oldTomTom=DQT.db,C_Map,TomTom
    local oldWaypoint,oldOwner,oldKey=maps.waypoint,maps.waypointOwner,maps.waypointKey
    local oldLines=maps.lines
    DQT.db={travel={showSegments=true,useTomTom=true}}
    C_Map={GetMapInfo=function() return {mapType=3} end}
    local a={key="a",x=10,y=10,location={name="A",zone="Zone",mapID=1}}
    local b={key="b",x=20,y=20,location={name="B",zone="Zone",mapID=1}}
    local c={key="c",x=30,y=30,location={name="C",zone="Other",mapID=2}}
    local plan={stops={a,b,c,a}}
    assert(#maps:GetSegments(plan,1)==1,"Guide lines do not bridge maps")
    plan.itinerary={{stop=a},{kind="travel"},{stop=b}}
    assert(#maps:GetSegments(plan,1)==0,"Transport and unresolved legs break guide lines")
    plan.itinerary=nil
    local created=0
    local canvas={CreateLine=function()
        created=created+1
        return {SetColorTexture=function() end,SetThickness=function() end,SetStartPoint=function(self,_,target) self.a=target end,
            SetEndPoint=function(self,_,target) self.b=target end,Show=function(self) self.shown=true end,Hide=function(self) self.shown=false end}
    end}
    maps.lines={}
    local af,bf={},{}
    maps:DrawSegments(plan,{GetMapID=function() return 1 end,GetCanvas=function() return canvas end},{[a]=af,[b]=bf})
    assert(created==1 and maps.lines[1].a==af and maps.lines[1].b==bf and maps.lines[1].shown,"Lines anchor to map pins rather than unscaled screen coordinates")
    maps:HideSegments()
    assert(not maps.lines[1].shown,"Segments clean up on hide")
    local added,removed=0,{}
    TomTom={AddWaypoint=function(_,id,x,y,options)
        assert(id==1 and x==0.1 and y==0.1 and options.persistent==false,"Normalised nonpersistent waypoint")
        added=added+1; return "owned-waypoint"
    end,RemoveWaypoint=function(_,uid) removed[#removed+1]=uid end}
    maps.waypoint,maps.waypointKey=nil,nil
    maps:FocusWaypoint(a,1)
    assert(added==1,"Optional TomTom focus")
    maps:FocusWaypoint(a,1)
    assert(added==1,"Focusing the same stop does not duplicate waypoints")
    maps:CheckWaypoint({stops={}})
    assert(#removed==1 and removed[1]=="owned-waypoint","Collected/reset stops remove only the owned waypoint")
    TomTom=nil
    assert(pcall(maps.FocusWaypoint,maps,a,1),"TomTom is optional")
    maps.waypoint,maps.waypointOwner,maps.waypointKey=oldWaypoint,oldOwner,oldKey
    maps.lines=oldLines
    DQT.db,C_Map,TomTom=oldDB,oldMap,oldTomTom
end
print("Travel passed: sourced graph, fares, characters, discovery, unknown nodes, directed paths, transport ordering, returns, UI, segments and owned waypoints.")
