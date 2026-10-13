local _, DQT = ...
local UI = DQT.UI

function UI:UpdateFilterSummary(hidden, dungeons)
    local summary = DQT:GetFilterSummary()
    local label = summary:match("^Default filters") and "Filters: default" or "Filters: customized"
    if hidden > 0 then label = label .. " | " .. hidden .. (dungeons and " dungeons hidden" or " quests hidden") end
    self.frame.filterSummary.text:SetText(label)
end
function UI:RefreshOptions()
    if not self.frame or not self.frame.optionControls then return end
    if self.currentView == "options" then
        self:UpdateNav()
        self:FitContent()
        self:LayoutOptions()
    end
    for _, control in ipairs(self.frame.optionControls) do
        local value = DQT:GetOption(control.option.key)
        if control.option.number then
            if not control:HasFocus() then control:SetText(tostring(value)) end
        else
            if control.option.invert then value = not value end
            control:SetChecked(value)
        end
    end
end
function UI:CreateOptions()
    if self.frame.optionsScroll then return end
    local frame = self.frame
    frame.optionsScroll = CreateFrame("ScrollFrame", "DungeonQuestTrackerForeverOptionsScrollFrame", frame, "UIPanelScrollFrameTemplate")
    frame.optionsScroll:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, 0)
    frame.optionsScroll:SetPoint("BOTTOMRIGHT", frame.content, "BOTTOMRIGHT", -28, 0)
    frame.optionsContent = CreateFrame("Frame", nil, frame.optionsScroll)
    frame.optionsContent:SetSize(690, 470)
    frame.optionsScroll:SetScrollChild(frame.optionsContent)
    frame.optionControls = {}
    frame.optionRows = {}
    local y = 0
    for _, option in ipairs(DQT.optionDefinitions) do
        if option.section then
            local title = frame.optionsContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            title:SetPoint("TOPLEFT", frame.optionsContent, "TOPLEFT", 0, -y-8)
            title:SetText(option.section)
            title:SetJustifyH("LEFT")
            frame.optionRows[#frame.optionRows+1] = {section=title}
            y=y+36
        else
            local row = CreateFrame("Frame", nil, frame.optionsContent)
            row:SetSize(680, 42)
            row:SetPoint("TOPLEFT", frame.optionsContent, "TOPLEFT", 0, -y)
            local control
            if option.number then
                control = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
                control:SetSize(54, 24)
                control:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -4)
                control:SetAutoFocus(false)
                control:SetNumeric(true)
                control:SetMaxLetters(2)
                local function Commit(self)
                    if not DQT:SetOption(option.key, self:GetText()) then self:SetText(tostring(DQT:GetOption(option.key))) end
                    self:ClearFocus()
                    self:SetText(tostring(DQT:GetOption(option.key)))
                end
                control:SetScript("OnEnterPressed", Commit)
                control:SetScript("OnEditFocusLost", function(self)
                    DQT:SetOption(option.key, self:GetText())
                    self:SetText(tostring(DQT:GetOption(option.key)))
                end)
                control:SetScript("OnEscapePressed", function(self)
                    self:SetText(tostring(DQT:GetOption(option.key))); self:ClearFocus()
                end)
            else
                control = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
                control:SetSize(24, 24)
                control:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -2)
                local function Toggle(self)
                    local value = self:GetChecked() and true or false
                    if option.invert then value = not value end
                    DQT:SetOption(option.key, value)
                end
                control:SetScript("OnClick", Toggle)
                row:EnableMouse(true)
                row:SetScript("OnMouseUp", function(_, button)
                    if button == "LeftButton" then control:SetChecked(not control:GetChecked()); Toggle(control) end
                end)
            end
            control.option = option
            frame.optionControls[#frame.optionControls+1] = control
            local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            label:SetPoint("TOPLEFT", row, "TOPLEFT", 30, -6)
            label:SetWidth(option.number and 560 or 640)
            label:SetJustifyH("LEFT")
            if label.SetWordWrap then label:SetWordWrap(true) end
            label:SetText(option.label)
            local entry = {row=row,label=label,control=control,option=option}
            frame.optionRows[#frame.optionRows+1] = entry
            if option.key == "lootReminders.enabled" then
                label:SetWidth(490)
                local preview = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                preview:SetSize(130, 24)
                preview:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -2)
                preview:SetText("Preview Alert")
                preview:SetScript("OnClick", function() DQT:PreviewQuestLootReminder() end)
                frame.lootReminderPreview = preview
                entry.preview = preview
            end
            if option.tip then UI.AddTooltip(control, option.label, option.tip) end
            y=y+42
        end
    end
    local resetFilters = CreateFrame("Button", nil, frame.optionsContent, "UIPanelButtonTemplate")
    resetFilters:SetSize(140, 24)
    resetFilters:SetPoint("TOPLEFT", frame.optionsContent, "TOPLEFT", 0, -y-12)
    resetFilters:SetText("Reset Filters")
    resetFilters:SetScript("OnClick", function() DQT:ResetFilters() end)
    local resetMinimap = CreateFrame("Button", nil, frame.optionsContent, "UIPanelButtonTemplate")
    resetMinimap:SetSize(170, 24)
    resetMinimap:SetPoint("LEFT", resetFilters, "RIGHT", 12, 0)
    resetMinimap:SetText("Reset Minimap Position")
    resetMinimap:SetScript("OnClick", function() DQT:ResetMinimapPosition() end)
    frame.resetFilters, frame.resetMinimap = resetFilters, resetMinimap
    frame.optionsContent:SetHeight(y+60)
end
function UI:LayoutOptions()
    local frame, compact = self.frame, self:IsCompact()
    local width = frame.checklistContent:GetWidth()
    frame.optionsContent:SetWidth(width)
    local y = 0
    for _, entry in ipairs(frame.optionRows) do
        if entry.section then
            entry.section:ClearAllPoints()
            entry.section:SetPoint("TOPLEFT",frame.optionsContent,"TOPLEFT",0,-y-6)
            entry.section:SetWidth(width-8)
            y = y + (compact and 28 or 34)
        else
            local row = entry.row
            row:SetWidth(width-8)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT",frame.optionsContent,"TOPLEFT",0,-y)
            local left = entry.option.number and 0 or 30
            local reserved = entry.preview and 154 or entry.option.number and 78 or 8
            entry.label:ClearAllPoints()
            entry.label:SetPoint("TOPLEFT",row,"TOPLEFT",left,-6)
            entry.label:SetWidth(width-8-left-reserved)
            local height = math.max(compact and 30 or 38,entry.label:GetStringHeight()+12)
            row:SetHeight(height)
            y = y + height
        end
    end
    frame.resetFilters:ClearAllPoints()
    frame.resetFilters:SetPoint("TOPLEFT",frame.optionsContent,"TOPLEFT",0,-y-12)
    frame.optionsContent:SetHeight(y+52)
    local maximum = math.max(0,frame.optionsContent:GetHeight()-frame.content:GetHeight())
    frame.optionsScroll:SetVerticalScroll(math.min(frame.optionsScroll:GetVerticalScroll(),maximum))
end
function UI:ShowOptions()
    self:Create()
    if self.currentView ~= "options" then self.optionsOrigin={view=self.currentView, key=self.currentDungeonKey} end
    self:ClearRows()
    self.currentView = "options"
    self:CreateOptions()
    self:UpdateNav()
    self.frame.content:Hide()
    self.frame.subtitle:SetText("Options")
    self:FitContent()
    self.frame.optionsScroll:Show()
    self:RefreshOptions()
    self.frame:Show()
end
function UI:CloseOptions()
    local origin = self.optionsOrigin or {}
    self.optionsOrigin = nil
    if origin.view == "checklist" and origin.key then DQT:OpenDungeon(origin.key)
    elseif origin.view == "turnins" then self:ShowTurnIns()
    elseif origin.view == "pickups" then self.currentDungeonKey=origin.key; self:ShowPickups()
    else self:ShowDungeonList() end
end
function UI:RequestShareAll(key)
    if not DQT:IsGrouped() then DQT:ShareDungeonQuests(key); return end
    if not DQT:GetOption("party.confirmShareAll") then DQT:ShareDungeonQuests(key); return end
    if not StaticPopupDialogs or type(StaticPopup_Show) ~= "function" then
        DQT:Print("Confirmation dialog unavailable; no quests shared. Use individual quest sharing or disable Share All confirmation in Options.")
        return
    end
    StaticPopupDialogs.DQT_CONFIRM_SHARE_ALL = StaticPopupDialogs.DQT_CONFIRM_SHARE_ALL or {
        text="Share all shareable quests for %s with your group?", button1=YES or "Yes", button2=NO or "No",
        OnAccept=function(_, dungeonKey) DQT:ShareDungeonQuests(dungeonKey) end,
        timeout=0, whileDead=true, hideOnEscape=true, preferredIndex=3,
    }
    local dungeon = DQT:GetDungeon(key)
    if dungeon then StaticPopup_Show("DQT_CONFIRM_SHARE_ALL", dungeon.name, nil, key) end
end
