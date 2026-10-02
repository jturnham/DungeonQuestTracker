local _, DQT = ...

DQT.UI = DQT.UI or {}
local UI = DQT.UI

local stateColors = {
    completed = "|cff55ff55Completed|r",
    ready = "|cff00ccffReady|r",
    active = "|cffffff55In Progress|r",
    missing = "|cffff9955Missing|r",
    locked = "|cffaaaaaaLocked|r",
    unavailable = "|cff777777Unavailable|r",
}

local collapsedHeight = 32
local expandedHeight = 104
local rowGap = 8
local contentWidth = 690
local viewportHeight = 470
local stateIcons = {
    completed = "Interface\\RaidFrame\\ReadyCheck-Ready",
    ready = "Interface\\GossipFrame\\ActiveQuestIcon",
    active = "Interface\\Icons\\INV_Misc_Book_09",
    missing = "Interface\\GossipFrame\\AvailableQuestIcon",
    locked = "Interface\\Icons\\INV_Misc_Lockbox_01",
    unavailable = "Interface\\RaidFrame\\ReadyCheck-NotReady",
}

local function AddTooltip(widget, title, body)
    widget:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(type(title) == "function" and title() or title)
        local text = type(body) == "function" and body() or body
        if text and text ~= "" then GameTooltip:AddLine(text, 1, 1, 1, true) end
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
end
UI.AddTooltip = AddTooltip

local function WrapText(text)
    if text.SetWordWrap then text:SetWordWrap(true) end
    if text.SetNonSpaceWrap then text:SetNonSpaceWrap(true) end
end

local function CreateButton(parent, text, width)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 120, 24)
    button:SetText(text)
    return button
end

local function FormatLocation(location)
    if not location then return "Unknown" end
    local parts = { location.name or "Unknown", location.zone or "Unknown zone" }
    if location.subzone then table.insert(parts, location.subzone) end
    if location.coordinates then table.insert(parts, location.coordinates) end
    return table.concat(parts, ", ")
end

local function QuestIsExpanded(questID)
    UI.expandedQuests = UI.expandedQuests or {}
    return UI.expandedQuests[questID] == true
end

local function ApplyCardBackdrop(frame)
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.bg:SetVertexColor(0.05, 0.05, 0.05, 0.92)

    frame.borderTop = frame:CreateTexture(nil, "OVERLAY")
    frame.borderTop:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.borderTop:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    frame.borderTop:SetHeight(1)
    frame.borderTop:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.borderTop:SetVertexColor(0.45, 0.38, 0.24, 0.95)

    frame.borderBottom = frame:CreateTexture(nil, "OVERLAY")
    frame.borderBottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    frame.borderBottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame.borderBottom:SetHeight(1)
    frame.borderBottom:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.borderBottom:SetVertexColor(0.45, 0.38, 0.24, 0.95)

    frame.borderLeft = frame:CreateTexture(nil, "OVERLAY")
    frame.borderLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.borderLeft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    frame.borderLeft:SetWidth(1)
    frame.borderLeft:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.borderLeft:SetVertexColor(0.45, 0.38, 0.24, 0.95)

    frame.borderRight = frame:CreateTexture(nil, "OVERLAY")
    frame.borderRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    frame.borderRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame.borderRight:SetWidth(1)
    frame.borderRight:SetTexture("Interface\\Buttons\\WHITE8X8")
    frame.borderRight:SetVertexColor(0.45, 0.38, 0.24, 0.95)
end

local function CreateRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(contentWidth, expandedHeight)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * (expandedHeight + rowGap)))
    row:RegisterForClicks("LeftButtonUp")

    row.toggle = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.toggle:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -2)
    row.toggle:SetWidth(18)
    row.toggle:SetJustifyH("LEFT")

    row.status = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("TOPLEFT", row.toggle, "TOPRIGHT", 3, 0)
    row.status:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 5, 0)
    row.status:SetWidth(88)
    row.status:SetJustifyH("LEFT")

    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title:SetPoint("TOPLEFT", row.status, "TOPRIGHT", 10, 0)
    row.title:SetWidth(490)
    row.title:SetJustifyH("LEFT")
    WrapText(row.title)

    row.share = CreateFrame("Button", nil, row)
    row.share:SetSize(24, 24)
    row.share:SetPoint("TOPRIGHT", row, "TOPRIGHT", -4, 2)
    row.share:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    row.share:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    row.share:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    AddTooltip(row.share, "Share quest", function() return row.shareReason or "" end)

    row.detail = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.detail:SetPoint("TOPLEFT", row, "TOPLEFT", 22, -32)
    row.detail:SetWidth(contentWidth - 30)
    row.detail:SetJustifyH("LEFT")
    WrapText(row.detail)

    row.reason = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.reason:SetPoint("TOPLEFT", row.detail, "BOTTOMLEFT", 0, -6)
    row.reason:SetWidth(contentWidth - 30)
    row.reason:SetJustifyH("LEFT")
    WrapText(row.reason)

    row.party = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.party:SetPoint("TOPLEFT", row.reason, "BOTTOMLEFT", 0, -6)
    row.party:SetWidth(contentWidth - 30)
    row.party:SetJustifyH("LEFT")
    WrapText(row.party)

    AddTooltip(row, function() return row.fullTitle or "Quest" end, function() return row.tooltipText or "" end)

    return row
end

local function CreateTurnInRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(690, 56)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * 62))

    row.rank = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.rank:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -2)
    row.rank:SetWidth(28)
    row.rank:SetJustifyH("LEFT")

    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title:SetPoint("TOPLEFT", row.rank, "TOPRIGHT", 10, 0)
    row.title:SetWidth(620)
    row.title:SetJustifyH("LEFT")
    WrapText(row.title)

    row.detail = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.detail:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -5)
    row.detail:SetWidth(620)
    row.detail:SetJustifyH("LEFT")
    WrapText(row.detail)
    row:EnableMouse(true)
    AddTooltip(row, function() return row.tooltipTitle or "Turn-in" end, function() return row.tooltipText or "" end)

    return row
end

local function CreateDungeonCard(parent, index)
    local card = CreateFrame("Button", nil, parent)
    card:SetSize(contentWidth, 124)
    card:RegisterForClicks("LeftButtonUp")
    ApplyCardBackdrop(card)

    card.art = card:CreateTexture(nil, "ARTWORK")
    card.art:SetPoint("TOPLEFT", card, "TOPLEFT", 4, -4)
    card.art:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -4, 4)
    card.art:SetTexCoord(0.08, 0.92, 0.15, 0.82)
    card.art:SetAlpha(0.48)

    card.shade = card:CreateTexture(nil, "BORDER")
    card.shade:SetTexture("Interface\\Buttons\\WHITE8X8")
    card.shade:SetVertexColor(0, 0, 0, 0.45)
    card.shade:SetPoint("TOPLEFT", card, "TOPLEFT", 4, -4)
    card.shade:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -4, 4)

    card.name = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    card.name:SetPoint("TOPLEFT", card, "TOPLEFT", 18, -16)
    card.name:SetWidth(650)
    card.name:SetJustifyH("LEFT")
    WrapText(card.name)

    card.meta = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.meta:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -8)
    card.meta:SetWidth(650)
    card.meta:SetJustifyH("LEFT")
    WrapText(card.meta)

    card.summary = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    card.summary:SetPoint("TOPLEFT", card.meta, "BOTTOMLEFT", 0, -7)
    card.summary:SetWidth(650)
    card.summary:SetJustifyH("LEFT")
    WrapText(card.summary)

    card.party = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.party:SetPoint("TOPLEFT", card.summary, "BOTTOMLEFT", 0, -7)
    card.party:SetWidth(650)
    card.party:SetJustifyH("LEFT")
    WrapText(card.party)
    AddTooltip(card, function() return card.dungeonName or "Dungeon" end, function() return card.notes or "" end)

    return card
end

function UI:Create()
    if self.frame then return end

    local frame = CreateFrame("Frame", "DungeonQuestTrackerFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(780, 620)
    frame:SetPoint("CENTER")
    frame:Hide()
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 6, 0)
    frame.title:SetText("DungeonQuestTracker")

    frame.version = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.version:SetJustifyH("RIGHT")
    frame.version:SetText("v" .. tostring(DQT.version or "0.2.0"))
    frame.optionsButton = CreateFrame("Button", nil, frame)
    frame.optionsButton:SetSize(16, 16)
    frame.optionsButton:SetNormalTexture("Interface\\Icons\\INV_Misc_Gear_01")
    frame.optionsButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    frame.optionsButton:SetScript("OnClick", function() UI:ShowOptions() end)
    AddTooltip(frame.optionsButton, "Options")
    frame.compactButton = CreateFrame("Button", nil, frame)
    frame.compactButton:SetSize(24, 24)
    if frame.CloseButton then
        frame.compactButton:SetPoint("RIGHT", frame.CloseButton, "LEFT", -2, 0)
    else
        frame.compactButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -2)
    end
    frame.optionsButton:SetPoint("RIGHT", frame.compactButton, "LEFT", -6, 0)
    frame.version:SetPoint("RIGHT", frame.optionsButton, "LEFT", -8, 0)
    frame.compactButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    frame.compactButton:SetScript("OnClick", function() DQT:SetOption("display.compact", not DQT:GetOption("display.compact")) end)
    AddTooltip(frame.compactButton, function() return DQT:GetOption("display.compact") and "Switch to full mode" or "Switch to compact mode" end)

    frame.nav = CreateFrame("Frame", nil, frame)
    frame.nav:SetSize(730, 30)
    frame.nav:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -38)

    frame.primaryButton = CreateButton(frame.nav, "Dungeons", 118)
    frame.primaryButton:SetPoint("LEFT", frame.nav, "LEFT", 0, 0)
    frame.primaryButton:SetScript("OnClick", function()
        if UI.currentView == "options" then UI:CloseOptions()
        elseif UI.currentView == "list" then
            if UI.currentDungeonKey then DQT:OpenDungeon(UI.currentDungeonKey) end
        else
            UI:ShowDungeonList()
        end
    end)

    frame.turnInsButton = CreateButton(frame.nav, "Turn-ins", 118)
    frame.turnInsButton:SetPoint("LEFT", frame.primaryButton, "RIGHT", 8, 0)
    frame.turnInsButton:SetScript("OnClick", function() UI:ShowTurnIns() end)

    frame.partyButton = CreateButton(frame.nav, "Check Party", 118)
    frame.partyButton:SetPoint("LEFT", frame.turnInsButton, "RIGHT", 8, 0)
    frame.partyButton:SetScript("OnClick", function()
        if UI.currentDungeonKey then DQT:RequestPartyDungeonStatus(UI.currentDungeonKey) end
    end)

    frame.shareButton = CreateButton(frame.nav, "Share All", 118)
    frame.shareButton:SetPoint("LEFT", frame.partyButton, "RIGHT", 8, 0)
    frame.shareButton:SetScript("OnClick", function()
        if UI.currentDungeonKey then UI:RequestShareAll(UI.currentDungeonKey) end
    end)
    AddTooltip(frame.partyButton, "Check Party", "Requests this dungeon's quest status from party members running DQT. Checks have a five-second cooldown; responses expire after two minutes.")
    AddTooltip(frame.shareButton, "Share All", "Requests sharing of active or ready quests the client marks shareable. Requires a group; drop, object and prerequisite quests may not be shareable.")

    frame.searchLabel = frame.nav:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.searchLabel:SetPoint("LEFT", frame.nav, "LEFT", 370, 0)
    frame.searchLabel:SetText("Search")
    frame.search = CreateFrame("EditBox", nil, frame.nav, "InputBoxTemplate")
    frame.search:SetSize(235, 24)
    frame.search:SetPoint("LEFT", frame.searchLabel, "RIGHT", 10, 0)
    frame.search:SetAutoFocus(false)
    frame.search:SetMaxLetters(100)
    frame.search:SetScript("OnTextChanged", function(self)
        UI.searchText = self:GetText() or ""
        if UI.currentView == "list" then UI:ShowDungeonList() end
    end)
    frame.search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    frame.search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    frame.clearSearch = CreateFrame("Button", nil, frame.nav, "UIPanelCloseButton")
    frame.clearSearch:SetSize(24, 24)
    frame.clearSearch:SetPoint("LEFT", frame.search, "RIGHT", 4, 0)
    frame.clearSearch:SetScript("OnClick", function() frame.search:SetText(""); frame.search:ClearFocus() end)
    AddTooltip(frame.clearSearch, "Clear search")

    frame.syncOption = CreateFrame("CheckButton", nil, frame.nav, "UICheckButtonTemplate")
    frame.syncOption:SetSize(24, 24)
    frame.syncOption:SetPoint("LEFT", frame.nav, "LEFT", 140, 0)
    frame.syncLabel = frame.nav:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.syncLabel:SetPoint("LEFT", frame.syncOption, "RIGHT", 2, 0)
    frame.syncLabel:SetText("Party data sync")
    frame.syncOption:SetScript("OnClick", function(self) DQT:SetQuestDataSync(self:GetChecked() and "on" or "off") end)
    AddTooltip(frame.syncOption, "Party quest-data sync", "Opt in to exchange missing quest records with grouped DQT users through Check Party. Party-supplied XP is not used for ranking.")

    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.subtitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -76)
    frame.subtitle:SetWidth(720)
    frame.subtitle:SetJustifyH("LEFT")
    WrapText(frame.subtitle)

    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetSize(720, 470)
    frame.content:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -112)

    frame.checklistScroll = CreateFrame("ScrollFrame", "DungeonQuestTrackerChecklistScrollFrame", frame, "UIPanelScrollFrameTemplate")
    frame.checklistScroll:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, 0)
    frame.checklistScroll:SetPoint("BOTTOMRIGHT", frame.content, "BOTTOMRIGHT", -28, 0)
    frame.checklistScroll:Hide()
    frame.checklistContent = CreateFrame("Frame", nil, frame.checklistScroll)
    frame.checklistContent:SetSize(690, 470)
    frame.checklistScroll:SetScrollChild(frame.checklistContent)

    frame.emptyMessage = frame.checklistContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.emptyMessage:SetPoint("TOPLEFT", frame.checklistContent, "TOPLEFT", 0, -12)
    frame.emptyMessage:SetWidth(680)
    frame.emptyMessage:SetJustifyH("LEFT")
    frame.emptyMessage:Hide()

    frame.dungeonScroll = CreateFrame("ScrollFrame", "DungeonQuestTrackerDungeonScrollFrame", frame, "UIPanelScrollFrameTemplate")
    frame.dungeonScroll:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, 0)
    frame.dungeonScroll:SetPoint("BOTTOMRIGHT", frame.content, "BOTTOMRIGHT", -28, 0)
    frame.dungeonScroll:Hide()

    frame.dungeonContent = CreateFrame("Frame", nil, frame.dungeonScroll)
    frame.dungeonContent:SetSize(contentWidth, 470)
    frame.dungeonScroll:SetScrollChild(frame.dungeonContent)

    frame.turnInScroll = CreateFrame("ScrollFrame", "DungeonQuestTrackerTurnInScrollFrame", frame, "UIPanelScrollFrameTemplate")
    frame.turnInScroll:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, 0)
    frame.turnInScroll:SetPoint("BOTTOMRIGHT", frame.content, "BOTTOMRIGHT", -28, 0)
    frame.turnInScroll:Hide()

    frame.turnInContent = CreateFrame("Frame", nil, frame.turnInScroll)
    frame.turnInContent:SetSize(contentWidth, 470)
    frame.turnInScroll:SetScrollChild(frame.turnInContent)

    frame.listEmpty = frame.dungeonContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.listEmpty:SetPoint("TOPLEFT", frame.dungeonContent, "TOPLEFT", 12, -20)
    frame.listEmpty:SetWidth(650)
    frame.listEmpty:SetJustifyH("LEFT")
    WrapText(frame.listEmpty)
    frame.listEmpty:Hide()

    frame.rows = {}
    frame.dungeonCards = {}
    frame.turnInRows = {}
    frame.filterSummary = CreateFrame("Button", nil, frame)
    frame.filterSummary:SetSize(690, 20)
    frame.filterSummary:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 24, 8)
    frame.filterSummary.text = frame.filterSummary:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.filterSummary.text:SetAllPoints()
    frame.filterSummary.text:SetJustifyH("LEFT")
    frame.filterSummary:SetScript("OnClick", function() UI:ShowOptions() end)
    AddTooltip(frame.filterSummary, "Filters", function() return DQT:GetFilterSummary() end)

    self.frame = frame
end

function UI:IsCompact()
    return DQT:GetOption("display.compact") and self.currentView ~= "options"
end

function UI:ApplyLayout()
    local frame, compact = self.frame, self:IsCompact()
    contentWidth = compact and 430 or 690
    viewportHeight = compact and 350 or 470
    frame:SetSize(compact and 520 or 780, compact and 500 or 620)
    frame.nav:SetWidth(compact and 470 or 730)
    frame.content:SetSize(contentWidth+30, viewportHeight)
    frame.subtitle:SetWidth(contentWidth+30)
    frame.emptyMessage:SetWidth(contentWidth-10)
    frame.listEmpty:SetWidth(contentWidth-24)
    frame.filterSummary:SetWidth(contentWidth)
    for _, child in ipairs({frame.checklistContent, frame.dungeonContent, frame.turnInContent}) do child:SetWidth(contentWidth) end
    for _, button in ipairs({frame.primaryButton, frame.turnInsButton, frame.partyButton, frame.shareButton}) do button:SetWidth(compact and 100 or 118) end
    frame.searchLabel:ClearAllPoints()
    frame.searchLabel:SetPoint("LEFT", frame.nav, "LEFT", compact and 140 or 370, 0)
    frame.search:SetWidth(compact and 215 or 235)
    local texture = DQT:GetOption("display.compact") and "UI-Panel-BiggerButton" or "UI-Panel-SmallerButton"
    frame.compactButton:SetNormalTexture("Interface\\Buttons\\" .. texture .. "-Up")
    frame.compactButton:SetPushedTexture("Interface\\Buttons\\" .. texture .. "-Down")
end

function UI:FitContent()
    local top = math.max(112, 76+self.frame.subtitle:GetStringHeight()+14)
    viewportHeight = math.max(120, self.frame:GetHeight()-top-38)
    self.frame.content:ClearAllPoints()
    self.frame.content:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 24, -top)
    self.frame.content:SetHeight(viewportHeight)
end

function UI:UpdateNav()
    if not self.frame then return end
    self:ApplyLayout()
    local listView = self.currentView == "list"
    self.frame.filterSummary:SetShown(self.currentView ~= "options")
    self.frame.search:SetShown(listView)
    self.frame.searchLabel:SetShown(listView)
    self.frame.clearSearch:SetShown(listView)
    self.frame.syncOption:SetShown(listView and not self:IsCompact())
    self.frame.syncLabel:SetShown(listView and not self:IsCompact())
    self.frame.syncOption:SetChecked(DQT.db and DQT.db.partyDataSync or false)
    if not listView then self.frame.search:ClearFocus() end
    self.frame.primaryButton:ClearAllPoints()
    self.frame.turnInsButton:ClearAllPoints()
    if self.frame.partyButton then self.frame.partyButton:ClearAllPoints() end
    if self.frame.shareButton then self.frame.shareButton:ClearAllPoints() end

    if self.currentView == "list" then
        self.frame.primaryButton:Hide()
        self.frame.turnInsButton:SetPoint("LEFT", self.frame.nav, "LEFT", 0, 0)
        self.frame.turnInsButton:Enable()
        if self.frame.partyButton then self.frame.partyButton:Hide() end
        if self.frame.shareButton then self.frame.shareButton:Hide() end
    else
        self.frame.primaryButton:SetText("Back")
        self.frame.primaryButton:SetPoint("LEFT", self.frame.nav, "LEFT", 0, 0)
        self.frame.primaryButton:Show()
        self.frame.primaryButton:Enable()
        self.frame.turnInsButton:SetPoint("LEFT", self.frame.primaryButton, "RIGHT", 8, 0)
        self.frame.turnInsButton:Enable()
        if self.currentView == "checklist" then
            self.frame.partyButton:SetPoint("LEFT", self.frame.turnInsButton, "RIGHT", 8, 0)
            self.frame.partyButton:Show()
            self.frame.partyButton:Enable()
            self.frame.shareButton:SetPoint("LEFT", self.frame.partyButton, "RIGHT", 8, 0)
            self.frame.shareButton:Show()
            self.frame.shareButton:Enable()
        else
            if self.frame.partyButton then self.frame.partyButton:Hide() end
            if self.frame.shareButton then self.frame.shareButton:Hide() end
        end
    end
end
function UI:ClearRows()
    if not self.frame then return end
    self.frame.content:Show()
    self.frame.checklistScroll:Hide()
    self.frame.emptyMessage:Hide()
    self.frame.listEmpty:Hide()
    if self.frame.optionsScroll then self.frame.optionsScroll:Hide() end
    if self.frame.dungeonScroll then
        self.frame.dungeonScroll:Hide()
        self.frame.dungeonScroll:SetVerticalScroll(0)
    end
    if self.frame.turnInScroll then
        self.frame.turnInScroll:Hide()
        self.frame.turnInScroll:SetVerticalScroll(0)
    end
    for _, row in ipairs(self.frame.rows) do row:Hide() end
    for _, card in ipairs(self.frame.dungeonCards) do card:Hide() end
    for _, row in ipairs(self.frame.turnInRows) do row:Hide() end
end
function UI:PositionChecklistRows(status)
    local y = 0
    for index, questStatus in ipairs(status.quests or {}) do
        local row = self.frame.rows[index]
        if row then
            local compact = self:IsCompact()
            local expanded = not compact and QuestIsExpanded(questStatus.questID)
            local headerHeight = math.max(compact and 24 or collapsedHeight, row.title:GetStringHeight() + (compact and 8 or 12))
            local height = headerHeight
            row.detail:ClearAllPoints()
            row.detail:SetPoint("TOPLEFT", row, "TOPLEFT", 22, -headerHeight)
            if expanded then
                height = math.max(expandedHeight, headerHeight + row.detail:GetStringHeight() + row.reason:GetStringHeight() + row.party:GetStringHeight() + 30)
            end
            row:SetHeight(height)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", self.frame.checklistContent, "TOPLEFT", 0, -y)
            row.detail:SetShown(expanded)
            row.reason:SetShown(expanded)
            if row.party then row.party:SetShown(expanded) end
            row.toggle:SetText(expanded and "-" or "+")
            y = y + height + (compact and 4 or rowGap)
        end
    end
    self.frame.checklistContent:SetHeight(math.max(viewportHeight, y))
    self.frame.checklistScroll:SetVerticalScroll(math.min(self.frame.checklistScroll:GetVerticalScroll(), math.max(0, y - viewportHeight)))
end

function UI:ShowDungeon(status)
    self:Create()
    self.currentDungeonKey = status.key
    self.currentView = "checklist"
    self.frame.checklistScroll:SetVerticalScroll(0)
    self:RenderChecklist(status)
end

function UI:RenderChecklist(status)
    self:ClearRows()
    self:UpdateNav()
    local counts = status.counts or {}
    self.frame.checklistScroll:Show()
    if #status.quests == 0 then
        local message = #(status.dungeon.quests or {}) == 0 and "No quests recorded yet." or "No quests recorded for your faction."
        if status.hidden and status.hidden > 0 then message = "No quests match your filters." end
        self.frame.emptyMessage:SetText(message .. "\n\n" .. (status.dungeon.notes or ""))
        self.frame.emptyMessage:Show()
    end
    self.frame.subtitle:SetText(string.format(
        "%s | %s | Done %d / %d | Ready %d | Active %d | Missing %d",
        status.dungeon.name,
        status.dungeon.recommendedLevel or "unknown",
        counts.completed or 0,
        #(status.quests or {}),
        counts.ready or 0,
        counts.active or 0,
        counts.missing or 0
    ))
    if self:IsCompact() then self.frame.subtitle:SetText(status.dungeon.name) end
    self:FitContent()
    self:UpdateFilterSummary(status.hidden or 0)

    for index, questStatus in ipairs(status.quests) do
        local row = self.frame.rows[index]
        if not row then
            row = CreateRow(self.frame.checklistContent, index)
            self.frame.rows[index] = row
        end

        local quest = questStatus.quest
        local statusText = stateColors[questStatus.state] or questStatus.stateReason or "Unknown"
        local prereqText = ""
        if quest.prerequisites and #quest.prerequisites > 0 then prereqText = " | Chain info available" end

        row.questID = questStatus.questID
        row.fullTitle = quest.name .. " (#" .. questStatus.questID .. ")"
        row.icon:SetTexture(stateIcons[questStatus.state] or stateIcons.missing)
        row.status:SetText(statusText)
        local compact = self:IsCompact()
        row:SetWidth(contentWidth)
        row.detail:SetWidth(contentWidth-30)
        row.reason:SetWidth(contentWidth-30)
        row.party:SetWidth(contentWidth-30)
        row.toggle:SetShown(not compact)
        row.icon:SetShown(not compact)
        row.status:SetShown(not compact)
        row.share:SetShown(not compact)
        row.title:ClearAllPoints()
        if compact then
            row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -2)
            row.title:SetWidth(contentWidth-8)
            row.title:SetText((statusText:match("^(|c%x%x%x%x%x%x%x%x)") or "") .. quest.name .. "|r")
        else
            row.title:SetPoint("TOPLEFT", row.status, "TOPRIGHT", 10, 0)
            row.title:SetWidth(490)
            row.title:SetText(string.format("%s (#%d)", quest.name, questStatus.questID))
        end
        row.detail:SetText("Pickup: " .. FormatLocation(quest.pickup) .. " | Turn in: " .. FormatLocation(quest.turnIn) .. prereqText)
        local chainNotes = {}
        for _, prereq in ipairs(quest.prerequisites or {}) do
            if prereq.note then table.insert(chainNotes, prereq.note) end
        end
        local reason = (questStatus.stateReason or "") .. " | " .. (quest.objectives or "")
        if quest.followUpOf then
            local parent = DQT:GetQuest(quest.followUpOf)
            reason = reason .. "\nDungeon follow-up: " .. (parent and parent.name or "Quest") .. " (#" .. quest.followUpOf .. ")."
        end
        if quest.partySupplied then reason = reason .. "\nParty supplied: " .. tostring(quest.source) .. " (v" .. tostring(quest.sourceVersion or "unknown") .. "); needs review, XP excluded."
        elseif quest.confidence == "needsReview" then reason = reason .. "\nBeta data: needs in-game verification." end
        if quest.verification and quest.verification.conflict then reason = reason .. "\nSource conflict: " .. quest.verification.conflict end
        if #chainNotes > 0 then reason = reason .. "\nChain: " .. table.concat(chainNotes, " ") end
        row.reason:SetText(reason)
        row.tooltipText = (questStatus.stateReason or "") .. "\nPickup: " .. FormatLocation(quest.pickup) .. "\nTurn in: " .. FormatLocation(quest.turnIn)
        if #chainNotes > 0 then row.tooltipText = row.tooltipText .. "\nChain: " .. table.concat(chainNotes, " ") end
        local canShare, shareReason = false, "Only active or ready quests can be shared."
        if questStatus.state == "active" or questStatus.state == "ready" then
            if DQT:IsGrouped() then
                canShare, shareReason = DQT:GetQuestShareState(questStatus.questID, quest.name)
            else shareReason = "Join a party before sharing quests." end
        end
        row.shareReason = shareReason
        row.share:SetEnabled(canShare)
        row.share:SetAlpha(canShare and 1 or 0.35)
        row.share:SetScript("OnClick", function()
            if not DQT:IsGrouped() then DQT:Print("Join a party before sharing quests."); return end
            local ok, result = DQT:ShareQuest(questStatus.questID, quest.name)
            DQT:Print(quest.name .. ": " .. tostring(result))
        end)
        if row.party then row.party:SetText(DQT:GetPartyQuestSummary(status.key, questStatus.questID)) end
        row:SetScript("OnClick", function()
            if UI:IsCompact() then return end
            UI.expandedQuests = UI.expandedQuests or {}
            UI.expandedQuests[questStatus.questID] = not UI.expandedQuests[questStatus.questID]
            UI:PositionChecklistRows(status)
        end)
        row:Show()
    end

    self:PositionChecklistRows(status)
    self.frame:Show()
end

function UI:ShowTurnIns(preserveScroll)
    self:Create()
    local scroll = preserveScroll and self.frame.turnInScroll:GetVerticalScroll() or 0
    self.currentView = "turnins"
    self:UpdateNav()
    self:ClearRows()
    self:UpdateNav()
    self.frame.content:Hide()
    self.frame.turnInScroll:Show()
    self.frame.turnInScroll:SetVerticalScroll(0)
    self.frame.filterSummary.text:SetText(DQT:GetOption("filters.ignoreGrayTurnIns") and "Turn-in filter: gray quests excluded" or "Turn-in filters: none")

    local turnIns = DQT:GetGlobalTurnInPriority() or { quests = {}, context = {}, xpToLevel = 0 }
    local context = turnIns.context or {}
    self.frame.subtitle:SetText(string.format(
        "All dungeon turn-ins | Level %s | XP %s/%s | To level %s",
        tostring(context.level or "?"),
        tostring(context.currentXp or 0),
        tostring(context.maxXp or 0),
        tostring(turnIns.xpToLevel or 0)
    ))
    if self:IsCompact() then self.frame.subtitle:SetText("Turn-ins | Level " .. tostring(context.level or "?") .. " | To level " .. tostring(turnIns.xpToLevel or 0)) end
    self:FitContent()

    if not turnIns.quests or #turnIns.quests == 0 then
        local row = self.frame.turnInRows[1]
        if not row then
            row = CreateTurnInRow(self.frame.turnInContent, 1)
            self.frame.turnInRows[1] = row
        end
        row.rank:SetText("-")
        row.title:SetText("No ready-to-turn-in dungeon quests detected yet.")
        row.detail:SetText("")
        row:SetWidth(contentWidth)
        row.title:SetWidth(self:IsCompact() and contentWidth-50 or 620)
        row.detail:SetShown(not self:IsCompact())
        row.tooltipTitle, row.tooltipText = "No ready turn-ins", ""
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", self.frame.turnInContent, "TOPLEFT", 0, 0)
        row:SetHeight(math.max(32, row.title:GetStringHeight()+12))
        row:Show()
        self.frame.turnInContent:SetHeight(viewportHeight)
        self.frame:Show()
        return
    end

    local y = 0
    for index, item in ipairs(turnIns.quests) do
        local row = self.frame.turnInRows[index]
        if not row then
            row = CreateTurnInRow(self.frame.turnInContent, index)
            self.frame.turnInRows[index] = row
        end

        local dingText = item.dings and " | levels you" or ""
        local riskText = ""
        if item.risk == "gray-next-level" then
            riskText = " | turns gray next level"
        elseif item.risk == "green-next-level" then
            riskText = " | turns green next level"
        elseif item.risk == "lower-next-level" then
            riskText = " | lower XP next level"
        end
        row.rank:SetText(tostring(index) .. ".")
        row.title:SetText(string.format("%s - %d XP%s%s", item.quest.name, item.effectiveXp or 0, dingText, riskText))
        local dungeonName = item.dungeon and item.dungeon.name or "Unknown dungeon"
        local lossText = ""
        if item.xpLossOnLevel and item.xpLossOnLevel > 0 then
            lossText = " | loses " .. tostring(item.xpLossOnLevel) .. " XP after level"
        end
        row.detail:SetText("[" .. dungeonName .. "] Turn in: " .. FormatLocation(item.quest.turnIn) .. " | Quest level " .. tostring(item.quest.questLevel or "?") .. " | " .. tostring(item.currentColor or "unknown") .. " now -> " .. tostring(item.nextColor or "unknown") .. " next" .. lossText .. " | XP source " .. tostring(item.xpSource or "unknown"))
        row.tooltipTitle = item.quest.name .. " - " .. tostring(item.effectiveXp or 0) .. " XP" .. dingText .. riskText
        row.tooltipText = "[" .. dungeonName .. "] Turn in: " .. FormatLocation(item.quest.turnIn) .. lossText .. " | XP source " .. tostring(item.xpSource or "unknown")
        local compact = self:IsCompact()
        row:SetWidth(contentWidth)
        row.title:SetWidth(compact and contentWidth-50 or 620)
        row.detail:SetWidth(compact and contentWidth-50 or 620)
        row.detail:SetShown(not compact)
        if compact then row.title:SetText(item.quest.name) end
        local height = compact and math.max(24, row.title:GetStringHeight()+8) or math.max(56, row.title:GetStringHeight() + row.detail:GetStringHeight() + 17)
        row:SetHeight(height)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", self.frame.turnInContent, "TOPLEFT", 0, -y)
        y = y + height + (compact and 4 or 8)
        row:Show()
    end

    self.frame.turnInContent:SetHeight(math.max(viewportHeight, y))
    self.frame.turnInScroll:SetVerticalScroll(math.min(scroll, math.max(0, y - viewportHeight)))
    self.frame:Show()
end
function UI:RefreshCurrentDungeon()
    if not self.frame or not self.frame:IsShown() then return end
    if self.currentView == "options" then self:RefreshOptions(); return end
    if self.currentView == "list" then self:ShowDungeonList(true); return end
    if self.currentView == "turnins" then self:ShowTurnIns(true); return end
    if not self.currentDungeonKey then return end
    local status = DQT:GetDisplayDungeonStatus(self.currentDungeonKey)
    if status then self:RenderChecklist(status) end
end

function UI:ShowDungeonList(preserveScroll)
    self:Create()
    local scroll = preserveScroll and self.frame.dungeonScroll:GetVerticalScroll() or 0
    self:ClearRows()
    self.currentView = "list"
    self:UpdateNav()
    self.frame.subtitle:SetText("Dungeons")
    self:FitContent()
    self.frame.content:Hide()
    self.frame.dungeonScroll:Show()
    self.frame.dungeonScroll:SetVerticalScroll(0)

    local y = 0
    local cardIndex, hidden = 0, 0
    local query = string.lower(self.searchText or ""):match("^%s*(.-)%s*$")
    for _, key in ipairs(DQT:GetOrderedDungeonKeys()) do
        local status = DQT:GetDisplayDungeonStatus(key)
        local dungeon = status and status.dungeon or DQT.dungeons[key]
        local matches = string.find(string.lower(dungeon.name .. " " .. key .. " " .. (dungeon.location or "")), query, 1, true)
        if status and DQT:ShouldShowDungeon(status) and matches then
            cardIndex = cardIndex + 1
            local counts = status.counts or {}
            local card = self.frame.dungeonCards[cardIndex]
            if not card then
                card = CreateDungeonCard(self.frame.dungeonContent, cardIndex)
                self.frame.dungeonCards[cardIndex] = card
            end

            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", self.frame.dungeonContent, "TOPLEFT", 0, -y)
            card.art:SetTexture(dungeon.art or "Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
            card.name:SetText(dungeon.name)
            card.dungeonName = dungeon.name
            card.notes = dungeon.notes
            card.meta:SetText(string.format("Level %s | %s | %s", tostring(dungeon.minLevel or "?"), dungeon.recommendedLevel or "unknown", dungeon.location or "location unknown"))
            card.summary:SetText(string.format("Ready %d | Active %d | Missing %d | Done %d / %d", counts.ready or 0, counts.active or 0, counts.missing or 0, counts.completed or 0, #(status.quests or {})))
            if #(dungeon.quests or {}) == 0 then card.summary:SetText("No quests recorded yet") end
            card.party:SetText(DQT:GetPartyDungeonSummary(key))
            local compact = self:IsCompact()
            card:SetWidth(contentWidth)
            for _, region in ipairs({card.bg, card.art, card.shade, card.borderTop, card.borderBottom, card.borderLeft, card.borderRight, card.meta, card.summary, card.party}) do region:SetShown(not compact) end
            card.name:ClearAllPoints()
            card.name:SetPoint("TOPLEFT", card, "TOPLEFT", compact and 0 or 18, compact and -4 or -16)
            card.name:SetWidth(compact and contentWidth-8 or 650)
            card.name:SetFontObject(compact and "GameFontNormal" or "GameFontNormalLarge")
            if compact then card.notes = card.meta:GetText() .. "\n" .. card.summary:GetText() .. "\n" .. card.party:GetText() .. "\n" .. (dungeon.notes or "") end
            local height = compact and math.max(28, card.name:GetStringHeight()+12) or math.max(124, card.name:GetStringHeight() + card.meta:GetStringHeight() + card.summary:GetStringHeight() + card.party:GetStringHeight() + 54)
            card:SetHeight(height)
            card:SetScript("OnClick", function() DQT:OpenDungeon(key) end)
            card:Show()
            y = y + height + (compact and 4 or 8)
        elseif matches then hidden = hidden+1
        end
    end

    self.frame.dungeonContent:SetHeight(math.max(viewportHeight, y))
    self.frame.dungeonScroll:SetVerticalScroll(math.min(scroll, math.max(0, y - viewportHeight)))
    if cardIndex == 0 then
        self.frame.listEmpty:SetText(query ~= "" and "No dungeons match your search and filters." or "No dungeons match your filters.")
        self.frame.listEmpty:Show()
    end
    self:UpdateFilterSummary(hidden, true)

    self.frame:Show()
end
function UI:Toggle()
    self:Create()
    if self.frame:IsShown() then self.frame:Hide(); return end
    self:ShowDungeonList()
end









