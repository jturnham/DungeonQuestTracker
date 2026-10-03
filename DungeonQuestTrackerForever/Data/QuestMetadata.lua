local _, DQT = ...
local guide = "https://www.wowhead.com/forever/guide/dungeons/every-dungeon-quest-location"

-- Provenance is not verification: preserve beta uncertainties explicitly.
for id, quest in pairs(DQT.quests) do
    if quest.faction == "Both" or quest.faction == "Neutral" then quest.faction = nil end
    if quest.classes then
        local normalized, seen = {}, {}
        for _, class in ipairs(quest.classes) do
            local tag = class:upper()
            if not seen[tag] then normalized[#normalized+1], seen[tag] = tag, true end
        end
        quest.classes = normalized
    end
    quest.confidence = quest.verifiedForever and "verifiedInGame" or "needsReview"
    quest.sourceNotes = quest.source
    quest.sourceURLs = { "https://www.wowhead.com/forever/quest=" .. id, guide }
    if type(quest.source) == "string" and quest.source:match("^https://") then
        quest.sourceURLs[#quest.sourceURLs+1] = quest.source
    end
    if quest.xpSource then quest.sourceURLs[#quest.sourceURLs+1] = quest.xpSource end
    quest.verification = {
        xp = "Pending in-game confirmation; record character level and displayed reward.",
        pickup = "Pending in-game NPC/object and coordinate confirmation.",
        turnIn = "Pending in-game NPC and coordinate confirmation.",
        prerequisites = "Pending in-game chain confirmation; source notes may be incomplete.",
    }
    if quest.followUpOf then
        quest.verification.sourceReview = "2026-10-02: dungeon continuation linked by quest ID; beta-client confirmation remains pending."
        if quest.questLevelUnverified then
            quest.verification.level = "Quest and minimum levels are provisional values from the preceding chain step; exact continuation levels need confirmation."
        end
    end
    quest.shareability = { assumption="clientDetermined", note="The client's pushable flag is authoritative; recipient eligibility can still block acceptance." }
    local pickup = ((quest.pickup and quest.pickup.subzone) or ""):lower()
    quest.pickupType = quest.pickupType or (pickup:find("drop", 1, true) and "drop" or "npc")
    for _, prerequisite in ipairs(quest.prerequisites or {}) do
        if prerequisite.questID and not DQT.quests[prerequisite.questID] then prerequisite.external = true end
    end
end

for _, id in ipairs({95204, 95189, 92415, 98423, 2951, 2947, 2949, 1100}) do DQT.quests[id].pickupType = "object" end
for _, id in ipairs({373, 6981, 97288, 95195, 6564, 6922, 6522, 2945}) do DQT.quests[id].pickupType = "drop" end
for _, id in ipairs({1489, 1490, 1198, 2842}) do DQT.quests[id].breadcrumbOnly = true end

-- Replace the old UI samples with sourced quest records, retaining provisional base XP.
for _, id in ipairs({214, 168}) do
    local quest = DQT.quests[id]
    quest.classicXp, quest.foreverXp = quest.foreverXp, nil
    quest.source = "https://www.wowhead.com/classic/quest=" .. id
    quest.sourceNotes = "Classic quest record and Forever dungeon guide; beta XP remains unverified."
    quest.sourceURLs[#quest.sourceURLs+1] = quest.source
end
DQT.quests[214].objectives = "Collect 10 Red Silk Bandanas from Defias enemies in the Deadmines."
DQT.quests[214].prerequisites = {
    { relationship="required", questID=155, external=true, note="Complete the Defias Brotherhood lead-in through the Defias Traitor escort before Scout Riell offers this quest; confirm the chain in Forever." },
}
DQT.quests[214].pickup.subzone = "Sentinel Hill"
DQT.quests[214].turnIn = { name="Scout Riell", zone="Westfall", subzone="Sentinel Hill", coordinates="56.3, 47.5" }
DQT.quests[168].objectives = "Collect 4 Miners' Union Cards from undead miners in the Deadmines tunnels before the instance portal."
DQT.quests[168].pickup.subzone = "Dwarven District"
DQT.quests[168].turnIn = { name="Wilder Thistlenettle", zone="Stormwind City", subzone="Dwarven District", coordinates="65.2, 21.2" }

-- The Forever guide confirms this prerequisite; the precursor remains external.
DQT.quests[1491].prerequisites = {
    { questID=865, external=true, relationship="required", note="Complete Raptor Horns from Mebok Mizzyrix in Ratchet before Smart Drinks." },
}
DQT.quests[166].prerequisites = {
    { questID=155, external=true, relationship="required", note="Complete the Defias Brotherhood chain through the Defias Traitor escort before the VanCleef dungeon step." },
}
DQT.quests[914].prerequisites[1].relationship = "required"
DQT.quests[1490].prerequisites[1].relationship = "required"

for _, id in ipairs({214, 168, 166, 1491, 914}) do
    DQT.quests[id].verification.sourceReview = "2026-10-01: objectives or chain notes checked against linked quest records/Forever dungeon guide; still needs beta-client confirmation."
end
local conflicts = {
    [5722] = "Forever guide describes an in-dungeon satchel start; current record describes Rahauro. Confirm which chain step the beta client uses.",
    [92401] = "Forever guide lists Tabitha in Undercity; current record lists the Sepulcher. Confirm beta pickup location.",
    [96403] = "Forever guide lists minimum level 14; current record lists 10. Confirm beta pickup level.",
    [96394] = "Forever guide lists minimum level 15 and conflicting coordinates; confirm pickup level and location.",
    [96393] = "Forever guide lists minimum level 15; current record lists 9. Confirm beta pickup level.",
    [98423] = "Forever guide lists minimum level 16; current record lists 9. Confirm beta pickup level.",
    [96395] = "Forever guide lists minimum level 14 for An Ancient Grudge; current record lists 10. Confirm beta pickup level.",
}
for id, note in pairs(conflicts) do
    if DQT.quests[id] then DQT.quests[id].verification.conflict = note end
end

-- October 1 changes the bonus, not the whole reward. These are estimates,
-- not client observations; source rounding and normal-XP differences can matter.
local xpPatchSource = "https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-october-1/2360696"
local xpBaselines = {
    [5723]={3202,850}, [5728]={3507,1150}, [5724]={4422,1450},
    [5761]={3507,1150}, [5725]={4422,1450},
    [1486]={4640,1600}, [1491]={3915,1350}, [959]={3915,1350},
    [1487]={5945,2050}, [6981]={7685,2650}, [914]={6380,2200}, [962]={4930,1350},
    [1013]={9135,2100}, [1098]={8700,2000}, [1014]={14355,3300},
    [391]={7520,2650}, [386]={6400,2000}, [377]={6720,2100},
    [387]={8480,2650}, [388]={8480,2650},
    [971]={10313,2750}, [1199]={9563,2550}, [6565]={9938,2650}, [6921]={10313,2750},
    [2904]={9188,2450}, [2922]={6890,2650}, [2926]={5720,2200},
    [2928]={6370,2450}, [2962]={6370,2450},
    [1221]={7875,2100}, [1144]={11438,3050},
}
local comparableXp = {
    [15]={1050, "https://www.wowhead.com/classic/quest=5713/one-shot-one-kill"},
    [16]={1150, "https://www.wowhead.com/classic/quest=5728/hidden-enemies"},
    [17]={1250, "https://www.wowhead.com/classic/quest=1138/fruit-of-the-sea"},
    [18]={1350, "https://www.wowhead.com/classic/quest=65/the-defias-brotherhood"},
    [20]={1550, "https://www.wowhead.com/forever/quest=98299/stop-the-spread"},
    [21]={1650, "https://www.wowhead.com/forever/quest=1076/devils-in-westfall"},
    [22]={1750, "https://www.wowhead.com/classic/quest=1033/elunes-tear"},
    [25]={2000, "https://www.wowhead.com/classic/quest=25/stonetalon-standstill"},
    [27]={2200, "https://www.wowhead.com/classic/quest=824/jeneu-of-the-earthen-ring"},
}
for id, quest in pairs(DQT.quests) do
    quest.verification.xpReview = "2026-10-01: reviewed after the dungeon quest bonus reduction; current client rewards still need confirmation."
    quest.sourceURLs[#quest.sourceURLs+1] = xpPatchSource
    local baseline = xpBaselines[id]
    if baseline then
        local oldXp, normalXp = baseline[1], baseline[2]
        quest.classicXp = normalXp
        quest.xpBeforeOctober1 = oldXp
        quest.foreverXp = math.floor(normalXp + (oldXp - normalXp) * 0.5 + 0.5)
        quest.xpEstimate = true
        quest.xpSource = "https://wowforever.wclbox.com/en/fuben/" .. quest.dungeon
        quest.sourceURLs[#quest.sourceURLs+1] = quest.xpSource
        quest.verification.xp = "October 1 patch estimate: normal XP + half the previous bonus. Assumes Classic XP is the normal baseline; rounded to nearest integer. Not verified in the updated client."
    elseif quest.foreverXp and quest.foreverXp > 0 and comparableXp[quest.questLevel] then
        local referenceXp, source = comparableXp[quest.questLevel][1], comparableXp[quest.questLevel][2]
        local normalXp = math.min(referenceXp, quest.foreverXp)
        quest.xpBeforeOctober1 = quest.foreverXp
        quest.xpNormalBaseline = normalXp
        quest.xpBaselineAssumed = true
        quest.xpComparableReward = referenceXp
        quest.foreverXp = math.floor(normalXp + (quest.xpBeforeOctober1 - normalXp) * 0.5 + 0.5)
        quest.xpEstimate = true
        quest.sourceURLs[#quest.sourceURLs+1] = source
        quest.verification.xpReview = "2026-10-02: estimated using a comparable same-level quest baseline, as requested by the maintainer."
        quest.verification.xp = "Comparable level-" .. quest.questLevel .. " reward: " .. referenceXp .. " XP; assumed normal baseline capped at old reward: " .. normalXp .. " XP. Added half the nonnegative previous bonus and rounded to nearest integer. Current client reward and bonus applicability remain unverified."
    elseif quest.foreverXp ~= nil then
        quest.xpOutdated = true
        quest.verification.xp = "Pre-October 1 value: current XP unknown. No sufficiently supported normal baseline to apply the bonus reduction; ranking remains provisional."
    else
        quest.verification.xp = "Classic fallback only; current Forever reward after October 1 remains unknown."
    end
end
for _, id in ipairs({1200,6561,6564}) do
    local quest = DQT.quests[id]
    quest.verification.xp = quest.verification.xp .. " Published Classic XP conflicts with the bundled baseline (or exceeds published Forever XP); the same-level comparison is an explicit assumption, not resolution of that conflict."
end
for _, id in ipairs({95697,95664,98815,95772,95646,95647,95810}) do
    local quest = DQT.quests[id]
    quest.questLevelUnverified = true
    quest.sourceURLs[#quest.sourceURLs+1] = "https://www.wowhead.com/forever/guide/excavation-site-wetlands-dungeon-overview-location-rewards"
    quest.verification.sourceReview = "2026-10-02: quest IDs, objectives and available pickup/chain notes reviewed against the dungeon guide and quest pages."
    quest.verification.xp = "Unknown: no published reward or pre-patch bonus available; no XP fabricated."
    quest.verification.conflict = "Level 24 pickup and level 28/31 quest levels are from published community records, not this client's observations. Some contacts and current beta eligibility still need confirmation."
end

-- Prefer individual post-update observations, never apply a guessed dungeon factor.
local reportedSource = "https://docs.google.com/spreadsheets/d/1-185bNiXoGX4kEoeeQ3DmJdSqN4ZavOKXgZNJTnwLlQ/edit"
local reportedXP = {
    [5723]=2150, [5722]=1800, [5725]=2950, [5728]=2350, [5761]=2350,
    [92401]=4600, [92421]=4600,
    [962]=3300, [1486]=3100, [959]=2650, [1487]=4000,
    [1013]=5600, [1098]=5350, [1014]=8850,
    [6563]=1750, [1221]=5000,
}
for id, xp in pairs(reportedXP) do
    local quest = DQT.quests[id]
    quest.xpPreviousEstimate = quest.foreverXp
    quest.foreverXp, quest.xpReported = xp, true
    quest.xpEstimate, quest.xpOutdated = nil, nil
    quest.xpSource = reportedSource
    quest.sourceURLs[#quest.sourceURLs+1] = reportedSource
    quest.verification.xpReview = "2026-10-03: replaced estimate with individual post-update player report."
    quest.verification.xp = "Player-reported beta reward, not independently verified. The source does not record character level/build for each observation; base reward and overlevel scaling remain provisional."
end
for id, quest in pairs(DQT.quests) do
    if quest.dungeon == "uldaman" or quest.dungeon == "razorfen-downs" then
        quest.verification.sourceReview = "2026-10-03: catalogued published quest identities, locations, chains and Classic fallback rewards; current Forever rewards and quest levels remain unverified."
    elseif quest.dungeon == "excavation-site-wetlands" then
        quest.questLevelUnverified = true
        quest.verification.sourceReview = "2026-10-03: added Open the Maw, Dragonmaw Rumors, Seeking Caitlin and three return follow-ups; revised provisional quest levels from community records."
        quest.sourceURLs[#quest.sourceURLs+1] = reportedSource
    end
end
