local _,DQT=...
local UI=DQT.UI
function UI:ShowXPRecords(export)
    local frame=self.xpRecords
    if not frame then
        frame=CreateFrame("Frame","DungeonQuestTrackerForeverXPRecords",UIParent,"BasicFrameTemplateWithInset")
        if type(UISpecialFrames)=="table" then table.insert(UISpecialFrames,"DungeonQuestTrackerForeverXPRecords") end
        frame:SetPoint("CENTER")
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart",function(self) self:StartMoving() end)
        frame:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
        frame:SetFrameStrata("DIALOG")
        frame.title=frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
        frame.title:SetPoint("TOPLEFT",14,-6)
        frame.title:SetText(DQT.L["XP Records | Manual export"])
        frame.scroll=CreateFrame("ScrollFrame",nil,frame,"UIPanelScrollFrameTemplate")
        frame.scroll:SetPoint("TOPLEFT",16,-40)
        frame.scroll:SetPoint("BOTTOMRIGHT",-34,52)
        frame.text=CreateFrame("EditBox",nil,frame.scroll)
        frame.text:SetMultiLine(true)
        frame.text:SetAutoFocus(false)
        frame.text:SetFontObject("ChatFontNormal")
        frame.text:SetMaxLetters(160000)
        frame.text:SetScript("OnEscapePressed",function(self) self:ClearFocus(); frame:Hide() end)
        frame.text:SetScript("OnTextChanged",function(self)
            self:SetHeight(math.max(frame.scroll:GetHeight(),self:GetStringHeight()+20))
        end)
        frame.scroll:SetScrollChild(frame.text)
        local function Button(label,x,callback)
            local button=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
            button:SetSize(104,24)
            button:SetPoint("BOTTOMLEFT",16+x,16)
            button:SetText(label)
            button:SetScript("OnClick",callback)
        end
        Button("Summary",0,function() UI:ShowXPRecords(false) end)
        Button("Copy export",112,function() UI:ShowXPRecords(true) end)
        Button("Clear records",224,function()
            if not StaticPopupDialogs or type(StaticPopup_Show)~="function" then
                DQT:Print("To delete local observations: /dqt xp clear confirm")
                return
            end
            StaticPopupDialogs.DQT_CLEAR_XP={text="Delete all local XP observations?",button1=YES or "Yes",button2=NO or "No",
                OnAccept=function() DQT.XPRecorder:Clear(); UI:ShowXPRecords(false) end,
                timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3}
            StaticPopup_Show("DQT_CLEAR_XP")
        end)
        self.xpRecords=frame
    end
    local compact=self:IsCompact()
    if self.ApplyWindowPreferences then self:ApplyWindowPreferences() end
    frame:SetSize(compact and 420 or 620,compact and 350 or 470)
    frame.text:SetWidth(compact and 366 or 566)
    frame.text:SetText(export and DQT.XPRecorder:Export() or DQT.XPRecorder:Summary())
    frame.scroll:SetVerticalScroll(0)
    frame:Show()
    if export then frame.text:SetFocus(); frame.text:HighlightText() else frame.text:ClearFocus() end
end
