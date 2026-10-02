local _, DQT = ...

DQT.optionDefinitions = {
    {section="Display"},
    {key="display.compact", label="Use compact mode", tip="Text-only dungeon and quest lists in a smaller window. Options always uses the full window width."},
    {section="Quest Checklist"},
    {key="filters.showCompleted", label="Show completed quests"},
    {key="filters.showUnavailable", label="Show quests unavailable to my faction, class or race"},
    {key="filters.showLowLevelLocked", label="Show locked quests below my current level"},
    {key="filters.ignoreGrayChecklist", label="Hide gray quests", tip="Ready quests and gray prerequisites blocking a non-gray quest remain visible."},
    {key="filters.ignoreRedChecklist", label="Hide red quests", tip="Quests five or more levels above you are hidden. Ready quests remain visible; the global planner is unaffected."},
    {key="filters.includeBreadcrumbs", label="Include breadcrumb-only quests in checklist totals"},
    {key="filters.showClassRestricted", label="Include class quests in checklist totals"},
    {key="filters.includeItemQuests", label="Include quests started by drops or dungeon objects"},
    {section="Dungeon List"},
    {key="filters.hideGrayDungeons", label="Hide gray dungeons", tip="Hides dungeons whose recommended upper level is gray, or whose visible quests are all gray."},
    {key="filters.hideRedDungeons", label="Hide red dungeons", tip="Hides dungeons whose recommended lower level is five or more levels above you, including empty placeholders."},
    {key="filters.hideLowDungeons", label="Hide dungeons below my level range"},
    {key="filters.lowLevelGap", label="Maximum levels below me", number=true, tip="Uses the upper end of the dungeon's recommended level range. Range: 0-60."},
    {key="filters.hideHighDungeons", label="Hide dungeons above my level range"},
    {key="filters.highLevelGap", label="Maximum levels above me", number=true, tip="Uses the lower end of the dungeon's recommended level range. Range: 0-60."},
    {key="filters.hideTrackedDungeons", label="Apply level/color dungeon filters even with active or ready quests", tip="On by default to keep the list within your level range. Turn it off to keep dungeons with current quests visible. Ready quests remain in the global turn-in planner."},
    {key="filters.onlyMissing", label="Show only dungeons with missing or locked quests", tip="When both list-only filters are enabled, a dungeon must satisfy both."},
    {key="filters.onlyReady", label="Show only dungeons with ready turn-ins"},
    {section="Turn-In Planner"},
    {key="filters.ignoreGrayTurnIns", label="Exclude gray quests from turn-in priority", tip="This explicitly hides gray ready quests from the planner. Other checklist and dungeon filters do not affect it."},
    {section="Minimap And Party"},
    {key="minimap.hide", label="Show minimap button", invert=true},
    {key="party.respond", label="Respond to party quest-status requests"},
    {key="party.autoBroadcast", label="Broadcast my quest status when opening a dungeon", tip="Only sends to your current group. Uses a five-second cooldown per dungeon; does not request replies."},
    {key="party.confirmShareAll", label="Ask for confirmation before Share All"},
    {key="partyDataSync", label="Enable party quest-data sync", tip="Opt-in on both clients. Received records stay separate and unverified XP is excluded from ranking."},
}
local definitions = {}
for _, option in ipairs(DQT.optionDefinitions) do if option.key then definitions[option.key] = option end end
local function Lookup(table, key)
    local group, field = key:match("^(%w+)%.(%w+)$")
    if group then
        if type(table[group]) == "table" then return table[group][field] end
        return nil
    end
    return table[key]
end
local function Store(table, key, value)
    local group, field = key:match("^(%w+)%.(%w+)$")
    if group then
        table[group] = type(table[group]) == "table" and table[group] or {}
        table[group][field] = value
    else table[key] = value end
end
function DQT:GetOption(key)
    local option = definitions[key]
    if not option then return nil end
    local value = self.db and Lookup(self.db, key)
    if option.number then
        if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then value = Lookup(self.defaults, key) end
        return math.max(0, math.min(60, math.floor(value)))
    end
    if type(value) ~= "boolean" then value = Lookup(self.defaults, key) end
    return value
end
function DQT:InitializeOptions()
    if not self.db then return end
    -- These old defaults were never applied before the Options implementation.
    if not self.db.optionsVersion then
        Store(self.db, "filters.showCompleted", true)
        Store(self.db, "filters.showUnavailable", false)
        Store(self.db, "filters.showClassRestricted", true)
    end
    if self.db.optionsVersion ~= 2 then
        for _, key in ipairs({"filters.ignoreGrayChecklist", "filters.hideGrayDungeons", "filters.hideTrackedDungeons"}) do
            if not (type(self.db.optionOverrides) == "table" and self.db.optionOverrides[key]) and Lookup(self.db, key) == false then Store(self.db, key, true) end
        end
        self.db.optionsVersion = 2
    end
    for key in pairs(definitions) do Store(self.db, key, self:GetOption(key)) end
end
function DQT:ApplyOptions()
    if self.Minimap then self.Minimap:Refresh() end
    if self.UI then self.UI:RefreshCurrentDungeon() end
end
function DQT:SetOption(key, value)
    local option = definitions[key]
    if not self.db or not option then return false end
    if option.number then
        value = tonumber(value)
        if not value or value ~= value or math.abs(value) == math.huge then return false end
        value = math.max(0, math.min(60, math.floor(value)))
    elseif type(value) ~= "boolean" then return false end
    Store(self.db, key, value)
    self.db.optionOverrides = type(self.db.optionOverrides) == "table" and self.db.optionOverrides or {}
    self.db.optionOverrides[key] = true
    if key == "partyDataSync" and self.ResetQuestDataTransfers then self:ResetQuestDataTransfers() end
    self:ApplyOptions()
    return true
end
function DQT:ResetFilters()
    for key in pairs(definitions) do
        if key:match("^filters%.") then
            Store(self.db, key, Lookup(self.defaults, key))
            if type(self.db.optionOverrides) == "table" then self.db.optionOverrides[key] = nil end
        end
    end
    self:ApplyOptions()
end
function DQT:ResetMinimapPosition()
    self.db.minimap = type(self.db.minimap) == "table" and self.db.minimap or {}
    self.db.minimap.angle = 225
    self:ApplyOptions()
end
function DQT:IsQuestGray(quest, context)
    if quest.questLevelUnverified then return false end
    return self:GetQuestColorInfo(quest.questLevel, context.level) == "gray"
end
function DQT:IsQuestRed(quest, context)
    if quest.questLevelUnverified then return false end
    return self:GetQuestColorInfo(quest.questLevel, context.level) == "red"
end
function DQT:GetQuestPickupType(quest)
    if quest.pickupType then return quest.pickupType end
    local location = quest.pickup or {}
    local text = ((location.name or "") .. " " .. (location.subzone or "")):lower()
    if text:find("drop", 1, true) then return "drop" end
    if text:find("sparklematic", 1, true) or text:find("vault", 1, true) or text:find("spawn points", 1, true) then return "object" end
    return "unknown"
end
function DQT:GetDisplayDungeonStatus(key)
    local raw = self:GetDungeonQuestStatus(key, true)
    if not raw then return nil end
    local context, blocking = self:GetPlayerContext(), {}
    local function MarkPrerequisites(quest, seen)
        for _, prerequisite in ipairs(quest.prerequisites or {}) do
            local id = prerequisite.questID
            if prerequisite.relationship == "required" and id and not seen[id] and not self:IsQuestComplete(id) then
                seen[id], blocking[id] = true, true
                local parent = self:GetQuest(id)
                if parent then MarkPrerequisites(parent, seen) end
            end
        end
    end
    for _, row in ipairs(raw.quests) do
        if row.state ~= "completed" and row.state ~= "unavailable" and not self:IsQuestGray(row.quest, context) and not (self:GetOption("filters.ignoreRedChecklist") and self:IsQuestRed(row.quest, context)) then MarkPrerequisites(row.quest, {}) end
    end
    local result = {key=key, dungeon=raw.dungeon, quests={}, counts={completed=0, ready=0, active=0, missing=0, locked=0, unavailable=0}, hidden=0, raw=raw}
    for _, row in ipairs(raw.quests) do
        local quest, visible = row.quest, true
        local available = self:GetQuestAvailability(quest, context) ~= "unavailable"
        if not available and not self:GetOption("filters.showUnavailable") then visible=false end
        if row.state == "completed" and not self:GetOption("filters.showCompleted") then visible=false end
        if quest.classes and not self:GetOption("filters.showClassRestricted") then visible=false end
        if quest.breadcrumbOnly and not self:GetOption("filters.includeBreadcrumbs") then visible=false end
        local pickupType = self:GetQuestPickupType(quest)
        if (pickupType == "drop" or pickupType == "object") and not self:GetOption("filters.includeItemQuests") then visible=false end
        if row.state ~= "ready" and not blocking[row.questID] then
            if self:GetOption("filters.ignoreGrayChecklist") and self:IsQuestGray(quest, context) then visible=false end
            if row.state == "locked" and not quest.questLevelUnverified and quest.questLevel < context.level and not self:GetOption("filters.showLowLevelLocked") then visible=false end
        end
        if row.state ~= "ready" and self:GetOption("filters.ignoreRedChecklist") and self:IsQuestRed(quest, context) then visible=false end
        if visible then
            result.quests[#result.quests+1] = row
            result.counts[row.state] = result.counts[row.state]+1
        else result.hidden=result.hidden+1 end
    end
    return result
end
function DQT:ShouldShowDungeon(status)
    local counts, raw = status.counts, status.raw
    if self:GetOption("filters.onlyMissing") and counts.missing+counts.locked == 0 then return false end
    if self:GetOption("filters.onlyReady") and counts.ready == 0 then return false end
    local relevant, tracked = false, false
    for _, row in ipairs(raw.quests) do
        if self:GetQuestAvailability(row.quest) ~= "unavailable" then
            relevant=true
            if row.state == "active" or row.state == "ready" then tracked=true end
        end
    end
    if #status.dungeon.quests > 0 and #status.quests == 0 then return false end
    if #status.quests == 0 and not self:DungeonHasVisibleQuests(status.key) then return false end
    if not relevant and #status.quests > 0 and not self:GetOption("filters.showUnavailable") then return false end
    if tracked and not self:GetOption("filters.hideTrackedDungeons") then return true end
    local level = self:GetPlayerContext().level
    local low, high = tostring(status.dungeon.recommendedLevel):match("(%d+)%D+(%d+)")
    low, high = tonumber(low) or status.dungeon.minLevel, tonumber(high) or status.dungeon.minLevel
    if level > 0 then
        if self:GetOption("filters.hideGrayDungeons") and self:GetQuestColorInfo(high, level) == "gray" then return false end
        if self:GetOption("filters.hideRedDungeons") and self:GetQuestColorInfo(low, level) == "red" then return false end
        if self:GetOption("filters.hideLowDungeons") and high+self:GetOption("filters.lowLevelGap") < level then return false end
        if self:GetOption("filters.hideHighDungeons") and low-self:GetOption("filters.highLevelGap") > level then return false end
    end
    if self:GetOption("filters.hideGrayDungeons") and #status.quests > 0 then
        local allGray = true
        for _, row in ipairs(status.quests) do if not self:IsQuestGray(row.quest, {level=level}) then allGray=false end end
        if allGray then return false end
    end
    return true
end
function DQT:GetFilterSummary()
    local labels = {}
    for _, option in ipairs(self.optionDefinitions) do
        if option.key and option.key:match("^filters%.") and self:GetOption(option.key) ~= Lookup(self.defaults, option.key) then
            local label = option.label
            if option.number then label = label .. ": " .. self:GetOption(option.key)
            elseif self:GetOption(option.key) == false then label = label .. " (off)" end
            labels[#labels+1] = label
        end
    end
    return #labels > 0 and table.concat(labels, "\n") or "Default filters\nGray/red quests and dungeons, and unavailable quests, are hidden. Ready quests and required gray blockers remain visible in checklists; ready turn-ins remain in the global planner."
end
