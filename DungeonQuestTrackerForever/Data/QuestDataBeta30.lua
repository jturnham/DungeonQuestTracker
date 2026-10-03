local _, DQT = ...

-- Classic catalog identities, not confirmation of current beta levels or rewards.
local contacts = {
    varimathras={name="Varimathras",zone="Undercity",subzone="Royal Quarter"},
    andrew={name="Andrew Brownell",zone="Undercity",subzone="Magic Quarter"},
    benedictus={name="Archbishop Benedictus",zone="Stormwind City",subzone="Cathedral Square"},
    myriam={name="Myriam Moonsinger",zone="The Barrens",subzone="Outside Razorfen Downs"},
    belnistrasz={name="Belnistrasz",zone="Razorfen Downs",subzone="Murder Pens"},
    brazier={name="Belnistrasz's Brazier",zone="Razorfen Downs",subzone="Murder Pens"},
    patrick={name="Patrick Garrett",zone="Undercity"},
    krom={name="Krom Stoutarm",zone="Ironforge",subzone="Hall of Explorers"},
    stormpike={name="Prospector Stormpike",zone="Ironforge",subzone="Hall of Explorers"},
    baelog={name="Baelog",zone="Uldaman",subzone="Lost Dwarves"},
    ghak={name="Ghak Healtouch",zone="Loch Modan",subzone="Thelsamar"},
    jarkal={name="Jarkal Mossmeld",zone="Badlands",subzone="Kargath"},
    ironband={name="Prospector Ironband",zone="Loch Modan",subzone="Ironband's Excavation Site"},
    belgrum={name="Advisor Belgrum",zone="Ironforge",subzone="Hall of Explorers"},
    talvash={name="Talvash del Kissel",zone="Ironforge",subzone="Mystic Ward"},
    bowl={name="Talvash's Scrying Bowl",zone="Uldaman",subzone="Summoned using the Phial of Scrying"},
    necklace={name="Shattered Necklace (drop)",zone="Uldaman",subzone="Entrance tunnels or dungeon enemies"},
    dran={name="Dran Droffers",zone="Orgrimmar",subzone="The Drag"},
    paladin={name="Remains of a Paladin",zone="Uldaman"},
    rigglefuzz={name="Rigglefuzz",zone="Badlands",coordinates="42, 52"},
    theldurin={name="Theldurin the Lost",zone="Badlands",coordinates="51, 76"},
    discs={name="The Discs of Norgannon",zone="Uldaman",subzone="Beyond Archaedas"},
    magellas={name="High Explorer Magellas",zone="Ironforge",subzone="Hall of Explorers"},
    dinita={name="Dinita Stonemantle",zone="Ironforge",subzone="Vault of Ironforge"},
    sage={name="Sage Truthseeker",zone="Thunder Bluff",subzone="Elder Rise"},
    bena={name="Bena Winterhoof",zone="Thunder Bluff"},
    tabetha={name="Tabetha",zone="Dustwallow Marsh",coordinates="46, 57"},
    hammertoe={name="Hammertoe Grez",zone="Badlands",subzone="Uldaman entrance tunnels"},
    ryedol={name="Prospector Ryedol",zone="Badlands"},
    karnik={name="Historian Karnik",zone="Ironforge",subzone="Hall of Explorers"},
}
-- id, title, faction, pickup level, quest level, Classic XP, giver, recipient,
-- objective, preceding step (external unless also catalogued here).
local rows = {
    {3341,"Bring the End","Horde",37,42,4300,"andrew","andrew","Recover the Skull of the Coldbringer from Amnennar."},
    {3636,"Bring the Light","Alliance",39,42,4300,"benedictus","benedictus","Defeat Amnennar the Coldbringer."},
    {6626,"A Host of Evil",nil,28,35,3450,"myriam","myriam","Slay 8 Razorfen Battleguards, 8 Razorfen Thornweavers and 8 Death's Head Cultists."},
    {3523,"Scourge of the Downs",nil,32,37,290,"belnistrasz","belnistrasz","Return Belnistrasz's Oathstone. Everyone should finish this before the escort."},
    {3525,"Extinguishing the Idol",nil,32,37,4250,"belnistrasz","brazier","Protect Belnistrasz during the idol ritual, then use his brazier.",3523},
    {2342,"Reclaimed Treasures","Horde",33,43,3600,"patrick","patrick","Recover the Garrett Family Treasure in the South Common Hall."},
    {1360,"Reclaimed Treasures","Alliance",33,43,3600,"krom","krom","Recover Krom Stoutarm's treasure in the North Common Hall."},
    {2398,"The Lost Dwarves","Alliance",35,40,315,"stormpike","baelog","Find Baelog and the missing dwarves."},
    {2240,"The Hidden Chamber","Alliance",35,40,3900,"baelog","stormpike","Read Baelog's Journal and explore the hidden chamber.",2398},
    {2202,"Uldaman Reagent Run","Horde",36,42,3450,"jarkal","jarkal","Collect 12 Magenta Fungus Caps.",2258},
    {17,"Uldaman Reagent Run","Alliance",38,42,3450,"ghak","ghak","Collect 12 Magenta Fungus Caps.",2500},
    {704,"Agmond's Fate","Alliance",33,38,2850,"ironband","ironband","Collect 4 Carved Stone Urns. Prepare Ironband Wants You!, Find Agmond and Murdaloc first.",739},
    {1139,"The Lost Tablets of Will","Alliance",30,45,5850,"belgrum","belgrum","Recover the Tablet of Will. Prepare the Hammertoe chain beginning with A Sign of Hope.",762},
    {2198,"The Shattered Necklace","Alliance",37,41,3300,"necklace","talvash","Take the Shattered Necklace to Talvash del Kissel."},
    {2199,"Lore for a Price","Alliance",37,41,2450,"talvash","talvash","Bring Talvash 5 Silver Bars.",2198},
    {2200,"Back to Uldaman","Alliance",37,42,2550,"talvash","paladin","Find the slain paladin in Uldaman.",2199},
    {2201,"Find the Gems","Alliance",37,43,3600,"paladin","bowl","Recover the ruby, sapphire and topaz, then contact Talvash using the Phial of Scrying.",2200},
    {2204,"Restoring the Necklace","Alliance",37,44,930,"bowl","talvash","Recover a power source from Archaedas and return it to Talvash.",2201},
    {2361,"Restoring the Necklace","Alliance",37,44,5600,"talvash","talvash","Collect the restored necklace from Talvash.",2204},
    {2283,"Necklace Recovery","Horde",37,41,2450,"dran","dran","Recover a Shattered Necklace from Uldaman."},
    {2284,"Necklace Recovery, Take 2","Horde",37,41,2450,"dran","paladin","Search the slain paladin for clues to the gems.",2283},
    {2318,"Translating the Journal","Horde",37,42,3450,"paladin","jarkal","Take the paladin's journal to Jarkal in Kargath.",2284},
    {2338,"Translating the Journal","Horde",37,42,345,"jarkal","jarkal","Let Jarkal borrow the necklace to translate the journal.",2318},
    {2339,"Find the Gems and Power Source","Horde",37,44,3750,"jarkal","jarkal","Recover the three necklace gems and Archaedas' power source.",2338},
    {2340,"Deliver the Gems","Horde",37,44,1850,"jarkal","dran","Deliver the necklace and gem salvage to Dran Droffers.",2339},
    {2341,"Necklace Recovery, Take 3","Horde",37,44,5600,"dran","jarkal","Visit Jarkal for the finished necklace.",2340},
    {2418,"Power Stones",nil,30,36,3500,"rigglefuzz","rigglefuzz","Collect 8 Dentrium and 8 An'Alleum Power Stones."},
    {709,"Solution to Doom",nil,30,40,3150,"theldurin","theldurin","Recover the Tablet of Ryun'eh."},
    {2278,"The Platinum Discs",nil,40,47,4200,"discs","discs","Speak to the stone watcher, then activate the Discs of Norgannon."},
    {2279,"The Platinum Discs","Alliance",40,47,5250,"discs","magellas","Take the miniature discs to the Explorers' League.",2278},
    {2439,"The Platinum Discs","Alliance",40,47,420,"magellas","dinita","Deliver the reward voucher to Dinita Stonemantle.",2279},
    {2280,"The Platinum Discs","Horde",40,47,5250,"discs","sage","Take the miniature discs to Thunder Bluff.",2278},
    {2440,"The Platinum Discs","Horde",40,47,420,"sage","bena","Deliver the reward voucher to Bena Winterhoof.",2280},
    {1956,"Power in Uldaman",nil,35,40,3150,"tabetha","tabetha","Recover an Obsidian Power Source from the Obsidian Sentinel. Complete Return to the Marsh, The Infernal Orb and The Exorcism first.",1955},
    {722,"Amulet of Secrets","Alliance",35,40,3150,"hammertoe","hammertoe","Recover Hammertoe's Amulet from Magregan Deepshadow. Begin with A Sign of Hope.",721},
    {723,"Prospect of Faith","Alliance",35,40,2350,"hammertoe","ryedol","Deliver Hammertoe's Amulet to Prospector Ryedol.",722},
    {724,"Prospect of Faith","Alliance",35,40,3150,"ryedol","karnik","Deliver the amulet to Historian Karnik.",723},
    {725,"Passing Word of a Threat","Alliance",35,40,1550,"karnik","belgrum","Take Karnik's note to Advisor Belgrum.",724},
    {726,"Passing Word of a Threat","Alliance",35,40,2350,"belgrum","karnik","Speak to Historian Karnik.",725},
    {762,"An Ambassador of Evil","Alliance",35,44,4650,"karnik","belgrum","Kill Ambassador Infernus in Angor Fortress and return proof to Belgrum.",726},
}
local added = {}
for _, row in ipairs(rows) do
    local id = row[1]
    local quest = {
        name=row[2], faction=row[3], minLevel=row[4], questLevel=row[5], classicXp=row[6],
        dungeon=id == 3341 or id == 3636 or id == 6626 or id == 3523 or id == 3525,
        pickup=contacts[row[7]], turnIn=contacts[row[8]], objectives=row[9], prerequisites={},
        source="https://www.wowhead.com/forever/quest=" .. id, verifiedForever=false,
    }
    quest.dungeon = quest.dungeon and "razorfen-downs" or "uldaman"
    if row[7] == "necklace" then quest.pickupType = "drop"
    elseif row[7] == "discs" or row[7] == "bowl" or row[7] == "paladin" then quest.pickupType = "object" end
    if row[10] then
        quest.prerequisites = {{questID=row[10],relationship="required",note="Complete the preceding chain step; levels and eligibility need beta confirmation."}}
    end
    DQT.quests[id], added[id] = quest, row[10]
end
for id, parent in pairs(added) do
    if parent and DQT.quests[parent] then DQT.quests[id].followUpOf = parent end
end
DQT.quests[1956].classes = {"MAGE"}
-- Move the Kraul continuation into its actual destination, without duplicating IDs.
DQT.quests[6522].classicXp = 2800

local wetlands = {
    [95663]={name="Dragonmaw Rumors",faction="Horde",pickup={name="Zaruk (player-reported; confirm in beta)",zone="Arathi Highlands",subzone="Hammerfall"},turnIn={name="Deathstalker Agent",zone="Wetlands",subzone="Hills above the Dragonmaw camp"},objectives="Meet the Deathstalker Agent above the Dragonmaw camp."},
    [95682]={name="Open the Maw",faction="Horde",followUpOf=95663,pickup={name="Deathstalker Agent",zone="Wetlands",subzone="Outside Excavation Site"},turnIn={name="Deathstalker Agent",zone="Wetlands",subzone="Outside Excavation Site"},objectives="Kill 2 Dragonmaw Saboteurs and 4 Dragonmaw Warders; recover a Dragonmaw Dispatch."},
    [95737]={name="Seeking Caitlin",faction="Alliance",pickup={name="Llana",zone="Ashenvale",subzone="Astranaar",coordinates="35.0, 48.6"},turnIn={name="Caitlin Grassman",zone="Wetlands",subzone="Menethil Harbor"},objectives="Find Caitlin Grassman in Menethil Harbor."},
    [95809]={name="Heartwoven",faction="Alliance",followUpOf=95647,pickup={name="Ardin Grassman",zone="Excavation Site: Wetlands"},turnIn={name="Caitlin Grassman",zone="Wetlands",subzone="Menethil Harbor"},objectives="Deliver Ardin's Reed-woven Heart to Caitlin."},
    [98824]={name="Prehistoric Prism",faction="Alliance",followUpOf=95810,pickup={name="Prospector Whelgar",zone="Wetlands",subzone="Whelgar's Excavation Site"},turnIn=contacts.magellas,objectives="Bring the Titan Relic to High Explorer Magellas. Players report the relic can disappear after the preceding turn-in; confirm the current build."},
    [98823]={name="Earthen Echo",faction="Horde",followUpOf=95664,pickup={name="Elder Rise contact (confirm in beta)",zone="Thunder Bluff",subzone="Elder Rise"},turnIn={name="Muln Earthfury",zone="Mulgore",subzone="Skywatcher Plateau, northwest Mulgore"},objectives="Deliver the Titan Relic to Muln Earthfury. Players report a missing-relic bug after the preceding step; confirm the current build."},
}
for id, quest in pairs(wetlands) do
    quest.dungeon, quest.minLevel, quest.questLevel = "excavation-site-wetlands", 24, 31
    quest.newInForever, quest.verifiedForever = true, false
    quest.source = "https://www.wowhead.com/forever/quest=" .. id
    quest.prerequisites = quest.followUpOf and {{questID=quest.followUpOf,relationship="required",note="Complete the previous dungeon-chain step."}} or {}
    DQT.quests[id] = quest
end
for _, id in ipairs({95697,95664,95772,95646,95647,95810}) do DQT.quests[id].questLevel = 31 end
DQT.quests[98815].questLevel = 28
DQT.quests[95647].pickup = wetlands[95737].turnIn
DQT.quests[95647].pickup.coordinates = "11.8, 58.6"
DQT.quests[95647].prerequisites = {{questID=95737,relationship="breadcrumb",note="Optional Seeking Caitlin lead-in from Llana. The updated dungeon guide and player reports allow direct pickup in Menethil Harbor; confirm in beta."}}
DQT.quests[95737].breadcrumbOnly = true
DQT.quests[95647].objectives = "Find Ardin Grassman in the Excavation Site; Heartwoven returns to Caitlin in Menethil Harbor."
DQT.quests[95810].objectives = "Take the Titan Relic to Prospector Whelgar, then continue with Prehistoric Prism in Ironforge."
DQT.quests[95664].objectives = "Take the Titan Relic to Elder Rise, then continue with Earthen Echo in Mulgore. Confirm the Elder Rise contact in beta."
for _, id in ipairs({95664,95810}) do
    DQT.quests[id].pickup.subzone = "Titan Relic from the final boss, Relic Guardian"
end
