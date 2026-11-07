local _, DQT = ...
local Maps = {cache={}}
DQT.PickupMap = Maps
local template = "DQTFPickupPinTemplate"
local aliases = { ["Stormwind City"]="Stormwind" }

function Maps:ResolveLocation(location)
    if type(location)~="table" then return end
    if location.mapID then
        local id=location.mapID
        if type(id)~="number" or id<=0 or id~=math.floor(id) or not C_Map or not C_Map.GetMapInfo then return end
        local ok,info=pcall(C_Map.GetMapInfo,id)
        if ok and type(info)=="table" then return id end
        return
    end
    local ok,id=pcall(self.ResolveMap,self,location.zone)
    if ok then return id end
end

function Maps:GetPlayerPosition()
    if not C_Map or not C_Map.GetBestMapForUnit or not C_Map.GetPlayerMapPosition then return end
    local ok,id=pcall(C_Map.GetBestMapForUnit,"player")
    if not ok or not id then return end
    local found,position=pcall(C_Map.GetPlayerMapPosition,id,"player")
    if not found or not position or type(position.GetXY)~="function" then return end
    local valid,x,y=pcall(position.GetXY,position)
    if valid and type(x)=="number" and type(y)=="number" and x>=0 and x<=1 and y>=0 and y<=1 and (x~=0 or y~=0) then
        return {mapID=id,x=x*100,y=y*100}
    end
end

function Maps:ResolveMap(zone)
    if not C_Map or not C_Map.GetMapInfo or not C_Map.GetMapChildrenInfo or not C_Map.GetBestMapForUnit then return end
    local id = C_Map.GetBestMapForUnit("player")
    if not id then return self.cache[zone] or nil end
    local seen = {}
    while id and not seen[id] do
        seen[id] = true
        local info = C_Map.GetMapInfo(id)
        if not info then return self.cache[zone] or nil end
        if not info.parentMapID or info.parentMapID == 0 then break end
        id = info.parentMapID
    end
    if self.root ~= id then
        local children=C_Map.GetMapChildrenInfo(id,nil,true)
        if not children or #children == 0 then return self.cache[zone] or nil end
        self.root=id; self.cache={}; self.mapNames=nil
        self.mapChildren=children
    end
    if self.cache[zone] ~= nil then return self.cache[zone] or nil end
    if not self.mapNames then
        local children=self.mapChildren or C_Map.GetMapChildrenInfo(id,nil,true)
        self.mapChildren=nil
        -- Do not cache an unavailable/empty hierarchy during client startup.
        if not children or #children == 0 then return end
        self.mapNames={}
        for _, info in ipairs(children) do
            if info.mapType == 3 or info.mapType == 4 then
                local ids=self.mapNames[info.name] or {}
                ids[#ids+1]=info.mapID
                self.mapNames[info.name]=ids
            end
        end
    end
    local matches = {}
    for _, name in ipairs({zone,aliases[zone]}) do
        for _, mapID in ipairs(self.mapNames[name] or {}) do
            matches[#matches+1]=mapID
        end
    end
    if #matches == 1 then self.cache[zone]=matches[1]; return matches[1] end
    self.cache[zone]=false
end

function Maps:GetPins(plan, mapID)
    local pins, zones = {}, {}
    local stops={}
    for _,stop in ipairs(plan and plan.stops or {}) do stops[#stops+1]=stop end
    if plan and plan.destination then stops[#stops+1]=plan.destination end
    for _,entry in ipairs(plan and plan.progress or {}) do if entry.stop then stops[#stops+1]=entry.stop end end
    for _,step in ipairs(plan and plan.itinerary or {}) do
        for _,stop in ipairs(step.transportStops or {}) do stops[#stops+1]=stop end
    end
    for index, stop in ipairs(stops) do
        if stop.x and stop.y and stop.x >= 0 and stop.x <= 100 and stop.y >= 0 and stop.y <= 100 then
            local zone=stop.location.mapID or stop.location.zone
            if zones[zone] == nil then zones[zone]=self:ResolveLocation(stop.location) or false end
            local id = zones[zone]
            if id and (not mapID or id == mapID) then
                local shared
                -- Merge against the original anchor, avoiding chains of nearby stops.
                for _, pin in ipairs(pins) do
                    local dx,dy=stop.x-pin.x*100,stop.y-pin.y*100
                    if pin.mapID == id and dx*dx+dy*dy <= 0.25 then shared=pin; break end
                end
                local entry={index=index,stop=stop}
                if shared then
                    shared.stops[#shared.stops+1]=entry
                    if stop.kind=="entrance" then shared.entrance=true end
                    if stop.kind=="turnIn" then shared.turnIn=true end
                    if stop.kind=="transport" then shared.transport=true end
                else
                    pins[#pins+1] = {index=index,stop=stop,stops={entry},mapID=id,x=stop.x/100,y=stop.y/100,entrance=stop.kind=="entrance",turnIn=stop.kind=="turnIn",transport=stop.kind=="transport"}
                end
            end
        end
    end
    return pins
end

function Maps:GetSegments(plan,mapID)
    local stops={}
    if plan and plan.itinerary then
        for _,step in ipairs(plan.itinerary) do if step.stop then stops[#stops+1]=step.stop else stops[#stops+1]=false end end
    else
        for _,stop in ipairs(plan and plan.stops or {}) do stops[#stops+1]=stop end
        if plan and plan.destination then stops[#stops+1]=plan.destination end
    end
    local previous,segments
    segments={}
    for _,stop in ipairs(stops) do
        if stop and stop.x and stop.y and stop.x>=0 and stop.x<=100 and stop.y>=0 and stop.y<=100
            and self:ResolveLocation(stop.location)==mapID then
            if previous then segments[#segments+1]={from=previous,to=stop} end
            previous=stop
        else previous=nil end
    end
    return segments
end
function Maps:HideSegments()
    for _,line in ipairs(self.lines or {}) do line:Hide() end
end
function Maps:DrawSegments(plan,map,pinFrames)
    self:HideSegments()
    if not DQT:GetOption("travel.showSegments") or type(map.GetCanvas)~="function" then return end
    local canvas=map:GetCanvas()
    if not canvas or type(canvas.CreateLine)~="function" then return end
    self.lines=self.lines or {}
    local index=0
    for _,segment in ipairs(self:GetSegments(plan,map:GetMapID())) do
        local a,b=pinFrames[segment.from],pinFrames[segment.to]
        if a and b and a~=b then
            index=index+1
            local line=self.lines[index]
            if not line then
                local ok,created=pcall(canvas.CreateLine,canvas,nil,"ARTWORK")
                if not ok or not created then return end
                line=created; self.lines[index]=line
            end
            for _,method in ipairs({"SetColorTexture","SetThickness","SetStartPoint","SetEndPoint","Show"}) do
                if type(line[method])~="function" then return end
            end
            line:SetColorTexture(0.8,0.75,0.3,0.7)
            line:SetThickness(2)
            line:SetStartPoint("CENTER",a,0,0)
            line:SetEndPoint("CENTER",b,0,0)
            line:Show()
        end
    end
end
function Maps:ClearWaypoint()
    if self.waypoint and self.waypointOwner and type(self.waypointOwner.RemoveWaypoint)=="function" then
        pcall(self.waypointOwner.RemoveWaypoint,self.waypointOwner,self.waypoint)
    end
    self.waypoint,self.waypointOwner,self.waypointKey=nil,nil,nil
end
function Maps:FocusWaypoint(stop,mapID)
    if self.trackedKey then return end
    if not DQT:GetOption("travel.useTomTom") then return end
    if self.waypointKey==stop.key then return end
    self:ClearWaypoint()
    if not stop.x or not stop.y or type(TomTom)~="table" or type(TomTom.AddWaypoint)~="function" or type(TomTom.RemoveWaypoint)~="function" then return end
    local ok,uid=pcall(TomTom.AddWaypoint,TomTom,mapID,stop.x/100,stop.y/100,
        {title="DQT: "..stop.location.name,from="DungeonQuestTrackerForever",persistent=false,crazy=true})
    if ok and uid then self.waypoint,self.waypointOwner,self.waypointKey=uid,TomTom,stop.key end
end

local function MatchesWaypoint(point, target)
    if not point or not target or point.uiMapID~=target.mapID or not point.position then return false end
    local position=point.position
    local x,y
    if type(position.GetXY)=="function" then x,y=position:GetXY()
    else x,y=position.x,position.y end
    return type(x)=="number" and type(y)=="number"
        and math.abs(x-target.x)<0.00001 and math.abs(y-target.y)<0.00001
end

function Maps:UpdateTrackerWaypoint(stop)
    if InCombatLockdown and InCombatLockdown() then return end
    local mapID=stop and stop.x and stop.y and self:ResolveLocation(stop.location)
    local x,y
    if mapID then x,y=stop.x/100,stop.y/100 end
    local tomtom=mapID and DQT:GetOption("travel.useTomTom") and type(TomTom)=="table"
        and type(TomTom.AddWaypoint)=="function" and type(TomTom.RemoveWaypoint)=="function" and TomTom
    local previous=self.trackerWaypoint
    if previous and previous.tomtom then
        if previous.tomtom==tomtom and previous.mapID==mapID and previous.x==x and previous.y==y and previous.key==stop.key then return end
        pcall(previous.tomtom.RemoveWaypoint,previous.tomtom,previous.uid)
        self.trackerWaypoint=nil
        previous=nil
    end
    local native=C_Map and C_Map.GetUserWaypoint and C_Map.SetUserWaypoint and C_Map.ClearUserWaypoint
        and C_Map.CanSetUserWaypointOnMap and UiMapPoint and UiMapPoint.CreateFromCoordinates
    local current=native and C_Map.GetUserWaypoint()
    if previous then
        if MatchesWaypoint(current,previous) then
            if not tomtom and previous.mapID==mapID and previous.x==x and previous.y==y then return end
            C_Map.ClearUserWaypoint()
            current=nil
        end
        self.trackerWaypoint=nil
    end
    if not mapID then return end
    local target={mapID=mapID,x=x,y=y,key=stop.key}
    if tomtom then
        local ok,uid=pcall(tomtom.AddWaypoint,tomtom,mapID,x,y,
            {title="DQT: "..stop.location.name,from="DungeonQuestTrackerForever",persistent=false,crazy=true})
        if ok and uid then
            target.uid,target.tomtom=uid,tomtom
            self.trackerWaypoint=target
            return
        end
    end
    if native and not current and C_Map.CanSetUserWaypointOnMap(mapID) then
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID,x,y))
        if MatchesWaypoint(C_Map.GetUserWaypoint(),target) then self.trackerWaypoint=target end
    end
end

function Maps:CreateTracker()
    local frame=CreateFrame("Frame",nil,UIParent)
    frame:SetFrameStrata("LOW")
    frame:SetSize(350,90)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart",frame.StartMoving)
    frame:SetScript("OnDragStop",function(window)
        window:StopMovingOrSizing()
        local x,y=window:GetCenter()
        local rootX,rootY=UIParent:GetCenter()
        if x and y and rootX and rootY and DQT.db then
            DQT.db.pickupTrackerPosition={x=x-rootX,y=y-rootY}
            window:ClearAllPoints()
            window:SetPoint("CENTER",UIParent,"CENTER",x-rootX,y-rootY)
        end
    end)
    local position=DQT.db and DQT.db.pickupTrackerPosition
    if type(position)=="table" and type(position.x)=="number" and type(position.y)=="number" then
        frame:SetPoint("CENTER",UIParent,"CENTER",position.x,position.y)
    else
        frame:SetPoint("RIGHT",UIParent,"RIGHT",-45,75)
    end
    local background=frame:CreateTexture(nil,"BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0,0,0,0.55)
    background:SetAlpha(0)
    local close=CreateFrame("Button",nil,frame,"UIPanelCloseButton")
    close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",3,4)
    close:SetScript("OnClick",function() Maps:TrackRoute(nil) end)
    frame.map=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
    frame.map:SetSize(46,20)
    frame.map:SetPoint("RIGHT",close,"LEFT",0,0)
    frame.map:SetText("Map")
    frame.map:SetScript("OnClick",function()
        if not Maps.trackerStop then return end
        Maps.key,Maps.startZone,Maps.plan=nil,nil,Maps.trackerPlan
        local ok,message=Maps:OpenStop(Maps.trackerStop)
        if not ok then DQT:Print(message) end
    end)
    local function FadeBackground(window,elapsed)
        local main=DQT.UI and DQT.UI.frame
        local covered=main and main:IsShown() and main:IsMouseOver()
        local target=window:IsMouseOver() and not covered and 1 or 0
        local alpha=background:GetAlpha()
        local step=elapsed/0.18
        alpha=target==1 and math.min(target,alpha+step) or math.max(target,alpha-step)
        background:SetAlpha(alpha)
        if alpha==target then window:SetScript("OnUpdate",nil) end
    end
    local function StartFade()
        frame:SetScript("OnUpdate",FadeBackground)
    end
    for _,region in ipairs({frame,close,frame.map}) do
        region:SetScript("OnEnter",StartFade)
        region:SetScript("OnLeave",StartFade)
    end
    frame:SetScript("OnShow",StartFade)
    frame:SetScript("OnHide",function(window)
        window:SetScript("OnUpdate",nil)
        background:SetAlpha(0)
    end)
    frame.title=frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
    frame.title:SetPoint("TOPLEFT",14,-10)
    frame.title:SetWidth(250)
    frame.title:SetJustifyH("LEFT")
    frame.steps=frame:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    frame.steps:SetWidth(322)
    frame.steps:SetJustifyH("LEFT")
    frame.steps:SetSpacing(4)
    self.tracker=frame
end

function Maps:RefreshTracker(plan)
    if not self.trackedKey then return end
    local combined=#self.trackedKeys>1
    local sharesMapRoute=not self.key or (not combined and self.key==self.trackedKey and not self.startZone)
    plan=plan or (sharesMapRoute and self.plan) or DQT:GetDungeonPickupRoute(self.trackedKeys)
    if sharesMapRoute then self.plan=plan end
    local lines,nextStop,nextLine={},nil,nil
    local function Add(stop,action)
        if not nextStop then nextStop,nextLine=stop,#lines+1 end
        local location=stop.location
        local coords=stop.x and stop.y and string.format(" (%.1f, %.1f)",stop.x,stop.y) or ""
        lines[#lines+1]=action..": "..location.name.." · "..location.zone..coords
    end
    for _,step in ipairs(plan.itinerary or {}) do
        if step.stop then
            Add(step.stop,step.kind=="turnIn" and "Turn in" or step.kind=="entrance" and "Entrance" or "Pick up")
        elseif step.toZone then
            local edge=step.route and step.route.edges[1]
            local destination=edge and (edge.toLabel or (DQT.Travel.nodes[edge.to] or {}).name)
            lines[#lines+1]=destination and (edge.mode..": "..destination) or ("Travel to "..step.toZone)
        end
        if nextStop and #lines>=3 then break end
    end
    if not plan.itinerary then
        for _,stop in ipairs(plan.stops) do
            Add(stop,"Pick up")
            if #lines==3 then break end
        end
        if #lines<3 and plan.destination then Add(plan.destination,"Entrance") end
    end
    if #lines==0 then lines[1]="No actionable stops." end
    if nextStop then
        local names={}
        for _,entry in ipairs(nextStop.quests or {}) do names[#names+1]=entry.quest.name end
        if #names>0 then table.insert(lines,nextLine+1,table.concat(names,", ")) end
    end
    self.tracker.title:SetText(combined and ("Pickups · "..#self.trackedKeys.." dungeons") or (plan.dungeon.name.." pickups"))
    self.tracker.steps:SetText(table.concat(lines,"\n"))
    local headerHeight=math.max(36,20+self.tracker.title:GetStringHeight())
    self.tracker.steps:ClearAllPoints()
    self.tracker.steps:SetPoint("TOPLEFT",14,-headerHeight)
    self.tracker:SetHeight(headerHeight+self.tracker.steps:GetStringHeight()+14)
    self.trackerPlan,self.trackerStop=plan,nextStop
    self.tracker.map:SetEnabled(nextStop~=nil and self:ResolveLocation(nextStop.location)~=nil)
    self:UpdateTrackerWaypoint(nextStop)
end

function Maps:TrackRoute(key,plan)
    self.trackedKeys=type(key)=="table" and key or {key}
    self.trackedKey=self.trackedKeys[1]
    if DQT.UI and DQT.UI.UpdatePickupSelections then DQT.UI:UpdatePickupSelections() end
    if not self.key then
        self.plan=plan
        if self.provider and WorldMapFrame:IsShown() then self.provider:RefreshAllData() end
    end
    if not self.trackedKey then
        self.trackerPlan,self.trackerStop=nil,nil
        if self.tracker then self.tracker:Hide() end
        self:UpdateTrackerWaypoint()
        return
    end
    self:ClearWaypoint()
    if not self.tracker then self:CreateTracker() end
    self.tracker:Show()
    self:RefreshTracker(plan)
end

function Maps:IsTracking(key)
    for _,selected in ipairs(self.trackedKeys or {}) do
        if selected==key then return true end
    end
    return false
end

function Maps:ToggleTrackedDungeon(key)
    local selected={}
    for _,existing in ipairs(self.trackedKeys or {}) do
        if existing~=key then selected[#selected+1]=existing end
    end
    if not self:IsTracking(key) then selected[#selected+1]=key end
    self.key,self.startZone,self.focusKey=nil,nil,nil
    self:TrackRoute(selected)
end

function Maps:QueueRouteRefresh()
    local function MapVisible()
        return self.provider and WorldMapFrame:IsShown()
    end
    if self.pending or (not self.trackedKey and not (self.key and MapVisible())) then return end
    local function Refresh()
        self.pending=nil
        self:RefreshTracker()
        if MapVisible() then self.provider:RefreshAllData() end
    end
    if C_Timer and C_Timer.After then
        self.pending=true
        C_Timer.After(0.2,Refresh)
    else
        Refresh()
    end
end
function Maps:CheckWaypoint(plan)
    if not self.waypointKey then return end
    for _,pin in ipairs(self:GetPins(plan)) do
        for _,entry in ipairs(pin.stops) do if entry.stop.key==self.waypointKey then return end end
    end
    self:ClearWaypoint()
end

DQTFPickupPinMixin = {}
function DQTFPickupPinMixin:CheckMouseButtonPassthrough()
    -- MapCanvas calls this for each acquisition. These hover-only pins do not
    -- need the default implementation's protected SetPassThroughButtons call.
end
function DQTFPickupPinMixin:OnLoad()
    self:SetSize(26,26)
    self:SetScalingLimits(1,1,1)
    if self.SetMouseClickEnabled then self:SetMouseClickEnabled(false) end
    self.icon=self:CreateTexture(nil,"BACKGROUND")
    self.icon:SetAllPoints()
    self.icon:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    self.icon:SetVertexColor(0.08,0.35,0.25,1)
    self.number=self:CreateFontString(nil,"OVERLAY","GameFontNormal")
    self.number:SetPoint("CENTER")
end
function DQTFPickupPinMixin:OnAcquired(pin)
    self.pickup=pin
    local marker=pin.entrance and "E" or pin.turnIn and "T" or pin.transport and "F" or tostring(pin.index)
    self.number:SetText(marker .. (#pin.stops>1 and "+" or ""))
    local focused=false
    for _,entry in ipairs(pin.stops) do if entry.stop.key and entry.stop.key==Maps.focusKey then focused=true end end
    if self.icon then self.icon:SetVertexColor(focused and 0.8 or 0.08,pin.entrance and 0.6 or 0.35,0.25,1) end
    self:SetPosition(pin.x,pin.y)
end
function DQTFPickupPinMixin:OnMouseEnter()
    local pin=self.pickup
    if not pin or not GameTooltip then return end
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    GameTooltip:SetText(pin.entrance and "Dungeon entrance approach" or pin.turnIn and "Prerequisite turn-in" or pin.transport and "Recorded transport approach" or (#pin.stops > 1 and "Pickups at this location" or "Quest pickup"))
    GameTooltip:AddLine(pin.stop.location.zone,0.8,0.8,0.8,true)
    for _, pickup in ipairs(pin.stops) do
        GameTooltip:AddLine(" ")
        local prefix=pickup.stop.kind=="entrance" and "Entrance: " or pickup.stop.kind=="turnIn" and "Turn in: " or pickup.stop.kind=="transport" and "Transport approach: " or "Stop "..pickup.index..": "
        GameTooltip:AddLine(prefix .. pickup.stop.location.name,1,1,1,true)
        for _, entry in ipairs(pickup.stop.quests) do
            GameTooltip:AddLine("  " .. (entry.preparation and "Preparation: " or "") .. entry.quest.name,1,0.82,0,true)
        end
        if pickup.stop.location.note then GameTooltip:AddLine(pickup.stop.location.note,0.7,0.7,0.7,true) end
    end
    GameTooltip:AddLine("Recorded location; verify in-game",0.7,0.7,0.7)
    GameTooltip:Show()
end
function DQTFPickupPinMixin:OnMouseLeave()
    if GameTooltip then GameTooltip:Hide() end
end

function Maps:Attach()
    if self.provider then return true end
    local map=WorldMapFrame
    if not map or not map.AddDataProvider or not map.AcquirePin or not map.RemoveAllPinsByTemplate or not MapCanvasDataProviderMixin or not MapCanvasPinMixin or not CreateFromMixins then return false end
    local provider=CreateFromMixins(MapCanvasDataProviderMixin)
    function provider:RemoveAllData() self:GetMap():RemoveAllPinsByTemplate(template); Maps:HideSegments() end
    function provider:RefreshAllData()
        self:RemoveAllData()
        local key=Maps.key or (Maps.trackedKey and Maps.trackedKeys)
        if key and not Maps.plan then Maps.plan=DQT:GetDungeonPickupRoute(key,Maps.startZone) end
        local plan=Maps.plan
        Maps:CheckWaypoint(plan)
        local pinFrames={}
        for _, pin in ipairs(Maps:GetPins(plan,self:GetMap():GetMapID())) do
            local frame=self:GetMap():AcquirePin(template,pin)
            for _,entry in ipairs(pin.stops) do pinFrames[entry.stop]=frame end
        end
        Maps:DrawSegments(plan,self:GetMap(),pinFrames)
    end
    function provider:OnShow() self:RefreshAllData() end
    function provider:OnHide() Maps:HideSegments() end
    function provider:OnMapChanged() self:RefreshAllData() end
    map:AddDataProvider(provider)
    self.provider=provider
    return true
end

function Maps:SetRoute(plan)
    self.plan=plan
    self.key=plan.key
    self.startZone=nil
    if not plan.automaticStart then self.startZone=plan.startZone end
    self:CheckWaypoint(plan)
    if self:Attach() and WorldMapFrame:IsShown() then self.provider:RefreshAllData() end
end

function Maps:InvalidateRoute()
    self.plan=nil
    self:QueueRouteRefresh()
end

function Maps:ClearRoute()
    self.plan=nil
    self.key,self.startZone=nil,nil
    self.focusKey=nil
    self:ClearWaypoint()
    self:HideSegments()
    if self.provider then self.provider:RemoveAllData() end
end

function Maps:OpenStop(stop)
    if InCombatLockdown and InCombatLockdown() then return false,"Open the pickup map after combat." end
    local id=self:ResolveLocation(stop.location)
    -- Use the ordinary UI entry point, not restricted C_Map.OpenWorldMap.
    if not OpenWorldMap and UIParentLoadAddOn then UIParentLoadAddOn("Blizzard_WorldMap") end
    if not id or not OpenWorldMap then return false,"No supported map found for this pickup zone." end
    OpenWorldMap(id)
    self.focusKey=stop.key
    if not self:Attach() then return false,"Map pins are unavailable in this client; recorded locations remain in the list." end
    self.provider:RefreshAllData()
    self:FocusWaypoint(stop,id)
    return true
end

if CreateFrame then
    local events=CreateFrame("Frame")
    events:RegisterEvent("ADDON_LOADED")
    events:RegisterEvent("QUEST_LOG_UPDATE")
    events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    events:RegisterEvent("ZONE_CHANGED")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterEvent("PLAYER_LOGOUT")
    events:RegisterEvent("PLAYER_LEVEL_UP")
    events:SetScript("OnEvent",function(_,event)
        if event == "ADDON_LOADED" then Maps:Attach(); return end
        if event == "PLAYER_LOGOUT" then
            if Maps.trackerWaypoint then Maps:UpdateTrackerWaypoint() end
            return
        end
        if event == "PLAYER_REGEN_ENABLED" then
            if Maps.trackedKey or Maps.trackerWaypoint then Maps:UpdateTrackerWaypoint(Maps.trackerStop) end
            return
        end
        Maps:InvalidateRoute()
        if event == "ZONE_CHANGED_NEW_AREA" and DQT.UI and DQT.UI.currentView == "pickups" then
            DQT.UI:RefreshCurrentDungeon()
        end
    end)
end
