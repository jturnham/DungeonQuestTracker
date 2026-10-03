local _, DQT = ...

local quests = {
    [97289] = {
        name = "Unending Torment", followUpOf = 97288, minLevel = 16, questLevel = 21,
        turnIn = { name = "Othmar", zone = "Undercity", subzone = "body in the room beside the Apothecarium" },
        objectives = "Take the Head of the Baron to Othmar's body beside the Apothecarium.",
    },
    [97290] = {
        name = "Unending Torment", followUpOf = 97289, minLevel = 16, questLevel = 21,
        turnIn = { name = "Master Apothecary Faranell", zone = "Undercity", subzone = "The Apothecarium" },
        objectives = "Report the encounter with Othmar to Master Apothecary Faranell.",
    },
    [97291] = {
        name = "Unending Torment", followUpOf = 97290, minLevel = 16, questLevel = 21,
        turnIn = { name = "Master Apothecary Faranell", zone = "Undercity", subzone = "The Apothecarium" },
        objectives = "Gather a Toxic Skullcap, Blisterweed and Essence of Agony from within Undercity for Faranell.",
    },
    [97292] = {
        name = "Unending Torment", followUpOf = 97291, minLevel = 16, questLevel = 21,
        turnIn = { name = "Master Apothecary Faranell", zone = "Undercity", subzone = "The Apothecarium" },
        objectives = "Administer the Hissing Serum through the system above Othmar's body, then return to Faranell.",
    },
    [389] = {
        name = "Bazil Thredd", followUpOf = 373,
        turnIn = { name = "Warden Thelwater", zone = "Stormwind City", subzone = "outside The Stockade" },
        objectives = "Ask Warden Thelwater about Bazil Thredd after delivering VanCleef's letter.",
    },
    [392] = {
        name = "The Curious Visitor", followUpOf = 391,
        turnIn = { name = "Baros Alexston", zone = "Stormwind City", subzone = "City Hall, Cathedral Square" },
        objectives = "Take the description of Thredd's visitor to Baros Alexston.",
    },
    [393] = {
        name = "Shadow of the Past", followUpOf = 392,
        turnIn = { name = "Master Mathias Shaw", zone = "Stormwind City", subzone = "SI:7, Old Town" },
        objectives = "Ask Mathias Shaw to identify Thredd's visitor.",
    },
    [350] = {
        name = "Look to an Old Friend", followUpOf = 393,
        turnIn = { name = "Elling Trias", zone = "Stormwind City", subzone = "upstairs in the cheese shop, Trade District" },
        objectives = "Speak to Elling Trias about the conspiracy.",
    },
    [2745] = {
        name = "Infiltrating the Castle", followUpOf = 350,
        turnIn = { name = "Tyrion", zone = "Stormwind City", subzone = "Stormwind Keep" },
        objectives = "Meet Tyrion in Stormwind Keep to prepare the infiltration.",
    },
    [2746] = {
        name = "Items of Some Consequence", followUpOf = 2745,
        turnIn = { name = "Tyrion", zone = "Stormwind City", subzone = "Stormwind Keep" },
        objectives = "Bring three Silk Cloth and two Clara's Fresh Apples to Tyrion.",
    },
    [434] = {
        name = "The Attack!", followUpOf = 2746,
        turnIn = { name = "Elling Trias", zone = "Stormwind City", subzone = "upstairs in the cheese shop, Trade District" },
        objectives = "Follow Tyrion's plan, defeat Lord Gregor Lescovar and Marzon, then report to Elling Trias.",
    },
    [394] = {
        name = "The Head of the Beast", followUpOf = 434,
        turnIn = { name = "Master Mathias Shaw", zone = "Stormwind City", subzone = "SI:7, Old Town" },
        objectives = "Report the outcome of the conspiracy to Mathias Shaw.",
    },
    [395] = {
        name = "Brotherhood's End", followUpOf = 394,
        turnIn = { name = "Baros Alexston", zone = "Stormwind City", subzone = "City Hall, Cathedral Square" },
        objectives = "Return to Baros Alexston for his report on the Defias Brotherhood.",
    },
    [396] = {
        name = "An Audience with the King", followUpOf = 395,
        turnIn = { name = "Lady Katrana Prestor", zone = "Stormwind City", subzone = "Stormwind Keep; receiving the report on the King's behalf" },
        objectives = "Deliver Alexston's report to Stormwind Keep. Confirm the receiving NPC in Forever.",
    },
    [6628] = {
        name = "Test of Lore", followUpOf = 1160,
        turnIn = { name = "Parqual Fintallas", zone = "Undercity", subzone = "The Apothecarium" },
        objectives = "Answer Parqual Fintallas' question after returning the Library book.",
    },
    [1394] = {
        name = "Final Passage", followUpOf = 6628,
        turnIn = { name = "Dorn Plainstalker", zone = "Thousand Needles" },
        objectives = "Return to Dorn Plainstalker after passing the final Test of Lore.",
    },
    [1952] = {
        name = "Mage's Wand", followUpOf = 1951,
        turnIn = { name = "Tabetha", zone = "Dustwallow Marsh", coordinates = "46, 57" },
        objectives = "Wait for Tabetha to finish crafting the wand after completing Rituals of Power and her other required preparations.",
        prerequisites = { { questID = 1948, relationship = "required", note = "Also complete Items of Power for Tabetha; confirm the requirement in Forever." } },
    },
    [1806] = {
        name = "The Test of Righteousness", followUpOf = 1654,
        turnIn = { name = "Jordan Stilwell", zone = "Ironforge", subzone = "outside the gates" },
        objectives = "Wait for Jordan Stilwell to forge Verigan's Fist after returning the dungeon materials.",
    },
    [1848] = {
        name = "Brutal Hauberk", followUpOf = 1838,
        turnIn = { name = "Thun'grim Firegaze", zone = "The Barrens", subzone = "east of the Crossroads" },
        objectives = "Collect the completed Brutal Hauberk from Thun'grim.",
    },
    [1839] = {
        name = "Ula'elek and the Brutal Gauntlets", followUpOf = 1838,
        turnIn = { name = "Ula'elek", zone = "Durotar", subzone = "Sen'jin Village" },
        objectives = "Meet Ula'elek for the gauntlet branch of the Brutal Armor chain.",
    },
    [1842] = {
        name = "Satyr Hooves", followUpOf = 1839,
        turnIn = { name = "Ula'elek", zone = "Durotar", subzone = "Sen'jin Village" },
        objectives = "Bring seven Uncloven Satyr Hooves from Ashenvale to Ula'elek.",
    },
    [1843] = {
        name = "Brutal Gauntlets", followUpOf = 1842,
        turnIn = { name = "Ula'elek", zone = "Durotar", subzone = "Sen'jin Village" },
        objectives = "Collect the finished Brutal Gauntlets from Ula'elek.",
    },
    [1840] = {
        name = "Orm Stonehoof and the Brutal Helm", followUpOf = 1838,
        turnIn = { name = "Orm Stonehoof", zone = "Thunder Bluff", subzone = "near the central pool" },
        objectives = "Meet Orm Stonehoof for the helm branch of the Brutal Armor chain.",
    },
    [1844] = {
        name = "Chimaeric Horn", followUpOf = 1840,
        turnIn = { name = "Orm Stonehoof", zone = "Thunder Bluff", subzone = "near the central pool" },
        objectives = "Recover a Chimaeric Horn from a Chimaera Matriarch in Stonetalon's Charred Vale.",
    },
    [1845] = {
        name = "Brutal Helm", followUpOf = 1844,
        turnIn = { name = "Orm Stonehoof", zone = "Thunder Bluff", subzone = "near the central pool" },
        objectives = "Collect the completed Brutal Helm from Orm Stonehoof.",
    },
    [1841] = {
        name = "Velora Nitely and the Brutal Legguards", followUpOf = 1838,
        turnIn = { name = "Velora Nitely", zone = "Undercity", subzone = "Trade Quarter" },
        objectives = "Meet Velora Nitely for the legguard branch of the Brutal Armor chain.",
    },
    [1846] = {
        name = "Dragonmaw Shinbones", followUpOf = 1841,
        turnIn = { name = "Velora Nitely", zone = "Undercity", subzone = "Trade Quarter" },
        objectives = "Bring eight Sturdy Dragonmaw Shinbones from Wetlands to Velora Nitely.",
    },
    [1847] = {
        name = "Brutal Legguards", followUpOf = 1846,
        turnIn = { name = "Velora Nitely", zone = "Undercity", subzone = "Trade Quarter" },
        objectives = "Collect the completed Brutal Legguards from Velora Nitely.",
    },
    [1700] = {
        name = "Grimand Elmore", followUpOf = 1701, races = { "Human" },
        turnIn = { name = "Grimand Elmore", zone = "Stormwind City", subzone = "Dwarven District" },
        objectives = "Deliver Furen's Notes to Grimand Elmore. Confirm the Classic race-specific referral in Forever.",
    },
    [1705] = {
        name = "Burning Blood", followUpOf = 1700,
        turnIn = { name = "Grimand Elmore", zone = "Stormwind City", subzone = "Dwarven District" },
        objectives = "Gather 20 Burning Blood and a Burning Rock from Duskwood for Grimand.",
    },
    [1706] = {
        name = "Grimand's Armor", followUpOf = 1705,
        turnIn = { name = "Grimand Elmore", zone = "Stormwind City", subzone = "Dwarven District" },
        objectives = "Collect the finished Fire Hardened Coif from Grimand.",
    },
    [1704] = {
        name = "Klockmort Spannerspan", followUpOf = 1701, races = { "Dwarf", "Gnome" },
        turnIn = { name = "Klockmort Spannerspan", zone = "Ironforge", subzone = "Tinker Town" },
        objectives = "Deliver Furen's Notes to Klockmort. Confirm the Classic race-specific referral in Forever.",
    },
    [1708] = {
        name = "Iron Coral", followUpOf = 1704,
        turnIn = { name = "Klockmort Spannerspan", zone = "Ironforge", subzone = "Tinker Town" },
        objectives = "Gather Searing Coral underwater south of Menethil Harbor for Klockmort.",
    },
    [1709] = {
        name = "Klockmort's Creation", followUpOf = 1708,
        turnIn = { name = "Klockmort Spannerspan", zone = "Ironforge", subzone = "Tinker Town" },
        objectives = "Collect the completed Fire Hardened Gauntlets from Klockmort.",
    },
    [1703] = {
        name = "Mathiel", followUpOf = 1701, races = { "NightElf" },
        turnIn = { name = "Mathiel", zone = "Darnassus", subzone = "Warrior's Terrace" },
        objectives = "Deliver Furen's Notes to Mathiel. Confirm the Classic race-specific referral in Forever.",
    },
    [1710] = {
        name = "Sunscorched Shells", followUpOf = 1703,
        turnIn = { name = "Mathiel", zone = "Darnassus", subzone = "Warrior's Terrace" },
        objectives = "Gather 20 Sunscorched Shells from Highperch in Thousand Needles for Mathiel.",
    },
    [1711] = {
        name = "Mathiel's Armor", followUpOf = 1710,
        turnIn = { name = "Mathiel", zone = "Darnassus", subzone = "Warrior's Terrace" },
        objectives = "Collect the completed Fire Hardened Leggings from Mathiel.",
    },
    [1782] = {
        name = "Furen's Armor", followUpOf = 1701,
        turnIn = { name = "Furen Longbeard", zone = "Stormwind City", subzone = "Dwarven District" },
        objectives = "Collect the completed Fire Hardened Hauberk from Furen.",
    },
    [6521] = {
        name = "An Unholy Alliance", followUpOf = 6522, classicXp = 3500,
        dungeon = "razorfen-downs", minLevel = 28, questLevel = 36,
        turnIn = { name = "Varimathras", zone = "Undercity", subzone = "Royal Quarter" },
        objectives = "Defeat Ambassador Malcin outside Razorfen Downs and bring his head to Varimathras. This continues the scroll quest from Razorfen Kraul.",
    },
}

-- Resolve ancestors first; continuation levels are provisional unless explicitly sourced.
local function Register(id)
    if DQT.quests[id] then return DQT.quests[id] end
    local quest = quests[id]
    local previous = DQT.quests[quest.followUpOf] or Register(quest.followUpOf)
    quest.dungeon = quest.dungeon or previous.dungeon
    quest.faction = previous.faction
    quest.classes = previous.classes
    quest.races = quest.races or previous.races
    quest.excludedRaces = previous.excludedRaces
    quest.newInForever = previous.newInForever
    quest.questLevelUnverified = quest.questLevel == nil
    quest.minLevel = quest.minLevel or previous.minLevel
    quest.questLevel = quest.questLevel or previous.questLevel
    quest.pickup = quest.pickup or previous.turnIn
    quest.prerequisites = quest.prerequisites or {}
    table.insert(quest.prerequisites, 1, { questID = quest.followUpOf, relationship = "required", note = "Complete the previous step in this dungeon quest chain." })
    quest.source = quest.source or "https://www.wowhead.com/forever/quest=" .. id
    quest.verifiedForever = false
    DQT.quests[id] = quest
    return quest
end
for id in pairs(quests) do Register(id) end

DQT.quests[391].followUpOf = 389
DQT.quests[391].prerequisites = { { questID = 389, relationship = "required", note = "Deliver The Unsent Letter, then complete Bazil Thredd at Warden Thelwater." } }
for id, previous in pairs({ [5724] = 5722, [2947] = 2945, [2948] = 2947, [2949] = 2945, [2950] = 2949 }) do
    DQT.quests[id].followUpOf = previous
end

-- All catalogued follow-ups inherit each dungeon containing their predecessor,
-- including shared class quests. Cross-dungeon steps keep their explicit home.
local registered = {}
local keys = {}
for key in pairs(DQT.dungeons) do keys[#keys + 1] = key end
table.sort(keys)
local function Include(id)
    if registered[id] then return end
    registered[id] = true
    local quest = DQT.quests[id]
    if not quest or not quest.followUpOf then return end
    Include(quest.followUpOf)
    local previous = DQT.quests[quest.followUpOf]
    for _, key in ipairs(keys) do
        local dungeon = DQT.dungeons[key]
        local hasPrevious, hasQuest = false, false
        for _, questID in ipairs(dungeon.quests) do
            if questID == quest.followUpOf then hasPrevious = true end
            if questID == id then hasQuest = true end
        end
        if not hasQuest and (key == quest.dungeon or (hasPrevious and previous.dungeon == quest.dungeon)) then
            dungeon.quests[#dungeon.quests + 1] = id
        end
    end
end
local ids = {}
for id, quest in pairs(DQT.quests) do
    if quest.followUpOf then ids[#ids + 1] = id end
end
table.sort(ids)
for _, id in ipairs(ids) do Include(id) end
