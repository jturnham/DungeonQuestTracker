local classes = {WARRIOR=true, PALADIN=true, HUNTER=true, ROGUE=true, PRIEST=true, SHAMAN=true, MAGE=true, WARLOCK=true, DRUID=true}
local races = {Human=true, Dwarf=true, NightElf=true, Gnome=true, Orc=true, Scourge=true, Tauren=true, Troll=true}
local function Text(value) return type(value) == "string" and value:match("%S") end
local function Integer(value, minimum, maximum)
    return type(value) == "number" and value == math.floor(value) and value >= minimum and value <= maximum
end
local membership, dungeonCount, questCount = {}, 0, 0
for key, dungeon in pairs(DQT.dungeons) do
    dungeonCount = dungeonCount+1
    assert(Text(key) and Text(dungeon.name), "Dungeon name/key missing")
    assert(Integer(dungeon.minLevel, 1, 100), "Dungeon level invalid: " .. key)
    assert(type(dungeon.quests) == "table", "Quest list missing: " .. key)
    local seen = {}
    for _, id in ipairs(dungeon.quests) do
        assert(Integer(id, 1, 1000000) and DQT.quests[id], "Unresolved dungeon quest: " .. tostring(id))
        assert(not seen[id], "Duplicate quest within dungeon: " .. key .. ":" .. id)
        seen[id] = true
        membership[id] = membership[id] or {}; membership[id][key] = true
    end
    for _, faction in ipairs(dungeon.factions or {}) do
        assert(faction == "Alliance" or faction == "Horde", "Invalid dungeon faction: " .. key)
    end
end
for id, quest in pairs(DQT.quests) do
    questCount = questCount+1
    assert(Integer(id, 1, 1000000) and Text(quest.name), "Invalid quest ID/name")
    assert(DQT.dungeons[quest.dungeon], "Unresolved primary dungeon: " .. id)
    assert(membership[id] and membership[id][quest.dungeon], "Quest absent from primary dungeon: " .. id)
    assert(Integer(quest.minLevel, 1, 100) and Integer(quest.questLevel, 1, 100), "Invalid quest level: " .. id)
    assert(quest.minLevel <= 35, "Quest outside release pickup range: " .. id)
    assert(not quest.faction or quest.faction == "Alliance" or quest.faction == "Horde", "Invalid faction: " .. id)
    for field, allowed in pairs({classes=classes, races=races, excludedRaces=races}) do
        local seen = {}
        for _, value in ipairs(quest[field] or {}) do
            assert(allowed[value] and not seen[value], "Invalid/duplicate " .. field .. ": " .. id)
            seen[value] = true
        end
    end
    for _, field in ipairs({"pickup", "turnIn"}) do
        local location = quest[field]
        assert(type(location) == "table" and Text(location.name) and Text(location.zone), "Invalid " .. field .. ": " .. id)
        if location.coordinates then assert(Text(location.coordinates), "Invalid coordinates: " .. id) end
    end
    for _, field in ipairs({"classicXp", "foreverXp"}) do
        if quest[field] ~= nil then assert(Integer(quest[field], 0, 1000000), "Invalid XP: " .. id) end
    end
    assert(Text(quest.objectives), "Missing objectives: " .. id)
    assert(quest.confidence == "needsReview" or quest.confidence == "verifiedSource" or quest.confidence == "verifiedInGame", "Invalid confidence: " .. id)
    assert(type(quest.sourceURLs) == "table" and #quest.sourceURLs > 0, "Missing sources: " .. id)
    for _, url in ipairs(quest.sourceURLs) do assert(url:match("^https://"), "Invalid source URL: " .. id) end
    assert(type(quest.prerequisites) == "table", "Missing prerequisites: " .. id)
    for _, prerequisite in ipairs(quest.prerequisites) do
        assert(prerequisite.relationship == "required" or prerequisite.relationship == "breadcrumb", "Invalid prerequisite relationship: " .. id)
        assert(prerequisite.questID or Text(prerequisite.note), "Empty prerequisite: " .. id)
        if prerequisite.questID then
            assert(Integer(prerequisite.questID, 1, 1000000), "Invalid prerequisite ID: " .. id)
            assert(DQT.quests[prerequisite.questID] or prerequisite.external == true, "Unresolved prerequisite: " .. id)
        end
    end
end
local visiting, visited = {}, {}
local function Visit(id)
    assert(not visiting[id], "Prerequisite cycle at quest " .. id)
    if visited[id] then return end
    visiting[id] = true
    for _, prerequisite in ipairs(DQT.quests[id].prerequisites) do
        if DQT.quests[prerequisite.questID] then Visit(prerequisite.questID) end
    end
    visiting[id], visited[id] = nil, true
end
for id in pairs(DQT.quests) do Visit(id) end
print("Data audit passed: " .. questCount .. " quests, " .. dungeonCount .. " dungeons; references, locations, enums, metadata, XP and acyclic prerequisites.")
