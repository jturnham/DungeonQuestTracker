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
    if quest.xpSource then quest.sourceURLs[#quest.sourceURLs+1] = quest.xpSource end
    quest.verification = {
        xp = "Pending in-game confirmation; record character level and displayed reward.",
        pickup = "Pending in-game NPC/object and coordinate confirmation.",
        turnIn = "Pending in-game NPC and coordinate confirmation.",
        prerequisites = "Pending in-game chain confirmation; source notes may be incomplete.",
    }
    quest.shareability = { assumption="clientDetermined", note="The client's pushable flag is authoritative; recipient eligibility can still block acceptance." }
    for _, prerequisite in ipairs(quest.prerequisites or {}) do
        if prerequisite.questID and not DQT.quests[prerequisite.questID] then prerequisite.external = true end
    end
end

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
