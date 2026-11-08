local addonName, DQT = ...

DQT.name = addonName
DQT.version = "0.6.4"

DQT.defaults = {
    partyDataSync = false,
    partyQuestCache = {},
    xpRecorder = {enabled=false},
    xpObservations = {},
    display = { compact = false, scale=100, favoritesFirst=true, largeText=false },
    favorites = {},
    profiles = {},
    characterProfiles = {},
    notifications = {entry=false,chains=false},
    pickups = {includeGray=true, includeBreadcrumbs=true, includeClass=true, usePlayerPosition=true, finishAtEntrance=false},
    travel = {useFlights=true,useTransports=true,useHearthstone=true,allowUnknownFlights=false,showSegments=false,useTomTom=false,recordFlightTimes=false,preferMeasuredTime=false,includeFutureSteps=false},
    travelCharacters = {},
    lootReminders = { enabled = true, duration=15, sound=true, soundPreset=1, masterChannel=true },
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
        hideTrackedDungeons = false,
        onlyMissing = false,
        onlyReady = false,
        includeBreadcrumbs = true,
        includeItemQuests = true,
    },
}
