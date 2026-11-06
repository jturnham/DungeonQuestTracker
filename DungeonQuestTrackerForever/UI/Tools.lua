local _,DQT=...
local UI,Safe,L=DQT.UI,DQT.SafeOptional,DQT.L
function UI:ApplyWindowPreferences()
    local scale=(DQT:GetOption("display.scale") or 100)/100
    for _,frame in ipairs({self.frame or false,self.utility or false,self.xpRecords or false}) do
        if frame then
            local fit=scale
            local sw,sh=Safe(UIParent.GetWidth,UIParent),Safe(UIParent.GetHeight,UIParent)
            local width,height=Safe(frame.GetWidth,frame),Safe(frame.GetHeight,frame)
            if type(sw)=="number" and type(sh)=="number" and type(width)=="number" and type(height)=="number" and width>0 and height>0 then
                fit=math.max(0.5,math.min(fit,(sw-24)/width,(sh-24)/height))
            end
            Safe(frame.SetScale,frame,fit); Safe(frame.SetClampedToScreen,frame,true)
        end
    end
end
local function Restore(frame,position)
    if not frame then return end
    frame:ClearAllPoints()
    local x=type(position)=="table" and position.x
    local y=type(position)=="table" and position.y
    if type(x)=="number" and type(y)=="number" and x==x and y==y and math.abs(x)<10000 and math.abs(y)<10000 then
        frame:SetPoint("CENTER",UIParent,"CENTER",x,y)
    else frame:SetPoint("CENTER") end
    Safe(frame.SetClampedToScreen,frame,true)
end
function UI:SaveWindowPosition()
    if not self.frame or not DQT.db then return end
    local x,y=Safe(self.frame.GetCenter,self.frame)
    local px,py=Safe(UIParent.GetCenter,UIParent)
    local scale=Safe(self.frame.GetScale,self.frame) or 1
    if type(x)=="number" and type(y)=="number" and type(px)=="number" and type(py)=="number" then
        DQT.db.windowPosition={x=x-px/scale,y=y-py/scale}
    end
end
function UI:ResetWindow()
    DQT.db.windowPosition=nil
    Restore(self.frame)
end
function UI:ResetLootPosition()
    DQT.db.lootReminders=DQT.db.lootReminders or {}
    DQT.db.lootReminders.position=nil
    if DQT.lootReminderFrame then
        DQT.lootReminderFrame:ClearAllPoints()
        DQT.lootReminderFrame:SetPoint("TOP",UIParent,"TOP",0,-150)
    end
end
function UI:ShowUtility(title,text,actions,kind)
    local frame=self.utility
    if not frame then
        frame=CreateFrame("Frame","DungeonQuestTrackerForeverTools",UIParent,"BasicFrameTemplateWithInset")
        if type(UISpecialFrames)=="table" then table.insert(UISpecialFrames,"DungeonQuestTrackerForeverTools") end
        frame:SetPoint("CENTER")
        frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart",frame.StartMoving)
        frame:SetScript("OnDragStop",frame.StopMovingOrSizing)
        frame:SetScript("OnHide",function() if DQT.Notifications.waiting then DQT.Notifications:Queue() end end)
        frame:SetFrameStrata("DIALOG")
        frame.title=frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
        frame.title:SetPoint("TOPLEFT",12,-6)
        frame.scroll=CreateFrame("ScrollFrame",nil,frame,"UIPanelScrollFrameTemplate")
        frame.scroll:SetPoint("TOPLEFT",16,-38)
        frame.text=CreateFrame("EditBox",nil,frame.scroll)
        frame.text:SetMultiLine(true); frame.text:SetAutoFocus(false)
        frame.text:SetFontObject("ChatFontNormal"); frame.text:SetMaxLetters(64000)
        frame.text:SetScript("OnTextChanged",function(self) self:SetHeight(math.max(frame.scroll:GetHeight(),self:GetStringHeight()+20)) end)
        frame.text:SetScript("OnEscapePressed",function(self) self:ClearFocus(); frame:Hide() end)
        frame.scroll:SetScrollChild(frame.text)
        frame.buttons={}
        self.utility=frame
    end
    for _,button in ipairs(frame.buttons) do button:Hide() end
    if frame.inputs then for _,input in ipairs(frame.inputs) do input:Hide(); input.label:Hide() end end
    frame.kind=kind
    frame.title:SetText(L[title])
    local compact=self:IsCompact()
    local width=compact and 460 or 680
    frame:SetSize(width,compact and 390 or 500)
    frame.title:SetWidth(width-52)
    frame.text:SetWidth(width-54)
    local all={{label="Copy text",run=function() frame.text:SetFocus(); frame.text:HighlightText() end}}
    for _,action in ipairs(actions or {}) do all[#all+1]=action end
    local rows=math.ceil(#all/3)
    frame.actionRows=rows
    frame.scroll:ClearAllPoints()
    frame.scroll:SetPoint("TOPLEFT",16,-38)
    frame.scroll:SetPoint("BOTTOMRIGHT",-34,18+rows*30)
    for index,action in ipairs(all) do
        local button=frame.buttons[index]
        if not button then button=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate"); frame.buttons[index]=button end
        button:SetSize((width-48)/3,24)
        button:ClearAllPoints()
        button:SetPoint("BOTTOMLEFT",16+((index-1)%3)*((width-48)/3+8),16+math.floor((index-1)/3)*30)
        button:SetText(L[action.label]); button:SetScript("OnClick",action.run); button:Show()
    end
    frame.text:SetText(L[text])
    frame.text:ClearFocus()
    frame.scroll:SetVerticalScroll(0)
    self:ApplyWindowPreferences()
    frame:Show()
    return frame
end
function UI:ShowTools()
    self:ShowUtility("Tools", "Choose a tool below. Reports are previewed locally and submitted manually.\n\nFavorites are toggled with the + / Fav button on dungeon cards. Profiles copy presentation and route preferences only. Notifications are opt-in and can be suppressed for this session.",{
        {label="Profiles",run=function() UI:ShowProfiles() end},
        {label="Bug report",run=function() UI:ShowBugReport() end},
        {label="Why hidden?",run=function() UI:ShowFilterReasons() end},
        {label="Party readiness",run=function() UI:ShowPartyReadiness(UI.currentDungeonKey) end},
        {label="Reset window",run=function() UI:ResetWindow() end},
        {label="Reset loot alert",run=function() UI:ResetLootPosition() end},
        {label="XP records",run=function() UI:ShowXPRecords() end},
        {label="Mute notices",run=function() DQT.Notifications:Suppress(); UI:ShowTools() end},
    })
end
function UI:ShowProfiles()
    local function Name() return UI.utility.inputs[1]:GetText():match("^%s*(.-)%s*$") end
    local function Action(method)
        if not DQT[method](DQT,Name()) then DQT:Print("Profile action rejected: use a unique name (1-32 letters/numbers/spaces), an existing profile, or a non-active profile for deletion.") end
        UI:ShowProfiles()
    end
    local frame=self:ShowUtility("Profiles",DQT:ProfileSummary(),{
        {label="Create copy",run=function() Action("CreateProfile") end},
        {label="Use profile",run=function() Action("UseProfile") end},
        {label="Delete profile",run=function() Action("DeleteProfile") end},
        {label="Tools",run=function() UI:ShowTools() end},
    })
    self:UtilityInputs(frame,{{label="Profile name",value=""}})
end
function UI:UtilityInputs(frame,fields)
    frame.inputs=frame.inputs or {}
    for index,field in ipairs(fields) do
        local input=frame.inputs[index]
        if not input then
            input=CreateFrame("EditBox",nil,frame,"InputBoxTemplate")
            input:SetAutoFocus(false); input:SetMaxLetters(300)
            input.label=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            input.label:SetJustifyH("LEFT")
            input:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
            input:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
            input:SetScript("OnTabPressed",function(self)
                local nextInput=frame.inputs[index%#fields+1]
                if nextInput then self:ClearFocus(); nextInput:SetFocus() end
            end)
            frame.inputs[index]=input
        end
        input.label:ClearAllPoints(); input.label:SetPoint("TOPLEFT",16,-38-(index-1)*32)
        input.label:SetWidth(100); input.label:SetText(L[field.label]); input.label:Show()
        input:SetSize(frame:GetWidth()-145,24)
        input:ClearAllPoints(); input:SetPoint("TOPLEFT",125,-34-(index-1)*32)
        input:SetText(field.value or ""); input:Show()
    end
    frame.scroll:ClearAllPoints()
    frame.scroll:SetPoint("TOPLEFT",16,-40-#fields*32)
    local rows=frame.actionRows
    frame.scroll:SetPoint("BOTTOMRIGHT",-34,18+rows*30)
end
function UI:ShowBugReport(id)
    local expected,actual="",""
    local function Update()
        expected,actual=UI.utility.inputs[1]:GetText(),UI.utility.inputs[2]:GetText()
        UI.utility.text:SetText(DQT:BuildBugReport(id,expected,actual))
    end
    local frame=self:ShowUtility("Bug report",DQT:BuildBugReport(id),{{label="Update preview",run=Update},{label="Tools",run=function() UI:ShowTools() end}})
    self:UtilityInputs(frame,{{label="Expected",value=expected},{label="Actual",value=actual}})
end
function UI:ShowPartyReadiness(key)
    self.partyReadinessKey=key
    self:ShowUtility("Party readiness",DQT:PartyReadiness(key),{
        {label="Check party",run=function() if key then DQT:RequestPartyDungeonStatus(key) end; UI:ShowPartyReadiness(key) end},
        {label="Refresh",run=function() UI:ShowPartyReadiness(key) end},
        {label="Checklist",run=function() if key then DQT:OpenDungeon(key); UI.utility:Hide() end end},
    },"party")
end
function UI:RefreshUtility()
    if self.utility and self.utility:IsShown() and self.utility.kind=="party" then self:ShowPartyReadiness(self.partyReadinessKey) end
end
function UI:ShowFilterReasons()
    local context=DQT:PrepareQuestScan(DQT:GetPlayerContext())
    local lines={"Current filter exclusions (search temporarily bypasses dungeon visibility).", "Favorites do not bypass filters. Ready/tracked quest protection follows Options.",""}
    for _,key in ipairs(DQT:GetOrderedDungeonKeys()) do
        local status=DQT:GetDisplayDungeonStatus(key,context)
        local visible,reasons=DQT:ShouldShowDungeon(status,context)
        if not visible or status.hidden>0 then
            lines[#lines+1]=status.dungeon.name..": "..(visible and "dungeon visible" or table.concat(reasons,", "))
            for _,excluded in ipairs(status.exclusions) do lines[#lines+1]="  "..excluded.questID..": "..table.concat(excluded.reasons,", ") end
        end
    end
    self:ShowUtility("Why hidden?",table.concat(lines,"\n"),{
        {label="Reset filters",run=function() DQT:ResetFilters(); UI:ShowFilterReasons() end},
        {label="Find selected",run=function()
            if UI.currentDungeonKey then UI:Create(); UI.frame.search:SetText(UI.currentDungeonKey); UI:ShowDungeonList(); UI.utility:Hide() end
        end},
        {label="Options",run=function() UI:ShowOptions(); UI.utility:Hide() end},
    })
end
function UI:ShowPreparation(key)
    local status=DQT:GetDungeonQuestStatus(key,true,true,DQT:PrepareQuestScan(DQT:GetPlayerContext()))
    if not status then return end
    local lines={status.dungeon.name,"Known quest preparation only; catalogue details may be provisional.",""}
    for _,row in ipairs(status.quests) do
        if row.state~="completed" and row.state~="unavailable" then lines[#lines+1]=row.quest.name..": "..row.state.." | "..(row.reason or "") end
    end
    self:ShowUtility("Dungeon preparation",table.concat(lines,"\n"),{
        {label="Checklist",run=function() DQT:OpenDungeon(key); UI.utility:Hide() end},
        {label="Mute notices",run=function() DQT.Notifications:Suppress(); UI.utility:Hide() end},
    })
end
function UI:ShowChainNotice(ids)
    local lines={"Newly available known chain quests. Optional referrals are labelled; availability still depends on the client.",""}
    for index=1,math.min(30,#ids) do
        local quest=DQT.quests[ids[index]]
        lines[#lines+1]=quest.name.." ("..ids[index]..")"..(quest.breadcrumbOnly and " [optional referral]" or "")
    end
    if #ids>30 then lines[#lines+1]="Additional quests available; review your checklists." end
    self:ShowUtility("Quest chains available",table.concat(lines,"\n"),{
        {label="Checklist",run=function() DQT:OpenDungeon(DQT.quests[ids[1]].dungeon); UI.utility:Hide() end},
        {label="Mute notices",run=function() DQT.Notifications:Suppress(); UI.utility:Hide() end},
    })
end
-- Resolution/UI-scale changes recover saved windows without touching global UI scale.
local events=CreateFrame("Frame")
for _,event in ipairs({"DISPLAY_SIZE_CHANGED","UI_SCALE_CHANGED"}) do Safe(events.RegisterEvent,events,event) end
events:SetScript("OnEvent",function() UI:ApplyWindowPreferences(); Restore(UI.frame,DQT.db and DQT.db.windowPosition) end)
UI.RestoreWindow=function(self) Restore(self.frame,DQT.db and DQT.db.windowPosition) end
