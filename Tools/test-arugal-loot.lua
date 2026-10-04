do
    local oldDB, oldLoaded = DQT.db, DQT.loaded
    local oldLog, oldItem, oldCount = C_QuestLog, C_Item, GetItemCount
    local oldInstance, oldInfo, oldFaction = IsInInstance, GetInstanceInfo, UnitFactionGroup
    local oldSlots, oldLink = GetNumLootItems, GetLootSlotLink
    local state, owned, instance, faction = "active", 0, "Shadowfang Keep", "Horde"
    DQT.db, DQT.loaded, C_Item = {lootReminders={enabled=true}}, true, nil
    C_QuestLog = {
        IsOnQuest=function(id) return id == 1014 and state == "active" end,
        ReadyForTurnIn=function(id) return id == 1014 and state == "ready" end,
        IsQuestFlaggedCompleted=function(id) return id == 1014 and state == "completed" end,
    }
    IsInInstance = function() return true, "party" end
    GetInstanceInfo = function() return instance end
    UnitFactionGroup = function() return faction end
    GetItemCount = function(id) return id == 5442 and owned or 0 end
    GetNumLootItems = function() return 1 end
    GetLootSlotLink = function() return "|Hitem:5442:0|h[Head of Arugal]|h" end
    local function Event(event, ...) DQT.lootReminderEvents.scripts.OnEvent(nil, event, ...) end
    for _, name in ipairs({"Archmage Arugal", "Arugal"}) do
        Event("PLAYER_ENTERING_WORLD")
        Event("ENCOUNTER_END", 1, name, 1, 5, 0)
        assert(not DQT.lootReminderFrame:IsShown(), "Failed Arugal encounter ignored")
        Event("BOSS_KILL", 1, name)
        local frame = DQT.lootReminderFrame
        assert(frame:IsShown() and frame.drops[1].questID == 1014 and frame.drops[1].itemID == 5442, "Arugal boss notification maps the correct quest item")
        frame:Hide()
        Event("ENCOUNTER_END", 1, name, 1, 5, 1)
        Event("LOOT_OPENED", false)
        assert(not frame:IsShown(), "Arugal kill, encounter and loot notifications deduplicate")
    end
    Event("PLAYER_ENTERING_WORLD")
    Event("ENCOUNTER_END", 1, "Archmage Arugal", 1, 5, 1)
    assert(DQT.lootReminderFrame:IsShown(), "Successful encounter triggers without BOSS_KILL")
    Event("PLAYER_ENTERING_WORLD")
    Event("LOOT_OPENED", false)
    assert(DQT.lootReminderFrame:IsShown(), "Head loot fallback works without an encounter notification")
    owned = 1
    Event("BAG_UPDATE_DELAYED")
    assert(not DQT.lootReminderFrame:IsShown(), "Looted head dismisses reminder")
    for _, value in ipairs({"ready", "completed", "missing", "owned", "wrongFaction", "wrongInstance", "disabled"}) do
        Event("PLAYER_ENTERING_WORLD")
        state = (value == "ready" or value == "completed" or value == "missing") and value or "active"
        owned = value == "owned" and 1 or 0
        faction = value == "wrongFaction" and "Alliance" or "Horde"
        instance = value == "wrongInstance" and "The Stockade" or "Shadowfang Keep"
        DQT.db.lootReminders.enabled = value ~= "disabled"
        Event("BOSS_KILL", 1, "Archmage Arugal")
        Event("LOOT_OPENED", false)
        assert(not DQT.lootReminderFrame:IsShown(), "Suppress irrelevant Arugal reminder: " .. value)
    end
    Event("PLAYER_ENTERING_WORLD")
    DQT.db, DQT.loaded = oldDB, oldLoaded
    C_QuestLog, C_Item, GetItemCount = oldLog, oldItem, oldCount
    IsInInstance, GetInstanceInfo, UnitFactionGroup = oldInstance, oldInfo, oldFaction
    GetNumLootItems, GetLootSlotLink = oldSlots, oldLink
end
print("Passed Arugal loot: boss aliases, encounter success, loot fallback, deduplication, looted head dismissal and relevance guards.")
