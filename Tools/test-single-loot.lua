do
    local oldLoaded, oldDB = DQT.loaded, DQT.db
    local oldInstance, oldInfo, oldZone = IsInInstance, GetInstanceInfo, GetRealZoneText
    local oldSlots, oldLink = GetNumLootItems, GetLootSlotLink
    local oldNeeds = DQT.NeedsQuestLoot
    local location, inside, questID, itemID = "The Barrens", false, 959, 5334
    DQT.loaded, DQT.db = true, {lootReminders={enabled=true}}
    IsInInstance = function() return inside, inside and "party" or "none" end
    GetInstanceInfo = function() return location end
    GetRealZoneText = function() return location end
    GetNumLootItems = function() return 1 end
    GetLootSlotLink = function() return "item:" .. itemID end
    DQT.NeedsQuestLoot = function(_, drop) return drop.questID == questID end
    local function Check(expected)
        DQT.lootReminderEvents.scripts.OnEvent(nil, "PLAYER_ENTERING_WORLD")
        DQT:HandleAvailableQuestLoot()
        local frame = DQT.lootReminderFrame
        assert(frame:IsShown() == expected, "Single-drop scope/exclusion")
        if expected then
            assert(#frame.drops == 1 and frame.drops[1].questID == questID, "Correct quest association")
            frame:Hide()
            DQT:HandleAvailableQuestLoot()
            assert(not frame:IsShown(), "Repeated loot does not spam")
        end
    end
    for _, data in ipairs({
        {959,5334,"The Barrens",false},
        {167,1875,"Westfall",false},
        {2922,9277,"Dun Morogh",false},
        {1701,6841,"Razorfen Kraul",true},
        {1838,6841,"Razorfen Kraul",true},
    }) do
        questID, itemID, location, inside = data[1], data[2], data[3], data[4]
        Check(true)
    end
    location, inside, questID = "The Stockade", true, 388
    itemID = 2909 -- Red Wool Bandana: multi-item collection.
    Check(false)
    location, inside, questID, itemID = "Wailing Caverns", true, 1486, 6443
    Check(false) -- Deviate Hide collection.
    location, inside, questID, itemID = "Stormwind City", false, 959, 5334
    Check(false)
    DQT.NeedsQuestLoot = oldNeeds
    IsInInstance, GetInstanceInfo, GetRealZoneText = oldInstance, oldInfo, oldZone
    GetNumLootItems, GetLootSlotLink = oldSlots, oldLink
    DQT.loaded, DQT.db = oldLoaded, oldDB
end
print("Single-copy loot mappings, shared-item quests, entrance scope and collection exclusions passed")
