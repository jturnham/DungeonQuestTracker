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
    [1716] = { { questID = 391, itemID = 2926, item = "Head of Bazil Thredd" } },
    [1696] = { { questID = 386, itemID = 3630, item = "Head of Targorr" } },
    [1663] = { { questID = 377, itemID = 3628, item = "Hand of Dextren Ward" } },
    [1666] = { { questID = 378, itemID = 3640, item = "Head of Deepfury" } },
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
    ["Bazil Thredd"] = { npcID = 1716, instance = "The Stockade" },
    ["Targorr the Dread"] = { npcID = 1696, instance = "The Stockade" },
    ["Dextren Ward"] = { npcID = 1663, instance = "The Stockade" },
    ["Kam Deepfury"] = { npcID = 1666, instance = "The Stockade" },
}

local function IsSecret(value)
    return type(issecretvalue) == "function" and issecretvalue(value)
end

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, ...)
    if ok and not IsSecret(a) and not IsSecret(b) then return a, b end
end

-- Index known items once; loot inspection needs neither corpse GUIDs nor unit APIs.
local lootItems = {}
local function IndexDrop(location, drop)
    lootItems[location] = lootItems[location] or {}
    local items = lootItems[location]
    items[drop.itemID] = items[drop.itemID] or {}
    for _, existing in ipairs(items[drop.itemID]) do
        if existing.questID == drop.questID then return end
    end
    items[drop.itemID][#items[drop.itemID] + 1] = drop
end
for name, encounter in pairs(encounters) do
    for _, drop in ipairs(reminders[encounter.npcID] or namedReminders[name] or {}) do
        if drop.itemID then
            IndexDrop(encounter.instance, drop)
        end
    end
end

-- Explicit single-copy objectives only; collection drops must not enter this allowlist.
-- Entrance targets have no reliable boss notification, so inspect available loot instead.
local singleDrops = {
    { questID = 959, itemID = 5334, item = "99-Year-Old Port", locations = { "Wailing Caverns", "The Barrens", "Northern Barrens" } },
    { questID = 167, itemID = 1875, item = "Thistlenettle's Badge", locations = { "The Deadmines", "Westfall" } },
    { questID = 2922, itemID = 9277, item = "Techbot's Memory Core", locations = { "Gnomeregan", "Dun Morogh" } },
    { questID = 1701, itemID = 6841, item = "Vial of Phlogiston", locations = { "Razorfen Kraul" } },
    { questID = 1838, itemID = 6841, item = "Vial of Phlogiston", locations = { "Razorfen Kraul" } },
}
for _, drop in ipairs(singleDrops) do
    for _, location in ipairs(drop.locations) do IndexDrop(location, drop) end
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

local seen, order, notified = {}, {}, {}
local function NotifyDrops(name, drops)
    local relevant = {}
    for _, drop in ipairs(drops) do
        if not notified[drop.questID] and DQT:NeedsQuestLoot(drop) then relevant[#relevant + 1] = drop end
    end
    if #relevant == 0 then return end
    for _, drop in ipairs(relevant) do notified[drop.questID] = true end
    DQT:ShowQuestLootReminder(name, relevant)
end

function DQT:HandleAvailableQuestLoot()
    if not self.loaded or not self:GetOption("lootReminders.enabled") then return end
    local inInstance, instanceType = SafeCall(IsInInstance)
    if inInstance and instanceType ~= "party" then return end
    local location = inInstance and SafeCall(GetInstanceInfo) or SafeCall(GetRealZoneText)
    local items = lootItems[location]
    if not items then return end
    local count = SafeCall(GetNumLootItems)
    if type(count) ~= "number" or count < 1 or count > 128 or count ~= math.floor(count) then return end
    local drops, found = {}, {}
    for slot = 1, count do
        local link = SafeCall(GetLootSlotLink, slot)
        local id = type(link) == "string" and tonumber(link:match("item:(%d+)"))
        if id and items[id] and not found[id] then
            found[id] = true
            for _, drop in ipairs(items[id]) do drops[#drops + 1] = drop end
        end
    end
    NotifyDrops("Available quest loot", drops)
end

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
    NotifyDrops(type(name) == "string" and name or "Defeated boss", drops)
end

local events = CreateFrame("Frame")
DQT.lootReminderEvents = events
local lootDelay
local function CheckAutoLoot(_, elapsed)
    lootDelay = lootDelay - elapsed
    if lootDelay > 0 then return end
    lootDelay = nil
    events:SetScript("OnUpdate", nil)
    DQT:HandleAvailableQuestLoot()
end
-- Restricted event registration can trigger a Blizzard warning without throwing a Lua error.
-- Use public encounter notifications, never probe or register combat-log events.
for _, event in ipairs({ "BOSS_KILL", "ENCOUNTER_END", "LOOT_READY", "LOOT_OPENED", "LOOT_SLOT_CHANGED", "BAG_UPDATE_DELAYED", "QUEST_LOG_UPDATE", "PLAYER_ENTERING_WORLD" }) do
    SafeCall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        seen, order, notified = {}, {}, {}
        lootDelay = nil
        events:SetScript("OnUpdate", nil)
        if DQT.lootReminderFrame then DQT.lootReminderFrame:Hide() end
    elseif event == "BOSS_KILL" or event == "ENCOUNTER_END" then
        if not DQT.loaded or not DQT:GetOption("lootReminders.enabled") then return end
        local _, name, _, _, success = ...
        if event == "ENCOUNTER_END" and (IsSecret(success) or success ~= 1) then return end
        if IsSecret(name) then return end
        if type(name) ~= "string" then return end
        local encounter = encounters[name]
        if encounter and SafeCall(GetInstanceInfo) == encounter.instance then
            -- Session-local identity for duplicate public encounter notifications, not a unit GUID.
            DQT:HandleQuestLootDeath("Creature-0-0-0-0-" .. encounter.npcID .. "-0000", name)
        end
    elseif event == "LOOT_READY" or event == "LOOT_OPENED" or event == "LOOT_SLOT_CHANGED" then
        if not DQT.loaded or not DQT:GetOption("lootReminders.enabled") then return end
        local autoLoot = ...
        if event ~= "LOOT_SLOT_CHANGED" and IsSecret(autoLoot) then return end
        if lootDelay or (event ~= "LOOT_SLOT_CHANGED" and autoLoot == true) then
            lootDelay = lootDelay or 0.15
            events:SetScript("OnUpdate", CheckAutoLoot)
        else DQT:HandleAvailableQuestLoot() end
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
