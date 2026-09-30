local addonName, DQT = ...

DQT.events = CreateFrame("Frame")
DQT.loaded = false

local orderedDungeonKeys = {
    "ragefire-chasm",
    "ruins-of-lordaeron",
    "deadmines",
    "hall-of-thanes",
    "wailing-caverns",
    "shadowfang-keep",
    "the-stockade",
}

local function CopyDefaults(defaults, target)
    target = target or {}
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
    return title and title:lower():gsub("%s+", " "):match("^%s*(.-)%s*$") or nil
end

local function SafeNumber(value, fallback)
    if type(value) == "number" then return value end
    return fallback or 0
end

function DQT:IsQuestComplete(questID)
    if not questID then return false end

    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        local complete = C_QuestLog.IsQuestFlaggedCompleted(questID)
        if complete then return true end
    end

    if IsQuestFlaggedCompleted then
        local complete = IsQuestFlaggedCompleted(questID)
        if complete then return true end
    end

    return false
end

function DQT:GetQuestLogIndexByQuestID(questID)
    if not questID then return nil end

    if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
        local index = C_QuestLog.GetLogIndexForQuestID(questID)
        if index and index > 0 then return index end
    end

    if GetQuestLogTitle and GetNumQuestLogEntries then
        for index = 1, GetNumQuestLogEntries() do
            local _, _, _, _, _, _, _, id = GetQuestLogTitle(index)
            if id == questID then return index end
        end
    end

    return nil
end

function DQT:GetQuestLogIndexByQuestName(questName)
    if not questName then return nil end
    local wanted = NormalizeQuestTitle(questName)

    if C_QuestLog and C_QuestLog.GetInfo and C_QuestLog.GetNumQuestLogEntries then
        for index = 1, C_QuestLog.GetNumQuestLogEntries() do
            local info = C_QuestLog.GetInfo(index)
            if info and NormalizeQuestTitle(info.title) == wanted then
                return index
            end
        end
    end

    if GetQuestLogTitle and GetNumQuestLogEntries then
        for index = 1, GetNumQuestLogEntries() do
            local title = GetQuestLogTitle(index)
            if NormalizeQuestTitle(title) == wanted then return index end
        end
    end

    return nil
end

function DQT:IsQuestActive(questID, questName)
    if questID and C_QuestLog and C_QuestLog.IsOnQuest then
        local active = C_QuestLog.IsOnQuest(questID)
        if active then return true end
    end

    if questID and self:GetQuestLogIndexByQuestID(questID) then return true end
    if questName and self:GetQuestLogIndexByQuestName(questName) then return true end

    return false
end

function DQT:IsQuestReadyForTurnIn(questID, questName)
    if not questID and not questName then return false end

    if questID and C_QuestLog and C_QuestLog.ReadyForTurnIn then
        local ready = C_QuestLog.ReadyForTurnIn(questID)
        if ready then return true end
    end

    local index = self:GetQuestLogIndexByQuestID(questID) or self:GetQuestLogIndexByQuestName(questName)
    if index then
        if C_QuestLog and C_QuestLog.GetInfo then
            local info = C_QuestLog.GetInfo(index)
            if info and info.isComplete then return true end
        end

        if IsCompleteQuest then
            local ready = IsCompleteQuest(index)
            if ready then return true end
        end

        if GetQuestLogTitle then
            local _, _, _, _, _, isComplete = GetQuestLogTitle(index)
            if isComplete then return true end
        end

        if GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
            local objectives = GetNumQuestLeaderBoards(index)
            if objectives and objectives > 0 then
                local allFinished = true
                for objectiveIndex = 1, objectives do
                    local _, _, finished = GetQuestLogLeaderBoard(objectiveIndex, index)
                    if not finished then
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
    local faction = UnitFactionGroup and UnitFactionGroup("player") or nil
    local _, classTag = UnitClass and UnitClass("player") or nil
    local _, raceTag = UnitRace and UnitRace("player") or nil
    local level = UnitLevel and UnitLevel("player") or 0
    local currentXp = UnitXP and UnitXP("player") or 0
    local maxXp = UnitXPMax and UnitXPMax("player") or 0
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

function DQT:DungeonHasVisibleQuests(dungeonKey)
    local dungeon = self:GetDungeon(dungeonKey)
    if not dungeon then return false end
    local context = self:GetPlayerContext()
    for _, questID in ipairs(dungeon.quests or {}) do
        local quest = self:GetQuest(questID)
        if self:QuestMatchesPlayerFaction(quest, context) then return true end
    end
    return false
end
function DQT:GetDungeon(dungeonKey)
    return self.dungeons and self.dungeons[dungeonKey]
end

function DQT:GetQuest(questID)
    return self.quests and self.quests[questID]
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

function DQT:GetQuestState(questID, quest)
    if self:IsQuestComplete(questID) then
        return "completed", "Completed"
    end

    if self:IsQuestReadyForTurnIn(questID, quest and quest.name) then
        return "ready", "Ready for turn-in"
    end

    if self:IsQuestActive(questID, quest and quest.name) then
        return "active", "In progress"
    end

    local availability, reason = self:GetQuestAvailability(quest)
    if availability == "locked" then return "locked", reason end
    if availability == "unavailable" then return "unavailable", reason end
    return "missing", reason or "Missing"
end

function DQT:GetQuestRewardXP(quest)
    if not quest then return 0, "none" end
    if quest.foreverXp then return quest.foreverXp, "Forever" end
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
        greenRange = GetQuestGreenRange() or greenRange
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

function DQT:GetTurnInPriority(status)
    local context = self:GetPlayerContext()
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

    local turnIns = {}
    local dungeonKeys = self:GetOrderedDungeonKeys()
    for _, dungeonKey in ipairs(dungeonKeys) do
        local status = self:GetDungeonQuestStatus(dungeonKey)
        if status then
            for _, row in ipairs(status.quests or {}) do
                if row.state == "ready" then
                    table.insert(turnIns, self:BuildTurnInItem(row, dungeonKey, status.dungeon, context, xpToLevel))
                end
            end
        end
    end

    self:SortTurnIns(turnIns)
    return { context = context, xpToLevel = xpToLevel, quests = turnIns }
end

function DQT:GetDungeonQuestStatus(dungeonKey)
    local dungeon = self:GetDungeon(dungeonKey)
    if not dungeon then return nil end

    local rows = {}
    local counts = { completed = 0, ready = 0, active = 0, missing = 0, locked = 0, unavailable = 0 }

    for _, questID in ipairs(dungeon.quests or {}) do
        local quest = self:GetQuest(questID)
        if quest and self:QuestMatchesPlayerFaction(quest) then
            local state, stateReason = self:GetQuestState(questID, quest)
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
    status.turnIns = self:GetTurnInPriority(status)
    return status
end

local partyPrefix = "DQT1"

local function GetAddonChannel()
    if IsInGroup and LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
    if IsInRaid and IsInRaid() then return "RAID" end
    if IsInGroup and IsInGroup() then return "PARTY" end
    return nil
end

local function SendAddon(prefix, message, channel, target)
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        return C_ChatInfo.SendAddonMessage(prefix, message, channel, target)
    end
    if SendAddonMessage then
        return SendAddonMessage(prefix, message, channel, target)
    end
end

local function RegisterAddonPrefix(prefix)
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        return C_ChatInfo.RegisterAddonMessagePrefix(prefix)
    end
    if RegisterAddonMessagePrefix then
        return RegisterAddonMessagePrefix(prefix)
    end
end

function DQT:GetQuestShareState(questID, questName)
    local index = self:GetQuestLogIndexByQuestID(questID) or self:GetQuestLogIndexByQuestName(questName)
    if not index then return false, "Not in quest log" end

    if GetQuestLogPushable then
        local pushable = GetQuestLogPushable(index)
        if not pushable then return false, "Not shareable" end
    elseif C_QuestLog and C_QuestLog.IsPushableQuest and questID then
        local pushable = C_QuestLog.IsPushableQuest(questID)
        if not pushable then return false, "Not shareable" end
    end

    return true, "Shareable"
end

function DQT:ShareQuest(questID, questName)
    local index = self:GetQuestLogIndexByQuestID(questID) or self:GetQuestLogIndexByQuestName(questName)
    if not index then return false, "Not in quest log" end

    local shareable, reason = self:GetQuestShareState(questID, questName)
    if not shareable then return false, reason end

    if C_QuestLog and C_QuestLog.SetSelectedQuest then
        C_QuestLog.SetSelectedQuest(questID)
    elseif SelectQuestLogEntry then
        SelectQuestLogEntry(index)
    end

    if QuestLogPushQuest then
        QuestLogPushQuest(index)
        return true, "Shared"
    end

    if C_QuestLog and C_QuestLog.ShareQuest then
        C_QuestLog.ShareQuest(questID)
        return true, "Shared"
    end

    return false, "Quest sharing API unavailable"
end

function DQT:ShareDungeonQuests(dungeonKey)
    local status = self:GetDungeonQuestStatus(dungeonKey)
    if not status then return 0, 0 end

    local shared, skipped = 0, 0
    for _, row in ipairs(status.quests or {}) do
        if row.state == "active" or row.state == "ready" then
            local ok = self:ShareQuest(row.questID, row.quest and row.quest.name)
            if ok then shared = shared + 1 else skipped = skipped + 1 end
        end
    end

    self:Print(string.format("Shared %d %s quest(s). %d skipped.", shared, status.dungeon.name, skipped))
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

function DQT:SendDungeonStatus(dungeonKey, target)
    local payload = self:BuildDungeonStatusPayload(dungeonKey)
    if not payload then return false end

    if target then
        SendAddon(partyPrefix, payload, "WHISPER", target)
        return true
    end

    local channel = GetAddonChannel()
    if not channel then return false end
    SendAddon(partyPrefix, payload, channel)
    return true
end

function DQT:RequestPartyDungeonStatus(dungeonKey)
    if not dungeonKey then return false end
    self.partyStatus = self.partyStatus or {}
    self.partyStatus[dungeonKey] = self.partyStatus[dungeonKey] or {}

    local channel = GetAddonChannel()
    if not channel then
        self:Print("Join a party to check party quest status.")
        return false
    end

    SendAddon(partyPrefix, "REQ|" .. dungeonKey, channel)
    self:SendDungeonStatus(dungeonKey)
    self:Print("Requested party quest status for " .. tostring((self:GetDungeon(dungeonKey) or {}).name or dungeonKey) .. ".")
    return true
end

function DQT:StorePartyDungeonStatus(sender, dungeonKey, encodedQuests)
    if not sender or not dungeonKey then return end
    self.partyStatus = self.partyStatus or {}
    self.partyStatus[dungeonKey] = self.partyStatus[dungeonKey] or {}

    local quests = {}
    for questID, state in tostring(encodedQuests or ""):gmatch("(%d+):([^,]+)") do
        quests[tonumber(questID)] = state
    end

    self.partyStatus[dungeonKey][sender] = { time = time and time() or 0, quests = quests }
end

function DQT:GetPartyQuestSummary(dungeonKey, questID)
    local entries = self.partyStatus and self.partyStatus[dungeonKey]
    if not entries then return "Party: not checked" end

    local total, completed, ready, active, missing, locked = 0, 0, 0, 0, 0, 0
    for _, entry in pairs(entries) do
        total = total + 1
        local state = entry.quests and entry.quests[questID] or "missing"
        if state == "completed" then completed = completed + 1
        elseif state == "ready" then ready = ready + 1
        elseif state == "active" then active = active + 1
        elseif state == "locked" then locked = locked + 1
        else missing = missing + 1 end
    end

    if total == 0 then return "Party: not checked" end
    return string.format("Party: %d checked | %d done, %d ready, %d active, %d missing/locked", total, completed, ready, active, missing + locked)
end

function DQT:HandleAddonMessage(prefix, message, channel, sender)
    if prefix ~= partyPrefix or not message or sender == UnitName("player") then return end
    local command, rest = message:match("^(%w+)|?(.*)$")
    if command == "REQ" then
        local dungeonKey = rest
        if dungeonKey and dungeonKey ~= "" then self:SendDungeonStatus(dungeonKey, sender) end
        return
    end

    if command == "STATUS" then
        local dungeonKey, encodedQuests = rest:match("^([^|]+)|?(.*)$")
        self:StorePartyDungeonStatus(sender, dungeonKey, encodedQuests)
        if self.UI and self.UI.RefreshCurrentDungeon then self.UI:RefreshCurrentDungeon() end
    end
end

function DQT:InitializeComms()
    RegisterAddonPrefix(partyPrefix)
end

function DQT:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99DQT|r " .. tostring(message))
end

function DQT:OpenDungeon(dungeonKey)
    local status = self:GetDungeonQuestStatus(dungeonKey)
    if not status then
        self:Print("Unknown dungeon: " .. tostring(dungeonKey))
        return
    end

    if self.UI and self.UI.ShowDungeon then
        self.UI:ShowDungeon(status)
    else
        self:Print(status.dungeon.name)
        for _, row in ipairs(status.quests) do
            self:Print(string.format("[%s] %s - %s", row.stateReason, row.quest.name, row.quest.pickup.name))
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
        self:Print(string.format("%d. [%s] %s: %d XP%s -> %s", index, dungeonName, item.quest.name, item.effectiveXp, dingText, item.quest.turnIn.name))
    end
end

function DQT:ShowHelp()
    self:Print("Commands:")
    self:Print("  /dqt - open the Ragefire Chasm test window")
    self:Print("  /dqt list - list known dungeon keys")
    self:Print("  /dqt rfc - open Ragefire Chasm")
    self:Print("  /dqt rol - open Ruins of Lordaeron")
    self:Print("  /dqt wc - open Wailing Caverns")
    self:Print("  /dqt hot - open Hall of Thanes")
    self:Print("  /dqt sfk - open Shadowfang Keep")
    self:Print("  /dqt stocks - open The Stockade")
    self:Print("  /dqt turnins - print global dungeon turn-in priority")
    self:Print("  /dqt debug - print basic client/API checks")
end

function DQT:Debug()
    local context = self:GetPlayerContext()
    self:Print("Version " .. tostring(self.version))
    self:Print("Client build: " .. tostring((select(4, GetBuildInfo()))))
    self:Print("Level/XP: " .. tostring(context.level) .. " " .. tostring(context.currentXp) .. "/" .. tostring(context.maxXp))
    self:Print("C_QuestLog available: " .. tostring(C_QuestLog ~= nil))
    self:Print("C_QuestLog.IsQuestFlaggedCompleted available: " .. tostring(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted ~= nil))
    self:Print("C_QuestLog.ReadyForTurnIn available: " .. tostring(C_QuestLog and C_QuestLog.ReadyForTurnIn ~= nil))
    self:Print("C_QuestLog.IsOnQuest available: " .. tostring(C_QuestLog and C_QuestLog.IsOnQuest ~= nil))
    self:Print("Legacy IsQuestFlaggedCompleted available: " .. tostring(IsQuestFlaggedCompleted ~= nil))
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

    if command == "debug" then DQT:Debug(); return end
    if command == "help" or command == "?" then DQT:ShowHelp(); return end

    if DQT.UI and DQT.UI.Toggle then DQT.UI:Toggle() else DQT:ShowHelp() end
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

    if event == "GROUP_ROSTER_UPDATE" and DQT.UI and DQT.UI.currentDungeonKey then
        DQT:SendDungeonStatus(DQT.UI.currentDungeonKey)
    end

    if DQT.UI and DQT.UI.RefreshCurrentDungeon then
        DQT.UI:RefreshCurrentDungeon()
    end
end)










