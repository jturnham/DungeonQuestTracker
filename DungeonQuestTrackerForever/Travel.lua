local _, DQT = ...
local Travel = {quotes={}}
DQT.Travel = Travel
local function Safe(fn, ...)
    if type(fn)~="function" then return end
    local ok,a,b,c,d=pcall(fn,...)
    if ok then return a,b,c,d end
end
local function Now()
    local value=Safe(GetTime)
    if type(value)=="number" and value==value and value>=0 and value<math.huge then return value end
end
local function Allowed(node,faction,class) return node and (node.faction=="Both" or node.faction==faction) and (not node.class or node.class==class) end
local function Better(a,b)
    if a and b and a.timed and b.timed and a.seconds~=b.seconds then return a.seconds<b.seconds end
    return not b or a.hops<b.hops or (a.hops==b.hops and (a.fare<b.fare or (a.fare==b.fare and a.tie<b.tie)))
end
local cities={Orgrimmar=true,Undercity=true,Ironforge=true,["Thunder Bluff"]=true,["Stormwind City"]=true}

function Travel:Character()
    local key=Safe(UnitGUID,"player")
    if type(key)~="string" or key=="" then
        key=nil
        local name=Safe(UnitName,"player")
        local realm=Safe(GetRealmName)
        if type(name)=="string" and type(realm)=="string" then key=realm..":"..name end
    end
    if key and DQT.db then
        if type(DQT.db.travelCharacters)~="table" then DQT.db.travelCharacters={} end
        if type(DQT.db.travelCharacters[key])~="table" then DQT.db.travelCharacters[key]={} end
        return DQT.db.travelCharacters[key],key
    end
    self.sessionKnown=self.sessionKnown or {}
    return self.sessionKnown
end
function Travel:SetKnown(id,value)
    if not self.nodes[id] or (value~=nil and type(value)~="boolean") then return end
    self:Character()[id]=value
    if DQT.PickupMap then DQT.PickupMap:InvalidateRoute() end
    DQT:RequestUIRefresh()
    return true
end
function Travel:Initialize()
    self.nodes,self.ids,self.adjacency={},{},{}
    local function AddNode(node)
        self.nodes[node.id]=node
        self.ids[#self.ids+1]=node.id
        self.adjacency[node.id]={}
    end
    for _,node in ipairs(DQT.travelData.nodes) do AddNode(node) end
    local forever="https://worldofwarcraft.blizzard.com/en-gb/news/24304071/world-of-warcraft-forever-found-photos-panel-recap"
    AddNode({id="Steamwheedle Port|Both",name="Steamwheedle Port",zone="Tanaris",faction="Both",portOnly=true,source=forever})
    AddNode({id="Powderfuse Port|Both",name="Powderfuse Port",zone="Riverglades",faction="Both",portOnly=true,source=forever})
    table.sort(self.ids)
    for _,edge in ipairs(DQT.travelData.edges) do
        self.adjacency[edge.from][#self.adjacency[edge.from]+1]=edge
    end
    -- Public Classic transport connections; no schedules, coordinates or durations inferred.
    local source="https://news.blizzard.com/en-us/article/23156366/wow-classic-getting-around-azeroth"
    local function Connect(a,b,mode,faction,crossing,routeSource,oneWay)
        local left,right
        for _,id in ipairs(self.ids) do
            local node=self.nodes[id]
            if Allowed(node,faction) then
                if node.name==a then left=id end
                if node.name==b then right=id end
            end
        end
        if left and right then
            self.adjacency[left][#self.adjacency[left]+1]={from=left,to=right,fare=0,mode=mode,faction=faction,source=routeSource or source,crossing=crossing}
            if not oneWay then
                self.adjacency[right][#self.adjacency[right]+1]={from=right,to=left,fare=0,mode=mode,faction=faction,source=routeSource or source,crossing=crossing}
            end
        end
    end
    for _,faction in ipairs({"Alliance","Horde"}) do
        Connect("Booty Bay","Ratchet","boat",faction,true)
        Connect("Steamwheedle Port","Powderfuse Port","boat",faction,true,forever)
    end
    Connect("Ironforge","Stormwind City","tram","Alliance")
    Connect("Auberdine","Menethil Harbor","boat","Alliance",true)
    Connect("Auberdine","Rut'theran Village","boat","Alliance")
    Connect("Menethil Harbor","Theramore Isle","boat","Alliance",true)
    Connect("Orgrimmar","Undercity","zeppelin","Horde",true)
    Connect("Orgrimmar","Grom'gol Base Camp","zeppelin","Horde",true)
    Connect("Undercity","Grom'gol Base Camp","zeppelin","Horde")
    Connect("Stormwind City","Auberdine","boat","Alliance",true,forever)
    Connect("Southshore","Auberdine","boat","Alliance",true,forever,true)
end

local function ContinentPosition(zone)
    if not (DQT.PickupMap and C_Map and C_Map.GetMapInfo) then return end
    local mapID=DQT.PickupMap:ResolveLocation({zone=zone})
    local continent=mapID
    for _=1,12 do
        local info=continent and Safe(C_Map.GetMapInfo,continent)
        if not info then return end
        if info.mapType==2 then
            local left,right,top,bottom=Safe(C_Map.GetMapRectOnMap,mapID,continent)
            if type(left)=="number" and type(right)=="number" and type(top)=="number" and type(bottom)=="number" then
                return continent,(left+right)/2,(top+bottom)/2
            end
            return continent
        end
        continent=info.parentMapID
    end
end

function Travel:FindCrossing(fromZone,toZone,context)
    if not context.transports then return end
    local origin,x,y=ContinentPosition(fromZone)
    local destination,dx,dy=ContinentPosition(toZone)
    if not origin or not destination or origin==destination then return end
    local best,bestDistance,bestArrival
    for _,id in ipairs(self.ids) do
        for _,edge in ipairs(self.adjacency[id]) do
            if edge.crossing and edge.faction==context.faction then
                local from,to=self.nodes[id],self.nodes[edge.to]
                local continent,px,py=ContinentPosition(from.zone)
                local arrival,ax,ay=ContinentPosition(to.zone)
                if continent==origin and arrival==destination then
                    local distance=self:InZone(from,fromZone) and 0 or (x and px and (x-px)^2+(y-py)^2 or math.huge)
                    local onward=self:InZone(to,toZone) and 0 or (dx and ax and (dx-ax)^2+(dy-ay)^2 or math.huge)
                    if not best or distance<bestDistance or (distance==bestDistance and onward<bestArrival) then
                        best,bestDistance,bestArrival=edge,distance,onward
                    end
                end
            end
        end
    end
    return best
end
function Travel:HearthRecord()
    local _,key=self:Character()
    if key and DQT.db then
        DQT.db.hearthCharacters=DQT.db.hearthCharacters or {}
        return DQT.db.hearthCharacters,key
    end
    self.sessionHearth=self.sessionHearth or {}
    return self.sessionHearth,"session"
end
function Travel:RecordHearth(requireAtInn)
    local bind,zone=Safe(GetBindLocation),Safe(GetRealZoneText)
    if type(bind)~="string" or bind=="" or type(zone)~="string" or zone=="" then return end
    if requireAtInn and (not Safe(IsResting) or (bind~=zone and bind~=Safe(GetSubZoneText) and bind~=Safe(GetMinimapZoneText))) then
        DQT:Print("Stand at your bound inn before confirming its location, or bind again to record it automatically.")
        return
    end
    local records,key=self:HearthRecord()
    records[key]={name=bind,zone=zone}
    self:HearthChanged(true)
    return true
end
function Travel:HearthChanged(force)
    local faction=Safe(UnitFactionGroup,"player")
    local _,class=Safe(UnitClass,"player")
    local hearth=self:Hearth(faction,class)
    local signature=hearth and (hearth.name..":"..hearth.zone) or "unavailable"
    -- Bag/cooldown events are frequent; rebuild only when routing eligibility changes.
    if not force and self.hearthSignature==signature then return end
    self.hearthSignature=signature
    if DQT.PickupMap then DQT.PickupMap:InvalidateRoute() end
    DQT:RequestUIRefresh()
end
function Travel:Hearth(faction,class)
    if not DQT:GetOption("travel.useHearthstone") then return end
    local bind=Safe(GetBindLocation)
    if type(bind)~="string" or bind=="" then return end
    local records,key=self:HearthRecord()
    local record=records[key]
    if not record or record.name~=bind then
        record=nil
        -- Only an exact, unambiguous town match is safe without observing a bind.
        for _,id in ipairs(self.ids) do
            local node=self.nodes[id]
            if node.name==bind and Allowed(node,faction,class) then
                if record then return end
                record={name=bind,zone=cities[node.name] and node.name or node.zone}
            end
        end
    end
    if not record then return end
    local count=Safe(C_Item and C_Item.GetItemCount or GetItemCount,6948,false)
    local start,duration,enabled=Safe(C_Container and C_Container.GetItemCooldown or GetItemCooldown,6948)
    local now=Now()
    local function Number(value) return type(value)=="number" and value==value and value>=0 and value<math.huge end
    if not Number(count) or count<1 or not Number(start) or not Number(duration) or enabled~=1 or not now then return end
    if duration>0 and (start>now or start+duration>now) then
        if start<=now and self.ScheduleHearthRefresh then self:ScheduleHearthRefresh(start+duration-now) end
        return
    end
    return {name=record.name,zone=record.zone}
end
function Travel:ForkContext(context)
    local copy={}
    for key,value in pairs(context) do copy[key]=value end
    return copy
end
function Travel:Consume(route,context)
    if route and route.hearth then
        context.hearthUsed=true
        context.hearthReadyAt=(context.provenElapsed or 0)+3600
    end
    -- Observed/average journey times never prove that a future cooldown expires.
    context.provenElapsed=(context.provenElapsed or 0)+(route and route.minimumSeconds or 0)
end
function Travel:Context(faction,class)
    return {faction=faction,known=self:Character(),allowUnknown=DQT:GetOption("travel.allowUnknownFlights"),
        class=class,flights=DQT:GetOption("travel.useFlights"),transports=DQT:GetOption("travel.useTransports"),
        hearth=self:Hearth(faction,class),timingRecords=self:TimingRecords() or false,preferTime=DQT:GetOption("travel.preferMeasuredTime"),provenElapsed=0,cache={}}
end
function Travel:InZone(node,zone)
    if zone=="Stormwind" then zone="Stormwind City" end
    if cities[node.name] then return zone==node.name end
    return node.zone==zone
end
function Travel:PathsFrom(zone,context,measured)
    local cacheKey=zone..(measured and ":timed" or ":legs")
    if context.cache[cacheKey] then return context.cache[cacheKey] end
    local best,visited={},{}
    for _,id in ipairs(self.ids) do
        local node=self.nodes[id]
        if Allowed(node,context.faction,context.class) and self:InZone(node,zone) then best[id]={hops=0,fare=0,tie=id,seconds=0,timed=measured,minimumSeconds=0} end
    end
    for _=1,#self.ids do
        local choice
        for _,id in ipairs(self.ids) do if not visited[id] and best[id] and (not choice or Better(best[id],best[choice])) then choice=id end end
        if not choice then break end
        visited[choice]=true
        for _,edge in ipairs(self.adjacency[choice]) do
            local target=self.nodes[edge.to]
            local permitted=Allowed(target,context.faction,context.class) and (not edge.faction or edge.faction==context.faction)
            if edge.mode=="flight" then
                local fromKnown,toKnown=context.known[edge.from],context.known[edge.to]
                if fromKnown==false or toKnown==false or (not context.allowUnknown and (fromKnown~=true or toKnown~=true)) then permitted=false end
                permitted=permitted and context.flights
            else permitted=permitted and context.transports end
            if permitted and not visited[edge.to] then
                local seconds,minimum=self:EdgeTiming(edge,context)
                if not measured or seconds then
                local previous=best[choice]
                local candidate={hops=previous.hops+1,fare=previous.fare+edge.fare,tie=previous.tie..">"..edge.to,edge=edge,parent=choice,timed=measured,
                    seconds=previous.seconds and seconds and previous.seconds+seconds or nil,minimumSeconds=previous.minimumSeconds+(minimum or 0)}
                if Better(candidate,best[edge.to]) then best[edge.to]=candidate end
                end
            end
        end
    end
    context.cache[cacheKey]=best
    return best
end
function Travel:NetworkRoute(fromZone,toZone,context)
    if not fromZone or not toZone or fromZone==toZone then return end
    for attempt=1,(context.preferTime and 2 or 1) do
    local measured=context.preferTime and attempt==1
    local paths=self:PathsFrom(fromZone,context,measured)
    local target
    for _,id in ipairs(self.ids) do
        if self:InZone(self.nodes[id],toZone) and paths[id] and paths[id].hops>0 and (not target or Better(paths[id],paths[target])) then target=id end
    end
    if target then
    local result={fromZone=fromZone,toZone=toZone,hops=paths[target].hops,fare=paths[target].fare,tie=paths[target].tie,edges={},provisional=true,
        seconds=paths[target].seconds,minimumSeconds=paths[target].minimumSeconds,timed=measured,timingFallback=context.preferTime and not measured}
    local id=target
    while paths[id].edge do
        local edge=paths[id].edge
        table.insert(result.edges,1,edge)
        if edge.mode=="flight" and (context.known[edge.from]~=true or context.known[edge.to]~=true) then result.assumed=true end
        id=paths[id].parent
    end
    if #result.edges==1 and result.edges[1].mode=="flight" then
        local quote=self.quotes[result.edges[1].from..">"..target]
        local now=Now()
        if quote and now and now-quote.time>=0 and now-quote.time<300 then result.quotedFare=quote.fare end
    end
    return result
    end
    end
end
function Travel:Route(fromZone,toZone,context)
    if not fromZone or not toZone or fromZone==toZone then return end
    local normal=self:NetworkRoute(fromZone,toZone,context)
    local bind=context.hearth
    local reusable=context.hearthUsed and context.hearthReadyAt and (context.provenElapsed or 0)>=context.hearthReadyAt
    if not bind or (context.hearthUsed and not reusable) or bind.zone==fromZone then return normal end
    if normal and normal.timed then return normal end -- Hearth cast/loading time is not measured.
    local onward=bind.zone~=toZone and self:NetworkRoute(bind.zone,toZone,context) or nil
    if bind.zone~=toZone and not onward then return normal end
    local route={fromZone=fromZone,toZone=toZone,hops=1+(onward and onward.hops or 0),
        fare=onward and onward.fare or 0,tie="hearth:"..bind.name,hearth=true,edges={},
        provisional=onward and onward.provisional,assumed=onward and onward.assumed,minimumSeconds=onward and onward.minimumSeconds or 0}
    -- Preserve the hearth when a conventional route is equally good.
    if normal and (normal.hops<route.hops or (normal.hops==route.hops and normal.fare<=route.fare)) then return normal end
    route.edges[1]={mode="hearthstone",fromLabel=fromZone,toLabel=bind.name}
    for _,edge in ipairs(onward and onward.edges or {}) do route.edges[#route.edges+1]=edge end
    return route
end
function Travel:OrderZones(zones,startZone,currentZone,context)
    local remaining,ordered={},{}
    for _,zone in ipairs(zones) do remaining[zone]=true end
    if startZone and startZone==currentZone and remaining[startZone] then ordered[1]=startZone; remaining[startZone]=nil end
    local from=ordered[1] or currentZone
    while next(remaining) do
        local choice,route
        for _,zone in ipairs(zones) do
            if remaining[zone] then
                local candidate=from and self:Route(from,zone,context)
                if candidate and (not route or Better(candidate,route)) then choice,route=zone,candidate end
            end
        end
        if not choice then
            if #ordered==0 and remaining[startZone] then choice=startZone
            else for _,zone in ipairs(zones) do if remaining[zone] then choice=zone; break end end end
        end
        self:Consume(route,context)
        ordered[#ordered+1]=choice; remaining[choice]=nil; from=choice
    end
    return ordered
end
function Travel:Describe(route)
    local parts={}
    for _,edge in ipairs(route.edges) do
        parts[#parts+1]=edge.mode..": "..(edge.fromLabel or self.nodes[edge.from].name).." -> "..(edge.toLabel or self.nodes[edge.to].name)
    end
    local price=route.quotedFare and ("Recent quoted fare: "..route.quotedFare.." copper") or ("Base fare: "..route.fare.." copper before discounts")
    local timing=route.seconds and ("\nMeasured/sourced transport estimate: "..math.ceil(route.seconds).." seconds. Walking and waiting are additional.") or "\nJourney time is unknown."
    if route.timed then timing=timing.." Fastest among fully timed recorded transport paths; not a door-to-door guarantee." end
    if route.timingFallback then timing=timing.." Missing timing: using fewest transport legs instead." end
    return table.concat(parts,"\n").."\n"..price..timing..(route.hearth and "\nUse your ready Hearthstone. Another use requires proven minimum travel to cover the hour cooldown; estimates do not count." or "")..(route.assumed and "\nSome flight nodes are assumed learned." or "").."\nContinue to the pickup on foot. Ground approaches and waiting are not timed. Transport data is provisional."
end
function Travel:ReadyReturns(progress,currentZone,context)
    local returns,zones={},{}
    for _,entry in ipairs(progress) do
        if entry.stop then
            local zone=entry.stop.location.zone
            if not returns[zone] then returns[zone]={}; zones[#zones+1]=zone end
            returns[zone][#returns[zone]+1]=entry.stop
        end
    end
    table.sort(zones)
    local result={}
    for _,zone in ipairs(self:OrderZones(zones,nil,currentZone,context)) do
        table.sort(returns[zone],function(a,b) return a.key<b.key end)
        for _,stop in ipairs(returns[zone]) do result[#result+1]=stop end
    end
    return result
end
function Travel:BuildItinerary(plan,currentZone,context)
    context=self:ForkContext(context)
    local steps,from={},currentZone
    local function Add(stop,kind)
        local zone=stop.location.zone
        if from and zone and from~=zone then
            local route=self:Route(from,zone,context)
            self:Consume(route,context)
            local crossing
            for _,edge in ipairs(route and route.edges or {}) do
                if edge.crossing then crossing=edge; break end
            end
            if not route then crossing=self:FindCrossing(from,zone,context) end
            local boarding
            if crossing then
                local departure,arrival=self.nodes[crossing.from].name,self.nodes[crossing.to].name
                if departure=="Stormwind City" then departure="Stormwind Harbor" end
                if arrival=="Stormwind City" then arrival="Stormwind Harbor" end
                boarding="Board the "..crossing.mode.." at "..departure.." for "..arrival
            end
            steps[#steps+1]={kind="travel",route=route,boarding=boarding,fromZone=from,toZone=zone,transportStops=self:TransportStops(route)}
        end
        steps[#steps+1]={kind=kind,stop=stop}
        from=zone or from
    end
    -- Only already-ready returns are actionable; never simulate completing objectives.
    for _,stop in ipairs(plan.readyReturns or self:ReadyReturns(plan.progress,currentZone,self:ForkContext(context))) do Add(stop,"turnIn") end
    for _,stop in ipairs(plan.stops) do Add(stop,"pickup") end
    if plan.destination then Add(plan.destination,"entrance") end
    return steps
end
function Travel:ObserveTaxi()
    local count=Safe(NumTaxiNodes)
    if type(count)~="number" or count<1 or count>300 or count~=math.floor(count) then return end
    local faction=Safe(UnitFactionGroup,"player")
    local _,class=Safe(UnitClass,"player")
    local matched,current={},nil
    for index=1,count do
        local title,kind=Safe(TaxiNodeName,index),Safe(TaxiNodeGetType,index)
        if type(title)=="string" then
            local match
            for _,id in ipairs(self.ids) do
                local node=self.nodes[id]
                if Allowed(node,faction,class) and (title==node.name or title:sub(1,#node.name+1)==node.name..",") then
                    if match then match=false; break end
                    match=id
                end
            end
            if match and (kind=="CURRENT" or kind=="REACHABLE") then
                self:Character()[match]=true; matched[index]=match
                if kind=="CURRENT" then current=match end
            end
        end
    end
    local direct={}
    for index in pairs(matched) do if Safe(GetNumRoutes,index)==1 then direct[index]=true end end
    self.taxiSelection=current and {from=current,targets=matched,direct=direct,time=Now()} or nil
    if current then
        if self.ObserveApproach then self:ObserveApproach(current) end
        local now=Now()
        for index,id in pairs(matched) do
            local fare=Safe(TaxiNodeCost,index)
            if now and id~=current and type(fare)=="number" and fare>=0 and fare<=10000000 and fare==math.floor(fare) then
                self.quotes[current..">"..id]={fare=fare,time=now}
            end
        end
    end
    if DQT.PickupMap then DQT.PickupMap:InvalidateRoute() end
    DQT:RequestUIRefresh()
end
Travel:Initialize()
local events=CreateFrame("Frame")
Travel.events=events
Safe(events.RegisterEvent,events,"TAXIMAP_OPENED")
for _,event in ipairs({"HEARTHSTONE_BOUND","BAG_UPDATE_DELAYED","BAG_UPDATE_COOLDOWN"}) do Safe(events.RegisterEvent,events,event) end
events:SetScript("OnEvent",function(_,event)
    if event=="TAXIMAP_OPENED" then Travel:ObserveTaxi()
    elseif event=="HEARTHSTONE_BOUND" then Travel:RecordHearth()
    else Travel:HearthChanged() end
end)
