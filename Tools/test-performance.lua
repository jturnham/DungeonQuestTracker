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
do
    local oldState, oldStatus = DQT.GetQuestState, DQT.GetDungeonQuestStatus
    local calls, scans = 0, 0
    DQT.GetQuestState = function() calls=calls+1; return "ready" end
    local context, reference, seen = DQT:GetPlayerContext(), {}, {}
    local xpToLevel = math.max(0, (context.maxXp or 0) - (context.currentXp or 0))
    for _, key in ipairs(DQT:GetOrderedDungeonKeys()) do
        local status = oldStatus(DQT, key, false, true, context)
        for _, row in ipairs(status.quests) do
            if not seen[row.questID] and not (DQT:GetOption("filters.ignoreGrayTurnIns") and DQT:IsQuestGray(row.quest, context)) then
                seen[row.questID] = true
                reference[#reference+1] = DQT:BuildTurnInItem(row, key, status.dungeon, context, xpToLevel)
            end
        end
    end
    DQT:SortTurnIns(reference)
    DQT:GroupTurnInsByLocation(reference,context)
    local previousCalls = calls
    calls = 0
    DQT.GetDungeonQuestStatus = function(self, ...) scans=scans+1; return oldStatus(self, ...) end
    local actual = DQT:GetGlobalTurnInPriority().quests
    assert(scans == 0 and calls < previousCalls, "Global planner avoids status allocations and repeated shared quest states")
    assert(#actual == #reference, "Planner retains every eligible unique quest")
    for i, item in ipairs(actual) do
        local expected = reference[i]
        assert(item.questID == expected.questID and item.dungeonKey == expected.dungeonKey and item.priorityScore == expected.priorityScore, "Same order, dungeon ownership and priorities")
    end
    print("Global turn-in state checks: " .. previousCalls .. " -> " .. calls .. "; no intermediate dungeon status scans.")
    DQT.GetQuestState = function() return "completed" end
    assert(#DQT:GetGlobalTurnInPriority().quests == 0, "Quest state is fresh on the next scan")
    DQT.GetQuestState, DQT.GetDungeonQuestStatus = oldState, oldStatus
end
do
    local saved = {}
    for _, name in ipairs({"GetDungeonQuestStatus", "GetQuest", "IsQuestComplete", "GetQuestAvailability", "IsQuestGray", "IsQuestRed"}) do saved[name]=DQT[name] end
    local checks = {}
    local parent = { prerequisites={{questID=100002, relationship="required"}} }
    local child = { questLevel=25, prerequisites={{questID=100001, relationship="required"}} }
    DQT.GetDungeonQuestStatus = function() return {quests={{questID=100003, quest=child, state="missing"}, {questID=100004, quest=child, state="missing"}}} end
    DQT.GetQuest = function(_, id) if id == 100001 then return parent end end
    DQT.IsQuestComplete = function(_, id) checks[id]=(checks[id] or 0)+1; return false end
    DQT.GetQuestAvailability = function() return "missing" end
    DQT.IsQuestGray, DQT.IsQuestRed = function() return false end, function() return false end
    DQT:GetDisplayDungeonStatus("test", {level=25})
    assert(checks[100001] == 1 and checks[100002] == 1, "Shared prerequisite ancestors traversed once per refresh")
    DQT:GetDisplayDungeonStatus("test", {level=25})
    assert(checks[100001] == 2 and checks[100002] == 2, "Prerequisite traversal never caches across refreshes")
    for name, fn in pairs(saved) do DQT[name]=fn end
end
print("Passed performance: context reuse, unique quest scans, shared prerequisite traversal, equivalent planner output, search scan counts and event coalescing.")
