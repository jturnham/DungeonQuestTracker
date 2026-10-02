local _, DQT = ...

local reminders = {
    [639] = {
        { questID = 373, itemID = 2874, item = "An Unsent Letter", startsQuest = true },
    },
    [3654] = {
        { questID = 6981, itemID = 10441, item = "Glowing Shard", startsQuest = true },
    },
    [4421] = {
        { questID = 6522, itemID = 17008, item = "Small Scroll", startsQuest = true },
    },
    [250483] = {
        { questID = 95216, itemID = 275443, item = "Highly Toxic Strain" },
    },
}
-- No guessed NPC IDs: this beta-only fallback also requires the exact instance name.
local namedReminders = {
    ["The Baron"] = {
        { questID = 97288, itemID = 280438, item = "Abominable Head", startsQuest = true },
        { questID = 95250, item = "Head of the Baron" },
    },
}
DQT.lootReminderData = reminders
DQT.namedLootReminderData = namedReminders

local encounters = {
    ["Edwin VanCleef"] = { npcID = 639, instance = "The Deadmines" },
    ["VanCleef"] = { npcID = 639, instance = "The Deadmines" },
    ["Mutanus the Devourer"] = { npcID = 3654, instance = "Wailing Caverns" },
    ["Mutanus"] = { npcID = 3654, instance = "Wailing Caverns" },
    ["Charlga Razorflank"] = { npcID = 4421, instance = "Razorfen Kraul" },
    ["Witherfang"] = { npcID = 250483, instance = "Ruins of Lordaeron" },
    ["The Baron"] = { npcID = 999999, instance = "Ruins of Lordaeron" },
}

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, ...)
    if ok then return a, b end
end

function DQT:NeedsQuestLoot(drop)
    local quest = self:GetQuest(drop.questID)
    if not quest then return false end
    local state = self:GetQuestState(drop.questID, quest)
    if state == "completed" or state == "ready" then return false end
    if self:GetQuestAvailability(quest) == "unavailable" then return false end
    local count = drop.itemID and SafeCall((C_Item and C_Item.GetItemCount) or GetItemCount, drop.itemID, false)
    if type(count) == "number" and count > 0 then return false end
    if drop.startsQuest then return state == "missing" end
    return state == "active"
end

function DQT:ShowQuestLootReminder(bossName, drops, preview, silent)
    local frame = self.lootReminderFrame
    if not frame then
        frame = CreateFrame("Frame", "DungeonQuestTrackerForeverLootReminder", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
        frame:SetSize(360, 110)
        frame:SetPoint("TOP", UIParent, "TOP", 0, -150)
        frame:SetFrameStrata("HIGH")
        frame:EnableMouse(true)
        if frame.SetBackdrop then
            frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
        else
            frame.background = frame:CreateTexture(nil, "BACKGROUND")
            frame.background:SetAllPoints(frame)
            frame.background:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background-Dark")
        end
        frame.icon = frame:CreateTexture(nil, "ARTWORK")
        frame.icon:SetSize(32, 32)
        frame.icon:SetPoint("TOPLEFT", 14, -16)
        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.title:SetPoint("TOPLEFT", 56, -14)
        frame.title:SetText("Quest Loot")
        frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.text:SetPoint("TOPLEFT", 56, -34)
        frame.text:SetWidth(272)
        frame.text:SetJustifyH("LEFT")
        frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        frame.close:SetPoint("TOPRIGHT", -2, -2)
        frame.close:SetScript("OnClick", function() frame:Hide() end)
        frame:SetScript("OnUpdate", function(_, elapsed)
            frame.remaining = (frame.remaining or 0) - elapsed
            if frame.remaining <= 0 then
                frame:Hide()
            else
                frame:SetAlpha(math.min(1, frame.remaining))
            end
        end)
        self.lootReminderFrame = frame
    end
    local lines = { bossName }
    frame.isPreview = preview == true
    frame.title:SetText(frame.isPreview and "Quest Loot (Preview)" or "Quest Loot")
    for _, drop in ipairs(drops) do lines[#lines + 1] = "Loot " .. drop.item .. " - " .. self:GetQuest(drop.questID).name end
    frame.text:SetText(table.concat(lines, "\n"))
    frame:SetHeight(math.max(96, (frame.text:GetStringHeight() or 48) + 50))
    local icon = drops[1].itemID and SafeCall((C_Item and C_Item.GetItemIconByID) or GetItemIcon, drops[1].itemID)
    frame.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_Bag_10")
    frame.drops, frame.bossName, frame.remaining = drops, bossName, 15
    frame:SetAlpha(1)
    frame:Show()
    if not silent then
        SafeCall((C_Sound and C_Sound.PlaySound) or PlaySound, (SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959, "Master")
    end
end

function DQT:PreviewQuestLootReminder()
    self:ShowQuestLootReminder("Witherfang", reminders[250483], true)
end

local seen, order = {}, {}
function DQT:HandleQuestLootDeath(guid, name)
    if not self.loaded or not self:GetOption("lootReminders.enabled") then return end
    local inInstance, instanceType = SafeCall(IsInInstance)
    if not inInstance or instanceType ~= "party" or type(guid) ~= "string" then return end
    local npcID = tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-%x+$"))
    if not npcID then return end
    local drops = reminders[npcID]
    if not drops and namedReminders[name] then
        local instanceName = SafeCall(GetInstanceInfo)
        if instanceName == "Ruins of Lordaeron" then drops = namedReminders[name] end
    end
    if not drops or seen[guid] then return end
    seen[guid] = true
    order[#order + 1] = guid
    if #order > 64 then seen[table.remove(order, 1)] = nil end
    local relevant = {}
    for _, drop in ipairs(drops) do if self:NeedsQuestLoot(drop) then relevant[#relevant + 1] = drop end end
    if #relevant > 0 then self:ShowQuestLootReminder(type(name) == "string" and name or "Defeated boss", relevant) end
end

local events = CreateFrame("Frame")
DQT.lootReminderEvents = events
-- Restricted event registration can trigger a Blizzard warning without throwing a Lua error.
-- Use public encounter notifications, never probe or register combat-log events.
for _, event in ipairs({ "BOSS_KILL", "BAG_UPDATE_DELAYED", "QUEST_LOG_UPDATE", "PLAYER_ENTERING_WORLD" }) do
    SafeCall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        seen, order = {}, {}
        if DQT.lootReminderFrame then DQT.lootReminderFrame:Hide() end
    elseif event == "BOSS_KILL" then
        if not DQT.loaded or not DQT:GetOption("lootReminders.enabled") then return end
        local _, name = ...
        if issecretvalue and issecretvalue(name) then return end
        if type(name) ~= "string" then return end
        local encounter = encounters[name]
        if encounter and SafeCall(GetInstanceInfo) == encounter.instance then
            -- Session-local identity for duplicate public encounter notifications, not a unit GUID.
            DQT:HandleQuestLootDeath("Creature-0-0-0-0-" .. encounter.npcID .. "-0000", name)
        end
    else
        local frame = DQT.lootReminderFrame
        if not frame or not frame:IsShown() then return end
        if frame.isPreview then return end
        if not DQT:GetOption("lootReminders.enabled") then frame:Hide(); return end
        local relevant = {}
        for _, drop in ipairs(frame.drops or {}) do if DQT:NeedsQuestLoot(drop) then relevant[#relevant + 1] = drop end end
        if #relevant == 0 then frame:Hide()
        elseif #relevant ~= #(frame.drops or {}) then
            local remaining = frame.remaining
            DQT:ShowQuestLootReminder(frame.bossName, relevant, false, true)
            frame.remaining = remaining
            frame:SetAlpha(math.min(1, math.max(0, remaining)))
        end
    end
end)
