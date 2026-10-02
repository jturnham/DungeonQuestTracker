local _, DQT = ...

DQT.Minimap = DQT.Minimap or {}
local MinimapButton = DQT.Minimap

local function GetAngle()
    local db = type(DungeonQuestTrackerDB) == "table" and DungeonQuestTrackerDB or type(DQT.db) == "table" and DQT.db or {}
    db.minimap = type(db.minimap) == "table" and db.minimap or {}
    return type(db.minimap.angle) == "number" and db.minimap.angle or 225
end

local function SetAngle(angle)
    local db = type(DungeonQuestTrackerDB) == "table" and DungeonQuestTrackerDB or type(DQT.db) == "table" and DQT.db or {}
    db.minimap = type(db.minimap) == "table" and db.minimap or {}
    db.minimap.angle = angle
end

local function UpdatePosition(button)
    if not Minimap then return end
    local angle = math.rad(GetAngle())
    local width = type(Minimap.GetWidth) == "function" and Minimap:GetWidth() or 140
    local height = type(Minimap.GetHeight) == "function" and Minimap:GetHeight() or 140
    local radiusX = (tonumber(width) or 140) / 2 + 20
    local radiusY = (tonumber(height) or 140) / 2 + 20
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radiusX, math.sin(angle) * radiusY)
end

local function GetCursorAngle(y, x)
    if math.atan2 then return math.atan2(y, x) end
    if x > 0 then return math.atan(y / x) end
    if x < 0 and y >= 0 then return math.atan(y / x) + math.pi end
    if x < 0 and y < 0 then return math.atan(y / x) - math.pi end
    if y > 0 then return math.pi / 2 end
    if y < 0 then return -math.pi / 2 end
    return 0
end

local function UpdateDragPosition(button)
    if not Minimap or type(GetCursorPosition) ~= "function" then return end
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    if not mx or not my or not px or not py or not scale or scale <= 0 then return end
    px, py = px / scale, py / scale

    local angle = math.deg(GetCursorAngle(py - my, px - mx))
    SetAngle(angle)
    UpdatePosition(button)
end

function MinimapButton:Create()
    if self.button then return end
    if not Minimap or type(CreateFrame) ~= "function" then return end

    local button = CreateFrame("Button", "DungeonQuestTrackerForeverMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetSize(54, 54)
    button.border:SetPoint("TOPLEFT")
    button.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button.icon = button:CreateTexture(nil, "BACKGROUND")
    button.icon:SetSize(20, 20)
    button.icon:SetPoint("CENTER", 0, 1)
    button.icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" and DQT.UI and DQT.UI.ShowTurnIns then
            DQT.UI:ShowTurnIns()
        elseif DQT.UI and DQT.UI.Toggle then
            DQT.UI:Toggle()
        end
    end)

    button:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("DungeonQuestTrackerForever")
        GameTooltip:AddLine("Left-click: open dungeon list", 1, 1, 1)
        GameTooltip:AddLine("Right-click: open turn-ins", 1, 1, 1)
        GameTooltip:AddLine("Drag: move button", 0.75, 0.75, 0.75)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", UpdateDragPosition)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        UpdatePosition(self)
    end)

    self.button = button
    UpdatePosition(button)
end

function MinimapButton:Refresh()
    self:Create()
    if not self.button then return end
    local db = type(DungeonQuestTrackerDB) == "table" and DungeonQuestTrackerDB or type(DQT.db) == "table" and DQT.db or {}
    UpdatePosition(self.button)
    if type(db.minimap) == "table" and db.minimap.hide then
        self.button:SetScript("OnUpdate", nil)
        self.button:Hide()
    else self.button:Show() end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, _, addonName)
    if addonName ~= DQT.name then return end
    MinimapButton:Refresh()
end)
