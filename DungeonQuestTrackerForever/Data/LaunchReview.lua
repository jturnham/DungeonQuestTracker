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
}
local rewardSources={}
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
