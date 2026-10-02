do
    local oldDB, oldLoaded = DQT.db, DQT.loaded
    local oldLog, oldItem, oldCount = C_QuestLog, C_Item, GetItemCount
    local oldInstance, oldInfo, oldFaction = IsInInstance, GetInstanceInfo, UnitFactionGroup
    local oldSlots, oldLink, oldSecret, oldSound, oldSoundAPI = GetNumLootItems, GetLootSlotLink, issecretvalue, PlaySound, C_Sound
    local active, ready, completed, owned, links = {}, {}, {}, {}, {}
    local instance, faction, soundCalls, scans = "The Stockade", "Alliance", 0, 0
    DQT.db, DQT.loaded = {lootReminders={enabled=true}}, true
    C_Item, C_Sound = nil, nil
    C_QuestLog = {
        IsOnQuest=function(id) return active[id] or false end,
        ReadyForTurnIn=function(id) return ready[id] or false end,
        IsQuestFlaggedCompleted=function(id) return completed[id] or false end,
    }
    UnitFactionGroup = function() return faction end
    IsInInstance = function() return true, "party" end
    GetInstanceInfo = function() return instance end
    GetItemCount = function(id) return owned[id] or 0 end
    GetNumLootItems = function() scans=scans+1; return #links end
    GetLootSlotLink = function(slot) return links[slot] end
    PlaySound = function() soundCalls=soundCalls+1 end
    local function Event(event, ...) DQT.lootReminderEvents.scripts.OnEvent(nil, event, ...) end
    local function Reset()
        Event("PLAYER_ENTERING_WORLD")
        active, ready, completed, owned, links = {}, {}, {}, {}, {}
    end
    for _, data in ipairs({{391,2926,"Bazil Thredd"},{386,3630,"Targorr the Dread"},{377,3628,"Dextren Ward"},{378,3640,"Kam Deepfury"}}) do
        Reset()
        active[data[1]]=true
        Event("ENCOUNTER_END", 1, data[3], 1, 5, 0)
        assert(not DQT.lootReminderFrame:IsShown(), "Failed encounter ignored")
        Event("ENCOUNTER_END", 1, data[3], 1, 5, 1)
        local frame = DQT.lootReminderFrame
        assert(frame:IsShown() and frame.drops[1].itemID==data[2], "Stockade encounter item mapping")
        local sounds = soundCalls
        frame:Hide()
        Event("BOSS_KILL", 1, data[3])
        links={"|Hitem:"..data[2]..":0|h[Quest item]|h"}
        Event("LOOT_READY", false)
        Event("LOOT_OPENED", false)
        assert(not frame:IsShown() and soundCalls==sounds, "Encounter and loot notifications deduplicate")
        Reset()
        active[data[1]]=true
        links={"|Hitem:"..data[2]..":0|h[Quest item]|h"}
        Event("LOOT_OPENED", false)
        assert(frame:IsShown() and frame.drops[1].questID==data[1], "Loot fallback without boss notification")
        owned[data[2]]=1
        Event("BAG_UPDATE_DELAYED")
        assert(not frame:IsShown(), "Collected item clears fallback")
    end
    Reset()
    active[391], active[377] = true, true
    links={"item:2926", "item:3628", "item:2926", "item:2909"}
    Event("LOOT_SLOT_CHANGED", 1)
    assert(#DQT.lootReminderFrame.drops==2, "Multiple quest items aggregate; duplicate slots and trash excluded")
    Reset()
    active[391]=true
    links={"item:2926"}
    local sounds = soundCalls
    Event("LOOT_READY", true)
    Event("LOOT_OPENED", true)
    owned[2926]=1
    DQT.lootReminderEvents.scripts.OnUpdate(nil, 0.2)
    assert(not DQT.lootReminderFrame:IsShown() and soundCalls==sounds, "Successful auto-loot produces no reminder")
    assert(not DQT.lootReminderEvents.scripts.OnUpdate, "Auto-loot delay has no idle callback")
    Reset()
    active[391]=true
    links={"item:2926"}
    Event("LOOT_OPENED", true)
    DQT.lootReminderEvents.scripts.OnUpdate(nil, 0.2)
    assert(DQT.lootReminderFrame:IsShown(), "Full bags leave item available and trigger reminder")
    for _, state in ipairs({"ready", "completed", "missing", "owned", "wrongFaction", "wrongInstance", "disabled"}) do
        Reset()
        active[391]=state~="missing"
        ready[391]=state=="ready"
        completed[391]=state=="completed"
        owned[2926]=state=="owned" and 1 or 0
        faction=state=="wrongFaction" and "Horde" or "Alliance"
        instance=state=="wrongInstance" and "Another dungeon" or "The Stockade"
        DQT.db.lootReminders.enabled=state~="disabled"
        links={"item:2926"}
        Event("LOOT_OPENED", false)
        assert(not DQT.lootReminderFrame:IsShown(), "Suppress irrelevant loot: "..state)
    end
    Reset()
    faction, instance, DQT.db.lootReminders.enabled = "Alliance", "The Stockade", true
    active[391]=true
    local secret = {}
    issecretvalue = function(value) return value==secret end
    GetNumLootItems = function() return secret end
    assert(pcall(Event, "LOOT_READY", false), "Secret slot count ignored")
    GetNumLootItems = function() return 1 end
    GetLootSlotLink = function() return secret end
    assert(pcall(Event, "LOOT_OPENED", false), "Secret link ignored")
    assert(pcall(Event, "ENCOUNTER_END", 1, secret, 1, 5, secret), "Secret encounter fields ignored")
    GetLootSlotLink = function() error("Unavailable loot API") end
    assert(pcall(Event, "LOOT_OPENED", false), "Throwing loot API ignored")
    GetNumLootItems = nil
    assert(pcall(Event, "LOOT_OPENED", false), "Missing loot API ignored")
    assert(not DQT.lootReminderFrame:IsShown() and DQTForbiddenEventRegistrations==0, "No restricted event registration or spurious alert")
    Event("PLAYER_ENTERING_WORLD")
    DQT.db, DQT.loaded = oldDB, oldLoaded
    C_QuestLog, C_Item, GetItemCount = oldLog, oldItem, oldCount
    IsInInstance, GetInstanceInfo, UnitFactionGroup = oldInstance, oldInfo, oldFaction
    GetNumLootItems, GetLootSlotLink, issecretvalue, PlaySound, C_Sound = oldSlots, oldLink, oldSecret, oldSound, oldSoundAPI
end
print("Passed Stockade loot: four mappings, encounter success, cross-trigger deduplication, item-based fallback, auto-loot/full bags and guarded restricted data.")
