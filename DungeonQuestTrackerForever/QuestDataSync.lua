local _, DQT = ...
local MAX_RECORDS, MAX_PARTS, PART_SIZE = 200, 40, 150
local classes = { WARRIOR=true, PALADIN=true, HUNTER=true, ROGUE=true, PRIEST=true, SHAMAN=true, MAGE=true, WARLOCK=true, DRUID=true }
local races = { Human=true, Dwarf=true, NightElf=true, Gnome=true, Orc=true, Scourge=true, Tauren=true, Troll=true }
local function Now()
    if type(GetTime) == "function" then
        local ok, value = pcall(GetTime)
        if ok and type(value) == "number" then return value end
    end
    return 0
end
local function Encode(value)
    return tostring(value):gsub("([^%w %-%._'])", function(c) return string.format("%%%02X", string.byte(c)) end)
end
local function Decode(value)
    if value:gsub("%%[%x][%x]", ""):find("%%") then return nil end
    return value:gsub("%%([%x][%x])", function(hex) return string.char(tonumber(hex, 16)) end)
end
local function Text(value, limit)
    return type(value) == "string" and #value > 0 and #value <= limit and not value:find("[%c|]")
end
local function Number(value, max)
    return type(value) == "number" and value == math.floor(value) and value >= 1 and value <= max
end
local function List(value, allowed)
    if value == nil then return true end
    if type(value) ~= "table" or #value < 1 or #value > 9 then return false end
    for _, item in ipairs(value) do if not allowed[item] then return false end end
    return true
end

function DQT:ValidatePartyQuest(id, quest)
    if not Number(id, 1000000) or type(quest) ~= "table" then return false end
    if not Text(quest.name, 180) or not self.dungeons[quest.dungeon] then return false end
    if not Number(quest.minLevel, 100) or not Number(quest.questLevel, 100) then return false end
    if quest.faction and quest.faction ~= "Horde" and quest.faction ~= "Alliance" then return false end
    if not List(quest.classes, classes) or not List(quest.races, races) or not List(quest.excludedRaces, races) then return false end
    for _, location in ipairs({ quest.pickup or false, quest.turnIn or false }) do
        if type(location) ~= "table" or not Text(location.name, 180) or not Text(location.zone, 120) then return false end
        if location.subzone and not Text(location.subzone, 240) then return false end
        if location.coordinates and not Text(location.coordinates, 40) then return false end
    end
    if quest.objectives and not Text(quest.objectives, 800) then return false end
    if type(quest.prerequisites) ~= "table" or #quest.prerequisites > 12 then return false end
    for _, prereq in ipairs(quest.prerequisites) do
        if type(prereq) ~= "table" or (prereq.relationship ~= "required" and prereq.relationship ~= "breadcrumb") then return false end
        if prereq.questID and (not Number(prereq.questID, 1000000) or prereq.questID == id) then return false end
        if prereq.note and not Text(prereq.note, 600) then return false end
    end
    return true
end

-- Flat, bounded fields only: received data is never evaluated as Lua.
function DQT:EncodePartyQuest(id, quest)
    if not self:ValidatePartyQuest(id, quest) then return nil end
    local fields = {}
    local function Add(key, value) if value ~= nil then fields[#fields+1] = key .. "=" .. Encode(value) end end
    for _, key in ipairs({ "name", "dungeon", "minLevel", "questLevel", "faction", "objectives" }) do Add(key, quest[key]) end
    for _, key in ipairs({ "classes", "races", "excludedRaces" }) do if quest[key] then Add(key, table.concat(quest[key], ",")) end end
    for _, key in ipairs({ "pickup", "turnIn" }) do
        for _, field in ipairs({ "name", "zone", "subzone", "coordinates" }) do Add(key .. "." .. field, quest[key][field]) end
    end
    Add("version", self.version)
    for index, prereq in ipairs(quest.prerequisites) do
        for _, key in ipairs({ "questID", "relationship", "note" }) do Add("p" .. index .. "." .. key, prereq[key]) end
    end
    local encoded = table.concat(fields, "&")
    return #encoded <= MAX_PARTS * PART_SIZE and encoded or nil
end

function DQT:DecodePartyQuest(id, encoded)
    if type(encoded) ~= "string" or #encoded > MAX_PARTS * PART_SIZE then return nil end
    local quest, seen = { pickup={}, turnIn={}, prerequisites={} }, {}
    for piece in (encoded .. "&"):gmatch("(.-)&") do
        local key, raw = piece:match("^([%w%.]+)=(.*)$")
        if not key or seen[key] then return nil end
        seen[key] = true
        local value = Decode(raw)
        if not value then return nil end
        if key == "name" or key == "dungeon" or key == "faction" or key == "objectives" then quest[key] = value
        elseif key == "minLevel" or key == "questLevel" then quest[key] = tonumber(value)
        elseif key == "version" then if not Text(value, 40) then return nil end; quest.sourceVersion = value
        elseif key == "classes" or key == "races" or key == "excludedRaces" then
            quest[key] = {}; for item in value:gmatch("[^,]+") do table.insert(quest[key], item) end
        else
            local location, field = key:match("^(%w+)%.(%w+)$")
            if (location == "pickup" or location == "turnIn") and (field == "name" or field == "zone" or field == "subzone" or field == "coordinates") then quest[location][field] = value
            else
                local index, part = key:match("^p(%d+)%.(%w+)$")
                index = tonumber(index)
                if not index or index < 1 or index > 12 or (part ~= "questID" and part ~= "relationship" and part ~= "note") then return nil end
                quest.prerequisites[index] = quest.prerequisites[index] or {}
                if part == "questID" then
                    if not Number(tonumber(value), 1000000) then return nil end
                    quest.prerequisites[index][part] = tonumber(value)
                else quest.prerequisites[index][part] = value end
            end
        end
    end
    local count = 0; for _ in pairs(quest.prerequisites) do count = count + 1 end
    for index=1,count do if not quest.prerequisites[index] then return nil end end
    if not self:ValidatePartyQuest(id, quest) then return nil end
    return quest
end

function DQT:GetSyncedDungeon(key, dungeon)
    if not self.db or not self.db.partyDataSync then return dungeon end
    local copy, seen = {}, {}
    for field, value in pairs(dungeon) do copy[field] = value end
    copy.quests = {}
    for _, id in ipairs(dungeon.quests or {}) do copy.quests[#copy.quests+1] = id; seen[id] = true end
    local extra = {}
    for id, quest in pairs(self.db.partyQuestCache or {}) do
        if not self.quests[id] and not seen[id] and quest.dungeon == key then extra[#extra+1] = id end
    end
    table.sort(extra)
    for _, id in ipairs(extra) do copy.quests[#copy.quests+1] = id end
    return copy
end

function DQT:ResetQuestDataTransfers()
    self.dataTransfers = { queue={}, pending={}, offered={}, offerTimes={}, received=0, elapsed=0 }
    if self.syncFrame then self.syncFrame:Hide() end
end
function DQT:QueueQuestData(message, target)
    local state = self.dataTransfers
    if not state or #message > 255 or #state.queue >= 512 then return false end
    state.queue[#state.queue+1] = { message=message, target=target }
    if self.syncFrame then self.syncFrame:Show() end
    return true
end
function DQT:TickQuestData(elapsed)
    local state = self.dataTransfers
    if not state or not self.db or not self.db.partyDataSync then return end
    state.elapsed = state.elapsed + elapsed
    if state.elapsed < 0.2 then return end
    state.elapsed = 0
    local now = Now()
    for key, pending in pairs(state.pending) do if now - pending.time > 180 then state.pending[key] = nil end end
    local item = table.remove(state.queue, 1)
    if item then self:SendQuestDataMessage(item.message, item.target) end
    if #state.queue == 0 and not next(state.pending) and self.syncFrame then self.syncFrame:Hide() end
end
function DQT:InitializeQuestDataSync()
    self:ResetQuestDataTransfers()
    local clean, count = {}, 0
    for id, quest in pairs(type(self.db.partyQuestCache) == "table" and self.db.partyQuestCache or {}) do
        if count < MAX_RECORDS and not self.quests[id] and self:ValidatePartyQuest(id, quest) then
            local record = self:DecodePartyQuest(id, self:EncodePartyQuest(id, quest))
            if record then
                record.partySupplied, record.confidence = true, "needsReview"
                record.source = Text(quest.source, 120) and quest.source or "Party supplied"
                record.sourceVersion = Text(quest.sourceVersion, 40) and quest.sourceVersion or "unknown"
                clean[id], count = record, count + 1
            end
        end
    end
    self.db.partyQuestCache = clean
    self.syncFrame = self.syncFrame or CreateFrame("Frame")
    self.syncFrame:SetScript("OnUpdate", function(_, elapsed) DQT:TickQuestData(elapsed) end)
    self.syncFrame:Hide()
end
function DQT:SetQuestDataSync(option)
    if not self.db then return end
    if option == "on" or option == "off" then self.db.partyDataSync = option == "on"; self:ResetQuestDataTransfers()
    elseif option == "clear" then self.db.partyQuestCache = {}; self:ResetQuestDataTransfers()
    elseif option ~= "" then self:Print("Usage: /dqt sync on|off|clear"); return end
    self:Print("Party quest-data sync: " .. (self.db.partyDataSync and "on" or "off"))
    if self.UI then self.UI:RefreshCurrentDungeon() end
end
function DQT:OfferQuestData(key)
    if not self.db or not self.db.partyDataSync or not self.dataTransfers then return end
    -- Invitations use the existing bounded group status transport.
    if not self:GetDungeon(key) then return end
    local last = self.dataTransfers.offerTimes[key]
    if last and Now()-last < 5 then return end
    self.dataTransfers.offerTimes[key] = Now()
    self.sendDataOffer = true
    self:SendDungeonStatus(key)
    self.sendDataOffer = nil
end
function DQT:HandleQuestDataMessage(command, rest, sender)
    if command ~= "CAT" and command ~= "GET" and command ~= "DATA" then return false end
    if not self.db or not self.db.partyDataSync or not self.dataTransfers then return true end
    local state = self.dataTransfers
    if command == "CAT" then
        local dungeon, ids = rest:match("^([^|]+)|([^|]*)$")
        if not self.dungeons[dungeon] then return true end
        local count = 0; for _ in pairs(state.pending) do count = count + 1 end
        for raw in ids:gmatch("%d+") do
            local id = tonumber(raw)
            local key = sender .. ":" .. id
            if count < 16 and state.received < MAX_RECORDS and not self:GetQuest(id) and not self.db.partyQuestCache[id] and not state.pending[key] and Number(id, 1000000) then
                if self:QueueQuestData("GET|" .. dungeon .. "|" .. id, sender) then
                    state.pending[key] = { id=id, dungeon=dungeon, time=Now(), parts={} }; count=count+1
                end
            end
        end
    elseif command == "GET" then
        local dungeon, raw = rest:match("^([^|]+)|(%d+)$")
        local id = tonumber(raw)
        local quest = id and self.quests[id]
        local allowed = false
        for _, candidate in ipairs((self.dungeons[dungeon] or {}).quests or {}) do if candidate == id then allowed = true end end
        local token = sender .. ":" .. tostring(id)
        if not quest or not allowed or (state.offered[token] and Now()-state.offered[token] < 30) then return true end
        local encoded = self:EncodePartyQuest(id, quest)
        if not encoded then return true end
        local total = math.ceil(#encoded/PART_SIZE)
        if #state.queue + total > 512 then return true end
        state.offered[token] = Now()
        for index=1,total do self:QueueQuestData("DATA|" .. id .. "|" .. index .. "|" .. total .. "|" .. encoded:sub((index-1)*PART_SIZE+1,index*PART_SIZE), sender) end
    else
        local raw, part, total, body = rest:match("^(%d+)|(%d+)|(%d+)|(.*)$")
        local id, index, size = tonumber(raw), tonumber(part), tonumber(total)
        local token = sender .. ":" .. tostring(id)
        local pending = state.pending[token]
        if not pending or Now()-pending.time > 180 or not Number(index, MAX_PARTS) or not Number(size, MAX_PARTS) or index > size or #body > PART_SIZE then return true end
        if pending.total and pending.total ~= size then state.pending[token] = nil; return true end
        if pending.parts[index] and pending.parts[index] ~= body then state.pending[token] = nil; return true end
        pending.total, pending.parts[index] = size, body
        for i=1,size do if not pending.parts[i] then return true end end
        state.pending[token] = nil
        local quest = self:DecodePartyQuest(id, table.concat(pending.parts))
        if quest and quest.dungeon == pending.dungeon and not self:GetQuest(id) and not self.db.partyQuestCache[id] then
            local count = 0; for _ in pairs(self.db.partyQuestCache) do count=count+1 end
            if count >= MAX_RECORDS then return true end
            quest.partySupplied, quest.confidence, quest.source = true, "needsReview", sender
            self.db.partyQuestCache[id] = quest
            state.received = state.received + 1
            self:RequestUIRefresh()
        end
    end
    return true
end
