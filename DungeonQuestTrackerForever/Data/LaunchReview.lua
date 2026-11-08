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
    [1490]={xp=120,url="https://wowforevertalents.com/quests/nara-wildmane-1490/"},
    [2842]={xp=280,url="https://wowforevertalents.com/quests/chief-engineer-scooty-2842/"},
}
for id,reward in pairs(publishedRewards) do
    local quest=DQT.quests[id]
    quest.xpPreviousEstimate=quest.foreverXp
    quest.foreverXp,quest.xpPublished,quest.xpSource=reward.xp,true,reward.url
    quest.xpEstimate,quest.xpOutdated,quest.xpReported=nil,nil,nil
    quest.sourceURLs[#quest.sourceURLs+1]=reward.url
    quest.verification.xpReview="2026-11-05: individual published beta reward from dated client-cache/log references. Reviewed by exact ID; not a launch-client or unmodified-reward observation."
end
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
    quest.verification={sourceReview="2026-11-07: exact quest ID matched to Forever sources."}
    if quest.foreverXp then
        if not quest.xpGuide then quest.xpPublished=true end
        quest.xpSource=quest.xpSource or quest.source
        quest.verification.xpReview="2026-11-07: individual Forever quest reward. Actual payout can vary by character level and modifiers."
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
AddDungeonQuest(drowned,95773,{name="Enemies in the Water",faction="Horde",minLevel=30,questLevel=37,
    preparationOnly=true,foreverXp=2850,source=Eternadex(95773),
    objectives="Gather ten Brinescale Tridents from Brinescale Skirmishers in Stranglethorn Vale."})
AddDungeonQuest(drowned,95776,{name="The Only Good Brinescale...",faction="Horde",minLevel=30,questLevel=38,
    followUpOf=95773,foreverXp=9500,source=Eternadex(95776),
    objectives="Defeat Var'Taka in the Drowned City."})
AddDungeonQuest(drowned,96774,{name="Ancient Gurubashi Idol",faction="Horde",minLevel=30,questLevel=40,pickup=mazu,
    foreverXp=8800,source=Eternadex(96774),objectives="Bring the Ancient Gurubashi Idol to Mazu'kon in Mulgore."})
AddDungeonQuest(drowned,95786,{name="An Acquaintance in Southshore",faction="Alliance",minLevel=30,questLevel=40,
    preparationOnly=true,turnIn=dibbs,objectives="Take the Savage Coast Report Bundle to Loremaster Dibbs in Southshore."})
AddDungeonQuest(drowned,95787,{name="Take Two With Water",faction="Alliance",minLevel=30,questLevel=40,pickup=dibbs,
    followUpOf=95786,objectives="Make rubbings of the four Tablets of I'lalai and return to Loremaster Dibbs."})
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
    foreverXp=14400,xpGuide=true,xpSource="https://conquestcapped.com/guides/wow-forever/wow-forever-alcaz-prison-guide/",
    objectives="Recover Zarla's Journal from Blazeroar. The quest giver in Dalaran still needs confirmation."})

for key,area in pairs({[drowned]="Off the coast of Stranglethorn Vale, west of Grom'gol",
    [kroldok]="Riverglades, above Sunnyglade",[alcaz]="Alcaz Island, Dustwallow Marsh"}) do
    local dungeonData=DQT.dungeons[key]
    dungeonData.placeholder=nil
    dungeonData.location=area
    dungeonData.source=blizzardDungeons
    dungeonData.notes="Forever quest data. Pickup locations and XP are listed where sourced."
end
DQT.dungeons[kroldok].entrance=Location("Cave west of the fortress gates","Riverglades","37.5, 37.5")
DQT.dungeons[kroldok].entrance.source="https://wowforever.be/guides/dungeons/kroldok-stronghold/quests/"
DQT.dungeons[kroldok].notes="Includes both factions' dungeon quests. Some givers, key-chain details, and launch rewards still need live verification."
DQT.dungeons[alcaz].notes="Initial coverage includes The Dragon's Journal. The reported Horde prison chain still needs exact quest IDs."

-- Live level-31 quest-log reward readings supplied on November 8.
DQT.quests[1221].verification.xpReview="2026-11-08: live level-31 quest log corroborates the published 5,000 XP reward."
for id,xp in pairs({[1102]=8500,[1109]=6950,[6522]=5900}) do
    local quest=DQT.quests[id]
    quest.foreverXp,quest.xpReported=xp,true
    quest.xpEstimate,quest.xpOutdated,quest.xpGuide,quest.xpPublished=nil,nil,nil,nil
    quest.xpSource="Live Forever quest log, level 31, 2026-11-08 (player report)"
    quest.verification.xpReview="Exact quest ID and displayed reward reported from the live quest log at character level 31."
    quest.verification.xp=quest.verification.xpReview
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
