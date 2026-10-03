local addonName, DQT = ...

DQT.events = CreateFrame("Frame")
DQT.loaded = false

local unpackResults = unpack or table.unpack
local function Pack(...) return { n = select("#", ...), ... } end
local function CallAPI(fn, ...)
    if type(fn) ~= "function" then return nil end
    local results = Pack(pcall(fn, ...))
    if not results[1] then
        DQT.lastAPIError = tostring(results[2])
        return nil
    end
    return unpackResults(results, 2, results.n)
end

local function IsFinished(value)
    return value == true or value == 1
end

local function Now()
    return CallAPI(GetTime) or CallAPI(time) or 0
end

local orderedDungeonKeys = {
    "ragefire-chasm",
    "ruins-of-lordaeron",
    "deadmines",
    "hall-of-thanes",
    "wailing-caverns",
    "shadowfang-keep",
    "the-stockade",
    "excavation-site-wetlands",
    "blackfathom-deeps",
    "city-of-dalaran",
    "scarlet-monastery-graveyard",
    "gnomeregan",
    "scarlet-monastery-library",
    "razorfen-kraul",
    "scarlet-monastery-armory",
}

local function CopyDefaults(defaults, target)
    target = type(target) == "table" and target or {}
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            target[key] = CopyDefaults(value, target[key])
        elseif target[key] == nil then
            target[key] = value
        end
    end
    return target
end

local function NormalizeQuestTitle(title)
    return type(title) == "string" and title:lower():gsub("%s+", " "):match("^%s*(.-)%s*$") or nil
end

local function SafeNumber(value, fallback)
    if type(value) == "number" then return value end
    return fallback or 0
end

function DQT:IsQuestComplete(questID)
    if not questID then return false end

    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        local complete = CallAPI(C_QuestLog.IsQuestFlaggedCompleted, questID)
        if IsFinished(complete) then return true end
    end

    if IsQuestFlaggedCompleted then
        local complete = CallAPI(IsQuestFlaggedCompleted, questID)
        if IsFinished(complete) then return true end
    end

    return false
end

function DQT:GetQuestLogIndexByQuestID(questID)
    if not questID then return nil end

    if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
        local index = CallAPI(C_QuestLog.GetLogIndexForQuestID, questID)
        if type(index) == "number" and index > 0 then return index end
    end

    if GetQuestLogTitle and GetNumQuestLogEntries then
        for index = 1, CallAPI(GetNumQuestLogEntries) or 0 do
            local _, _, _, _, _, _, _, id = CallAPI(GetQuestLogTitle, index)
            if id == questID then return index end
        end
    end

    return nil
end

function DQT:GetQuestLogIndexByQuestName(questName, questID)
    if not questName then return nil end
    local wanted = NormalizeQuestTitle(questName)
    local ambiguous = false
    if questID then
        for id, quest in pairs(self.quests or {}) do
            if id ~= questID and NormalizeQuestTitle(quest.name) == wanted then ambiguous = true; break end
        end
    end
    local function Matches(title, id, isHeader)
        if isHeader or NormalizeQuestTitle(title) ~= wanted then return false end
        if questID and type(id) == "number" and id > 0 then return id == questID end
        return not ambiguous
    end

    if C_QuestLog and C_QuestLog.GetInfo and C_QuestLog.GetNumQuestLogEntries then
        for index = 1, CallAPI(C_QuestLog.GetNumQuestLogEntries) or 0 do
            local info = CallAPI(C_QuestLog.GetInfo, index)
            if type(info) == "table" and Matches(info.title, info.questID, info.isHeader) then
                return index
            end
        end
    end

    if GetQuestLogTitle and GetNumQuestLogEntries then
        for index = 1, CallAPI(GetNumQuestLogEntries) or 0 do
            local title, _, _, isHeader, _, _, _, id = CallAPI(GetQuestLogTitle, index)
            if Matches(title, id, isHeader) then return index end
        end
    end

    return nil
end

function DQT:IsQuestActive(questID, questName)
    if questID and C_QuestLog and C_QuestLog.IsOnQuest then
        local active = CallAPI(C_QuestLog.IsOnQuest, questID)
        if IsFinished(active) then return true end
    end

    if questID and self:GetQuestLogIndexByQuestID(questID) then return true end
    if questName and self:GetQuestLogIndexByQuestName(questName, questID) then return true end

    return false
end

function DQT:IsQuestReadyForTurnIn(questID, questName)
    if not questID and not questName then return false end

    if questID and C_QuestLog and C_QuestLog.ReadyForTurnIn then
        local ready = CallAPI(C_QuestLog.ReadyForTurnIn, questID)
        if IsFinished(ready) then return true end
    end

    local index = self:GetQuestLogIndexByQuestID(questID) or self:GetQuestLogIndexByQuestName(questName, questID)
    if index then
        if C_QuestLog and C_QuestLog.GetInfo then
            local info = CallAPI(C_QuestLog.GetInfo, index)
            if type(info) == "table" and IsFinished(info.isComplete) then return true end
        end

        if IsCompleteQuest then
            local ready = CallAPI(IsCompleteQuest, index)
            if IsFinished(ready) then return true end
        end

        if GetQuestLogTitle then
            local _, _, _, _, _, isComplete = CallAPI(GetQuestLogTitle, index)
            if IsFinished(isComplete) then return true end
        end

        if GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
            local objectives = CallAPI(GetNumQuestLeaderBoards, index)
            if type(objectives) == "number" and objectives > 0 then
                local allFinished = true
                for objectiveIndex = 1, objectives do
                    local _, _, finished = CallAPI(GetQuestLogLeaderBoard, objectiveIndex, index)
                    if not IsFinished(finished) then
                        allFinished = false
                        break
                    end
                end
                if allFinished then return true end
            end
        end
    end

    return false
end

function DQT:GetPlayerContext()
    local faction = CallAPI(UnitFactionGroup, "player")
    local classTag, raceTag
    if UnitClass then classTag = select(2, CallAPI(UnitClass, "player")) end
    if UnitRace then raceTag = select(2, CallAPI(UnitRace, "player")) end
    local level = CallAPI(UnitLevel, "player") or 0
    local currentXp = CallAPI(UnitXP, "player") or 0
    local maxXp = CallAPI(UnitXPMax, "player") or 0
    return { faction = faction, class = classTag, race = raceTag, level = level, currentXp = currentXp, maxXp = maxXp }
end

local function ContainsValue(values, value)
    if not values or not value then return false end
    for _, candidate in ipairs(values) do
        if candidate == value then return true end
    end
    return false
end

function DQT:GetQuestAvailability(quest, context)
    context = context or self:GetPlayerContext()

    if quest.faction and context.faction and quest.faction ~= context.faction then
        return "unavailable", "Different faction"
    end

    if quest.classes and context.class and not ContainsValue(quest.classes, context.class) then
        return "unavailable", "Different class"
    end

    if quest.races and context.race and not ContainsValue(quest.races, context.race) then
        return "unavailable", "Different race"
    end
    if quest.excludedRaces and context.race and ContainsValue(quest.excludedRaces, context.race) then
        return "unavailable", "Unavailable for this race"
    end

    if quest.minLevel and context.level and context.level > 0 and context.level < quest.minLevel then
        return "locked", "Requires level " .. tostring(quest.minLevel)
    end

    for _, prereq in ipairs(quest.prerequisites or {}) do
        if prereq.relationship == "required" and prereq.questID and not self:IsQuestComplete(prereq.questID) then
            local prereqQuest = self:GetQuest(prereq.questID)
            local prereqName = prereqQuest and prereqQuest.name or ("quest " .. tostring(prereq.questID))
            return "locked", "Requires " .. prereqName
        end
    end

    return "available", "Available"
end

function DQT:QuestMatchesPlayerFaction(quest, context)
    if not quest then return false end
    context = context or self:GetPlayerContext()
    if not quest.faction or quest.faction == "Both" then return true end
    if not context.faction then return true end
    return quest.faction == context.faction
end

function DQT:QuestMatchesPlayerClass(quest, context)
    context = context or self:GetPlayerContext()
    return not quest.classes or not context.class or ContainsValue(quest.classes, context.class)
end

function DQT:DungeonHasVisibleQuests(dungeonKey, context)
    local dungeon = self:GetDungeon(dungeonKey)
    if not dungeon then return false end
    context = context or self:GetPlayerContext()
    if #(dungeon.quests or {}) == 0 then
        return not dungeon.factions or not context.faction or ContainsValue(dungeon.factions, context.faction)
    end
    for _, questID in ipairs(dungeon.quests or {}) do
        local quest = self:GetQuest(questID)
        if quest and self:QuestMatchesPlayerFaction(quest, context) and self:QuestMatchesPlayerClass(quest, context) then return true end
    end
    return dungeon.factions and ContainsValue(dungeon.factions, context.faction) or false
end
function DQT:GetDungeon(dungeonKey)
    local dungeon = self.dungeons and self.dungeons[dungeonKey]
    if dungeon and self.GetSyncedDungeon then return self:GetSyncedDungeon(dungeonKey, dungeon) end
    return dungeon
end

function DQT:GetQuest(questID)
    return (self.quests and self.quests[questID]) or (self.db and self.db.partyDataSync and self.db.partyQuestCache and self.db.partyQuestCache[questID])
end

function DQT:GetOrderedDungeonKeys()
    local keys, seen = {}, {}
    for _, key in ipairs(orderedDungeonKeys) do
        if self.dungeons and self.dungeons[key] then
            table.insert(keys, key)
            seen[key] = true
        end
    end
    for key in pairs(self.dungeons or {}) do
        if not seen[key] then table.insert(keys, key) end
    end
    return keys
end

function DQT:GetQuestState(questID, quest, context)
    if self:IsQuestComplete(questID) then
        return "completed", "Completed"
    end

    if self:IsQuestReadyForTurnIn(questID, quest and quest.name) then
        return "ready", "Ready for turn-in"
    end

    if self:IsQuestActive(questID, quest and quest.name) then
        return "active", "In progress"
    end

    local availability, reason = self:GetQuestAvailability(quest, context)
    if availability == "locked" then return "locked", reason end
    if availability == "unavailable" then return "unavailable", reason end
    return "missing", reason or "Missing"
end

function DQT:GetQuestRewardXP(quest)
    if not quest then return 0, "none" end
    if quest.partySupplied then return 0, "Party supplied (XP unverified)" end
    if quest.foreverXp then
        if quest.xpReported then return quest.foreverXp, "Forever (player reported)" end
        if quest.xpEstimate then return quest.foreverXp, "Forever (Oct 1 estimate)" end
        if quest.xpOutdated then return quest.foreverXp, "Forever (outdated; unverified)" end
        return quest.foreverXp, "Forever"
    end
    if quest.classicXp then return quest.classicXp, "Classic" end
    return 0, "unknown"
end

function DQT:GetQuestColorInfo(questLevel, playerLevel)
    questLevel = SafeNumber(questLevel, 0)
    playerLevel = SafeNumber(playerLevel, 0)

    if questLevel <= 0 or playerLevel <= 0 then
        return "unknown", 1, 0
    end

    local diff = questLevel - playerLevel
    local greenRange = 5
    if GetQuestGreenRange then
        greenRange = CallAPI(GetQuestGreenRange) or greenRange
    end

    if diff >= 5 then return "red", 1, diff end
    if diff >= 3 then return "orange", 1, diff end
    if diff >= -2 then return "yellow", 1, diff end
    if diff >= -greenRange then return "green", 1, diff end
    return "gray", 0, diff
end

function DQT:GetQuestXpEfficiencyAtLevel(quest, playerLevel)
    local xp = self:GetQuestRewardXP(quest)
    local color, multiplier = self:GetQuestColorInfo(quest and quest.questLevel, playerLevel)
    return math.floor(xp * multiplier), color
end

function DQT:GetQuestXpEfficiency(quest, context)
    return self:GetQuestXpEfficiencyAtLevel(quest, SafeNumber(context and context.level, 0))
end

function DQT:GetTurnInRisk(quest, context)
    local level = SafeNumber(context and context.level, 0)
    if level <= 0 then
        return "unknown", 0, "unknown", "unknown"
    end

    local currentXp, currentColor = self:GetQuestXpEfficiencyAtLevel(quest, level)
    local nextXp, nextColor = self:GetQuestXpEfficiencyAtLevel(quest, level + 1)
    local loss = math.max(0, currentXp - nextXp)

    if currentColor ~= nextColor or loss > 0 then
        if nextColor == "gray" then return "gray-next-level", loss, currentColor, nextColor end
        if nextColor == "green" then return "green-next-level", loss, currentColor, nextColor end
        return "lower-next-level", loss, currentColor, nextColor
    end

    return "stable", 0, currentColor, nextColor
end
function DQT:BuildTurnInItem(row, dungeonKey, dungeon, context, xpToLevel)
    local quest = row.quest
    local rawXp, xpSource = self:GetQuestRewardXP(quest)
    local effectiveXp, currentColor = self:GetQuestXpEfficiency(quest, context)
    local risk, xpLossOnLevel, _, nextColor = self:GetTurnInRisk(quest, context)
    local dings = xpToLevel > 0 and effectiveXp >= xpToLevel
    local atLevelRisk = risk ~= "stable" and risk ~= "unknown"
    local priorityScore = effectiveXp

    if dings then priorityScore = priorityScore + 100000 end
    if atLevelRisk then priorityScore = priorityScore + 50000 + xpLossOnLevel end
    if risk == "gray-next-level" then priorityScore = priorityScore + 25000 end
    if risk == "green-next-level" then priorityScore = priorityScore + 10000 end
    if quest.turnInGroup then priorityScore = priorityScore + quest.turnInGroup end

    return {
        questID = row.questID,
        quest = quest,
        dungeonKey = dungeonKey,
        dungeon = dungeon,
        rawXp = rawXp,
        xpSource = xpSource,
        effectiveXp = effectiveXp,
        currentColor = currentColor,
        nextColor = nextColor,
        risk = risk,
        xpLossOnLevel = xpLossOnLevel,
        xpToLevel = xpToLevel,
        dings = dings,
        atLevelRisk = atLevelRisk,
        priorityScore = priorityScore,
    }
end

function DQT:SortTurnIns(turnIns)
    table.sort(turnIns, function(a, b)
        if a.priorityScore ~= b.priorityScore then return a.priorityScore > b.priorityScore end
        local aLevel = a.quest.questLevel or 0
        local bLevel = b.quest.questLevel or 0
        if aLevel ~= bLevel then return aLevel > bLevel end
        local aDungeon = a.dungeon and a.dungeon.name or ""
        local bDungeon = b.dungeon and b.dungeon.name or ""
        if aDungeon ~= bDungeon then return aDungeon < bDungeon end
        return (a.quest.name or "") < (b.quest.name or "")
    end)
end

function DQT:GetTurnInPriority(status, context)
    context = context or self:GetPlayerContext()
    local xpToLevel = 0
    if context.maxXp and context.maxXp > 0 then
        xpToLevel = math.max(0, context.maxXp - SafeNumber(context.currentXp, 0))
    end

    local turnIns = {}
    for _, row in ipairs(status.quests or {}) do
        if row.state == "ready" then
            table.insert(turnIns, self:BuildTurnInItem(row, status.key, status.dungeon, context, xpToLevel))
        end
    end

    self:SortTurnIns(turnIns)
    return { context = context, xpToLevel = xpToLevel, quests = turnIns }
end

function DQT:GetGlobalTurnInPriority()
    local context = self:GetPlayerContext()
    local xpToLevel = 0
    if context.maxXp and context.maxXp > 0 then
        xpToLevel = math.max(0, context.maxXp - SafeNumber(context.currentXp, 0))
    end

    local turnIns, seenQuests = {}, {}
    local ignoreGray = self:GetOption("filters.ignoreGrayTurnIns")
    local dungeonKeys = self:GetOrderedDungeonKeys()
    for _, dungeonKey in ipairs(dungeonKeys) do
        local status = self:GetDungeonQuestStatus(dungeonKey, false, true, context)
        if status then
            for _, row in ipairs(status.quests or {}) do
                if row.state == "ready" and not seenQuests[row.questID] and not (ignoreGray and self:IsQuestGray(row.quest, context)) then
                    seenQuests[row.questID] = true
                    table.insert(turnIns, self:BuildTurnInItem(row, dungeonKey, status.dungeon, context, xpToLevel))
                end
            end
        end
    end

    self:SortTurnIns(turnIns)
    return { context = context, xpToLevel = xpToLevel, quests = turnIns }
end

function DQT:GetDungeonQuestStatus(dungeonKey, includeUnavailable, skipTurnIns, context)
    local dungeon = self:GetDungeon(dungeonKey)
    if not dungeon then return nil end
    context = context or self:GetPlayerContext()

    local rows = {}
    local counts = { completed = 0, ready = 0, active = 0, missing = 0, locked = 0, unavailable = 0 }

    for _, questID in ipairs(dungeon.quests or {}) do
        local quest = self:GetQuest(questID)
        if quest and (includeUnavailable or (self:QuestMatchesPlayerFaction(quest, context) and self:QuestMatchesPlayerClass(quest, context))) then
            local state, stateReason = self:GetQuestState(questID, quest, context)
            counts[state] = (counts[state] or 0) + 1
            table.insert(rows, {
                questID = questID,
                quest = quest,
                state = state,
                stateReason = stateReason,
                complete = state == "completed",
                ready = state == "ready",
            })
        end
    end

    local status = { key = dungeonKey, dungeon = dungeon, quests = rows, counts = counts }
    if not skipTurnIns then status.turnIns = self:GetTurnInPriority(status, context) end
    return status
end

local partyPrefix = "DQT1"

local function GetAddonChannel()
    if LE_PARTY_CATEGORY_INSTANCE and CallAPI(IsInGroup, LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
    if CallAPI(IsInRaid) then return "RAID" end
    if CallAPI(IsInGroup) or (CallAPI(GetNumPartyMembers) or 0) > 0 then return "PARTY" end
    return nil
end

local function SendAddon(prefix, message, channel, target)
    local fn = C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
    if type(fn) ~= "function" then return false end
    local ok, result = pcall(fn, prefix, message, channel, target)
    if not ok then DQT.lastAPIError = tostring(result) end
    return ok and result ~= false
end

local function RegisterAddonPrefix(prefix)
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        return CallAPI(C_ChatInfo.RegisterAddonMessagePrefix, prefix)
    end
    if RegisterAddonMessagePrefix then
        return CallAPI(RegisterAddonMessagePrefix, prefix)
    end
end

function DQT:GetQuestShareState(questID, questName)
    local index = self:GetQuestLogIndexByQuestID(questID) or self:GetQuestLogIndexByQuestName(questName)
    if not index then return false, "Not in quest log" end

    if GetQuestLogPushable then
        local pushable = CallAPI(GetQuestLogPushable, index)
        if not pushable then return false, "Not shareable" end
    elseif C_QuestLog and C_QuestLog.IsPushableQuest and questID then
        local pushable = CallAPI(C_QuestLog.IsPushableQuest, questID)
        if not pushable then return false, "Not shareable" end
    else
        return false, "Shareability API unavailable"
    end

    return true, "Shareable"
end

function DQT:ShareQuest(questID, questName)
    local index = self:GetQuestLogIndexByQuestID(questID) or self:GetQuestLogIndexByQuestName(questName)
    if not index then return false, "Not in quest log" end

    local shareable, reason = self:GetQuestShareState(questID, questName)
    if not shareable then return false, reason end

    local fn = QuestLogPushQuest or (C_QuestLog and C_QuestLog.ShareQuest)
    if type(fn) ~= "function" then return false, "Quest sharing API unavailable" end
    local ok, result = pcall(fn, QuestLogPushQuest and index or questID)
    if not ok then self.lastAPIError = tostring(result); return false, "Quest sharing API failed" end
    if result == false then return false, "Client rejected sharing" end
    local quest = self:GetQuest(questID)
    if quest and self.OfferQuestData then self:OfferQuestData(quest.dungeon) end
    return true, "Share requested"
end

function DQT:ShareDungeonQuests(dungeonKey)
    local status = self:GetDungeonQuestStatus(dungeonKey)
    if not status then return 0, 0 end

    if not GetAddonChannel() then self:Print("Join a party before sharing quests."); return 0, 0 end
    local shared, skipped, reasons = 0, 0, {}
    for _, row in ipairs(status.quests or {}) do
        if row.state == "active" or row.state == "ready" then
            local ok, reason = self:ShareQuest(row.questID, row.quest and row.quest.name)
            if ok then shared = shared + 1 else
                skipped = skipped + 1
                reasons[reason] = (reasons[reason] or 0) + 1
            end
        end
    end

    self:Print(string.format("Requested sharing for %d %s quest(s). %d skipped.", shared, status.dungeon.name, skipped))
    if shared == 0 and skipped == 0 then self:Print("No active or ready quests in this dungeon to share.") end
    local reasonKeys = {}
    for reason in pairs(reasons) do table.insert(reasonKeys, reason) end
    table.sort(reasonKeys)
    for _, reason in ipairs(reasonKeys) do self:Print(reason .. ": " .. reasons[reason]) end
    return shared, skipped
end

function DQT:BuildDungeonStatusPayload(dungeonKey)
    local status = self:GetDungeonQuestStatus(dungeonKey)
    if not status then return nil end

    local pieces = { "STATUS", dungeonKey }
    local questPieces = {}
    for _, row in ipairs(status.quests or {}) do
        table.insert(questPieces, tostring(row.questID) .. ":" .. tostring(row.state or "unknown"))
    end
    table.insert(pieces, table.concat(questPieces, ","))
    return table.concat(pieces, "|")
end

function DQT:SendDungeonStatus(dungeonKey)
    local payload = self:BuildDungeonStatusPayload(dungeonKey)
    if not payload then return false end

    local channel = GetAddonChannel()
    if not channel then return false end
    -- Larger checklists can exceed the 255-byte addon-message limit.
    local header = (self.sendDataOffer and "CAT|" or "STATUS|") .. dungeonKey .. "|"
    local encoded = payload:match("^[^|]+|[^|]+|(.*)$") or ""
    if self.sendDataOffer then
        local ids = {}
        for _, id in ipairs((self.dungeons[dungeonKey] or {}).quests or {}) do
            if self.quests[id] then ids[#ids+1] = tostring(id) end
        end
        encoded = table.concat(ids, ",")
    end
    local chunk = header
    for piece in encoded:gmatch("[^,]+") do
        if #chunk + #piece + 1 > 255 then
            if not SendAddon(partyPrefix, chunk, channel) then return false end
            chunk = header
        end
        chunk = chunk .. (chunk ~= header and "," or "") .. piece
    end
    return SendAddon(partyPrefix, chunk, channel)
end

function DQT:RequestPartyDungeonStatus(dungeonKey)
    if not self:GetDungeon(dungeonKey) then return false end
    self.partyStatus = self.partyStatus or {}
    self.partyStatus[dungeonKey] = self.partyStatus[dungeonKey] or {}

    local channel = GetAddonChannel()
    if not channel then
        self:Print("Join a party to check party quest status.")
        return false
    end

    self.partyRequestTimes = self.partyRequestTimes or {}
    local last = self.partyRequestTimes[dungeonKey]
    if last and Now() - last < 5 then self:Print("Please wait before checking this dungeon again."); return false end
    if not SendAddon(partyPrefix, "REQ|" .. dungeonKey, channel) then
        self:Print("Party addon messaging is unavailable."); return false
    end
    self.partyRequestTimes[dungeonKey] = Now()
    self.partyStatus[dungeonKey] = {}
    self:SendDungeonStatus(dungeonKey)
    if self.OfferQuestData then self:OfferQuestData(dungeonKey) end
    self:Print("Requested party quest status for " .. tostring((self:GetDungeon(dungeonKey) or {}).name or dungeonKey) .. ".")
    return true
end

function DQT:StorePartyDungeonStatus(sender, dungeonKey, encodedQuests)
    if type(sender) ~= "string" or not self:GetDungeon(dungeonKey) then return end
    self.partyStatus = self.partyStatus or {}
    self.partyStatus[dungeonKey] = self.partyStatus[dungeonKey] or {}

    local entry = self.partyStatus[dungeonKey][sender]
    local quests = entry and Now() - entry.time < 5 and entry.quests or {}
    local allowedStates = { completed = true, ready = true, active = true, missing = true, locked = true, unavailable = true }
    local dungeonQuests = {}
    for _, id in ipairs(self:GetDungeon(dungeonKey).quests or {}) do dungeonQuests[id] = true end
    for questID, state in tostring(encodedQuests or ""):gmatch("(%d+):([^,]+)") do
        local id = tonumber(questID)
        if dungeonQuests[id] and allowedStates[state] then quests[id] = state end
    end

    self.partyStatus[dungeonKey][sender] = { time = Now(), quests = quests }
end

function DQT:GetPartyQuestSummary(dungeonKey, questID)
    local entries = self.partyStatus and self.partyStatus[dungeonKey]
    if not entries then return "Party: not checked" end
    local now = Now()

    local total, completed, ready, active, missing, locked = 0, 0, 0, 0, 0, 0
    for _, entry in pairs(entries) do
        local state = entry.quests and entry.quests[questID]
        if now - entry.time <= 120 and state and state ~= "unavailable" then
        total = total + 1
        if state == "completed" then completed = completed + 1
        elseif state == "ready" then ready = ready + 1
        elseif state == "active" then active = active + 1
        elseif state == "locked" then locked = locked + 1
        else missing = missing + 1 end
        end
    end

    if total == 0 then return "Party: not checked" end
    return string.format("Party: %d checked | %d done, %d ready, %d active, %d missing/locked", total, completed, ready, active, missing + locked)
end

function DQT:IsGrouped()
    return GetAddonChannel() ~= nil
end

function DQT:GetPartyDungeonSummary(dungeonKey)
    local entries = self.partyStatus and self.partyStatus[dungeonKey]
    local checked, ready, missing = 0, 0, 0
    local now = Now()
    for _, entry in pairs(entries or {}) do
        if now - entry.time <= 120 then
            checked = checked + 1
            for _, state in pairs(entry.quests or {}) do
                if state == "ready" then ready = ready + 1 end
                if state == "missing" or state == "locked" then missing = missing + 1 end
            end
        end
    end
    if checked == 0 then return "Party: not checked" end
    return string.format("Party: %d checked | Quest totals: %d ready, %d missing/locked", checked, ready, missing)
end

function DQT:NormalizePartySender(sender)
    if type(sender) ~= "string" then return nil end
    local function FullName(unit)
        local name, realm = CallAPI(UnitFullName or UnitName, unit)
        if not name then return nil end
        realm = realm and realm ~= "" and realm or CallAPI(GetNormalizedRealmName) or CallAPI(GetRealmName) or ""
        return name .. (realm ~= "" and "-" .. realm:gsub("[%s%-]", "") or ""), name
    end
    local playerName, playerShort = FullName("player")
    if sender:lower() == tostring(playerName):lower() or sender:lower() == tostring(playerShort):lower() then return nil end
    local count = CallAPI(GetNumGroupMembers) or CallAPI(GetNumRaidMembers) or 0
    local raid = CallAPI(IsInRaid)
    local partyCount = CallAPI(GetNumSubgroupMembers) or CallAPI(GetNumPartyMembers) or 4
    for index = 1, raid and count or partyCount do
        local full, short = FullName((raid and "raid" or "party") .. index)
        if full and (sender:lower() == full:lower() or sender:lower() == short:lower()) then return full end
    end
    return nil
end

function DQT:HandleAddonMessage(prefix, message, channel, sender)
    if prefix ~= partyPrefix or type(message) ~= "string" or #message > 255 or not GetAddonChannel() then return end
    if channel ~= "PARTY" and channel ~= "RAID" and channel ~= "INSTANCE_CHAT" and channel ~= "WHISPER" then return end
    sender = self:NormalizePartySender(sender)
    if not sender then return end
    local command, rest = message:match("^(%w+)|?(.*)$")
    if self.HandleQuestDataMessage and self:HandleQuestDataMessage(command, rest, sender) then return end
    if command == "REQ" then
        if not self:GetOption("party.respond") then return end
        local dungeonKey = rest
        if self:GetDungeon(dungeonKey) then
            self.partyResponseTimes = self.partyResponseTimes or {}
            local last = self.partyResponseTimes[dungeonKey]
            if not last or Now() - last >= 5 then
                self.partyResponseTimes[dungeonKey] = Now()
                self:SendDungeonStatus(dungeonKey)
                if self.OfferQuestData then self:OfferQuestData(dungeonKey) end
            end
        end
        return
    end

    if command == "STATUS" then
        local dungeonKey, encodedQuests = rest:match("^([^|]+)|?(.*)$")
        self:StorePartyDungeonStatus(sender, dungeonKey, encodedQuests)
        self:RequestUIRefresh()
    end
end

function DQT:InitializeComms()
    RegisterAddonPrefix(partyPrefix)
end

function DQT:SendQuestDataMessage(message, target)
    if not GetAddonChannel() or not self:NormalizePartySender(target) then return false end
    return SendAddon(partyPrefix, message, "WHISPER", target)
end

function DQT:Print(message)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99DQT|r " .. tostring(message))
    elseif type(print) == "function" then print("DQT: " .. tostring(message)) end
end

function DQT:OpenDungeon(dungeonKey)
    local status = self:GetDisplayDungeonStatus(dungeonKey)
    if not status then
        self:Print("Unknown dungeon: " .. tostring(dungeonKey))
        return
    end

    if self.UI and self.UI.ShowDungeon then
        self.UI:ShowDungeon(status)
    else
        self:Print(status.dungeon.name)
        for _, row in ipairs(status.quests) do
            self:Print(string.format("[%s] %s - %s", row.stateReason, row.quest.name, row.quest.pickup and row.quest.pickup.name or "Unknown"))
        end
    end
    if self:GetOption("party.autoBroadcast") and self:IsGrouped() then
        self.autoBroadcastTimes = self.autoBroadcastTimes or {}
        local last = self.autoBroadcastTimes[dungeonKey]
        if not last or Now()-last >= 5 then
            self.autoBroadcastTimes[dungeonKey] = Now()
            self:SendDungeonStatus(dungeonKey)
        end
    end
end

function DQT:PrintTurnIns()
    local plan = self:GetGlobalTurnInPriority()
    local turnIns = plan and plan.quests or {}
    if #turnIns == 0 then
        self:Print("No ready-to-turn-in dungeon quests detected.")
        return
    end

    self:Print("Global dungeon turn-in priority:")
    for index, item in ipairs(turnIns) do
        local dingText = item.dings and " - levels you" or ""
        local dungeonName = item.dungeon and item.dungeon.name or "Unknown dungeon"
        self:Print(string.format("%d. [%s] %s: %d XP%s -> %s", index, dungeonName, item.quest.name, item.effectiveXp, dingText, item.quest.turnIn and item.quest.turnIn.name or "Unknown"))
    end
end

function DQT:ShowHelp()
    self:Print("Commands:")
    self:Print("  /dqt - open the dungeon list")
    self:Print("  /dqt list - list known dungeon keys")
    self:Print("  /dqt rfc - open Ragefire Chasm")
    self:Print("  /dqt rol - open Ruins of Lordaeron")
    self:Print("  /dqt wc - open Wailing Caverns")
    self:Print("  /dqt hot - open Hall of Thanes")
    self:Print("  /dqt sfk - open Shadowfang Keep")
    self:Print("  /dqt stocks - open The Stockade")
    self:Print("  /dqt turnins - print global dungeon turn-in priority")
    self:Print("  /dqt debug [questID] - client/API checks and quest state details")
    self:Print("  /dqt options - open Options")
    self:Print("  /dqt minimap - toggle the minimap button")
    self:Print("  /dqt sync on|off|clear - opt-in party quest data or clear received records")
end

function DQT:Debug(questID)
    local context = self:GetPlayerContext()
    self:Print("Version " .. tostring(self.version))
    self:Print("Client build: " .. tostring((select(4, CallAPI(GetBuildInfo))) or "unavailable"))
    self:Print("Level/XP: " .. tostring(context.level) .. " " .. tostring(context.currentXp) .. "/" .. tostring(context.maxXp))
    self:Print("C_QuestLog available: " .. tostring(C_QuestLog ~= nil))
    self:Print("C_QuestLog.IsQuestFlaggedCompleted available: " .. tostring(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted ~= nil))
    self:Print("C_QuestLog.ReadyForTurnIn available: " .. tostring(C_QuestLog and C_QuestLog.ReadyForTurnIn ~= nil))
    self:Print("C_QuestLog.IsOnQuest available: " .. tostring(C_QuestLog and C_QuestLog.IsOnQuest ~= nil))
    self:Print("Legacy IsQuestFlaggedCompleted available: " .. tostring(IsQuestFlaggedCompleted ~= nil))
    self:Print("Addon messaging available: " .. tostring(type(C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage) == "function"))
    self:Print("Sharing available: " .. tostring(type(QuestLogPushQuest or (C_QuestLog and C_QuestLog.ShareQuest)) == "function"))
    self:Print("Last API error: " .. tostring(self.lastAPIError or "none"))
    if questID then
        local quest = self:GetQuest(questID)
        if not quest then self:Print("Unknown tracked quest ID: " .. tostring(questID)); return end
        local state, reason = self:GetQuestState(questID, quest)
        local index = self:GetQuestLogIndexByQuestID(questID)
        local titleIndex = self:GetQuestLogIndexByQuestName(quest.name)
        self:Print(string.format("Quest %d: %s | %s (%s)", questID, quest.name, state, reason))
        self:Print("Log index by ID/title: " .. tostring(index) .. "/" .. tostring(titleIndex))
        self:Print("Completed/ready/active: " .. tostring(self:IsQuestComplete(questID)) .. "/" .. tostring(self:IsQuestReadyForTurnIn(questID, quest.name)) .. "/" .. tostring(self:IsQuestActive(questID, quest.name)))
        local availability, detail = self:GetQuestAvailability(quest, context)
        self:Print("Availability: " .. availability .. " (" .. detail .. ")")
    end
end

local function HandleSlashCommand(input)
    input = input and input:lower():match("^%s*(.-)%s*$") or ""
    local command, rest = input:match("^(%S+)%s*(.*)$")

    if command == "dungeon" and rest ~= "" then DQT:OpenDungeon(rest); return end
    if command == "rfc" then DQT:OpenDungeon("ragefire-chasm"); return end
    if command == "rol" or command == "ruins" then DQT:OpenDungeon("ruins-of-lordaeron"); return end
    if command == "wc" or command == "wailing" then DQT:OpenDungeon("wailing-caverns"); return end
    if command == "hot" or command == "thanes" or command == "hall" then DQT:OpenDungeon("hall-of-thanes"); return end
    if command == "sfk" or command == "shadowfang" then DQT:OpenDungeon("shadowfang-keep"); return end
    if command == "stockade" or command == "stocks" then DQT:OpenDungeon("the-stockade"); return end
    if command == "turnins" or command == "turnin" then DQT:PrintTurnIns(); return end

    if command == "list" then
        DQT:Print("Known dungeons:")
        for _, key in ipairs(DQT:GetOrderedDungeonKeys()) do
            local dungeon = DQT.dungeons[key]
            DQT:Print(string.format("  %s - /dqt dungeon %s", dungeon.name, key))
        end
        return
    end

    if command == "debug" then DQT:Debug(tonumber(rest)); return end
    if command == "options" then DQT.UI:ShowOptions(); return end
    if command == "minimap" then DQT:SetOption("minimap.hide", not DQT:GetOption("minimap.hide")); return end
    if command == "sync" and DQT.SetQuestDataSync then DQT:SetQuestDataSync(rest); return end
    if command == "help" or command == "?" then DQT:ShowHelp(); return end

    if DQT.UI and DQT.UI.Toggle then DQT.UI:Toggle() else DQT:ShowHelp() end
end

local refreshElapsed
local function FlushUIRefresh(_, elapsed)
    refreshElapsed = refreshElapsed + elapsed
    if refreshElapsed < 0.05 then return end
    DQT.events:SetScript("OnUpdate", nil)
    refreshElapsed = nil
    if DQT.UI and DQT.UI.RefreshCurrentDungeon then DQT.UI:RefreshCurrentDungeon() end
end
function DQT:RequestUIRefresh()
    if refreshElapsed or not self.UI or not self.UI.frame or not self.UI.frame:IsShown() then return end
    refreshElapsed = 0
    self.events:SetScript("OnUpdate", FlushUIRefresh)
end

DQT.events:RegisterEvent("ADDON_LOADED")
DQT.events:RegisterEvent("QUEST_LOG_UPDATE")
DQT.events:RegisterEvent("PLAYER_XP_UPDATE")
DQT.events:RegisterEvent("PLAYER_LEVEL_UP")
DQT.events:RegisterEvent("CHAT_MSG_ADDON")
DQT.events:RegisterEvent("GROUP_ROSTER_UPDATE")
DQT.events:SetScript("OnEvent", function(_, event, ...)
    local loadedAddon, message, channel, sender = ...
    if event == "ADDON_LOADED" then
        if loadedAddon ~= addonName then return end
        DungeonQuestTrackerDB = CopyDefaults(DQT.defaults, DungeonQuestTrackerDB)
        DQT.db = DungeonQuestTrackerDB
        DQT:InitializeOptions()
        if DQT.InitializeQuestDataSync then DQT:InitializeQuestDataSync() end
        DQT.loaded = true
        DQT:InitializeComms()
        SLASH_DUNGEONQUESTTRACKER1 = "/dqt"
        SLASH_DUNGEONQUESTTRACKER2 = "/dungeonquesttracker"
        SlashCmdList.DUNGEONQUESTTRACKER = HandleSlashCommand
        DQT:Print("Loaded. Type /dqt rfc to check Ragefire Chasm.")
        return
    end

    if event == "CHAT_MSG_ADDON" then
        DQT:HandleAddonMessage(loadedAddon, message, channel, sender)
        return
    end

    if event == "GROUP_ROSTER_UPDATE" then
        DQT.partyStatus = {}
        DQT.partyResponseTimes = {}
        DQT.autoBroadcastTimes = {}
        if DQT.ResetQuestDataTransfers then DQT:ResetQuestDataTransfers() end
    end

    DQT:RequestUIRefresh()
end)










