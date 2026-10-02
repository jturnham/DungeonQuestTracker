do
    local oldContext, oldPriority = DQT.GetPlayerContext, DQT.GetTurnInPriority
    local contextCalls, priorityCalls = 0, 0
    DQT.GetPlayerContext = function(self)
        contextCalls = contextCalls + 1
        return oldContext(self)
    end
    DQT.GetTurnInPriority = function(self, ...)
        priorityCalls = priorityCalls + 1
        return oldPriority(self, ...)
    end
    local status = DQT:GetDungeonQuestStatus("ragefire-chasm")
    assert(status.turnIns and contextCalls == 1 and priorityCalls == 1, "Default status retains planner with one context snapshot")
    contextCalls, priorityCalls = 0, 0
    DQT:GetGlobalTurnInPriority()
    assert(contextCalls == 1 and priorityCalls == 0, "Global planner avoids per-dungeon rankings and repeated context calls")
    contextCalls, priorityCalls = 0, 0
    DQT:GetDisplayDungeonStatus("ragefire-chasm")
    assert(contextCalls == 1 and priorityCalls == 0, "Checklist filtering skips unused rankings")
    contextCalls, priorityCalls = 0, 0
    local savedSearch = DQT.UI.searchText
    DQT.UI.searchText = ""
    DQT.UI:ShowDungeonList()
    assert(contextCalls == 1 and priorityCalls == 0, "Entire dungeon list shares one context and builds no rankings")
    DQT.UI.searchText = savedSearch
    DQT.GetPlayerContext, DQT.GetTurnInPriority = oldContext, oldPriority

    local ui, oldSearch, oldDisplay = DQT.UI, DQT.UI.searchText, DQT.GetDisplayDungeonStatus
    local scans = 0
    DQT.GetDisplayDungeonStatus = function(self, ...)
        scans = scans + 1
        return oldDisplay(self, ...)
    end
    ui.searchText = "Wailing Caverns"
    ui:ShowDungeonList()
    assert(scans == 1, "Search scans only matching dungeons")
    scans, ui.searchText = 0, "no such dungeon"
    ui:ShowDungeonList()
    assert(scans == 0, "Empty search results require no quest scans")
    ui.searchText, DQT.GetDisplayDungeonStatus = oldSearch, oldDisplay

    local oldRefresh = ui.RefreshCurrentDungeon
    local refreshes = 0
    ui.RefreshCurrentDungeon = function() refreshes = refreshes + 1 end
    ui.frame:Show()
    DQT:RequestUIRefresh()
    for i=1,20 do DQT.events.scripts.OnEvent(nil, "QUEST_LOG_UPDATE") end
    assert(refreshes == 0, "Event bursts do not refresh synchronously")
    DQT.events.scripts.OnUpdate(nil, 0.02)
    assert(refreshes == 0, "Short coalescing window")
    DQT.events.scripts.OnUpdate(nil, 0.04)
    assert(refreshes == 1 and not DQT.events.scripts.OnUpdate, "One refresh per burst and no idle update callback")
    ui.frame:Hide()
    DQT:RequestUIRefresh()
    assert(not DQT.events.scripts.OnUpdate, "Hidden UI schedules no scan")
    ui.RefreshCurrentDungeon = oldRefresh
    ui:ShowDungeonList()
end
print("Passed performance: context reuse, no duplicate planners, search scan counts, event coalescing and no idle/hidden updates.")
