local _,DQT=...
if DQT.launchReviewApplied then return end
DQT.launchReviewApplied=true
-- November 5 launch review: acquisition gates are ID-linked, not name-matched.
-- Player reports establish the new gates; local client validation remains pending.
local dungeon="ruins-of-lordaeron"
local function Location(name,zone,coordinates)
    return {name=name,zone=zone,coordinates=coordinates}
end
local linnea=Location("Deathguard Linnea","Tirisfal Glades","65.5, 60.2")
local renferrel=Location("Apothecary Renferrel","Silverpine Forest","42.8, 40.9")
local faranell=Location("Master Apothecary Faranell","Undercity","48.8, 69.3")
local records={
    [356]={name="Rear Guard Patrol",minLevel=6,questLevel=11,pickup=linnea,turnIn=linnea,
        objectives="Patrol Balnir Farmstead and defeat the specified Scourge enemies, then return to Deathguard Linnea.",prerequisites={}},
    [99156]={name="Rear Guard Patrol",minLevel=6,questLevel=13,pickup=linnea,turnIn=linnea,followUpOf=356,
        objectives="Defeat Riptear in eastern Tirisfal Glades and bring his heart to Deathguard Linnea.",
        prerequisites={{questID=356,relationship="required",note="Required: complete Rear Guard Patrol (#356) first. This second step is the Riptear quest, not the patrol collection step."}}},
    [447]={name="A Recipe For Death",minLevel=9,questLevel=12,pickup=renferrel,turnIn=faranell,
        objectives="Collect the requested bear and spider reagents in Silverpine Forest and deliver them to Master Apothecary Faranell.",prerequisites={}},
    [450]={name="A Recipe For Death",minLevel=9,questLevel=15,pickup=faranell,turnIn=renferrel,followUpOf=447,
        objectives="Recover Berard's Journal in Pyrewood Village and return it to Apothecary Renferrel.",
        prerequisites={{questID=447,relationship="required",note="Required: finish the first A Recipe For Death (#447), then accept the journal step."}}},
    [451]={name="A Recipe For Death",minLevel=9,questLevel=18,pickup=renferrel,turnIn=faranell,followUpOf=450,
        objectives="Gather the requested lake moss and tumor samples, then return to Master Apothecary Faranell.",
        prerequisites={{questID=450,relationship="required",note="Required: complete the journal step (#450) before the final reagent collection."}}},
}
for _,id in ipairs({356,99156,447,450,451}) do
    local quest=records[id]
    quest.dungeon,quest.faction=dungeon,"Horde"
    quest.preparationOnly,quest.verifiedForever,quest.awaitingFinalVerification=true,false,true
    quest.pickupType,quest.confidence="npc","needsReview"
    quest.source="https://www.wowhead.com/forever/quest="..id
    quest.sourceURLs={quest.source,"https://bindonforever.com/quest/"..id}
    quest.verification={sourceReview="2026-11-05: exact-ID preparation chain review. Names repeat across distinct steps; Forever eligibility still needs local confirmation.",
        xpReview="2026-11-05: no independently verified current Forever reward; XP remains unknown.",
        xp="Current unmodified Forever XP not independently confirmed; no reward inferred from Classic or another step.",
        level=id==99156 and "Sources disagree on minimum level (6 versus 10); 6 retained provisionally pending current-client verification." or "Published route reference; verify current client eligibility."}
    quest.shareability={assumption="clientDetermined",note="The client determines whether this preparation quest can be shared."}
    DQT.quests[id]=quest
    table.insert(DQT.dungeons[dungeon].quests,id)
end
local gates={
    [92422]={parent=99156,note="Required: complete both Rear Guard Patrol steps (#356, then #99156/Riptear) before picking up The Wrath of Rath'mael. Launch reports corroborate this new gate."},
    [95216]={parent=451,note="Required: complete A Recipe For Death (#447 -> #450 -> #451) before picking up The New Plague. This is not the similarly named A New Plague chain in Brill. Launch player reports; local confirmation pending."},
}
local publishedRewards={
    [5214]={xp=8300,url="https://www.wowhead.com/forever/quest=5214/the-great-fras-siabi",
        review="Wowhead Forever lists 8,300 XP for this exact quest ID. Actual payout can vary by character level and modifiers."},
    [7507]={xp=9950,url="https://www.wowhead.com/forever/quest=7507/forors-compendium",
        review="Wowhead Forever lists 9,950 XP for this exact quest ID. Actual payout can vary by character level and modifiers."},
    [1160]={xp=5000,url="https://ahledger.com/wow-forever/quests/1160-test-of-lore",
        review="2026-11-09: public Forever client observations for the book quest (#1160). Actual payout can vary by character level and modifiers."},
    [1490]={xp=120,url="https://wowforevertalents.com/quests/nara-wildmane-1490/"},
    [2842]={xp=280,url="https://wowforevertalents.com/quests/chief-engineer-scooty-2842/"},
}
for id,reward in pairs(publishedRewards) do
    local quest=DQT.quests[id]
    quest.xpPreviousEstimate=quest.foreverXp
    quest.foreverXp,quest.xpPublished,quest.xpSource=reward.xp,true,reward.url
    quest.xpEstimate,quest.xpOutdated,quest.xpReported=nil,nil,nil
    quest.sourceURLs[#quest.sourceURLs+1]=reward.url
    quest.verification.xpReview=reward.review or "2026-11-05: individual published beta reward from dated client-cache/log references. Reviewed by exact ID; not a launch-client or unmodified-reward observation."
end
local fras=DQT.quests[5214]
fras.name="The Great Fras Siabi"
fras.pickup.coordinates="80, 58"
fras.pickup.subzone="Light's Hope Chapel"
fras.turnIn=fras.pickup
fras.objectives="Recover the premium tobacco from Fras Siabi's smoke shop in Stratholme and return it to Smokey LaRue."
local foror=DQT.quests[7507]
foror.name="Foror's Compendium"
foror.pickup={name="Nostro's Compendium of Dragon Slaying",zone="Dire Maul"}
foror.pickupType="drop"
for id,gate in pairs(gates) do
    local quest=DQT.quests[id]
    quest.prerequisites={{questID=gate.parent,relationship="required",note=gate.note}}
    quest.followUpOf=gate.parent
    quest.sourceURLs[#quest.sourceURLs+1]="https://www.wowhead.com/forever/quest="..id
    quest.verification.prerequisites="2026-11-05: launch player reports reviewed against exact quest IDs and the preceding series. Required gate modelled; not independently played through locally."
    quest.verification.conflict=nil
    quest.verification.launchReview="Other Ruins prerequisites remain provisional; these reviewed links replace the generic pending-chain warning for this quest only."
end
-- Preserve dated published/reported/estimated XP until a current quest-specific
-- observation establishes a replacement. An empty XP field on a page is not zero.
-- Explicit guide rewards are provisional, never promoted to client observations.
local guideURL="https://trgaming.ddnsgeek.com/wow-forever-excavation-site-wetlands-dungeon-guide-quests-bosses-and-loot/"
local guideRewards={
    [95795]=6150,[95809]=6150,[98824]=6950,[95772]=6150,
    [95646]=6150,[95647]=4900,[95810]=1250,[95697]=6950,
    [95664]=1400,[98823]=6950,[95682]=6950,[92422]=4600,
    [95663]=550,[95737]=1250,
    [1491]=2650,[1198]=5700,[1740]=5100,[6922]=7250,[2398]=320,[2318]=3450,[6521]=3500,
}
local rewardSources={}
rewardSources[1491]="https://hearthproof.com/dungeons/wailing-caverns/"
for _,id in ipairs({1198,1740,6922}) do rewardSources[id]="https://hearthproof.com/dungeons/blackfathom-deeps/" end
for _,id in ipairs({2398,2318}) do rewardSources[id]="https://hearthproof.com/dungeons/uldaman/" end
rewardSources[6521]="https://hearthproof.com/dungeons/razorfen-downs/"
rewardSources[95663]="https://warcraft.wiki.gg/wiki/Dragonmaw_Rumors"
rewardSources[95737]="https://www.wowhead.com/forever/quest=95737/seeking-caitlin"
local dalaranURL="https://trgaming.ddnsgeek.com/wow-forever-city-of-dalaran-dungeon-guide-quests-bosses-and-loot/"
for _,id in ipairs({96984,92458,96986,96988,96987,92489,92456}) do
    guideRewards[id],rewardSources[id]=9400,dalaranURL
end
for _,id in ipairs({97289,97290,97291,97292}) do
    guideRewards[id]=1650
    rewardSources[id]="https://www.foreverdb.app/en/forever/quests/"..id.."/unending-torment"
end
-- Distinct IDs are essential: the explosive placement and detonator steps
-- have the same title but different rewards. Never spread one across a chain.
guideRewards[92753],rewardSources[92753]=4050,"https://www.wowhead.com/forever/quest=92753/destruction-in-deadmines"
guideRewards[92819],rewardSources[92819]=680,"https://warcraft.wiki.gg/wiki/Destruction_in_Deadmines_(2)"
guideRewards[95042],rewardSources[95042]=2000,"https://eternadex.com/en/quests/95042/"
guideRewards[95111],rewardSources[95111]=1000,"https://urgametips.com/wow-forever/quest-guides/underrated-talent-ott-tarren-mill-blacksmithing/"
for id,xp in pairs(guideRewards) do
    local quest=DQT.quests[id]
    local url=rewardSources[id] or (id==92422 and "https://trgaming.ddnsgeek.com/wow-forever-ruins-of-lordaeron-dungeon-guide-quests-bosses-and-loot/" or guideURL)
    quest.xpPreviousValue=quest.foreverXp
    quest.foreverXp,quest.xpGuide,quest.xpSource=xp,true,url
    quest.xpOutdated,quest.xpEstimate,quest.xpPublished,quest.xpReported=nil,nil,nil,nil
    quest.sourceURLs=quest.sourceURLs or {}
    quest.sourceURLs[#quest.sourceURLs+1]=url
    quest.verification.xpReview="2026-11-05: exact quest ID/objective matched to a published reward page, guide or player report (see xpSource). Provisional reported base reward, not independently verified in the current client; player level and modifiers can change the payout."
end
for _,quest in pairs(DQT.quests) do
    quest.verification.launchXPReview="2026-11-05: current source sweep. Rewards retain their explicit published/report/estimate/Classic/unknown provenance; no global recalibration or missing-field-to-zero conversion."
end

-- November 6 source review: distinguish reviewed fields from local observations.
-- Historical source dates remain in the audit metadata; they are not UI warnings.
local reviewedRewards={
    [167]={1550,"oh-brother"},[168]={1350,"collecting-memories"},
    [1051]={3300,"vorrel-s-revenge"},[1221]={5000,"blueleaf-tubers"},
    [1275]={2400,"researching-the-corruption"},[1489]={290,"hamuul-runetotem"},
    [2418]={3500,"power-stones"},[6563]={1750,"the-essence-of-aku-mai"},
}
for id,reward in pairs(reviewedRewards) do
    local quest=DQT.quests[id]
    local url="https://wowforevertalents.com/quests/"..reward[2].."-"..id.."/"
    quest.foreverXp,quest.xpPublished,quest.xpSource=reward[1],true,url
    quest.xpGuide,quest.xpEstimate,quest.xpReported,quest.xpOutdated=nil,nil,nil,nil
    quest.sourceURLs[#quest.sourceURLs+1]=url
    quest.verification.xpReview="2026-11-06: current individual reward page matches this quest ID and amount. Published reward replaces the estimate, player-report or Classic-fallback label; no claim of a new local observation."
end
local reputationSource="https://wowforevertalents.com/reputations/kirin-tor/"
for id,xp in pairs({[92432]=650,[92459]=270}) do
    local quest=DQT.quests[id]
    quest.foreverXp,quest.xpPublished,quest.xpSource=xp,true,reputationSource
    quest.xpGuide,quest.xpEstimate,quest.xpReported,quest.xpOutdated=nil,nil,nil,nil
    quest.sourceURLs[#quest.sourceURLs+1]=reputationSource
    quest.verification.xpReview="2026-11-06: exact quest ID matched through the Kirin Tor reward table's quest link. Published client-cache/log reward; not a new local observation."
end
for _,id in ipairs({96984,92458,96986,96988,96987,92489,92456,92457}) do
    DQT.quests[id].detailsSourceReviewed=true
end
DQT.quests[96984].objectives="Recover the Arcane Mote inside the City of Dalaran and return to Magus Wordeen Voidglare in Tarren Mill."
DQT.quests[96984].prerequisites[1].note="Complete Blood in the Streets, then collect the dungeon quest and sewer key from Modera's image."
DQT.quests[92458].objectives="Recover the Arcane Mote inside the City of Dalaran and return to Modera's image beside Lordamere Lake."
DQT.quests[92457].objectives="Defeat 8 Seeking Remnants, 8 Saturated Remnants and 8 Mana Echoes inside the dungeon, then return to Modera's image beside Lordamere Lake."
DQT.quests[92432].pickup={name="Emissary Jacques",zone="Hillsbrad Foothills",subzone="Southshore",coordinates="48.3, 60.0"}
DQT.quests[92432].objectives="Report to Modera's image beside Lordamere Lake."
local contacts={
    [95697]={pickup="Borstan",turnIn="Borstan"},
    [95663]={pickup="Zaruk"},[95772]={turnIn="Daewyn Songblade's body"},
    [95647]={turnIn="Ardin Grassman"},[95664]={turnIn="Bashana Runetotem"},
    [98823]={pickup="Bashana Runetotem"},
}
for id,sides in pairs(contacts) do
    for side,name in pairs(sides) do DQT.quests[id][side].name=name end
end
DQT.quests[95664].objectives="Take the Titan Relic to Bashana Runetotem on Elder Rise in Thunder Bluff."
DQT.quests[95647].prerequisites[1].note="Seeking Caitlin is an optional introduction from Llana in Astranaar; Lost in the Thicket Things can be picked up directly from Caitlin in Menethil Harbor."
local deathstalkers=DQT.quests[1098]
deathstalkers.turnIn={name="Deathstalker Vincent's body",zone="Shadowfang Keep",subzone="Courtyard, right of the stairs"}
deathstalkers.sourceURLs[#deathstalkers.sourceURLs+1]="https://hearthproof.com/dungeons/shadowfang-keep/"
deathstalkers.verification.turnIn="2026-11-08: published Forever guide identifies Vincent's body as the turn-in."
local dragonmawRumors=DQT.quests[95663]
dragonmawRumors.pickup.coordinates="74.4, 35.6"
dragonmawRumors.sourceURLs[#dragonmawRumors.sourceURLs+1]="https://warcraft.wiki.gg/wiki/Dragonmaw_Rumors"
dragonmawRumors.verification.prerequisites="Live player confirms direct pickup from Zaruk in Hammerfall. Dragonmaw Rumors starts the chain."
DQT.quests[95682].prerequisites[1].note="Turn in Dragonmaw Rumors to the Deathstalker Agent before picking up Open the Maw."
local wetlandsGuide="https://forever-tavern.com/dungeons/excavation-site-wetlands/"
local function WetlandsReview(id)
    local quest=DQT.quests[id]
    quest.sourceURLs[#quest.sourceURLs+1]=wetlandsGuide
    quest.verification.sourceReview="2026-11-08: reviewed Wetlands quest contacts and chain against the published Forever quest guide."
    return quest
end
local agent=Location("Deathstalker Agent","Wetlands","51.4, 59.2")
agent.subzone="Hills above the Dragonmaw camp"
WetlandsReview(95663).turnIn=agent
local openMaw=WetlandsReview(95682)
openMaw.pickup,openMaw.turnIn=agent,agent
local tastes=WetlandsReview(95697)
tastes.pickup.coordinates,tastes.turnIn.coordinates="57.3, 53.3","57.3, 53.3"
tastes.objectives="Collect four Thicket Raptor Meat inside the Excavation Site and return to Borstan."
local bashana=Location("Bashana Runetotem","Thunder Bluff","70.8, 33.6")
bashana.subzone="Elder Rise"
WetlandsReview(95664).turnIn=bashana
local echo=WetlandsReview(98823)
echo.pickup=bashana
echo.turnIn.coordinates="33.4, 22.5"
WetlandsReview(98815).prerequisites={{questID=484,external=true,relationship="required",
    note="Complete Young Crocolisk Skins from James Halloran in Menethil Harbor (8.6, 55.8). Daily Delivery is a referral."}}
WetlandsReview(95646).prerequisites={{questID=275,external=true,relationship="required",
    note="At Rethiel the Greenwarden (Wetlands 56.3, 40.5), complete Tramping Paws, Fire Taboo, and Blisters on the Land."}}
local relic=WetlandsReview(95810)
relic.verification.xpReview="Sources disagree on Lost Relic Carry XP. Retained the existing provisional 1,250 XP pending a live reward reading."
-- Sourced objective areas, not surveyed walking paths or exact spawn locations.
DQT.quests[356].routeObjectives={{name="Balnir Farmstead patrol area",zone="Tirisfal Glades",coordinates="76, 61",
    source="https://wowforever.wclbox.com/en/renwu/356",sourceReviewed=true,note="Approximate published objective area; follow the quest log for targets."}}
DQT.quests[450].routeObjectives={{name="Berard's Journal, Pyrewood Village",zone="Silverpine Forest",coordinates="43, 73",
    source="https://wowforever.wclbox.com/en/renwu/450",sourceReviewed=true,note="Approximate published objective area; the journal is in Pyrewood Village."}}

-- November 7: use exact-ID quest rewards. Category-table XP can omit the dungeon bonus.
local drowned="the-drowned-city"
local kroldok="kroldok-stronghold"
local alcaz="alcaz-prison"
local blizzardDungeons="https://worldofwarcraft.blizzard.com/en-us/news/24301455/explore-the-new-dungeons-of-world-of-warcraft-forever"
local kin=Location("Kin'weelay","Stranglethorn Vale","32.3, 27.7")
local dibbs=Location("Loremaster Dibbs","Hillsbrad Foothills","50.6, 57.1")
local mazu=Location("Mazu'kon","Mulgore","32.5, 20.6")
local zoneSources={
    ["razorfen-downs"]="https://legacyofwarcraft.com/db/forever/quests/razorfen-downs.html",
    ["maraudon"]="https://legacyofwarcraft.com/db/forever/quests/maraudon.html",
    ["blackrock-depths"]="https://legacyofwarcraft.com/db/forever/quests/blackrock-depths.html",
    ["blackmaw-hold"]="https://legacyofwarcraft.com/db/forever/quests/blackmaw-hold.html",
    ["shapers-terrace"]="https://legacyofwarcraft.com/db/forever/quests/the-shaper-s-terrace.html",
    ["zul-farrak"]="https://www.wowhead.com/forever/guide/zulfarrak-dungeon-overview-location-rewards",
    ["scarlet-monastery-library"]="https://www.wowhead.com/forever/guide/scarlet-monastery-library-dungeon-overview-location-rewards",
    [drowned]="https://www.wowhead.com/forever/zone=16550/the-drowned-city",
    [kroldok]="https://www.wowhead.com/forever/zone=16842/kroldok-stronghold",
    [alcaz]="https://www.wowhead.com/forever/zone=16620/alcaz-prison",
}
local function AddDungeonQuest(key,id,quest)
    local dungeonData=DQT.dungeons[key]
    quest.dungeon=key
    quest.pickup=quest.pickup or Location("Unknown quest giver","Unknown")
    quest.turnIn=quest.turnIn or quest.pickup
    quest.pickupType="npc"
    quest.confidence=quest.pickup.zone=="Unknown" and "needsReview" or "verifiedSource"
    quest.shareability={assumption="clientDetermined",note="The client determines whether this quest can be shared."}
    quest.source=quest.source or "https://www.wowhead.com/forever/quest="..id
    quest.sourceURLs={quest.source,zoneSources[key]}
    if quest.xpSource and quest.xpSource~=quest.source then
        quest.sourceURLs[#quest.sourceURLs+1]=quest.xpSource
    end
    quest.verification={sourceReview="Exact quest ID matched to Forever sources."}
    if quest.foreverXp then
        if not quest.xpGuide then quest.xpPublished=true end
        quest.xpSource=quest.xpSource or quest.source
        quest.verification.xpReview="Individual Forever quest reward. Actual payout can vary by character level and modifiers."
    else
        quest.verification.xpReview="Individual Forever reward unavailable. XP remains unknown."
    end
    quest.prerequisites=quest.prerequisites or {}
    if quest.followUpOf then
        quest.prerequisites[1]={questID=quest.followUpOf,relationship="required",note="Complete "..DQT.quests[quest.followUpOf].name.." first."}
    end
    DQT.quests[id]=quest
    table.insert(dungeonData.quests,id)
end

local function Eternadex(id)
    return "https://eternadex.com/en/quests/"..id.."/"
end

local sourceReviewQuests={
    {key="dire-maul-west",id=98830,name="The Broken Glaive",min=52,level=60,xp=13200,kind="drop",
        pickup=Location("Tortheldrin's Broken Glaive","Dire Maul"),turnIn=Location("Shen'dralar Ancient","Dire Maul"),
        objective="Deliver Tortheldrin's Broken Glaive to the Shen'dralar Ancient."},
    {key="lower-blackrock-spire",id=98325,name="Blood and Thunder",faction="Horde",min=55,level=60,xp=650,
        pickup=Location("Warlord Goretooth","Badlands","5.8, 47.5"),
        objective="Speak to Warlord Goretooth to serve the Kargath Expeditionary Force."},
    {key="blackmaw-hold",id=97327,name="Blackmaw Pouches",min=55,level=60,xp=13200,
        pickup=Location("Ekkal","Azshara","42.0, 38.9"),
        objective="Recover five Blackmaw Pouches inside Blackmaw Hold and return to Ekkal."},
    {key="uldaman",id=721,name="A Sign of Hope",faction="Alliance",min=35,level=35,xp=4800,
        pickup=Location("Prospector Ryedol","Badlands","53.4, 43.4"),turnIn=Location("Hammertoe Grez","Badlands","37.8, 10.7"),
        objective="Find Hammertoe Grez in the Uldaman excavation."},
    {key="zul-farrak",id=2861,name="Tabetha's Task",min=40,level=46,xp=410,
        pickup=Location("City mage trainers","Unknown"),turnIn=Location("Tabetha","Dustwallow Marsh","46.1, 57.1"),
        objective="Speak with Tabetha in Dustwallow Marsh. Offered by Anastasia Hartwell, Bink, Jennea Cannon or Deino."},
    {key="alcaz-prison",id=96376,name="State Secrets",faction="Horde",min=48,level=53,xp=6550,
        turnIn=Location("Nazgrel","Orgrimmar","32.4, 36.0"),
        objective="Find Mason Connery's treasure in Westfall and take its documents to Nazgrel."},
    {key="alcaz-prison",id=96377,name="State Secrets",faction="Alliance",min=48,level=53,xp=6550,
        turnIn=Location('Renzik "The Shiv"',"Stormwind City","78.4, 71.0"),
        objective="Find Mason Connery's treasure in Westfall and take its documents to Renzik."},
    {key="alcaz-prison",id=96379,name="State Secrets",min=48,level=53,xp=6550,
        turnIn=Location("Rix Xizzix","Stranglethorn Vale","28.5, 75.8"),
        objective="Find Mason Connery's treasure in Westfall and take its documents to Rix Xizzix."},
    {key="gnomeregan",id=2931,name="Castpipe's Task",faction="Alliance",min=25,level=28,xp=230,
        pickup=Location("Gaxim Rustfizzle","Stonetalon Mountains"),turnIn=Location("Master Mechanic Castpipe","Ironforge"),
        objective="Speak with Master Mechanic Castpipe in Ironforge."},
    {key="gnomeregan",id=2925,name="Klockmort's Essentials",faction="Alliance",min=24,level=30,xp=250,
        pickup=Location("Mathiel","Darnassus"),turnIn=Location("Klockmort Spannerspan","Ironforge"),
        objective="Speak with Klockmort Spannerspan in Ironforge."},
    {key="gnomeregan",id=2923,name="Tinkmaster Overspark",faction="Alliance",min=20,level=26,xp=210,
        pickup=Location("Brother Sarno","Stormwind City"),turnIn=Location("Tinkmaster Overspark","Ironforge"),
        objective="Speak with Tinkmaster Overspark in Ironforge."},
    {key="gnomeregan",id=2927,name="The Day After",faction="Alliance",min=20,level=27,xp=220,
        pickup=Location("Gnoarn","Ironforge"),turnIn=Location("Ozzie Togglevolt","Dun Morogh"),
        objective="Speak with Ozzie Togglevolt in Kharanos."},
    {key="kroldok-stronghold",id=94997,name="Lingering Essence",faction="Alliance",min=38,level=42,xp=3450,
        pickup=Location("Sergeant Riftan","Riverglades","30.6, 49.0"),turnIn=Location("Ashe Amberhall","Riverglades","66.7, 81.1"),
        objective="Bring the Satchel of Cursed Mementos to Ashe Amberhall."},
    {key="kroldok-stronghold",id=94998,name="Curios of Curiosity",faction="Alliance",min=38,level=42,xp=3450,
        pickup=Location("Ashe Amberhall","Riverglades","66.7, 81.1"),turnIn=Location("Melanie Sable","Riverglades","66.2, 83.3"),
        objective="Bring the Satchel of Mementos to Melanie Sable."},
    {key="alcaz-prison",id=95263,name="Somber News",faction="Alliance",min=48,level=53,xp=2850,
        pickup=Location("King's fate discovered","Alcaz Prison"),turnIn=Location("Sully McCleary","Dustwallow Marsh","63.5, 42.4"),
        objective="Return to Sully McCleary with what you learned about the king."},
    {key="zul-farrak",id=2864,name="Tran'rek",min=40,level=45,xp=390,
        pickup=Location("Krazek","Stranglethorn Vale","27.0, 77.2"),turnIn=Location("Tran'rek","Tanaris","51.6, 26.8"),
        objective="Speak with Tran'rek in Gadgetzan."},
    {key="blackfathom-deeps",id=6562,name="Trouble in the Deeps",faction="Horde",min=17,level=22,xp=440,
        pickup=Location("Tsunaman","Stonetalon Mountains","47.3, 64.3"),turnIn=Location("Je'neu Sancrea","Ashenvale"),
        objective="Speak with Je'neu Sancrea at Zoram'gar Outpost."},
    {key="blackmaw-hold",id=92065,name="Blackmaw Reclamation",min=47,level=60,xp=13200,
        pickup=Location("Gatekeeper Rageroar","Azshara","42.3, 20.2"),parent=86814,
        objective="Bring Varrox Bleakhoof's head to Gatekeeper Rageroar. Requires Neutral standing with Timbermaw Hold."},
    {key="blackmaw-hold",id=92066,name="The Twin Bears",min=47,level=55,xp=11300,
        pickup=Location("Lorekeeper Nok","Azshara","41.4, 20.0"),
        objective="Recover the Totems of Ursoc and Ursol inside Blackmaw Hold."},
    {key="blackmaw-hold",id=92069,name="Claws That Rend, Tusks that Gore",min=45,level=58,xp=12400,
        pickup=Location("Ogtinc","Azshara","42.4, 42.7"),
        objective="Recover the Claws of the Great Bear and Tusks of the Unbroken from Blackmaw Hold."},
    {key="blackmaw-hold",id=92070,name="A Lost Memento",min=47,level=55,xp=11300,
        pickup=Location("Feathered Charm Necklace","Blackmaw Hold"),turnIn=Location("Unele","Azshara","43.2, 18.2"),kind="drop",
        objective="Bring the Feathered Charm Necklace found in Blackmaw Hold to Unele."},
    {key="blackmaw-hold",id=96246,name="Blackmaw Pouches",min=55,level=60,
        pickup=Location("Ekkal","Azshara","42.0, 38.9"),objective="Bring five Blackmaw Pouches to Ekkal."},
    {key="blackmaw-hold",id=97173,name="Blackmaw Magic",faction="Alliance",min=52,level=59,xp=12800,
        pickup=Location("Archmage Timear","Alterac Mountains","15.4, 74.0"),objective="Recover a Blackmaw Ritual Totem from Blackmaw Hold."},
    {key="blackmaw-hold",id=97198,name="Blackmaw Magic",faction="Horde",min=52,level=59,xp=16100,
        pickup=Location("Muln Earthfury","Mulgore","33.4, 22.5"),objective="Recover a Blackmaw Ritual Totem from Blackmaw Hold."},
    {key="blackmaw-hold",id=92344,name="Get to the Roots of It",faction="Alliance",min=45,level=55,xp=11300,parent=92345,
        pickup=Location("Mathrengyl Bearwalker","Darnassus","35.2, 8.6"),objective="Gather ten Nordrassil Root Caps inside Blackmaw Hold."},
    {key="shapers-terrace",id=95928,name="Crystalline Elements",faction="Horde",min=55,level=60,xp=17650,
        pickup=Location("Mayena Earthseeker","Mulgore","34.9, 22.1"),
        objective="Recover a Moist Crystal, Charged Crystal, Noxious Crystal and Fiery Crystal from Shaper's Terrace."},
    {key="shapers-terrace",id=95790,name="Digestible Research",faction="Alliance",min=55,level=60,xp=17650,kind="drop",
        pickup=Location("Journal pages","Shaper's Terrace"),turnIn=Location("Curator Thorius","Ironforge"),
        objective="Collect 15 Partially Digested Journal Pages inside Shaper's Terrace."},
    {key="shapers-terrace",id=97049,name="Essence of Seeping Slimes",faction="Horde",min=55,level=60,xp=17650,
        pickup=Location("Chemist Fuely","Undercity","47.5, 71.9"),objective="Gather eight Seeping Slime Essences inside Shaper's Terrace."},
    {key="shapers-terrace",id=95925,name="Mapping the Way Forward",faction="Alliance",min=55,level=60,xp=17650,
        pickup=Location("Curator Thorius","Ironforge"),objective="Find the landmarks in Shaper's Terrace and fill out the explorer's map."},
    {key="shapers-terrace",id=95926,name="The Dark Crystal",faction="Horde",min=55,level=60,xp=17650,
        pickup=Location("Master Apothecary Faranell","Undercity","48.7, 69.2"),
        objective="Recover a Drained Crystal Fragment near the Achromatic Crystal in Shaper's Terrace."},
}
for _,record in ipairs(sourceReviewQuests) do
    local prerequisite=record.parent and {{questID=record.parent,external=true,relationship="required",
        note=record.parent==86814 and "Complete Blackmaw Counter-Offensive in Rageroar's chain." or "Complete Beneath Nordrassil from Commander Truesong."}} or {}
    AddDungeonQuest(record.key,record.id,{name=record.name,faction=record.faction,minLevel=record.min,questLevel=record.level,
        foreverXp=record.xp,pickup=record.pickup,turnIn=record.turnIn,objectives=record.objective,prerequisites=prerequisite,
        source="https://db.icy-veins.com/wow-forever/quests/"..record.id})
    DQT.quests[record.id].pickupType=record.kind or "npc"
end
DQT.quests[2864].preparationOnly=true
DQT.quests[6562].preparationOnly=true
for _,id in ipairs({2931,2925,2923,2927}) do DQT.quests[id].preparationOnly=true end

for _,entry in ipairs({
    {id=96773,faction="Alliance",pickup=Location("Archmage Lan'dalock","Alterac Mountains","15.3, 73.9")},
    {id=97196,faction="Horde",pickup=Location("Sutara Plainstalker","Mulgore","34.6, 22.8")},
}) do
    AddDungeonQuest("razorfen-downs",entry.id,{name="The Coldbringer's Eye",faction=entry.faction,minLevel=34,questLevel=41,
        pickup=entry.pickup,foreverXp=8600,source="https://www.wowhead.com/forever/quest="..entry.id.."/the-coldbringers-eye",
        objectives="Recover the Coldbringer's Eye from the orb behind Amnennar in Razorfen Downs."})
end
AddDungeonQuest("maraudon",96776,{name="An'she's Radiance",faction="Horde",minLevel=43,questLevel=51,
    pickup=Location("Olana Brighthoof","Mulgore","32.6, 24.2"),foreverXp=11900,
    source="https://www.wowhead.com/forever/quest=96776/anshes-radiance",
    objectives="Recover An'she's Radiance near Landslide in Maraudon and return to Olana Brighthoof."})
AddDungeonQuest("maraudon",93404,{name="Rot and Regret",minLevel=35,questLevel=49,
    pickup=Location("Woodwyrd","Shen'dralas","69.5, 71.9"),foreverXp=11100,
    source="https://db.icy-veins.com/wow-forever/quests/93404",
    xpSource="https://www.stillsixty.com/quest/93404?revision=8a19945f-1d49-4799-8c54-4003c3b3787c",
    prerequisites={{questID=93594,external=true,relationship="required",note="Complete Word of the Woods."}},
    objectives="Collect a Vial of Earth Song Water in Maraudon and return to Woodwyrd."})
AddDungeonQuest("razorfen-downs",93604,{name="Agamaggan's Blood",minLevel=35,questLevel=45,
    pickup=Location("Kog'thug the Brave","Shen'dralas","72.7, 31.2"),foreverXp=8150,xpGuide=true,
    source="https://www.wowhead.com/forever/quest=93604/agamaggans-blood",
    prerequisites={{questID=93601,external=true,relationship="required",note="Complete Passing the Blame after Rot and Regret."}},
    objectives="Use the cauldron in Razorfen Downs, defeat the summoned Virulent Blood of Agamaggan and return its blood to Kog'thug."})
AddDungeonQuest("blackrock-depths",97197,{name="Fragment of the Firelands",faction="Horde",minLevel=46,questLevel=55,
    pickup=Location("Alaana Stormwalker","Mulgore","33.4, 22.6"),foreverXp=14800,
    source="https://www.wowhead.com/forever/quest=97197/fragment-of-the-firelands",
    objectives="Recover a Fragment of the Firelands in Blackrock Depths and return to Alaana Stormwalker."})
AddDungeonQuest("blackmaw-hold",92343,{name="Get to the Roots of It",faction="Horde",minLevel=45,questLevel=55,
    pickup=Location("Nara Wildmane","Thunder Bluff","75.6, 31.6"),foreverXp=11300,
    source="https://www.wowhead.com/forever/quest=92343/get-to-the-roots-of-it",
    prerequisites={{questID=92346,external=true,relationship="required",note="Complete Beneath Nordrassil from Jediga in Azshara."}},
    objectives="Gather ten Nordrassil Root Caps in Blackmaw Hold and return to Nara Wildmane."})
AddDungeonQuest("shapers-terrace",95924,{name="Panic at the Digsite",faction="Alliance",minLevel=55,questLevel=60,
    pickup=Location("Curator Thorius","Ironforge","71.5, 15.7"),foreverXp=17650,
    source="https://www.wowhead.com/forever/quest=95924/panic-at-the-digsite",
    objectives="Slay six Ravasaur Matriarchs, nine Ironhide Ravasaurs and Venomridge in Shaper's Terrace."})
for key,location in pairs({["blackmaw-hold"]="Azshara",["shapers-terrace"]="Northern Un'Goro Crater"}) do
    local data=DQT.dungeons[key]
    data.placeholder=nil
    data.location=location
    data.source=zoneSources[key]
    data.notes="Initial Forever quest coverage. Additional quests and chain details are still under review."
end

AddDungeonQuest("zul-farrak",96775,{name="Zum'rah's Head",faction="Horde",minLevel=42,questLevel=46,
    pickup=Location("Mazu'kon","Mulgore","32.5, 20.7"),foreverXp=10100,
    source="https://www.wowhead.com/forever/quest=96775/zumrahs-head",
    objectives="Slay Witch Doctor Zum'rah in Zul'Farrak and bring his head to Mazu'kon at Skywatcher Plateau."})
AddDungeonQuest("zul-farrak",96770,{name="The Witch Doctor's Head",faction="Alliance",minLevel=39,questLevel=46,
    pickup=Location("Archmage Lan'dalock","Alterac Mountains","15.3, 73.9"),foreverXp=10100,
    source="https://www.wowhead.com/forever/quest=96770/the-witch-doctors-head",
    objectives="Slay Witch Doctor Zum'rah in Zul'Farrak and bring his head to Archmage Lan'dalock in outdoor Dalaran."})

AddDungeonQuest("scarlet-monastery-library",96800,{name="Past Due",faction="Alliance",minLevel=30,questLevel=38,
    pickup=Location("Magus Olvek","Alterac Mountains","10.0, 63.8"),foreverXp=6750,
    xpSource="https://www.forevercraft.app/quests/96800",
    objectives="Recover The Lost Magic of the Runemasters in Arcanist Doan's room and return to Magus Olvek."})

AddDungeonQuest(drowned,629,{name="The Vile Reef",faction="Horde",minLevel=30,questLevel=37,pickup=kin,
    preparationOnly=true,foreverXp=2850,source=Eternadex(629),
    objectives="Recover a fragment of the tablet at the Vile Reef and return to Kin'weelay."})
AddDungeonQuest(drowned,95748,{name="The Gurubashi Legends of Old",faction="Horde",minLevel=30,questLevel=40,pickup=kin,
    preparationOnly=true,followUpOf=629,foreverXp=3150,source=Eternadex(95748),
    objectives="Take a rubbing of the Gurubashi tablet on the coast north of the Vile Reef."})
AddDungeonQuest(drowned,95770,{name="Locating the Lost City",faction="Horde",minLevel=30,questLevel=40,pickup=kin,
    preparationOnly=true,followUpOf=95748,foreverXp=3150,source=Eternadex(95770),
    objectives="Find the cavern entrance west of the Vile Reef and report to Kin'weelay."})
AddDungeonQuest(drowned,95775,{name="The Drowned City",faction="Horde",minLevel=30,questLevel=40,pickup=kin,
    followUpOf=95770,foreverXp=8450,source="https://www.wowhead.com/forever/quest=95775/the-drowned-city",
    objectives="Make rubbings of the four Tablets of I'lalai inside the Drowned City."})
local gromgolCommander=Location("Commander Aggro'gosh","Stranglethorn Vale","32.2, 28.8")
gromgolCommander.subzone="Grom'gol Base Camp"
AddDungeonQuest(drowned,95773,{name="Enemies in the Water",faction="Horde",minLevel=30,questLevel=37,
    pickup=gromgolCommander,preparationOnly=true,followUpOf=95748,foreverXp=2850,
    source="https://www.wowhead.com/forever/quest=95773/enemies-in-the-water",
    objectives="Gather ten Brinescale Tridents from Brinescale Skirmishers in Stranglethorn Vale."})
AddDungeonQuest(drowned,95776,{name="The Only Good Brinescale...",faction="Horde",minLevel=30,questLevel=38,
    pickup=gromgolCommander,followUpOf=95773,foreverXp=9500,source=Eternadex(95776),
    objectives="Defeat Var'Taka in the Drowned City."})
AddDungeonQuest(drowned,96774,{name="Ancient Gurubashi Idol",faction="Horde",minLevel=30,questLevel=40,pickup=mazu,
    foreverXp=8800,source=Eternadex(96774),objectives="Bring the Ancient Gurubashi Idol to Mazu'kon in Mulgore."})
AddDungeonQuest(drowned,95786,{name="An Acquaintance in Southshore",faction="Alliance",minLevel=30,questLevel=40,
    preparationOnly=true,pickup=Location("Brother Nimetz","Stranglethorn Vale","37.8, 3.6"),turnIn=dibbs,
    foreverXp=3150,source="https://www.wowhead.com/forever/quest=95786/an-acquaintance-in-southshore",
    prerequisites={{questID=205,external=true,relationship="required",note="Complete Troll Witchery at Rebel Camp."}},
    objectives="Take the Savage Coast Report Bundle to Loremaster Dibbs in Southshore."})
AddDungeonQuest(drowned,95787,{name="Take Two With Water",faction="Alliance",minLevel=30,questLevel=40,pickup=dibbs,
    followUpOf=95786,foreverXp=8450,source="https://www.wowhead.com/forever/quest=95787/take-two-with-water",
    objectives="Make rubbings of the four Tablets of I'lalai and return to Loremaster Dibbs."})
AddDungeonQuest(drowned,95788,{name="Magics of the Drowned City",faction="Alliance",minLevel=30,questLevel=40,
    objectives="Collect five I'lalai Fetishes from trolls in the Drowned City."})
AddDungeonQuest(drowned,97130,{name="Ancient Gurubashi Secrets",faction="Alliance",minLevel=34,questLevel=40,
    objectives="Recover the Ancient Gurubashi Idol in the Drowned City."})
AddDungeonQuest(drowned,95789,{name="Shady Saltseers",minLevel=34,questLevel=40,
    objectives="Collect ten Voodoo-Infused Artifacts from Saltseer pirates in the Drowned City."})
AddDungeonQuest(drowned,95791,{name="The Saltseer Captain",minLevel=34,questLevel=40,
    objectives="Defeat Captain Dreadrise and three Saltseer Coroners in the Drowned City."})
local kroldokGuide="https://conquestcapped.com/guides/wow-forever/wow-forever-kroldok-stronghold-guide/"
local function AddKroldokQuest(id,quest)
    quest.xpGuide,quest.xpSource=true,kroldokGuide
    AddDungeonQuest(kroldok,id,quest)
    quest.verification.xpReview="2026-11-08: exact quest ID matched to the launch guide. Published reward is provisional."
end
local krom=Location("Krom'rosh","Riverglades","59.4, 45.5")
local demar=Location("Commander Demar Brant","Riverglades","66.5, 80.9")
local ashe=Location("Ashe Amberhall","Riverglades","66.6, 81.0")
local ranath=Location("Ranath Nightstride","Alterac Mountains","17.8, 66.0")
ranath.subzone="Dalaran inn"
AddKroldokQuest(94968,{name="Eye of Mugg",faction="Horde",minLevel=40,questLevel=45,pickup=krom,
    foreverXp=11500,objectives="Bring Overlord Mugg's eye to Krom'rosh at Rog'mar."})
AddKroldokQuest(94982,{name="Eye of Mugg",faction="Alliance",minLevel=40,questLevel=45,pickup=demar,
    foreverXp=11500,objectives="Bring Overlord Mugg's eye to Commander Demar Brant at Farholde Keep."})
AddKroldokQuest(94972,{name="Tome of Twilight",faction="Horde",minLevel=39,questLevel=44,
    foreverXp=11050,objectives="Recover the Tome of Twilight from Nar'gurk. The Horde giver still needs verification."})
AddKroldokQuest(94984,{name="Tome of Twilight",faction="Alliance",minLevel=39,questLevel=44,pickup=ashe,
    foreverXp=11050,objectives="Recover the Tome of Twilight from Nar'gurk and return to Ashe Amberhall at Farholde Keep.",
    prerequisites={{questID=94907,external=true,relationship="required",
        note="At Ashe Amberhall, do Scraps of Knowledge and Curious Trinkets, then finish A Small Favor."}}})
AddKroldokQuest(94975,{name="A Token of Vengeance",faction="Horde",minLevel=38,questLevel=42,
    foreverXp=8200,objectives="Collect 15 Cultist Ears. Da'grosh and Bring Me His Head are reported leads; the giver and gate need confirmation."})
AddKroldokQuest(94983,{name="Twilight Mementos",faction="Alliance",minLevel=38,questLevel=42,
    foreverXp=10200,objectives="Collect eight Twilight Bangles. Players report checking Sergeant Riftan after Bring Me His Head; confirm the giver.",
    prerequisites={{questID=94890,external=true,relationship="required",
        note="Complete Bring Me His Head from Sergeant Riftan in Riverglades (30.5, 48.9)."}}})
AddKroldokQuest(96771,{name="Vengeance of the Highborne",faction="Alliance",minLevel=37,questLevel=45,pickup=ranath,
    foreverXp=11500,objectives="Defeat Zalfan Moonshadow in Krol'dok Stronghold and return to Ranath Nightstride."})

AddDungeonQuest(alcaz,96772,{name="The Dragon's Journal",faction="Alliance",minLevel=46,questLevel=53,
    pickup=Location("Archmage Lan'dalock","Alterac Mountains","15.9, 73.1"),foreverXp=14400,
    source="https://www.wowhead.com/forever/quest=96772/the-dragons-journal",
    objectives="Recover Zarla's Journal from Blazeroar and return to Archmage Lan'dalock in Dalaran."})
local sully=Location("Sully McCleary","Dustwallow Marsh","63.4, 42.4")
sully.subzone="Theramore Graveyard"
AddDungeonQuest(alcaz,95262,{name="The Secret Prison",faction="Alliance",minLevel=48,questLevel=53,pickup=sully,
    foreverXp=14400,source="https://www.wowhead.com/forever/quest=95262/the-secret-prison",
    objectives="Explore Alcaz Prison and learn what became of Varian Wrynn.",
    prerequisites={{questID=95198,relationship="required",external=true,
        note="Complete The Return of the King? in the chain that starts with Our Man in Theramore."}}})
AddDungeonQuest(alcaz,96381,{name="A Bit of Wet Work",faction="Alliance",minLevel=48,questLevel=53,pickup=sully,
    foreverXp=11550,source="https://www.wowhead.com/forever/quest=96381/a-bit-of-wet-work",
    prerequisites={{questID=95198,relationship="required",external=true,
        note="Follow the Our Man in Theramore chain through The Return of the King?."}},
    objectives="Defeat 15 Strashasz Soldiers and eight Enchantresses, then bring Tidemistress Ca'zass's head to Sully."})
local ulka=Location("Sergeant Ulka","Dustwallow Marsh","70.4, 19.0")
local ulkaGate={questID=95285,external=true,relationship="required",
    note="Complete Right Place, Wrong Time in the Missing Kor'kron chain."}
AddDungeonQuest(alcaz,96332,{name="A Little Payback",faction="Horde",minLevel=48,questLevel=53,pickup=ulka,
    foreverXp=9700,source="https://www.wowhead.com/forever/quest=96332/a-little-payback",prerequisites={ulkaGate},
    objectives="Defeat 15 Strashasz Soldiers and eight Enchantresses, then bring Tidemistress Ca'zass's head to Ulka."})
AddDungeonQuest(alcaz,96334,{name="Blood Red Bandanas",faction="Horde",minLevel=48,questLevel=53,pickup=ulka,
    turnIn=Location("Eitrigg","Orgrimmar","34.6, 38.6"),
    foreverXp=9700,source="https://www.wowhead.com/forever/quest=96334/blood-red-bandanas",prerequisites={ulkaGate},
    objectives="Collect eight Blood Red Bandanas from the human guards in Alcaz Prison and deliver them to Eitrigg."})
AddDungeonQuest(alcaz,95309,{name="No Orc Left Behind",faction="Horde",minLevel=48,questLevel=53,
    pickup=ulka,
    turnIn=Location("Commander Folkar","Alcaz Prison"),foreverXp=12100,
    source="https://www.wowhead.com/forever/quest=95309/no-orc-left-behind",
    prerequisites={{questID=95285,external=true,relationship="required",
        note="Complete Right Place, Wrong Time in the Missing Kor'kron chain."}},
    objectives="Find Commander Folkar inside Alcaz Prison."})
local folkar=DQT.quests[95309].turnIn
AddDungeonQuest(alcaz,95454,{name="The Honor of the Kor'kron",faction="Horde",minLevel=48,questLevel=53,
    pickup=folkar,followUpOf=95309,foreverXp=12100,
    source="https://www.wowhead.com/forever/quest=95454/the-honor-of-the-korkron",
    objectives="Look for Varian Wrynn in Alcaz Prison and read the note on the ground."})
AddDungeonQuest(alcaz,96369,{name="Bad News for Folkar",faction="Horde",minLevel=48,questLevel=53,
    pickup=Location("Perfumed Note","Alcaz Prison"),turnIn=folkar,followUpOf=95454,
    foreverXp=2400,source="https://www.wowhead.com/forever/quest=96369/bad-news-for-folkar",
    objectives="Read the Perfumed Note and report to Commander Folkar."})
DQT.quests[96369].pickupType="object"
AddDungeonQuest(alcaz,95483,{name="Thrall Needs to Know",faction="Horde",minLevel=48,questLevel=53,
    pickup=folkar,turnIn=Location("Thrall","Orgrimmar"),followUpOf=96369,foreverXp=2400,
    source="https://www.wowhead.com/forever/quest=95483/thrall-needs-to-know",
    objectives="Deliver Commander Folkar's report to Thrall in Orgrimmar."})
AddDungeonQuest(kroldok,94969,{name="Krol'dok No More!",faction="Alliance",minLevel=40,questLevel=42,
    pickup=Location("Marcus Tilwell","Krol'dok Stronghold"),foreverXp=3450,
    source="https://www.wowhead.com/forever/quest=94969/kroldok-no-more",
    objectives="Escort Marcus Tilwell to safety."})
local mason=Location("Mason Connery","Alcaz Prison")
AddDungeonQuest(alcaz,96335,{name="The Man in the Iron Chains",minLevel=48,questLevel=53,
    pickup=mason,foreverXp=2850,source="https://www.wowhead.com/forever/quest=96335/the-man-in-the-iron-chains",
    objectives="Leave the Questioner alive until you find Mason Connery, then recover the shackle key from the Questioner."})
AddDungeonQuest(alcaz,96337,{name="More Valuable Than Gold",minLevel=48,questLevel=53,
    pickup=mason,turnIn=Location("Treasure location","Westfall","43.4, 67.8"),followUpOf=96335,foreverXp=11550,
    source="https://www.wowhead.com/forever/quest=96337/more-valuable-than-gold",
    objectives="Follow Mason Connery's note to the marked location in Westfall."})

local kroldokMould=Location("Krol'dok Moulding from Tunk","Krol'dok Stronghold")
for _,branch in ipairs({
    {faction="Horde",mould=94973,key=94974,smith=Location("Kreza Darkthorn","Riverglades","59.8, 46.0")},
    {faction="Alliance",mould=94980,key=94981,smith=Location("Alphonse Dumas","Riverglades","64.4, 82.0")},
}) do
    AddDungeonQuest(kroldok,branch.mould,{name="Krol'dok Moulding",faction=branch.faction,minLevel=38,questLevel=41,
        pickup=kroldokMould,turnIn=branch.smith,foreverXp=3300,
        source="https://www.wowhead.com/forever/quest="..branch.mould.."/kroldok-moulding",
        objectives="Loot Tunk's key mould and bring it to "..branch.smith.name.."."})
    DQT.quests[branch.mould].pickupType="drop"
    AddDungeonQuest(kroldok,branch.key,{name="Key Ingredients",faction=branch.faction,minLevel=38,questLevel=41,
        pickup=branch.smith,followUpOf=branch.mould,foreverXp=3300,
        source="https://www.wowhead.com/forever/quest="..branch.key.."/key-ingredients",
        objectives="Bring four Thick Leather and twelve Iron Bars to "..branch.smith.name.."."})
end

local drownedGuide="https://www.wowhead.com/forever/guide/the-drowned-city-dungeon-overview-location-rewards"
AddDungeonQuest(drowned,95798,{name="The Web of Magic",faction="Alliance",minLevel=30,questLevel=40,
    pickup=dibbs,turnIn=Location("Abra Cadabra","Alterac Mountains"),followUpOf=95788,
    source="https://www.wowhead.com/forever/quest=95798/the-web-of-magic",
    objectives="Deliver the I'lalai Fetish to Abra Cadabra in outdoor Dalaran."})
AddDungeonQuest(drowned,95799,{name="Findings for the Explorer's League",faction="Alliance",minLevel=30,questLevel=40,
    pickup=dibbs,turnIn=Location("Historian Karnik","Ironforge"),followUpOf=95787,
    source="https://www.wowhead.com/forever/quest=95799/findings-for-the-explorers-league",
    objectives="Deliver Loremaster Dibbs's translations to Historian Karnik in Ironforge."})
local krazek=Location("Krazek","Stranglethorn Vale","27.0, 77.2")
krazek.subzone="Booty Bay"
for id,location in pairs({[95788]=dibbs,[95789]=krazek,[95791]=krazek,
    [97130]=Location("Archmage Timear","Alterac Mountains","15.6, 73.6")}) do
    local quest=DQT.quests[id]
    quest.pickup,quest.turnIn=location,location
    quest.confidence="verifiedSource"
    quest.sourceURLs[#quest.sourceURLs+1]=drownedGuide
end
for _,id in ipairs({95787,95788}) do
    local quest=DQT.quests[id]
    quest.prerequisites[#quest.prerequisites+1]={questID=205,relationship="required",external=true,
        note="Complete Troll Witchery in Stranglethorn Vale to unlock the Southshore dungeon quests."}
    quest.sourceURLs[#quest.sourceURLs+1]=drownedGuide
end
local mementos=DQT.quests[94983]
mementos.pickup=Location("Sergeant Riftan","Riverglades","30.6, 49.0")
mementos.turnIn=mementos.pickup
mementos.objectives="Collect eight Twilight Bangles and return to Sergeant Riftan."
mementos.confidence="verifiedSource"
local aggro=Location("Commander Aggro'gosh","Riverglades","33.4, 38.0")
for _,id in ipairs({94972,94975}) do
    local quest=DQT.quests[id]
    quest.pickup,quest.turnIn=aggro,aggro
    quest.confidence="verifiedSource"
end
for id,gate in pairs({
    [94968]={95278,"It Is Time, Brother..."},
    [94972]={95278,"It Is Time, Brother..."},
    [94975]={94768,"Bring Me His Head"},
}) do
    local quest=DQT.quests[id]
    quest.prerequisites={{questID=gate[1],relationship="required",external=true,
        note="Follow Krom'rosh's Riverglades chain through "..gate[2].."."}}
    quest.sourceURLs[#quest.sourceURLs+1]="https://www.wowhead.com/forever/quest=94968/eye-of-mugg"
end
DQT.quests[94972].objectives="Recover the Tome of Twilight from Nar'gurk and return to Commander Aggro'gosh."
DQT.quests[94975].objectives="Collect 15 Cultist Ears and return to Commander Aggro'gosh."
for _,id in ipairs({94972,94975,94983}) do
    local quest=DQT.quests[id]
    quest.sourceURLs[#quest.sourceURLs+1]="https://www.wowhead.com/forever/guide/kroldok-stronghold-dungeon-overview-location-rewards"
end

for key,area in pairs({[drowned]="Off the coast of Stranglethorn Vale, west of Grom'gol",
    [kroldok]="Riverglades, above Sunnyglade",[alcaz]="Alcaz Island, Dustwallow Marsh"}) do
    local dungeonData=DQT.dungeons[key]
    dungeonData.placeholder=nil
    dungeonData.location=area
    dungeonData.source=blizzardDungeons
    dungeonData.notes="Forever quest data. Pickup locations and XP are listed where sourced."
end
for _,key in ipairs({drowned,kroldok,alcaz,"zul-farrak","maraudon","blackrock-depths","blackmaw-hold","shapers-terrace"}) do
    DQT.dungeons[key].provisionalData=false
end
local reviewedDungeonSources={
    ["scarlet-monastery-cathedral"]="https://www.wowhead.com/forever/guide/scarlet-monastery-cathedral-dungeon-overview-location-rewards",
    ["sunken-temple"]="https://legacyofwarcraft.com/db/forever/quests/sunken-temple.html",
    ["dire-maul-east"]="https://www.wowhead.com/forever/guide/dire-maul-warpwood-quarter-east-dungeon-overview-location-rewards",
    ["dire-maul-north"]="https://www.wowhead.com/forever/guide/dire-maul-gordoks-commons-north-dungeon-overview-location-rewards",
    ["dire-maul-west"]="https://www.wowhead.com/forever/guide/dire-maul-capital-gardens-west-dungeon-overview-location-rewards",
    ["lower-blackrock-spire"]="https://www.wowhead.com/forever/guide/lower-blackrock-spire-dungeon-overview-location-rewards",
    ["upper-blackrock-spire"]="https://www.wowhead.com/forever/guide/upper-blackrock-spire-dungeon-overview-location-rewards",
    ["scholomance"]="https://www.wowhead.com/forever/guide/scholomance-dungeon-overview-location-rewards",
    ["stratholme-main-gate"]="https://www.wowhead.com/forever/guide/stratholme-live-side-dungeon-overview-location-rewards",
    ["stratholme-service-gate"]="https://www.wowhead.com/forever/guide/stratholme-undead-side-dungeon-overview-location-rewards",
}
for key,url in pairs(reviewedDungeonSources) do
    local dungeonData=DQT.dungeons[key]
    dungeonData.provisionalData=false
    dungeonData.source=url
    dungeonData.notes=dungeonData.notes:gsub("Classic%-source quest data; Forever changes still need review%. ","")
end
local reviewedContacts={
    [5526]=Location("Rabine Saturna","Moonglade","51, 45"),
    [7441]=Location("Azj'Tordin","Feralas","76, 37"),
    [7488]=Location("Latronicus Moonspear","Feralas","30, 46"),
    [7489]=Location("Talo Thornhoof","Feralas","76, 43"),
    [5382]=Location("Eva Sarkhoff","Western Plaguelands","70, 73"),
    [5515]=Location("Eva Sarkhoff","Western Plaguelands","70, 73"),
    [5384]=Location("Eva Sarkhoff","Western Plaguelands","70, 73"),
    [5529]=Location("Betina Bigglezink","Eastern Plaguelands","81, 59"),
    [5212]=Location("Betina Bigglezink","Eastern Plaguelands","81, 59"),
}
for id,location in pairs(reviewedContacts) do
    local quest=DQT.quests[id]
    quest.pickup,quest.turnIn=location,location
    quest.sourceURLs[#quest.sourceURLs+1]=reviewedDungeonSources[quest.dungeon]
end
DQT.quests[5212].objectives="Collect 20 Plagued Flesh Samples in Stratholme and return to Betina Bigglezink."
DQT.quests[5212].prerequisites={}
DQT.quests[5529].objectives="Slay 20 Plagued Hatchlings inside Scholomance and return to Betina Bigglezink."
DQT.quests[5384].prerequisites={{questID=5515,relationship="required",note="Complete Krastinov's Bag of Horrors and bring the Blood of Innocents to Scholomance."}}
DQT.dungeons[kroldok].entrance=Location("Cave west of the fortress gates","Riverglades","37.5, 37.5")
DQT.dungeons[kroldok].entrance.source="https://wowforever.be/guides/dungeons/kroldok-stronghold/quests/"
DQT.dungeons[kroldok].notes="Includes dungeon quests and key chains for both factions. Some rewards and unlocks still need live verification."
DQT.dungeons[alcaz].notes="Includes Alliance and Horde quests and the hidden Mason Connery chain. Additional follow-ups are under review."

-- Live level-31 quest-log reward readings supplied on November 8.
DQT.quests[1221].verification.xpReview="2026-11-08: live level-31 quest log corroborates the published 5,000 XP reward."
local function RecordReportedXP(id,xp,level,date)
    local quest=DQT.quests[id]
    quest.foreverXp,quest.xpReported=xp,true
    quest.xpEstimate,quest.xpOutdated,quest.xpGuide,quest.xpPublished=nil,nil,nil,nil
    quest.xpSource="Live Forever quest log, level "..level..", "..date.." (player report)"
    quest.verification.xpReview="Exact quest ID and displayed reward reported from the live quest log at character level "..level.."."
    quest.verification.xp=quest.verification.xpReview
end
for id,xp in pairs({[1102]=8500,[1109]=6950,[6522]=5900}) do RecordReportedXP(id,xp,31,"2026-11-08") end
RecordReportedXP(2841,8200,35,"2026-11-09")
RecordReportedXP(2949,6400,35,"2026-11-09")
RecordReportedXP(2936,9700,"not recorded","2026-11-17")
local foreverDatabaseRewards={
    [1654]=875,
    [378]=5750,
    [2945]=6400,
    [2947]=4850,
    [1142]=7250,
    [1951]=6300,
    [1048]=12250,
    [1053]=15300,
    [3341]=9050,
    [3636]=10200,
    [6626]=8200,
    [3523]=675,
    [3525]=10100,
    [2342]=7000,
    [1360]=6300,
    [2240]=6850,
    [2202]=6750,
    [17]=6050,
    [704]=5000,
    [1139]=10250,
    [2198]=5800,
    [2200]=4450,
    [2204]=1650,
    [2283]=4800,
    [2284]=4800,
    [2338]=350,
    [2339]=7300,
    [709]=6150,
    [2278]=8200,
    [1956]=7800,
    [722]=5500,
    [1446]=12750,
    [1475]=13850,
    [2768]=12600,
    [2770]=14200,
    [2846]=12100,
    [2865]=7800,
    [2991]=10500,
    [3042]=7800,
    [3373]=5450,
    [3380]=6550,
    [3446]=9550,
    [3447]=11900,
    [3527]=10500,
    [3528]=15400,
    [3801]=500,
    [3802]=9450,
    [3907]=13500,
    [3981]=9450,
    [3982]=10100,
    [4001]=12600,
    [4002]=550,
    [4003]=16100,
    [4004]=19900,
    [4024]=11450,
    [4063]=12400,
    [4081]=9950,
    [4082]=10650,
    [4123]=10450,
    [4126]=14800,
    [4128]=550,
    [4132]=15500,
    [4133]=550,
    [4134]=11300,
    [4136]=5550,
    [4143]=9950,
    [4146]=9200,
    [4201]=10900,
    [4241]=11450,
    [4242]=9800,
    [4263]=10450,
    [4264]=11150,
    [4286]=10450,
    [4322]=13950,
    [4341]=11500,
    [4342]=2900,
    [4362]=16900,
    [4363]=20250,
    [4701]=12500,
    [4742]=16200,
    [4764]=4400,
    [4766]=650,
    [4769]=650,
    [4771]=23650,
    [4788]=15100,
    [4903]=15350,
    [4907]=650,
    [4974]=26600,
    [4982]=11850,
    [5001]=12500,
    [5047]=17650,
    [5081]=16200,
    [5089]=12850,
    [5102]=26600,
    [5103]=13200,
    [5125]=21900,
    [5127]=16600,
    [5160]=17650,
    [5161]=650,
    [5164]=650,
    [5212]=14500,
    [5243]=14500,
    [5251]=17450,
    [5466]=23650,
    [5515]=15700,
    [5518]=17650,
    [5525]=17650,
    [5526]=22200,
    [5529]=14750,
    [5848]=13850,
    [6163]=9900,
    [6402]=650,
    [6502]=22200,
    [6602]=26600,
    [7028]=10250,
    [7029]=10250,
    [7041]=10250,
    [7044]=6650,
    [7046]=11100,
    [7064]=11900,
    [7065]=11900,
    [7066]=11900,
    [7067]=10650,
    [7068]=6750,
    [7070]=6750,
    [7201]=10100,
    [7441]=20750,
    [7461]=23650,
    [7462]=1550,
    [7463]=13200,
    [7481]=19700,
    [7482]=19700,
    [7483]=3300,
    [7484]=3300,
    [7485]=3300,
    [7488]=20200,
    [7498]=15700,
    [7499]=15700,
    [7500]=15700,
    [7501]=15700,
    [7502]=15700,
    [7503]=15700,
    [7504]=15700,
    [7505]=15700,
    [7506]=15700,
    [7631]=13200,
    [7647]=19900,
    [7650]=13200,
    [7668]=19900,
    [7703]=22200,
    [7877]=1550,
    [8232]=12400,
    [8236]=12400,
    [8253]=12400,
    [8257]=12400,
    [8413]=12400,
    [8418]=12400,
    [8422]=12400,
    [8425]=12400,
    [8945]=16600,
    [8948]=13200,
    [8949]=13200,
    [8950]=13200,
    [8951]=19900,
    [8952]=19900,
    [8953]=19900,
    [8954]=19900,
    [8955]=19900,
    [8956]=19900,
    [8957]=19900,
    [8958]=19900,
    [8959]=19900,
    [8966]=16600,
    [8967]=16600,
    [8968]=16600,
    [8969]=16600,
    [8989]=16600,
    [8990]=16600,
    [8991]=16600,
    [8992]=16600,
    [8996]=650,
    [9015]=13200,
    [9053]=12400,
}
for id,xp in pairs(foreverDatabaseRewards) do
    local quest=DQT.quests[id]
    local url="https://db.icy-veins.com/wow-forever/quests/"..id
    quest.foreverXp,quest.xpPublished,quest.xpSource=xp,true,url
    quest.xpGuide,quest.xpEstimate,quest.xpOutdated,quest.xpReported=nil,nil,nil,nil
    quest.sourceURLs[#quest.sourceURLs+1]=url
    quest.verification.xpReview="2026-11-17: explicit Experience reward on the individual Icy Veins Forever quest record. Actual payout depends on character level and bonuses."
end
DQT.quests[1102].sourceURLs[#DQT.quests[1102].sourceURLs+1]="https://hearthproof.com/dungeons/razorfen-kraul/"
DQT.quests[6522].verification.xpReview=DQT.quests[6522].verification.xpReview.." A published guide lists 2,800 XP; the newer exact-ID reading takes precedence provisionally."

-- Exact-ID level discrepancies corroborated by Forever quest records.
local reviewedLevels={
    [378]={min=22,source="https://bindonforever.com/quest/378"},
    [544]={min=30,source="https://www.wowhead.com/forever/quest=544/prison-break-in"},
    [545]={min=30,level=35,source="https://questing.wiki/wow-forever/quests/series/544/"},
    [704]={min=30,source="https://questing.wiki/wow-forever/dungeons/uldaman/quests/"},
    [1139]={min=35,source="https://questing.wiki/wow-forever/dungeons/uldaman/quests/"},
    [4136]={min=48,source="https://questing.wiki/wow-forever/quests/4136/"},
    [6628]={level=30,source="https://ahledger.com/wow-forever/quests/6628-test-of-lore"},
}
for id,review in pairs(reviewedLevels) do
    local quest=DQT.quests[id]
    quest.minLevel,quest.questLevel=review.min or quest.minLevel,review.level or quest.questLevel
    quest.sourceURLs[#quest.sourceURLs+1]=review.source
    quest.verification.level="2026-11-08: level fields reviewed against exact-ID Forever quest records."
end

-- Exact-ID Forever quest-window observations. Preserve local player reports
-- and omit conflicting values that appear to include character modifiers.
local observedRewards={
    [95798]={2420,"the-web-of-magic"},
    [95799]={2420,"findings-for-the-explorers-league"},
    [95697]={6950,"changing-tastes"},
    [95664]={1400,"elder-knowledge"},
    [95772]={6150,"songblade-search"},
    [95647]={4900,"lost-in-the-thicket-things"},
    [95810]={1250,"lost-relic-carry"},
    [6922]={7250,"baron-aquanis"},
    [1101]={7950,"the-crone-of-the-kraul"},
    [1701]={2300,"fire-hardened-mail"},
    [95795]={6150,"fallen-in-the-fen"},
    [98823]={6950,"earthen-echo"},
    [95036]={1750,"a-moon-kissed-blade"},
    [95042]={2000,"seeking-the-kor-gem"},
    [96984]={9400,"heart-of-disruption"},
    [96986]={9400,"the-grave-knight"},
    [96988]={9400,"source-of-power"},
    [96987]={9400,"opportunistic-education"},
    [92456]={9400,"a-green-sample"},
    [97289]={1650,"unending-torment"},
    [97290]={1650,"unending-torment"},
    [97291]={1650,"unending-torment"},
    [97292]={1650,"unending-torment"},
    [389]={440,"bazil-thredd"},
    [393]={600,"shadow-of-the-past"},
    [1049]={8450,"compendium-of-the-fallen"},
    [1050]={8900,"mythology-of-the-titans"},
    [1113]={7850,"hearts-of-zeal"},
    [1806]={3850,"the-test-of-righteousness"},
    [2924]={5500,"essential-artificials"},
    [2929]={4950,"the-grand-betrayal"},
    [2930]={6550,"data-rescue"},
    [5730]={1450,"hidden-enemies"},
    [6521]={7350,"an-unholy-alliance"},
    [92422]={4600,"the-wrath-of-rathmael"},
    [95789]={10450,"shady-saltseers"},
    [95791]={10450,"the-saltseer-captain"},
    [98423]={2550,"the-treaty-of-understanding"},
}
for id,reward in pairs(observedRewards) do
    local quest=DQT.quests[id]
    local url="https://ahledger.com/wow-forever/quests/"..id.."-"..reward[2]
    quest.foreverXp,quest.xpPublished,quest.xpSource=reward[1],true,url
    quest.xpGuide,quest.xpEstimate,quest.xpOutdated=nil,nil,nil
    quest.sourceURLs[#quest.sourceURLs+1]=url
    quest.verification.xpReview="AHledger Forever quest-window observation for this exact quest ID. Actual payout can vary by character level and modifiers."
    quest.verification.xp=quest.verification.xpReview
end

for id,reward in pairs({
    [95788]={8450,"magics-of-the-drowned-city"},
    [97130]={10450,"ancient-gurubashi-secrets"},
    [94975]={8200,"a-token-of-vengeance"},
    [94968]={11500,"eye-of-mugg"},
    [94983]={10200,"twilight-mementos"},
}) do
    local quest=DQT.quests[id]
    local url="https://www.wowhead.com/forever/quest="..id.."/"..reward[2]
    quest.foreverXp,quest.xpPublished,quest.xpSource=reward[1],true,url
    quest.xpGuide=nil
    quest.sourceURLs[#quest.sourceURLs+1]=url
    quest.verification.xpReview="Explicit XP in the Gains section of the individual Wowhead Forever quest page."
end

-- November 20 review against individual Forever records.
for id,xp in pairs({
    [373]=2050,
    [2929]=6200,
    [2398]=550,
    [2318]=6750,
    [98824]=6150,
    [92753]=2700,
    [92819]=140,
    [544]=3300,
    [545]=2050,
    [92434]=270,
    [97287]=270,
    [4724]=11850,
    [4729]=12500,
    [4768]=22200,
    [4862]=12500,
    [4866]=18900,
    [4867]=18900,
    [4981]=11850,
    [4983]=11850,
    [5214]=17450,
    [5262]=17450,
    [5263]=18250,
    [5282]=17450,
    [5463]=14500,
    [7429]=650,
    [7489]=20200,
    [7507]=19900,
    [7643]=9900,
    [7649]=13200,
    [7651]=13200,
    [9016]=19900,
    [9019]=19900,
    [9020]=19900,
    [9022]=19900,
    [392]=600,
    [350]=250,
    [2745]=250,
    [2746]=625,
    [434]=1900,
    [394]=250,
    [395]=625,
    [396]=3750,
    [6628]=250,
    [1394]=4200,
    [1952]=3150,
    [1848]=3050,
    [1839]=1200,
    [1842]=1200,
    [1843]=1850,
    [1840]=1200,
    [1844]=1200,
    [1845]=1850,
    [1841]=1200,
    [1846]=1200,
    [1847]=1850,
    [1700]=575,
    [1705]=2300,
    [1706]=3050,
    [1704]=575,
    [1708]=1750,
    [1709]=3050,
    [1703]=1150,
    [1710]=1850,
    [1711]=3050,
    [1782]=3400,
    [356]=650,
    [99156]=900,
    [447]=900,
    [450]=1350,
    [451]=2050,
    [95798]=2350,
    [95799]=2350,
}) do
    local quest=DQT.quests[id]
    local url="https://db.icy-veins.com/wow-forever/quests/"..id
    quest.foreverXp,quest.xpPublished,quest.xpSource=xp,true,url
    quest.xpReported,quest.xpGuide,quest.xpEstimate,quest.xpOutdated=nil,nil,nil,nil
    quest.sourceURLs[#quest.sourceURLs+1]=url
    quest.verification.xpReview="2026-11-20: explicit reward on the individual Forever record. Character level and bonuses can affect actual payout."
end
for id,parent in pairs({[94997]=94983,[94998]=94997,[95263]=95262}) do
    local quest=DQT.quests[id]
    quest.followUpOf=parent
    quest.prerequisites={{questID=parent,relationship="required",note="Complete "..DQT.quests[parent].name.." first."}}
end
for id,xp in pairs({[2201]=6300,[1445]=10600,[4282]=11150,[9017]=19900,[9021]=19900}) do
    local quest=DQT.quests[id]
    local url="https://db.icy-veins.com/wow-forever/quests/"..id
    quest.foreverXp,quest.xpPublished,quest.xpSource=xp,true,url
    quest.xpReported,quest.xpGuide,quest.xpEstimate,quest.xpOutdated=nil,nil,nil,nil
    quest.sourceURLs[#quest.sourceURLs+1]=url
    quest.verification.xpReview="2026-11-21: explicit reward in the individual Forever quest record."
end
DQT.quests[98325].preparationOnly=true
DQT.quests[2861].preparationOnly=true
