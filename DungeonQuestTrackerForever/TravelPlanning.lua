local _,DQT=...
if DQT.travelPlanningLoaded then return end
DQT.travelPlanningLoaded=true
local Travel=DQT.Travel
local function Safe(fn,...)
    if type(fn)~="function" then return end
    local ok,a,b=pcall(fn,...)
    if ok then return a,b end
end
local function Number(value,low,high)
    return type(value)=="number" and value==value and value<math.huge and value>=low and value<=high
end
local function Build()
    local _,build=Safe(GetBuildInfo)
    return type(build)=="string" and build:match("^%d+$") and build or nil
end
local function ValidTiming(row,maxCount)
    return type(row)=="table" and Number(row.count,1,maxCount or 20) and row.count==math.floor(row.count)
        and Number(row.total,5*row.count,7200*row.count) and Number(row.minimum,5,7200)
        and Number(row.maximum,row.minimum,7200) and row.total/row.count>=row.minimum and row.total/row.count<=row.maximum
end
function Travel:ScheduleHearthRefresh(remaining)
    if not Number(remaining,0.01,3600) or not C_Timer or type(C_Timer.After)~="function" then return end
    local now=Safe(GetTime)
    if not Number(now,0,math.huge) then return end
    local deadline=now+remaining
    if self.hearthRefreshDeadline and math.abs(self.hearthRefreshDeadline-deadline)<1 then return end
    self.hearthRefreshDeadline=deadline
    Safe(C_Timer.After,remaining+0.1,function()
        if Travel.hearthRefreshDeadline~=deadline then return end
        Travel.hearthRefreshDeadline=nil
        Travel:HearthChanged(true)
    end)
end
function Travel:ClearTimings()
    local records=self:TimingRecords()
    if records then for key in pairs(records) do records[key]=nil end end
    self:StopFlight()
    if DQT.PickupMap then DQT.PickupMap:InvalidateRoute() end
    DQT:RequestUIRefresh()
end
function Travel:TimingRecords()
    local _,key=self:Character()
    local build=Build()
    if not key or not build or not DQT.db then return end
    DQT.db.travelTimings=type(DQT.db.travelTimings)=="table" and DQT.db.travelTimings or {}
    local id=key..":"..build
    if type(DQT.db.travelTimings[id])~="table" then DQT.db.travelTimings[id]={} end
    return DQT.db.travelTimings[id],id
end
function Travel:EdgeTiming(edge,context)
    local minimum=Number(edge.minimumSeconds,1,14400) and edge.minimumDurationConfirmed==true
        and type(edge.minimumDurationSource)=="string" and edge.minimumDurationSource:match("^https://") and edge.minimumSeconds or 0
    if Number(edge.seconds,1,14400) and type(edge.durationSource)=="string" and edge.durationSource:match("^https://") then
        return edge.seconds,minimum
    end
    if edge.mode~="flight" then return nil,minimum end
    local records
    if context then records=context.timingRecords else records=self:TimingRecords() end
    local row=records and records[edge.from..">"..edge.to]
    if ValidTiming(row) then
        return row.total/row.count,minimum
    end
    return nil,minimum
end
function Travel:ObserveApproach(id)
    local position=DQT.PickupMap and DQT.PickupMap:GetPlayerPosition()
    local zone=Safe(GetRealZoneText)
    if not position or not self.nodes[id] or not self:InZone(self.nodes[id],zone) then return end
    local _,key=self:Character()
    if not key or not DQT.db then return end
    DQT.db.travelApproaches=type(DQT.db.travelApproaches)=="table" and DQT.db.travelApproaches or {}
    local records=DQT.db.travelApproaches[key]
    if type(records)~="table" then records={}; DQT.db.travelApproaches[key]=records end
    records[id]={name=self.nodes[id].name.." flight approach",zone=zone,mapID=position.mapID,
        coordinates=string.format("%.2f, %.2f",position.x,position.y),
        source="Observed player position while speaking to this flight master",build=Build()}
end
function Travel:Approach(id)
    local _,key=self:Character()
    local records=key and DQT.db and DQT.db.travelApproaches
    local record=type(records)=="table" and type(records[key])=="table" and records[key][id]
    if type(record)=="table" and record.build==Build() and type(record.mapID)=="number" and type(record.coordinates)=="string"
        and self.nodes[id] and self:InZone(self.nodes[id],record.zone) then return record end
    return self.nodes[id] and self.nodes[id].location
end
function Travel:TransportStops(route)
    local stops,seen={},{}
    for _,edge in ipairs(route and route.edges or {}) do
        for _,id in ipairs({edge.from,edge.to}) do
            local location=self:Approach(id)
            if location and not seen[id] then
                local x,y=tostring(location.coordinates):match("^(%d+%.?%d*),%s*(%d+%.?%d*)$")
                x,y=tonumber(x),tonumber(y)
                if Number(x,0,100) and Number(y,0,100) then
                    stops[#stops+1]={kind="transport",key="transport:"..id,location=location,x=x,y=y,quests={},provisional=true}
                    seen[id]=true
                end
            end
        end
    end
    return stops
end
function Travel:StartFlight(index)
    self.pendingFlight=nil
    if not DQT:GetOption("travel.recordFlightTimes") then return end
    local selection=self.taxiSelection
    local now=Safe(GetTime)
    local records,identity=self:TimingRecords()
    if not selection or not records or not Number(now,0,math.huge) or not Number(selection.time,0,now)
        or now-selection.time>60 or not Number(index,1,300) or index~=math.floor(index) then return end
    local target=selection.targets[index]
    -- A direct edge is necessary: a multi-hop taxi quote is not a single-edge time.
    local direct=false
    for _,edge in ipairs(self.adjacency[selection.from] or {}) do
        if edge.mode=="flight" and edge.to==target then direct=true end
    end
    if not direct or target==selection.from or not selection.direct or not selection.direct[index] then return end
    self.pendingFlight={from=selection.from,to=target,selected=now,identity=identity,lastPoll=now}
    self.flightTick=0
    self.events:SetScript("OnUpdate",function(_,elapsed)
        Travel.flightTick=(Travel.flightTick or 0)+elapsed
        if Travel.flightTick>=0.25 then Travel.flightTick=0; Travel:PollFlight() end
    end)
end
function Travel:StopFlight()
    self.pendingFlight=nil
    self.events:SetScript("OnUpdate",nil)
end
function Travel:PollFlight()
    local pending=self.pendingFlight
    if not pending then self:StopFlight(); return end
    local now=Safe(GetTime)
    local records,identity=self:TimingRecords()
    local taxi=Safe(UnitOnTaxi,"player")
    if not DQT:GetOption("travel.recordFlightTimes") or not Number(now,pending.selected,pending.selected+7200)
        or identity~=pending.identity or taxi==nil or Safe(UnitIsDeadOrGhost,"player") then self:StopFlight(); return end
    -- A long render/polling pause can include unknown time after arrival.
    if pending.lastPoll and now-pending.lastPoll>2 then self:StopFlight(); return end
    pending.lastPoll=now
    if taxi then pending.start=pending.start or now; return end
    if not pending.start then
        if now-pending.selected>10 then self:StopFlight() end
        return
    end
    local duration=now-pending.start
    local zone=Safe(GetRealZoneText)
    if Number(duration,5,7200) and self.nodes[pending.to] and self:InZone(self.nodes[pending.to],zone) then
        local key=pending.from..">"..pending.to
        local row=records[key]
        local count=0
        for _ in pairs(records) do count=count+1 end
        if not row and count>=128 then self:StopFlight(); return end
        if not ValidTiming(row,19) then row={count=0,total=0,minimum=duration,maximum=duration} end
        row.count,row.total=row.count+1,row.total+duration
        row.minimum,row.maximum=math.min(row.minimum,duration),math.max(row.maximum,duration)
        records[key]=row
        if DQT.PickupMap then DQT.PickupMap:InvalidateRoute() end
        DQT:RequestUIRefresh()
    end
    self:StopFlight()
end
-- Observe the player's choice without calling, replacing or automating taxi actions.
if type(hooksecurefunc)=="function" and type(TakeTaxiNode)=="function" then
    Safe(hooksecurefunc,"TakeTaxiNode",function(index) Travel:StartFlight(index) end)
end
local events=CreateFrame("Frame")
Safe(events.RegisterEvent,events,"PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent",function() Travel:StopFlight(); Travel.taxiSelection=nil end)

function Travel:FutureSteps(plan,context)
    local result,seen={},{}
    if not DQT:GetOption("travel.includeFutureSteps") then return result end
    local function Add(id,depth)
        if depth>64 or seen[id] or #result>=120 then return end
        seen[id]=true
        local quest=DQT:GetQuest(id)
        if not quest or quest.partySupplied or not DQT:QuestMatchesPlayerFaction(quest,context) or not DQT:QuestMatchesPlayerClass(quest,context) then return end
        local state=DQT:GetQuestState(id,quest,context)
        if state=="completed" or state=="ready" or state=="unavailable" then return end
        local conditions={}
        for _,gate in ipairs(quest.prerequisites or {}) do
            if not DQT:IsPrerequisiteSatisfied(gate,context) and gate.relationship=="required" then
                if gate.questID and not gate.anyOf and gate.state~="active" then Add(gate.questID,depth+1) end
                conditions[#conditions+1]=gate.note or ("Meet the prerequisite for #"..tostring(gate.questID or "unknown"))
            end
        end
        local condition=state=="locked" and (table.concat(conditions," ").." Recheck eligibility after completing these requirements.") or "After accepting this quest and completing its objectives."
        if state=="locked" then result[#result+1]={kind="pickup",questID=id,quest=quest,location=quest.pickup,condition=condition,hypothetical=true} end
        local count=0
        for _,location in ipairs(quest.routeObjectives or {}) do
            if location.sourceReviewed and type(location.source)=="string" and location.source:match("^https://") and count<20 then
                count=count+1
                result[#result+1]={kind="objective",questID=id,quest=quest,location=location,condition="After accepting #"..id.."; follow the current quest objectives.",hypothetical=true}
            end
        end
        if count==0 then result[#result+1]={kind="objective",questID=id,quest=quest,condition="After accepting #"..id..". Objective locations are not recorded; follow the quest log.",hypothetical=true} end
        result[#result+1]={kind="turnIn",questID=id,quest=quest,location=quest.turnIn,condition="After completing #"..id..". Return here before taking the next chain step.",hypothetical=true}
    end
    for _,entry in ipairs(plan.progress or {}) do if entry.state=="active" then Add(entry.questID,0) end end
    for _,entry in ipairs(plan.blocked or {}) do Add(entry.questID,0) end
    while #result>120 do table.remove(result) end
    return result
end
