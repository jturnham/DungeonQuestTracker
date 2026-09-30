local addonName, DQT = ...

DQT.name = addonName
DQT.version = "0.1.0"

DQT.defaults = {
    minimap = { hide = false },
    filters = {
        showCompleted = false,
        showUnavailable = true,
        showClassRestricted = true,
    },
}
