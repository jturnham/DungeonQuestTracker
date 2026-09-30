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

local function CreateButton(parent, text, width)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 120, 24)
    button:SetText(text)
    return button
end

local function FormatLocation(location)
    if not location then return "Unknown" end
    local parts = { location.name, location.zone }
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
    row:SetSize(690, expandedHeight)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * (expandedHeight + rowGap)))
    row:RegisterForClicks("LeftButtonUp")

    row.toggle = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.toggle:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -2)
    row.toggle:SetWidth(18)
    row.toggle:SetJustifyH("LEFT")

    row.status = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.status:SetPoint("TOPLEFT", row.toggle, "TOPRIGHT", 4, 0)
    row.status:SetWidth(95)
    row.status:SetJustifyH("LEFT")

    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title:SetPoint("TOPLEFT", row.status, "TOPRIGHT", 10, 0)
    row.title:SetWidth(540)
    row.title:SetJustifyH("LEFT")

    row.detail = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.detail:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -7)
    row.detail:SetWidth(560)
    row.detail:SetJustifyH("LEFT")

    row.reason = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.reason:SetPoint("TOPLEFT", row.detail, "BOTTOMLEFT", 0, -6)
    row.reason:SetWidth(560)
    row.reason:SetJustifyH("LEFT")

    row.party = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.party:SetPoint("TOPLEFT", row.reason, "BOTTOMLEFT", 0, -6)
    row.party:SetWidth(560)
    row.party:SetJustifyH("LEFT")

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

    row.detail = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.detail:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -5)
    row.detail:SetWidth(620)
    row.detail:SetJustifyH("LEFT")

    return row
end

local function CreateDungeonCard(parent, index)
    local card = CreateFrame("Button", nil, parent)
    card:SetSize(690, 104)
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
    card.name:SetWidth(500)
    card.name:SetJustifyH("LEFT")

    card.meta = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    card.meta:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -8)
    card.meta:SetWidth(600)
    card.meta:SetJustifyH("LEFT")

    card.summary = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    card.summary:SetPoint("TOPLEFT", card.meta, "BOTTOMLEFT", 0, -7)
    card.summary:SetWidth(620)
    card.summary:SetJustifyH("LEFT")

    return card
end

function UI:Create()
    if self.frame then return end

    local frame = CreateFrame("Frame", "DungeonQuestTrackerFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(780, 620)
    frame:SetPoint("CENTER")
    frame:Hide()
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 6, 0)
    frame.title:SetText("DungeonQuestTracker")

    frame.version = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.version:SetPoint("RIGHT", frame.TitleBg, "RIGHT", -28, 0)
    frame.version:SetJustifyH("RIGHT")
    frame.version:SetText("v" .. tostring(DQT.version or "0.1.0"))

    frame.nav = CreateFrame("Frame", nil, frame)
    frame.nav:SetSize(730, 30)
    frame.nav:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -38)

    frame.primaryButton = CreateButton(frame.nav, "Dungeons", 118)
    frame.primaryButton:SetPoint("LEFT", frame.nav, "LEFT", 0, 0)
    frame.primaryButton:SetScript("OnClick", function()
        if UI.currentView == "list" then
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
        if UI.currentDungeonKey then DQT:ShareDungeonQuests(UI.currentDungeonKey) end
    end)

    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.subtitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -76)
    frame.subtitle:SetWidth(720)
    frame.subtitle:SetJustifyH("LEFT")

    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetSize(720, 470)
    frame.content:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -112)

    frame.dungeonScroll = CreateFrame("ScrollFrame", "DungeonQuestTrackerDungeonScrollFrame", frame, "UIPanelScrollFrameTemplate")
    frame.dungeonScroll:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, 0)
    frame.dungeonScroll:SetPoint("BOTTOMRIGHT", frame.content, "BOTTOMRIGHT", -28, 0)
    frame.dungeonScroll:Hide()

    frame.dungeonContent = CreateFrame("Frame", nil, frame.dungeonScroll)
    frame.dungeonContent:SetSize(660, 470)
    frame.dungeonScroll:SetScrollChild(frame.dungeonContent)

    frame.turnInScroll = CreateFrame("ScrollFrame", "DungeonQuestTrackerTurnInScrollFrame", frame, "UIPanelScrollFrameTemplate")
    frame.turnInScroll:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, 0)
    frame.turnInScroll:SetPoint("BOTTOMRIGHT", frame.content, "BOTTOMRIGHT", -28, 0)
    frame.turnInScroll:Hide()

    frame.turnInContent = CreateFrame("Frame", nil, frame.turnInScroll)
    frame.turnInContent:SetSize(660, 470)
    frame.turnInScroll:SetScrollChild(frame.turnInContent)

    frame.rows = {}
    frame.dungeonCards = {}
    frame.turnInRows = {}

    self.frame = frame
end

function UI:UpdateNav()
    if not self.frame then return end
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
            local expanded = QuestIsExpanded(questStatus.questID)
            local height = expanded and expandedHeight or collapsedHeight
            row:SetHeight(height)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", self.frame.content, "TOPLEFT", 0, -y)
            row.detail:SetShown(expanded)
            row.reason:SetShown(expanded)
            if row.party then row.party:SetShown(expanded) end
            row.toggle:SetText(expanded and "-" or "+")
            y = y + height + rowGap
        end
    end
end

function UI:ShowDungeon(status)
    self:Create()
    self.currentDungeonKey = status.key
    self.currentView = "checklist"
    self:RenderChecklist(status)
end

function UI:RenderChecklist(status)
    self:ClearRows()
    self:UpdateNav()
    local counts = status.counts or {}
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

    for index, questStatus in ipairs(status.quests) do
        local row = self.frame.rows[index]
        if not row then
            row = CreateRow(self.frame.content, index)
            self.frame.rows[index] = row
        end

        local quest = questStatus.quest
        local statusText = stateColors[questStatus.state] or questStatus.stateReason or "Unknown"
        local prereqText = ""
        if quest.prerequisites and #quest.prerequisites > 0 then prereqText = " | Chain info available" end

        row.questID = questStatus.questID
        row.status:SetText(statusText)
        row.title:SetText(string.format("%s (#%d)", quest.name, questStatus.questID))
        row.detail:SetText("Pickup: " .. FormatLocation(quest.pickup) .. " | Turn in: " .. FormatLocation(quest.turnIn) .. prereqText)
        row.reason:SetText((questStatus.stateReason or "") .. " | " .. (quest.objectives or ""))
        if row.party then row.party:SetText(DQT:GetPartyQuestSummary(status.key, questStatus.questID)) end
        row:SetScript("OnClick", function()
            UI.expandedQuests = UI.expandedQuests or {}
            UI.expandedQuests[questStatus.questID] = not UI.expandedQuests[questStatus.questID]
            UI:PositionChecklistRows(status)
        end)
        row:Show()
    end

    self:PositionChecklistRows(status)
    self.frame:Show()
end

function UI:ShowTurnIns()
    self:Create()
    self.currentView = "turnins"
    self:UpdateNav()
    self:ClearRows()
    self:UpdateNav()
    self.frame.content:Hide()
    self.frame.turnInScroll:Show()
    self.frame.turnInScroll:SetVerticalScroll(0)

    local turnIns = DQT:GetGlobalTurnInPriority() or { quests = {}, context = {}, xpToLevel = 0 }
    local context = turnIns.context or {}
    self.frame.subtitle:SetText(string.format(
        "All dungeon turn-ins | Level %s | XP %s/%s | To level %s",
        tostring(context.level or "?"),
        tostring(context.currentXp or 0),
        tostring(context.maxXp or 0),
        tostring(turnIns.xpToLevel or 0)
    ))

    if not turnIns.quests or #turnIns.quests == 0 then
        local row = self.frame.turnInRows[1]
        if not row then
            row = CreateTurnInRow(self.frame.turnInContent, 1)
            self.frame.turnInRows[1] = row
        end
        row.rank:SetText("-")
        row.title:SetText("No ready-to-turn-in dungeon quests detected yet.")
        row.detail:SetText("Ready quests will appear here in the suggested turn-in order.")
        row:Show()
        self.frame.turnInContent:SetHeight(56)
        self.frame:Show()
        return
    end

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
        row:Show()
    end

    self.frame.turnInContent:SetHeight(math.max(470, #turnIns.quests * 62))
    self.frame:Show()
end
function UI:RefreshCurrentDungeon()
    if not self.currentDungeonKey or not self.frame or not self.frame:IsShown() then return end
    if self.currentView == "list" then return end
    if self.currentView == "turnins" then self:ShowTurnIns(); return end
    local status = DQT:GetDungeonQuestStatus(self.currentDungeonKey)
    if status then self:RenderChecklist(status) end
end

function UI:ShowDungeonList()
    self:Create()
    self:ClearRows()
    self.currentView = "list"
    self:UpdateNav()
    self.frame.subtitle:SetText("Choose a dungeon.")
    self.frame.content:Hide()
    self.frame.dungeonScroll:Show()
    self.frame.dungeonScroll:SetVerticalScroll(0)

    local y = 0
    local cardIndex = 0
    for _, key in ipairs(DQT:GetOrderedDungeonKeys()) do
        local dungeon = DQT.dungeons[key]
        local status = DQT:GetDungeonQuestStatus(key)
        if status and #(status.quests or {}) > 0 then
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
            card.meta:SetText(string.format("Level %s | %s | %s", tostring(dungeon.minLevel or "?"), dungeon.recommendedLevel or "unknown", dungeon.location or "location unknown"))
            card.summary:SetText(string.format("Ready %d | Active %d | Missing %d | Done %d / %d", counts.ready or 0, counts.active or 0, counts.missing or 0, counts.completed or 0, #(status.quests or {})))
            card:SetScript("OnClick", function() DQT:OpenDungeon(key) end)
            card:Show()
            y = y + 116
        end
    end

    self.frame.dungeonContent:SetHeight(math.max(470, y))
    if cardIndex == 0 then
        self.frame.subtitle:SetText("No tracked dungeon quests are available for your character's faction yet.")
    end

    self.frame:Show()
end
function UI:Toggle()
    self:Create()
    if self.frame:IsShown() then self.frame:Hide(); return end
    self:ShowDungeonList()
end









