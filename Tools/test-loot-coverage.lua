do
    local oldDB, oldLoaded = DQT.db, DQT.loaded
    local oldState, oldAvailability = DQT.GetQuestState, DQT.GetQuestAvailability
    local oldInstance, oldInfo, oldCount, oldItem = IsInInstance, GetInstanceInfo, GetItemCount, C_Item
    local oldSlots, oldLink = GetNumLootItems, GetLootSlotLink
    local questID, itemID, location, owned, state
    DQT.db, DQT.loaded, C_Item = {lootReminders={enabled=true}}, true, nil
    DQT.GetQuestState = function(_, id) return id == questID and state or "completed" end
    DQT.GetQuestAvailability = function() return "available" end
    IsInInstance = function() return true, "party" end
    GetInstanceInfo = function() return location end
    GetItemCount = function(id) return id == itemID and owned or 0 end
    GetNumLootItems = function() return 1 end
    GetLootSlotLink = function() return "item:" .. itemID end
    local function Event(event, ...) DQT.lootReminderEvents.scripts.OnEvent(nil, event, ...) end
    local cases = {
        {5761,14540,"Taragaman the Hungerer","Ragefire Chasm"},
        {166,3637,"Edwin VanCleef","The Deadmines"},
        {2040,7365,"Sneed's Shredder","The Deadmines"},
        {914,9738,"Lord Cobrahn","Wailing Caverns"},
        {914,9739,"Lady Anacondra","Wailing Caverns"},
        {914,9740,"Lord Pythas","Wailing Caverns"},
        {914,9741,"Lord Serpentis","Wailing Caverns"},
        {1200,5881,"Twilight Lord Kelris","Blackfathom Deeps"},
        {6561,5881,"Twilight Lord Kelris","Blackfathom Deeps"},
        {6922,16782,"Baron Aquanis","Blackfathom Deeps",true},
        {96393,274286,"Durgen Dirgehammer","Hall of Thanes"},
        {95250,268518,"The Baron","Ruins of Lordaeron"},
        {95646,270180,"Highland Horror","Excavation Site: Wetlands"},
        {95810,270865,"Relic Guardian","Excavation Site: Wetlands",true},
        {95664,270865,"Relic Guardian","Excavation Site: Wetlands",true},
        {2841,9299,"Mekgineer Thermaplugg","Gnomeregan"},
        {1101,5792,"Charlga Razorflank","Razorfen Kraul"},
        {1102,5793,"Charlga Razorflank","Razorfen Kraul"},
        {3341,10420,"Amnennar the Coldbringer","Razorfen Downs"},
        {2204,7672,"Archaedas","Uldaman"},
        {2339,7672,"Archaedas","Uldaman"},
        {2201,7670,"Grimlok","Uldaman"},
        {2339,7670,"Grimlok","Uldaman"},
        {1956,8053,"Obsidian Sentinel","Uldaman"},
    }
    for _, row in ipairs(cases) do
        questID, itemID, location, owned, state = row[1], row[2], row[4], 0, row[5] and "missing" or "active"
        assert(DQT:GetQuest(questID), "Mapped quest exists: " .. questID)
        Event("PLAYER_ENTERING_WORLD")
        Event("ENCOUNTER_END", 1, row[3], 1, 5, 0)
        assert(not DQT.lootReminderFrame or not DQT.lootReminderFrame:IsShown(), "Failed encounter ignored")
        Event("BOSS_KILL", 1, row[3])
        local frame = DQT.lootReminderFrame
        assert(frame:IsShown() and frame.drops[1].itemID == itemID and frame.drops[1].questID == questID, "Boss mapping: " .. questID)
        frame:Hide()
        Event("LOOT_OPENED", false)
        assert(not frame:IsShown(), "Encounter/loot deduplication")
        Event("PLAYER_ENTERING_WORLD")
        Event("LOOT_OPENED", false)
        assert(frame:IsShown(), "Loot fallback: " .. questID)
        owned = 1
        Event("BAG_UPDATE_DELAYED")
        assert(not frame:IsShown(), "Owned item dismisses")
        owned, location = 0, "Wrong instance"
        Event("PLAYER_ENTERING_WORLD")
        Event("BOSS_KILL", 1, row[3])
        Event("LOOT_OPENED", false)
        assert(not frame:IsShown(), "Instance scope")
    end
    -- One-copy gems from distinct bosses are separate reminders, not a repeated collection.
    Event("PLAYER_ENTERING_WORLD")
    questID, location, state, owned = 914, "Wailing Caverns", "active", 0
    for _, row in ipairs(cases) do
        if row[1] == 914 then
            itemID = row[2]
            Event("BOSS_KILL", 1, row[3])
            assert(DQT.lootReminderFrame:IsShown() and DQT.lootReminderFrame.drops[1].itemID == itemID, "Each distinct gem alerts")
            DQT.lootReminderFrame:Hide()
        end
    end
    Event("PLAYER_ENTERING_WORLD")
    questID, location, state, owned = 2339, "Uldaman", "active", 0
    for _, name in ipairs({"Grimlok", "Archaedas"}) do
        Event("BOSS_KILL", 1, name)
        assert(DQT.lootReminderFrame:IsShown(), "Both necklace boss items alert")
        DQT.lootReminderFrame:Hide()
    end
    Event("PLAYER_ENTERING_WORLD")
    DQT.db, DQT.loaded = oldDB, oldLoaded
    DQT.GetQuestState, DQT.GetQuestAvailability = oldState, oldAvailability
    IsInInstance, GetInstanceInfo, GetItemCount, C_Item = oldInstance, oldInfo, oldCount, oldItem
    GetNumLootItems, GetLootSlotLink = oldSlots, oldLink
end
print("Named-mob loot coverage: 24 mappings, instance scopes, bag checks, loot fallback and per-item deduplication passed")
