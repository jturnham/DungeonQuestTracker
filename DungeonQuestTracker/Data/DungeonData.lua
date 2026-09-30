local _, DQT = ...

DQT.dungeons = {
    ["ragefire-chasm"] = {
        name = "Ragefire Chasm",
        minLevel = 8,
        recommendedLevel = "13-18",
        factions = { "Horde" },
        location = "Orgrimmar, Cleft of Shadow",
        art = "Interface\\LFGFrame\\UI-LFG-BACKGROUND-RagefireChasm",
        notes = "First real Horde dungeon dataset. Quest availability should be verified on your Forever character.",
        quests = { 5723, 5722, 5724, 5728, 5761, 5725 },
    },
    ["ruins-of-lordaeron"] = {
        name = "Ruins of Lordaeron",
        minLevel = 15,
        recommendedLevel = "15-20",
        factions = { "Horde" },
        location = "Ruins above Undercity, entrance near 72.5, 11.4",
        art = "Interface\\LFGFrame\\UI-LFG-BACKGROUND-ShadowfangKeep",
        notes = "New Forever dungeon. Horde quest data is sourced from beta client guide listings and should be verified in-game.",
        quests = { 92401, 92421, 92422, 95216, 95204, 97288, 95250, 95195, 95189, 92415 },
    },
    ["hall-of-thanes"] = {
        name = "Hall of Thanes",
        minLevel = 13,
        recommendedLevel = "13-18",
        factions = { "Alliance", "Horde" },
        location = "Old Ironforge, beneath The High Seat",
        art = "Interface\\LFGFrame\\UI-LFG-BACKGROUND-BlackrockDepths",
        notes = "New Forever dungeon. Current beta sources conflict on Horde access: An Ancient Grudge and Important Heirlooms are shown as cross-faction in some guides, while the remaining rows are Alliance-only.",
        quests = { 96395, 96403, 96394, 96393, 98423 },
    },    ["shadowfang-keep"] = {
        name = "Shadowfang Keep",
        minLevel = 16,
        recommendedLevel = "22-30",
        factions = { "Horde", "Alliance" },
        location = "Silverpine Forest, north of Pyrewood Village",
        art = "Interface\\LFGFrame\\UI-LFG-BACKGROUND-ShadowfangKeep",
        notes = "Classic-era dungeon. Main dungeon quests are Horde-heavy, with class quests for Warlocks and Paladins.",
        quests = { 1098, 1013, 1014, 1740, 1654 },
    },
    ["the-stockade"] = {
        name = "The Stockade",
        minLevel = 16,
        recommendedLevel = "22-30",
        factions = { "Alliance" },
        location = "Stormwind City, Canal District",
        art = "Interface\\LFGFrame\\UI-LFG-BACKGROUND-StormwindStockade",
        notes = "Alliance capital dungeon. Forever's compact quest index only lists The Stockade Riots, but the checklist includes the useful classic Stockade quest prep set.",
        quests = { 391, 387, 388, 377, 386, 378 },
    },    ["wailing-caverns"] = {
        name = "Wailing Caverns",
        minLevel = 13,
        recommendedLevel = "17-24",
        factions = { "Alliance", "Horde" },
        location = "The Barrens, southwest of Crossroads",
        art = "Interface\\LFGFrame\\UI-LFG-BACKGROUND-WailingCaverns",
        notes = "Classic-era dungeon with a mix of Horde, neutral, Ratchet, item-start, and chain quests. Forever listing keeps several factions unrecorded; those are shown to both factions.",
        quests = { 1489, 1490, 1486, 1491, 962, 959, 1487, 914, 6981 },
    },    ["deadmines"] = {
        name = "The Deadmines",
        minLevel = 10,
        recommendedLevel = "17-26",
        factions = { "Alliance" },
        art = "Interface\\LFGFrame\\UI-LFG-BACKGROUND-Deadmines",
        quests = { 166, 214, 168, 167, 2040, 373 },
    },
}





