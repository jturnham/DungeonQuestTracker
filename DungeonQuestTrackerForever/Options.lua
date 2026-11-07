local _, DQT = ...

DQT.optionDefinitions = {
    {section="Display"},
    {key="display.scale",label="Window scale (%)",number=true,min=70,max=150},
    {key="display.largeText",label="Larger quest and dungeon text"},
    {key="display.favoritesFirst",label="Sort favorite dungeons first"},
    {key="notifications.entry",label="Show dungeon-entry preparation summary (opt-in)"},
    {key="notifications.chains",label="Notify when quest chains become available (opt-in)"},
    {key="lootReminders.duration",label="Loot alert duration (seconds)",number=true,min=3,max=60},
    {key="lootReminders.sound",label="Play loot alert sound"},
    {key="lootReminders.soundPreset",label="Alert sound: 1 warning, 2 ready check, 3 tell",number=true,min=1,max=3},
    {key="lootReminders.masterChannel",label="Play alert sound on Master channel",tip="Off uses the SFX channel. Game volume settings still apply."},
    {key="xpRecorder.enabled",label="Record dungeon quest XP locally (opt-in)",tip="Stores up to 500 observations for 90 days. No uploads or ranking changes. Open XP Records to inspect, copy an anonymous export or clear records. Event rewards are not assumed to be base XP."},
    {key="display.compact", label="Use compact mode", tip="Text-only dungeon and quest lists in a smaller window. Options always uses the full window width."},
    {key="lootReminders.enabled", label="Show boss quest-loot reminders", tip="Brief on-screen reminder to check a defeated boss for known quest items. A reminder does not guarantee the item dropped."},
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
    {key="filters.hideTrackedDungeons", label="Apply level/color dungeon filters even with active or ready quests", tip="Off by default: current quests keep their dungeon and quest rows visible regardless of level. Enable for strict level filtering. Ready quests remain in the global turn-in planner."},
    {key="filters.onlyMissing", label="Show only dungeons with unfinished quests", tip="Includes missing, locked, active and ready quests; hides fully completed dungeons. When both list-only filters are enabled, a dungeon must satisfy both."},
    {key="filters.onlyReady", label="Show only dungeons with ready turn-ins"},
    {section="Turn-In Planner"},
    {key="filters.ignoreGrayTurnIns", label="Exclude gray quests from turn-in priority", tip="This explicitly hides gray ready quests from the planner. Other checklist and dungeon filters do not affect it."},
    {section="Pickup Routes"},
    {key="pickups.includeGray", label="Include gray pickup quests"},
    {key="pickups.includeBreadcrumbs", label="Include optional pickup breadcrumbs"},
    {key="pickups.includeClass", label="Include my class pickup quests"},
    {key="pickups.usePlayerPosition", label="Start pickups from my map position", tip="Uses a valid player position only on the same map as recorded stops; otherwise uses the current-zone cluster."},
    {key="pickups.finishAtEntrance", label="Finish pickup routes at the entrance", tip="Uses recorded entrance approaches where available. Unknown entrances remain text-only; cross-zone travel is not optimized."},
    {section="Travel"},
    {key="travel.useHearthstone",label="Include a ready Hearthstone in pickup routes",tip="Requires a known bind destination and a Hearthstone in your bags. A second use needs a sourced guaranteed minimum journey covering the hour cooldown; flight-time estimates never count. Confirm an existing bind at its inn, or bind again to record it automatically."},
    {key="travel.useFlights",label="Use known flights in pickup routes"},
    {key="travel.allowUnknownFlights",label="Allow unverified flight knowledge",tip="Unknown flight points may be used with an explicit warning. Points marked not learned are still excluded."},
    {key="travel.useTransports",label="Use recorded boats, zeppelins and tram routes",tip="Classic connections are provisional in Forever. Departure approaches and waiting times are not estimated."},
    {key="travel.showSegments",label="Show same-map pickup guide lines",tip="Straight guide segments only, not walkable terrain paths or cross-zone travel lines."},
    {key="travel.useTomTom",label="Use TomTom for pickup waypoints",tip="Send focused stops and the active pickup tracker's next stop to TomTom when available."},
    {key="travel.recordFlightTimes",label="Record flight times on this character",tip="Measures uninterrupted flights you take in this client build. No uploads. Interrupted flights and unknown destinations are discarded; measured times are estimates for future journeys."},
    {key="travel.preferMeasuredTime",label="Prefer the fastest measured transport route",tip="Compares transport legs with complete timing evidence only. Falls back to fewest legs when timing is missing. Walking and waiting are excluded; this is not a fastest door-to-door route."},
    {key="travel.includeFutureSteps",label="Preview later prerequisite objectives and returns",tip="Shows conditional future steps separately. Does not mark quests complete, unlock pickups, change XP turn-in priority or put future steps in next-stop navigation."},
    {section="Minimap And Party"},
    {key="minimap.hide", label="Show minimap button", invert=true},
    {key="party.respond", label="Respond to party quest-status requests"},
    {key="party.autoBroadcast", label="Broadcast my quest status when opening a dungeon", tip="Only sends to your current group. Uses a five-second cooldown per dungeon; does not request replies."},
    {key="party.confirmShareAll", label="Ask for confirmation before Share All"},
    {key="partyDataSync", label="Enable party quest-data sync", tip="Opt-in on both clients. Received records stay separate and unverified XP is excluded from ranking."},
}
local definitions = {}
for _, option in ipairs(DQT.optionDefinitions) do
    if option.key then definitions[option.key] = option end
    for _,field in ipairs({"section","label","tip"}) do if option[field] then option[field]=DQT.L[option[field]] end end
end
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
        return math.max(option.min or 0, math.min(option.max or 60, math.floor(value)))
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
    if not self.db.optionsVersion or self.db.optionsVersion < 2 then
        for _, key in ipairs({"filters.ignoreGrayChecklist", "filters.hideGrayDungeons"}) do
            if not (type(self.db.optionOverrides) == "table" and self.db.optionOverrides[key]) and Lookup(self.db, key) == false then Store(self.db, key, true) end
        end
    end
    if not self.db.optionsVersion or self.db.optionsVersion < 3 then
        if not (type(self.db.optionOverrides) == "table" and self.db.optionOverrides["filters.hideTrackedDungeons"]) then
            Store(self.db, "filters.hideTrackedDungeons", false)
        end
        self.db.optionsVersion = 3
    end
    for key in pairs(definitions) do Store(self.db, key, self:GetOption(key)) end
end
function DQT:ApplyOptions()
    if self.SaveActiveProfile then self:SaveActiveProfile() end
    if self.UI and self.UI.ApplyWindowPreferences then self.UI:ApplyWindowPreferences() end
    if self.Notifications then self.Notifications:OptionsChanged() end
    if self.Minimap then self.Minimap:Refresh() end
    if self.PickupMap and not self:GetOption("travel.useTomTom") then self.PickupMap:ClearWaypoint() end
    if self.PickupMap then self.PickupMap:InvalidateRoute() end
    if self.UI then self.UI:RefreshCurrentDungeon() end
end
function DQT:ResetPickupOptions()
    if not self.db then return end
    self.db.pickups = {}
    for key, value in pairs(self.defaults.pickups) do self.db.pickups[key] = value end
    for key in pairs(self.db.optionOverrides or {}) do
        if key:match("^pickups%.") then self.db.optionOverrides[key] = nil end
    end
    self:ApplyOptions()
end
function DQT:SetOption(key, value)
    local option = definitions[key]
    if not self.db or not option then return false end
    if option.number then
        value = tonumber(value)
        if not value or value ~= value or math.abs(value) == math.huge then return false end
        value = math.max(option.min or 0, math.min(option.max or 60, math.floor(value)))
    elseif type(value) ~= "boolean" then return false end
    Store(self.db, key, value)
    self.db.optionOverrides = type(self.db.optionOverrides) == "table" and self.db.optionOverrides or {}
    self.db.optionOverrides[key] = true
    if key == "partyDataSync" and self.ResetQuestDataTransfers then self:ResetQuestDataTransfers() end
    if key == "lootReminders.enabled" and not value and self.lootReminderFrame then self.lootReminderFrame:Hide() end
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
function DQT:GetDisplayDungeonStatus(key, context)
    context = context or self:PrepareQuestScan(self:GetPlayerContext())
    local raw = self:GetDungeonQuestStatus(key, true, true, context)
    if not raw then return nil end
    local blocking, seen = {}, {}
    local function MarkPrerequisites(quest)
        for _, prerequisite in ipairs(quest.prerequisites or {}) do
            local id = prerequisite.questID
            if prerequisite.relationship == "required" and id and not prerequisite.anyOf and not seen[id] then
                seen[id] = true
                if not self:IsPrerequisiteSatisfied(prerequisite, context) then
                    blocking[id] = true
                    local parent = self:GetQuest(id)
                    if parent then MarkPrerequisites(parent) end
                end
            end
        end
    end
    for _, row in ipairs(raw.quests) do
        if row.state ~= "completed" and row.state ~= "unavailable" and not self:IsQuestGray(row.quest, context) and not (self:GetOption("filters.ignoreRedChecklist") and self:IsQuestRed(row.quest, context)) then MarkPrerequisites(row.quest) end
    end
    local result = {key=key, dungeon=raw.dungeon, quests={}, counts={completed=0, ready=0, active=0, missing=0, locked=0, unavailable=0}, hidden=0, raw=raw,exclusions={}}
    for _, row in ipairs(raw.quests) do
        local quest, visible = row.quest, true
        local reasons={}
        local function Exclude(reason) visible=false; reasons[#reasons+1]=reason end
        local protectTracked = (row.state == "active" or row.state == "ready") and not self:GetOption("filters.hideTrackedDungeons")
        local available = self:GetQuestAvailability(quest, context) ~= "unavailable"
        if not available and not self:GetOption("filters.showUnavailable") then Exclude("faction/class/race unavailable") end
        if row.state == "completed" and not self:GetOption("filters.showCompleted") then Exclude("completed quests hidden") end
        if quest.classes and not self:GetOption("filters.showClassRestricted") then Exclude("class quests hidden") end
        if quest.breadcrumbOnly and not self:GetOption("filters.includeBreadcrumbs") then Exclude("optional breadcrumbs hidden") end
        local pickupType = self:GetQuestPickupType(quest)
        if (pickupType == "drop" or pickupType == "object") and not self:GetOption("filters.includeItemQuests") then Exclude("item/object starts hidden") end
        if row.state ~= "ready" and not protectTracked and not blocking[row.questID] then
            if self:GetOption("filters.ignoreGrayChecklist") and self:IsQuestGray(quest, context) then Exclude("gray quest hidden") end
            if row.state == "locked" and not quest.questLevelUnverified and quest.questLevel < context.level and not self:GetOption("filters.showLowLevelLocked") then Exclude("lower-level locked quest hidden") end
        end
        if row.state ~= "ready" and not protectTracked and self:GetOption("filters.ignoreRedChecklist") and self:IsQuestRed(quest, context) then Exclude("red quest hidden") end
        if visible then
            result.quests[#result.quests+1] = row
            result.counts[row.state] = result.counts[row.state]+1
        else
            result.hidden=result.hidden+1
            result.exclusions[#result.exclusions+1]={questID=row.questID,reasons=reasons}
        end
    end
    return result
end
function DQT:ShouldShowDungeon(status, context)
    context = context or self:GetPlayerContext()
    local counts, raw = status.counts, status.raw
    local reasons={}
    local function Exclude(reason) reasons[#reasons+1]=reason end
    if self:GetOption("filters.onlyMissing") and counts.missing+counts.locked+counts.active+counts.ready == 0 then Exclude("no unfinished visible quests") end
    if self:GetOption("filters.onlyReady") and counts.ready == 0 then Exclude("no ready visible quests") end
    local relevant, tracked = false, false
    for _, row in ipairs(raw.quests) do
        if self:GetQuestAvailability(row.quest, context) ~= "unavailable" then
            relevant=true
            if row.state == "active" or row.state == "ready" then tracked=true end
        end
    end
    if #status.dungeon.quests > 0 and #status.quests == 0 then Exclude("all quest rows hidden") end
    if #status.quests == 0 and not self:DungeonHasVisibleQuests(status.key, context) then Exclude("no faction-eligible quest coverage") end
    if not relevant and #status.quests > 0 and not self:GetOption("filters.showUnavailable") then Exclude("no eligible quests") end
    if tracked and not self:GetOption("filters.hideTrackedDungeons") then return #reasons==0,reasons end
    local level = context.level
    local low, high = tostring(status.dungeon.recommendedLevel):match("(%d+)%D+(%d+)")
    low, high = tonumber(low) or status.dungeon.minLevel, tonumber(high) or status.dungeon.minLevel
    if level > 0 then
        if self:GetOption("filters.hideGrayDungeons") and self:GetQuestColorInfo(high, level) == "gray" then Exclude("gray dungeon hidden") end
        if self:GetOption("filters.hideRedDungeons") and self:GetQuestColorInfo(low, level) == "red" then Exclude("red dungeon hidden") end
        if self:GetOption("filters.hideLowDungeons") and high+self:GetOption("filters.lowLevelGap") < level then Exclude("below configured level range") end
        if self:GetOption("filters.hideHighDungeons") and low-self:GetOption("filters.highLevelGap") > level then Exclude("above configured level range") end
    end
    if self:GetOption("filters.hideGrayDungeons") and #status.quests > 0 then
        local allGray = true
        for _, row in ipairs(status.quests) do if not self:IsQuestGray(row.quest, {level=level}) then allGray=false end end
        if allGray then Exclude("all visible quests gray") end
    end
    return #reasons==0,reasons
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
