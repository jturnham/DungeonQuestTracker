local addonName, DQT = ...

DQT.name = addonName
DQT.version = "0.4.0"

DQT.defaults = {
    partyDataSync = false,
    partyQuestCache = {},
    display = { compact = false },
    lootReminders = { enabled = true },
    minimap = { hide = false, angle = 225 },
    party = { respond = true, autoBroadcast = false, confirmShareAll = false },
    filters = {
        showCompleted = true,
        showUnavailable = false,
        showClassRestricted = true,
        showLowLevelLocked = true,
        ignoreGrayChecklist = true,
        ignoreRedChecklist = true,
        ignoreGrayTurnIns = false,
        hideGrayDungeons = true,
        hideRedDungeons = true,
        hideLowDungeons = false,
        lowLevelGap = 5,
        hideHighDungeons = false,
        highLevelGap = 5,
        hideTrackedDungeons = true,
        onlyMissing = false,
        onlyReady = false,
        includeBreadcrumbs = true,
        includeItemQuests = true,
    },
}
