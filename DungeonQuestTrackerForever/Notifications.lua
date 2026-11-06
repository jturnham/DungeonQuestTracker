local _,DQT=...
local Safe=DQT.SafeOptional
local Notices={suppressed=false,baseline=nil,announced={},entrySeen={}}
DQT.Notifications=Notices
local function Busy()
    return Safe(InCombatLockdown) or Safe(UnitAffectingCombat,"player") or (StaticPopup_Visible and Safe(StaticPopup_Visible))
        or (QuestFrame and Safe(QuestFrame.IsShown,QuestFrame)) or (GossipFrame and Safe(GossipFrame.IsShown,GossipFrame))
        or (DQT.UI and DQT.UI.utility and DQT.UI.utility:IsShown())
        or (DQT.UI and DQT.UI.xpRecords and DQT.UI.xpRecords:IsShown())
end
function Notices:InstanceKey()
    local inside,kind=Safe(IsInInstance)
    if not inside or kind~="party" then return end
    local name=Safe(GetInstanceInfo)
    if type(name)~="string" then return end
    local match
    for key,dungeon in pairs(DQT.dungeons) do
        if dungeon.name==name or (name=="Deadmines" and dungeon.name=="The Deadmines") then
            if match then return end
            match=key
        end
    end
    -- Ambiguous names (e.g. Scarlet Monastery wings) must remain unresolved.
    return match
end
function Notices:ChainSnapshot()
    local context=DQT:PrepareQuestScan(DQT:GetPlayerContext())
    local result={}
    for id,quest in pairs(DQT.quests) do
        if quest.followUpOf or #(quest.prerequisites or {})>0 then result[id]=DQT:GetQuestState(id,quest,context)=="missing" end
    end
    return result
end
function Notices:Process()
    if not DQT.db or self.suppressed then return end
    if Busy() then self.waiting=true; return end
    self.waiting=nil
    if DQT:GetOption("notifications.chains") then
        local snapshot=self:ChainSnapshot()
        local unlocked={}
        if self.baseline then
            for id,available in pairs(snapshot) do
                if available and self.baseline[id]==false and not self.announced[id] then
                    unlocked[#unlocked+1]=id
                end
            end
        end
        self.baseline=snapshot
        table.sort(unlocked)
        if #unlocked>0 then
            for _,id in ipairs(unlocked) do self.announced[id]=true end
            DQT.UI:ShowChainNotice(unlocked)
            -- Keep a pending entry until this notification is closed.
            if self.entryPending then self.waiting=true end
            return
        end
    end
    if DQT:GetOption("notifications.entry") and self.entryPending then
        local key=self:InstanceKey()
        self.entryPending=nil
        if key and not self.entrySeen[key] then
            self.entrySeen[key]=true
            DQT.UI:ShowPreparation(key)
        end
    end
end
function Notices:Queue(entry)
    if not DQT.db or self.suppressed or not (DQT:GetOption("notifications.entry") or DQT:GetOption("notifications.chains")) then return end
    if entry then self.entryPending=true end
    if self.elapsed then return end
    self.elapsed=0
    self.events:SetScript("OnUpdate",function(frame,elapsed)
        Notices.elapsed=Notices.elapsed+elapsed
        if Notices.elapsed<0.25 then return end
        frame:SetScript("OnUpdate",nil)
        Notices.elapsed=nil
        Notices:Process()
    end)
end
function Notices:OptionsChanged()
    local enabled=DQT:GetOption("notifications.chains")
    if enabled~=self.chainsEnabled then self.baseline=nil; self.chainsEnabled=enabled end
    if not enabled then self.baseline=nil end
    if not DQT:GetOption("notifications.entry") then self.entryPending=nil end
    self:Queue(true)
end
function Notices:Suppress()
    self.suppressed=true
    self.entryPending,self.waiting,self.elapsed=nil,nil,nil
    self.events:SetScript("OnUpdate",nil)
end
local frame=CreateFrame("Frame")
Notices.events=frame
for _,event in ipairs({"PLAYER_ENTERING_WORLD","ZONE_CHANGED_NEW_AREA","QUEST_LOG_UPDATE","PLAYER_LEVEL_UP","PLAYER_REGEN_ENABLED","GOSSIP_CLOSED","QUEST_FINISHED"}) do Safe(frame.RegisterEvent,frame,event) end
frame:SetScript("OnEvent",function(_,event)
    Notices:Queue(event=="PLAYER_ENTERING_WORLD" or event=="ZONE_CHANGED_NEW_AREA")
end)
