local _, DQT = ...

DQT.pickupRouteDungeons = {
    ["city-of-dalaran"]=true,
    ["shadowfang-keep"]=true, ["the-stockade"]=true, ["blackfathom-deeps"]=true,
    ["gnomeregan"]=true, ["razorfen-kraul"]=true, ["razorfen-downs"]=true,
    ["uldaman"]=true, ["excavation-site-wetlands"]=true,
    ["scarlet-monastery-graveyard"]=true, ["scarlet-monastery-library"]=true,
    ["scarlet-monastery-armory"]=true, ["scarlet-monastery-cathedral"]=true,
}

local function Coordinates(location)
    local x, y = tostring(location.coordinates or ""):match("^%s*(%d+%.?%d*)%s*,%s*(%d+%.?%d*)%s*$")
    x, y = tonumber(x), tonumber(y)
    if x and y and x >= 0 and x <= 100 and y >= 0 and y <= 100 then return x, y end
end
local function StopKey(location)
    return table.concat({location.zone or "", location.name or "", location.subzone or "", location.coordinates or ""}, "|")
end
local function Distance(a, b)
    local dx, dy = a.x-b.x, a.y-b.y
    return math.sqrt(dx*dx + dy*dy)
end
local function Cost(stops)
    local cost = 0
    for i=2,#stops do cost = cost + Distance(stops[i-1], stops[i]) end
    return cost
end
-- Coordinate-space ordering only: no conversion to travel time or cross-zone distance.
local function OrderStops(stops, start)
    table.sort(stops, function(a,b) return a.key < b.key end)
    local positioned, unknown = {}, {}
    for _, stop in ipairs(stops) do
        local target = stop.x and positioned or unknown
        target[#target+1] = stop
    end
    local distances={}
    for _, a in ipairs(positioned) do distances[a]={} end
    for i,a in ipairs(positioned) do
        distances[a][a]=0
        for j=i+1,#positioned do
            local b=positioned[j]
            local value=Distance(a,b)
            distances[a][b],distances[b][a]=value,value
        end
    end
    local best, bestCost = {}, math.huge
    if #positioned <= 7 then
        local path, used = {}, {}
        local function Search(cost)
            if cost >= bestCost then return end
            if #path == #positioned then
                bestCost = cost
                for i, stop in ipairs(path) do best[i] = stop end
                return
            end
            for i, stop in ipairs(positioned) do
                if not used[i] and (#path > 0 or not start or stop == start) then
                    local previous = path[#path]
                    used[i], path[#path+1] = true, stop
                    Search(cost + (previous and distances[previous][stop] or 0))
                    used[i], path[#path] = nil, nil
                end
            end
        end
        Search(0)
    else
        -- Bound work for larger catalogues; nearest-neighbour from each possible start.
        for first=1,#positioned do
            if not start or positioned[first] == start then
            local path, used = {positioned[first]}, {[first]=true}
            while #path < #positioned do
                local choice, distance
                for i, stop in ipairs(positioned) do
                    local value = not used[i] and distances[path[#path]][stop]
                    if value and (not distance or value < distance) then choice, distance = i, value end
                end
                used[choice], path[#path+1] = true, positioned[choice]
            end
            local cost = Cost(path)
            if cost < bestCost then best, bestCost = path, cost end
            end
        end
    end
    for _, stop in ipairs(unknown) do best[#best+1] = stop end
    return best
end

local factionHubs = {
    Horde = {Orgrimmar=1, ["Thunder Bluff"]=2, Undercity=3},
    Alliance = {Ironforge=1, ["Stormwind City"]=2, Darnassus=3},
}
-- Count nearby eligible pickups only within the same zone. Percent coordinates
-- are a cluster heuristic, not comparable physical distances between zone maps.
local function StartingCluster(byZone, faction)
    local best
    for zone, stops in pairs(byZone) do
        local total = 0
        for _, stop in ipairs(stops) do total=total+#stop.quests end
        for _, anchor in ipairs(stops) do
            local count, distance = #anchor.quests, 0
            if anchor.x then
                for _, stop in ipairs(stops) do
                    if stop ~= anchor and stop.x then
                        local value = Distance(anchor,stop)
                        if value <= 10 then count=count+#stop.quests; distance=distance+value*#stop.quests end
                    end
                end
            end
            local candidate = {zone=zone,stop=anchor,count=count,total=total,positioned=anchor.x and 1 or 0,
                hub=(factionHubs[faction] or {})[zone] or 99,distance=distance/count}
            local better = not best
            if best then
                if candidate.count ~= best.count then better=candidate.count>best.count
                elseif candidate.total ~= best.total then better=candidate.total>best.total
                elseif candidate.positioned ~= best.positioned then better=candidate.positioned>best.positioned
                elseif candidate.hub ~= best.hub then better=candidate.hub<best.hub
                elseif zone ~= best.zone then better=zone<best.zone
                elseif candidate.distance ~= best.distance then better=candidate.distance<best.distance
                else better=anchor.key<best.stop.key end
            end
            if better then best=candidate end
        end
    end
    return best
end

function DQT:GetDungeonPickupRoute(key, startZone, context)
    context = context or self:GetPlayerContext()
    local dungeon = self:GetDungeon(key)
    local result = {key=key, dungeon=dungeon, stops={}, zones={}, blocked={}, inside={}, unknown={}, excluded=0, context=context}
    if not dungeon or not self.pickupRouteDungeons[key] then return result end
    local visited, states, groups, byZone = {}, {}, {}, {}
    local function State(id, quest)
        if not states[id] then
            local state, reason = self:GetQuestState(id, quest, context)
            states[id] = {state=state, reason=reason}
        end
        return states[id]
    end
    local function Add(id, preparation, depth)
        if visited[id] or depth > 64 then return end
        visited[id] = true
        local quest = self:GetQuest(id)
        if not quest then return end
        local status = State(id, quest)
        if status.state == "active" or status.state == "ready" or status.state == "completed" then return end
        if status.state == "unavailable" then result.excluded=result.excluded+1; return end
        local entry = {questID=id, quest=quest, preparation=preparation, reason=status.reason}
        local notes = {}
        for _, prerequisite in ipairs(quest.prerequisites or {}) do
            if not self:IsPrerequisiteSatisfied(prerequisite, context) and prerequisite.questID then
                local parent = self:GetQuest(prerequisite.questID)
                if parent and not prerequisite.anyOf then Add(prerequisite.questID, true, depth+1) end
                notes[#notes+1] = prerequisite.note or ("Complete " .. (parent and parent.name or ("quest " .. prerequisite.questID)))
            elseif prerequisite.note then
                notes[#notes+1] = prerequisite.note
            end
        end
        entry.notes = table.concat(notes, " ")
        if status.state == "locked" then result.blocked[#result.blocked+1]=entry; return end
        local location = quest.pickup or {}
        local pickupType = self:GetQuestPickupType(quest)
        local dungeonLocation = location.zone == dungeon.name or (location.zone and location.zone:find("Scarlet Monastery",1,true))
        if pickupType == "drop" or dungeonLocation then result.inside[#result.inside+1]=entry; return end
        if not location.zone or not location.name or location.zone:find("Unknown",1,true) or location.name:find("Unknown",1,true) then
            result.unknown[#result.unknown+1]=entry; return
        end
        local stopKey = StopKey(location)
        local stop = groups[stopKey]
        if not stop then
            local x,y = Coordinates(location)
            stop = {key=stopKey, location=location, quests={}, x=x, y=y}
            groups[stopKey] = stop
            byZone[location.zone] = byZone[location.zone] or {}
            byZone[location.zone][#byZone[location.zone]+1] = stop
        end
        stop.quests[#stop.quests+1] = entry
    end
    for _, id in ipairs(dungeon.quests or {}) do Add(id, false, 0) end
    for zone in pairs(byZone) do result.zones[#result.zones+1] = zone end
    table.sort(result.zones)
    local manual = startZone and byZone[startZone] ~= nil
    local currentZone
    if type(GetRealZoneText) == "function" then
        local ok,zone=pcall(GetRealZoneText)
        if ok then currentZone=zone end
    end
    if currentZone == "Stormwind" then currentZone="Stormwind City" end
    local localStart=not manual and currentZone and byZone[currentZone] ~= nil
    local cluster=StartingCluster(localStart and {[currentZone]=byZone[currentZone]} or byZone,context.faction)
    if not manual then
        startZone=localStart and currentZone or (cluster and cluster.zone)
    end
    result.startZone = startZone
    result.automaticStart = not manual
    result.startReason = manual and "Manually selected starting zone." or (cluster and ("Suggested from " .. cluster.count .. " nearby missing pickups for " .. (context.faction or "your character") .. ". Same-zone coordinate heuristic; not a travel-time estimate.") or "No eligible pickup stops.")
    if not manual then
        result.startReason=localStart and "Starting in your current zone. Stops within the zone use recorded coordinates, not your exact position."
            or "No eligible pickups in your current zone, or zone unavailable. Starting with the largest nearby missing-pickup cluster; cross-zone travel is not optimized."
    end
    for i, zone in ipairs(result.zones) do
        if zone == startZone then table.remove(result.zones,i); table.insert(result.zones,1,zone); break end
    end
    for _, zone in ipairs(result.zones) do
        local anchor = not manual and cluster and zone==cluster.zone and cluster.stop.x and cluster.stop or nil
        local stops = OrderStops(byZone[zone],anchor)
        for _, stop in ipairs(stops) do result.stops[#result.stops+1] = stop end
    end
    for _, list in ipairs({result.blocked,result.inside,result.unknown}) do
        table.sort(list,function(a,b) return a.questID < b.questID end)
    end
    return result
end
