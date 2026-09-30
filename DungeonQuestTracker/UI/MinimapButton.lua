local _, DQT = ...

DQT.Minimap = DQT.Minimap or {}
local MinimapButton = DQT.Minimap

local function GetAngle()
    local db = DungeonQuestTrackerDB or DQT.db or {}
    db.minimap = db.minimap or {}
    return db.minimap.angle or 225
end

local function SetAngle(angle)
    local db = DungeonQuestTrackerDB or DQT.db or {}
    db.minimap = db.minimap or {}
    db.minimap.angle = angle
end

local function UpdatePosition(button)
    local angle = math.rad(GetAngle())
    local radius = 80
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
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
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    px, py = px / scale, py / scale

    local angle = math.deg(GetCursorAngle(py - my, px - mx))
    SetAngle(angle)
    UpdatePosition(button)
end

function MinimapButton:Create()
    if self.button then return end

    local button = CreateFrame("Button", "DungeonQuestTrackerMinimapButton", Minimap)
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
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("DungeonQuestTracker")
        GameTooltip:AddLine("Left-click: open dungeon list", 1, 1, 1)
        GameTooltip:AddLine("Right-click: open turn-ins", 1, 1, 1)
        GameTooltip:AddLine("Drag: move button", 0.75, 0.75, 0.75)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
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
    local db = DungeonQuestTrackerDB or DQT.db or {}
    if db.minimap and db.minimap.hide then self.button:Hide() else self.button:Show() end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, _, addonName)
    if addonName ~= DQT.name then return end
    MinimapButton:Refresh()
end)