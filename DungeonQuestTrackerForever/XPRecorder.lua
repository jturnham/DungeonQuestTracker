local _,DQT=...
local Recorder={limit=500,retention=90*86400,pending={},seen={}}
DQT.XPRecorder=Recorder
local columns={"questID","build","addonVersion","capturedAt","levelBefore","levelAtEvent","xpBefore","xpAtEvent","xpMaxBefore","eventXP","displayedXP","modifiers"}
Recorder.columns=columns
local function Safe(fn,...)
    if type(fn)~="function" then return end
    local ok,a,b=pcall(fn,...)
    if ok then return a,b end
end
local function Integer(value,min,max)
    return type(value)=="number" and value==value and value>=min and value<=max and value==math.floor(value)
end
local function Number(value,min,max) return Integer(value,min,max) and value or -1 end
local function Clock() return Number(Safe(time),0,4102444800) end
function Recorder:Valid(row)
    if type(row)~="table" or not Integer(row.questID,1,10000000) or not DQT.quests[row.questID] then return false end
    if not Integer(row.build,1,10000000) and row.build~=-1 then return false end
    if type(row.addonVersion)~="string" or #row.addonVersion>24 or not row.addonVersion:match("^%d+%.%d+%.%d+$") then return false end
    if not Integer(row.capturedAt,-1,4102444800) or row.modifiers~="unknown" then return false end
    for _,key in ipairs({"levelBefore","levelAtEvent"}) do
        if row[key]~=-1 and not Integer(row[key],1,100) then return false end
    end
    for _,key in ipairs({"xpBefore","xpAtEvent","xpMaxBefore","displayedXP"}) do
        if not Integer(row[key],-1,10000000) then return false end
    end
    return Integer(row.eventXP,0,10000000)
end
function Recorder:Records()
    if not DQT.db then return {} end
    local records,clean=DQT.db.xpObservations,{}
    local now=Clock()
    if type(records)=="table" then
        -- Inspect only a bounded saved array, even if a local file was edited.
        for i=1,math.min(#records,self.limit) do
            local row=records[i]
            if self:Valid(row) and (now<0 or row.capturedAt<0 or (row.capturedAt<=now+86400 and now-row.capturedAt<=self.retention)) then
                local copy={}
                for _,key in ipairs(columns) do copy[key]=row[key] end
                clean[#clean+1]=copy
            end
        end
    end
    DQT.db.xpObservations=clean
    return clean
end
function Recorder:Clear()
    if DQT.db then DQT.db.xpObservations={} end
    self.pending,self.seen={},{}
end
function Recorder:CapturePanel()
    self.pending={}
    if not DQT:GetOption("xpRecorder.enabled") then return end
    local id=Safe(GetQuestID)
    if not Integer(id,1,10000000) or not DQT.quests[id] then return end
    self.pending[id]={at=Number(Safe(GetTime),0,1000000000),level=Number(Safe(UnitLevel,"player"),1,100),
        xp=Number(Safe(UnitXP,"player"),0,10000000),max=Number(Safe(UnitXPMax,"player"),0,10000000),
        displayed=Number(Safe(GetRewardXP),0,10000000)}
end
function Recorder:TurnedIn(id,xp)
    if not DQT.db or not DQT:GetOption("xpRecorder.enabled") then self.pending={}; return end
    if not Integer(id,1,10000000) or not DQT.quests[id] or not Integer(xp,0,10000000) then return end
    -- Non-repeatable dungeon captures are deduplicated per quest per session.
    if self.seen[id] then return end
    local before=self.pending[id]
    self.pending={}
    local now=Number(Safe(GetTime),0,1000000000)
    if before and (now<0 or before.at<0 or now<before.at or now-before.at>300) then before=nil end
    local _,build=Safe(GetBuildInfo)
    local row={questID=id,build=Number(tonumber(build),1,10000000),addonVersion=DQT.version,capturedAt=Clock(),
        levelBefore=before and before.level or -1,levelAtEvent=Number(Safe(UnitLevel,"player"),1,100),
        xpBefore=before and before.xp or -1,xpAtEvent=Number(Safe(UnitXP,"player"),0,10000000),
        xpMaxBefore=before and before.max or -1,eventXP=xp,displayedXP=before and before.displayed or -1,modifiers="unknown"}
    if not self:Valid(row) then return end
    local records=self:Records()
    if #records>=self.limit then table.remove(records,1) end
    records[#records+1]=row
    self.seen[id]=true
end
function Recorder:Export()
    local lines={"DQT-XP-OBSERVATIONS\t1",table.concat(columns,"\t")}
    for _,row in ipairs(self:Records()) do
        local values={}
        for _,key in ipairs(columns) do values[#values+1]=tostring(row[key]) end
        lines[#lines+1]=table.concat(values,"\t")
    end
    return table.concat(lines,"\n")
end
function Recorder:Summary()
    local records=self:Records()
    local lines={#records.." / "..self.limit.." local XP observations | recording "..(DQT:GetOption("xpRecorder.enabled") and "ON" or "OFF"),
        "Retained for 90 days when timestamps are available. No uploads or planner changes.",
        "Modifiers are unknown. Event XP is not a verified base reward; XP at the event may precede the actual XP update.",
        "Export includes only IDs, versions/builds, timestamps, level/XP context and reward values. No character/account/realm names.",""}
    for i=#records,1,-1 do
        local row=records[i]
        local quest=DQT.quests[row.questID]
        local known,source=DQT:GetQuestRewardXP(quest)
        lines[#lines+1]=quest.name.." ("..row.questID..") | build "..row.build.." | level before "..row.levelBefore
        local reference=DQT:IsQuestRewardXPKnown(quest) and tostring(known) or "unknown"
        lines[#lines+1]="Event: "..row.eventXP.." XP | panel: "..row.displayedXP.." | bundled reference: "..reference.." ("..source..")"
        lines[#lines+1]="Raw comparisons only; level scaling, modifiers and patch changes require review.\n"
    end
    return table.concat(lines,"\n")
end
local events=CreateFrame("Frame")
Recorder.events=events
for _,event in ipairs({"QUEST_COMPLETE","QUEST_TURNED_IN","QUEST_FINISHED"}) do Safe(events.RegisterEvent,events,event) end
events:SetScript("OnEvent",function(_,event,...)
    if event=="QUEST_COMPLETE" then Recorder:CapturePanel()
    elseif event=="QUEST_TURNED_IN" then Recorder:TurnedIn(...)
    else Recorder.pending={} end
end)
