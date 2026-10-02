do
    local oldSound, oldSoundAPI, oldSoundKit = PlaySound, C_Sound, SOUNDKIT
    local soundCalls = 0
    C_Sound, SOUNDKIT = nil, { RAID_WARNING = 8959 }
    PlaySound = function(id, channel)
        assert(id == 8959 and channel == "Master", "Notification sound and channel")
        soundCalls = soundCalls + 1
    end
    assert(DQTForbiddenEventRegistrations == 0, "No forbidden combat-log event registered during addon load")
    assert(DQT.lootReminderEvents.events.BOSS_KILL, "Public boss-kill event registered")
    local oldLog, oldInstance, oldInfo, oldCount = C_QuestLog, IsInInstance, GetInstanceInfo, GetItemCount
    local oldItem, oldCombat, oldModern, oldFaction, oldLevel = C_Item, CombatLogGetCurrentEventInfo, C_CombatLog, UnitFactionGroup, UnitLevel
    local oldDB, oldLoaded = DQT.db, DQT.loaded
    local active, complete, ready, counts = {}, {}, {}, {}
    local faction, inInstance, instanceType = "Alliance", true, "party"
    UnitFactionGroup = function() return faction end
    UnitLevel = function() return 30 end
    IsInInstance = function() return inInstance, instanceType end
    GetInstanceInfo = function() return "Ruins of Lordaeron" end
    C_QuestLog = {
        IsQuestFlaggedCompleted = function(id) return complete[id] or false end,
        IsOnQuest = function(id) return active[id] or false end,
        ReadyForTurnIn = function(id) return ready[id] or false end,
    }
    C_Item = nil
    GetItemCount = function(id) return counts[id] or 0 end
    DQT.db, DQT.loaded = { lootReminders = { enabled = true } }, true
    local function Death(id, spawn, name)
        DQT:HandleQuestLootDeath("Creature-0-1-2-3-" .. id .. "-" .. spawn, name)
    end
    Death(639, "AAA1", "Edwin VanCleef")
    local frame = DQT.lootReminderFrame
    assert(frame and frame:IsShown() and frame.text:GetText():find("An Unsent Letter", 1, true), "Starter drop banner")
    assert(soundCalls == 1, "Alert plays one notification sound")
    frame:Hide()
    Death(639, "AAA1", "Edwin VanCleef")
    assert(not frame:IsShown(), "Duplicate death events suppressed")
    assert(soundCalls == 1, "Duplicate events never replay sound")
    counts[2874] = 1
    Death(639, "AAA2", "Edwin VanCleef")
    assert(not frame:IsShown(), "Already-owned starter suppressed")
    counts[2874], complete[373] = 0, true
    Death(639, "AAA3", "Edwin VanCleef")
    assert(not frame:IsShown(), "Completed quest suppressed")
    complete[373], faction = nil, "Horde"
    Death(639, "AAA4", "Edwin VanCleef")
    assert(not frame:IsShown(), "Wrong faction suppressed")
    Death(250483, "BBB1", "Witherfang")
    assert(not frame:IsShown(), "Objective drop requires active quest")
    active[95216] = true
    Death(250483, "BBB2", "Witherfang")
    assert(frame:IsShown() and frame.text:GetText():find("Highly Toxic Strain", 1, true), "Active quest objective banner")
    counts[275443] = 1
    DQT.lootReminderEvents.scripts.OnEvent(nil, "BAG_UPDATE_DELAYED")
    assert(not frame:IsShown(), "Looting dismisses banner")
    counts[275443], ready[95216] = 0, true
    Death(250483, "BBB3", "Witherfang")
    assert(not frame:IsShown(), "Ready quest suppressed")
    Death(999999, "CCC1", "The Baron")
    assert(frame:IsShown() and frame.text:GetText():find("Abominable Head", 1, true), "Scoped beta boss-name fallback")
    frame.scripts.OnUpdate(frame, 16)
    assert(not frame:IsShown(), "Banner expires")
    GetInstanceInfo = function() return "Another dungeon" end
    Death(999999, "CCC2", "The Baron")
    assert(not frame:IsShown(), "Name fallback never matches a different dungeon")
    GetInstanceInfo = oldInfo
    inInstance = false
    Death(3654, "DDD1", "Mutanus")
    assert(not frame:IsShown(), "World deaths ignored")
    inInstance, instanceType = true, "raid"
    Death(3654, "DDD2", "Mutanus")
    assert(not frame:IsShown(), "Raid deaths ignored")
    instanceType = "party"
    DQT:SetOption("lootReminders.enabled", false)
    Death(3654, "DDD3", "Mutanus")
    assert(not frame:IsShown(), "Disabled option suppresses reminders")
    DQT:SetOption("lootReminders.enabled", true)
    local combatCalls = 0
    C_CombatLog = { GetCurrentEventInfo = function() combatCalls = combatCalls + 1; error("Forbidden combat API") end }
    CombatLogGetCurrentEventInfo = C_CombatLog.GetCurrentEventInfo
    GetInstanceInfo = function() return "Wailing Caverns" end
    DQT.lootReminderEvents.scripts.OnEvent(nil, "BOSS_KILL", 1, "Mutanus the Devourer")
    assert(frame:IsShown(), "Public boss-kill notification")
    DQT:SetOption("lootReminders.enabled", false)
    assert(not frame:IsShown(), "Disabling dismisses current banner immediately")
    DQT:SetOption("lootReminders.enabled", true)
    DQT.lootReminderEvents.scripts.OnEvent(nil, "BOSS_KILL", 1, "Mutanus the Devourer")
    assert(not frame:IsShown(), "Duplicate public notification suppressed")
    DQT.lootReminderEvents.scripts.OnEvent(nil, "PLAYER_ENTERING_WORLD")
    DQT:SetOption("lootReminders.enabled", false)
    DQT.UI:ShowOptions()
    assert(DQT.UI.frame.lootReminderPreview, "Options contains alert preview button")
    DQT.UI.frame.lootReminderPreview.scripts.OnClick()
    assert(frame:IsShown() and frame.isPreview and frame.title:GetText():find("Preview", 1, true), "Preview works with reminders disabled")
    assert(frame.text:GetText():find("Highly Toxic Strain", 1, true), "Preview uses real banner content")
    frame.scripts.OnUpdate(frame, 14)
    assert(frame:IsShown() and frame:GetAlpha() == 1, "Alert holds full opacity for fourteen seconds")
    frame.scripts.OnUpdate(frame, 0.5)
    assert(frame:IsShown() and frame:GetAlpha() == 0.5, "Alert fades during final second")
    DQT.lootReminderEvents.scripts.OnEvent(nil, "BAG_UPDATE_DELAYED")
    DQT.lootReminderEvents.scripts.OnEvent(nil, "QUEST_LOG_UPDATE")
    assert(frame:IsShown(), "Quest and bag events do not dismiss preview")
    frame.scripts.OnUpdate(frame, 16)
    assert(not frame:IsShown(), "Preview expires normally")
    DQT:PreviewQuestLootReminder()
    assert(frame:GetAlpha() == 1 and frame.remaining == 15, "New preview resets opacity and timer")
    frame.close.scripts.OnClick()
    assert(not frame:IsShown(), "Preview dismisses normally")
    DQT:ShowQuestLootReminder("Witherfang", DQT.lootReminderData[250483])
    assert(not frame.isPreview and frame.title:GetText() == "Quest Loot", "Real alerts reset preview state")
    local previousSoundCalls = soundCalls
    DQT:ShowQuestLootReminder("Witherfang", DQT.lootReminderData[250483], false, true)
    assert(soundCalls == previousSoundCalls, "Updating an existing alert does not replay sound")
    PlaySound = function() error("Sound unavailable") end
    assert(pcall(DQT.PreviewQuestLootReminder, DQT) and frame:IsShown(), "Sound API failures do not break visual alerts")
    PlaySound = nil
    assert(pcall(DQT.PreviewQuestLootReminder, DQT), "Missing sound API supported")
    frame:Hide()
    DQT:SetOption("lootReminders.enabled", true)
    DQT.lootReminderEvents.scripts.OnEvent(nil, "BOSS_KILL", 1, "Mutanus the Devourer")
    assert(frame:IsShown(), "New instance session resets duplicate tracking")
    frame.close.scripts.OnClick()
    assert(not frame:IsShown(), "Dismiss button")
    DQT.lootReminderEvents.scripts.OnEvent(nil, "BOSS_KILL", 999, "Unknown boss")
    assert(not frame:IsShown() and combatCalls == 0, "Unknown boss ignored and combat APIs never accessed")
    assert(pcall(DQT.HandleQuestLootDeath, DQT, "bad GUID", "Mutanus"), "Malformed GUID ignored")
    DQT.lootReminderEvents.scripts.OnEvent(nil, "PLAYER_ENTERING_WORLD")
    C_QuestLog, IsInInstance, GetInstanceInfo, GetItemCount = oldLog, oldInstance, oldInfo, oldCount
    C_Item, CombatLogGetCurrentEventInfo, C_CombatLog, UnitFactionGroup, UnitLevel = oldItem, oldCombat, oldModern, oldFaction, oldLevel
    DQT.db, DQT.loaded = oldDB, oldLoaded
    PlaySound, C_Sound, SOUNDKIT = oldSound, oldSoundAPI, oldSoundKit
end
print("Passed loot reminders: relevant drops, faction/history/bag checks, instance scope, dismiss/timeout, options, public boss notifications and no combat API access.")
