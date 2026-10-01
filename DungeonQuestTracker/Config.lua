local addonName, DQT = ...

DQT.name = addonName
DQT.version = "0.2.0"

DQT.defaults = {
    partyDataSync = false,
    partyQuestCache = {},
    minimap = { hide = false },
    filters = {
        showCompleted = false,
        showUnavailable = true,
        showClassRestricted = true,
    },
}
