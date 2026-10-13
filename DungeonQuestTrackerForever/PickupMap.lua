local _, DQT = ...
local Maps = {cache={}}
DQT.PickupMap = Maps
local template = "DQTFPickupPinTemplate"
local aliases = { ["Stormwind City"]="Stormwind" }

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
    for index, stop in ipairs(plan and plan.stops or {}) do
        if stop.x and stop.y and stop.x >= 0 and stop.x <= 100 and stop.y >= 0 and stop.y <= 100 then
            local zone=stop.location.zone
            if zones[zone] == nil then zones[zone]=self:ResolveMap(zone) or false end
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
                else
                    pins[#pins+1] = {index=index,stop=stop,stops={entry},mapID=id,x=stop.x/100,y=stop.y/100}
                end
            end
        end
    end
    return pins
end

DQTFPickupPinMixin = {}
function DQTFPickupPinMixin:OnLoad()
    self:SetSize(26,26)
    self:SetScalingLimits(1,1,1)
    self.icon=self:CreateTexture(nil,"BACKGROUND")
    self.icon:SetAllPoints()
    self.icon:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    self.icon:SetVertexColor(0.08,0.35,0.25,1)
    self.number=self:CreateFontString(nil,"OVERLAY","GameFontNormal")
    self.number:SetPoint("CENTER")
end
function DQTFPickupPinMixin:OnAcquired(pin)
    self.pickup=pin
    self.number:SetText(tostring(pin.index) .. (#pin.stops > 1 and "+" or ""))
    self:SetPosition(pin.x,pin.y)
end
function DQTFPickupPinMixin:OnMouseEnter()
    local pin=self.pickup
    if not pin or not GameTooltip then return end
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    GameTooltip:SetText(#pin.stops > 1 and "Pickups at this location" or "Quest pickup")
    GameTooltip:AddLine(pin.stop.location.zone,0.8,0.8,0.8,true)
    for _, pickup in ipairs(pin.stops) do
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Stop " .. pickup.index .. ": " .. pickup.stop.location.name,1,1,1,true)
        for _, entry in ipairs(pickup.stop.quests) do
            GameTooltip:AddLine("  " .. (entry.preparation and "Preparation: " or "") .. entry.quest.name,1,0.82,0,true)
        end
    end
    GameTooltip:AddLine("Recorded beta location",0.7,0.7,0.7)
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
    function provider:RemoveAllData() self:GetMap():RemoveAllPinsByTemplate(template) end
    function provider:RefreshAllData()
        self:RemoveAllData()
        if Maps.key and not Maps.plan then Maps.plan=DQT:GetDungeonPickupRoute(Maps.key,Maps.startZone) end
        local plan=Maps.plan
        for _, pin in ipairs(Maps:GetPins(plan,self:GetMap():GetMapID())) do
            self:GetMap():AcquirePin(template,pin)
        end
    end
    function provider:OnShow() self:RefreshAllData() end
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
    if self:Attach() and WorldMapFrame:IsShown() then self.provider:RefreshAllData() end
end

function Maps:InvalidateRoute()
    self.plan=nil
end

function Maps:ClearRoute()
    self.plan=nil
    self.key,self.startZone=nil,nil
    if self.provider then self.provider:RemoveAllData() end
end

function Maps:OpenStop(stop)
    if InCombatLockdown and InCombatLockdown() then return false,"Open the pickup map after combat." end
    local id=self:ResolveMap(stop.location.zone)
    -- Use the ordinary UI entry point, not restricted C_Map.OpenWorldMap.
    if not OpenWorldMap and UIParentLoadAddOn then UIParentLoadAddOn("Blizzard_WorldMap") end
    if not id or not OpenWorldMap then return false,"No supported map found for this pickup zone." end
    OpenWorldMap(id)
    if not self:Attach() then return false,"Map pins are unavailable in this client; recorded locations remain in the list." end
    self.provider:RefreshAllData()
    return true
end

if CreateFrame then
    local events=CreateFrame("Frame")
    events:RegisterEvent("ADDON_LOADED")
    events:RegisterEvent("QUEST_LOG_UPDATE")
    events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    events:RegisterEvent("PLAYER_LEVEL_UP")
    events:RegisterEvent("PLAYER_XP_UPDATE")
    events:RegisterEvent("CHAT_MSG_ADDON")
    events:SetScript("OnEvent",function(_,event,prefix)
        if event == "ADDON_LOADED" then Maps:Attach(); return end
        if event == "CHAT_MSG_ADDON" and prefix ~= "DQT1" then return end
        Maps:InvalidateRoute()
        if event == "ZONE_CHANGED_NEW_AREA" and DQT.UI and DQT.UI.currentView == "pickups" then
            DQT.UI:RefreshCurrentDungeon()
        end
        if not Maps.key or not Maps.provider or not WorldMapFrame:IsShown() or Maps.pending then return end
        if C_Timer and C_Timer.After then
            Maps.pending=true
            C_Timer.After(0.2,function()
                Maps.pending=nil
                if WorldMapFrame:IsShown() then Maps.provider:RefreshAllData() end
            end)
        else Maps.provider:RefreshAllData() end
    end)
end
