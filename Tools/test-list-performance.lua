do
    local oldLog, oldTitle, oldCount, oldHistory = C_QuestLog, GetQuestLogTitle, GetNumQuestLogEntries, IsQuestFlaggedCompleted
    local oldScan, oldDB, oldSearch = DQT.PrepareQuestScan,DQT.db,DQT.UI.searchText
    local ids, history, ready = {2841,1098,5728},{},{}
    local infoCalls, historyCalls = 0,0
    GetQuestLogTitle,GetNumQuestLogEntries = nil,nil
    IsQuestFlaggedCompleted = function() return false end
    C_QuestLog = {
        GetNumQuestLogEntries=function() return #ids end,
        GetInfo=function(index)
            infoCalls=infoCalls+1
            local id=ids[index]
            return {questID=id,title=DQT.quests[id].name,isComplete=ready[id] or false}
        end,
        IsQuestFlaggedCompleted=function(id) historyCalls=historyCalls+1; return history[id] or false end,
        IsOnQuest=function(id) for _, candidate in ipairs(ids) do if candidate==id then return true end end return false end,
        ReadyForTurnIn=function(id) return ready[id] or false end,
    }
    DQT.db={filters={ignoreGrayChecklist=false,ignoreRedChecklist=false,hideGrayDungeons=false,hideRedDungeons=false,showCompleted=true,showUnavailable=true,showClassRestricted=true,includeBreadcrumbs=true,includeItemQuests=true},display={}}
    DQT.UI.searchText=""
    local function Cards()
        local result={}
        for _, card in ipairs(DQT.UI.frame.dungeonCards) do
            if card:IsShown() then result[card.dungeonName]=card.summary:GetText() end
        end
        return result
    end
    DQT.PrepareQuestScan=function(_,context) return context end
    DQT.UI:ShowDungeonList()
    local reference, oldInfo, oldHistoryCalls = Cards(),infoCalls,historyCalls
    DQT.PrepareQuestScan=oldScan
    infoCalls,historyCalls=0,0
    DQT.UI:ShowDungeonList()
    local actual=Cards()
    for name,summary in pairs(reference) do assert(actual[name]==summary,"Optimized list retains counts: "..name) end
    for name in pairs(actual) do assert(reference[name],"Optimized list retains visibility") end
    assert(infoCalls < oldInfo/4,"Dungeon list must avoid repeatedly scanning the live quest log")
    assert(historyCalls < oldHistoryCalls,"Shared histories and prerequisites are checked once per refresh")
    print("Dungeon list API calls: quest-log info "..oldInfo.." -> "..infoCalls.."; history "..oldHistoryCalls.." -> "..historyCalls)
    DQT.UI.searchText="Wailing Caverns"
    DQT.UI:ShowDungeonList()
    local card=DQT.UI.frame.dungeonCards[1]
    local handler, oldTexture, oldOpen=card.scripts.OnClick,card.art.SetTexture,DQT.OpenDungeon
    local textures,opened=0,nil
    card.art.SetTexture=function() textures=textures+1 end
    DQT.UI:ShowDungeonList()
    assert(card.scripts.OnClick==handler and textures==0,"Refreshing pooled cards reuses handlers and unchanged art")
    DQT.UI.searchText="Shadowfang Keep"
    DQT.UI:ShowDungeonList()
    DQT.OpenDungeon=function(_,key) opened=key end
    card.scripts.OnClick(card)
    assert(opened=="shadowfang-keep","Reused card opens the currently displayed dungeon")
    DQT.OpenDungeon,card.art.SetTexture=oldOpen,oldTexture
    local function Scan()
        local value=DQT:GetPlayerContext()
        value.faction,value.level="Horde",30
        return DQT:PrepareQuestScan(value)
    end
    local context=Scan()
    assert(DQT:GetQuestState(2841,DQT.quests[2841],context)=="active")
    ready[2841]=true
    local fresh=Scan()
    assert(DQT:GetQuestState(2841,DQT.quests[2841],fresh)=="ready","Next refresh picks up ready transitions")
    history[2841]=true
    fresh=Scan()
    assert(DQT:GetQuestState(2841,DQT.quests[2841],fresh)=="completed","Next refresh picks up completion")
    ready[2841],history[2841]=nil,nil
    ids={1098,5728}
    fresh=Scan()
    assert(DQT:GetQuestState(2841,DQT.quests[2841],fresh)=="missing","Abandoned quests do not remain cached")
    C_QuestLog.GetInfo=function() error("Unavailable API") end
    GetNumQuestLogEntries=function() return 1 end
    GetQuestLogTitle=function() return DQT.quests[2841].name,35,nil,false,nil,1,nil,2841 end
    fresh=Scan()
    assert(DQT:GetQuestState(2841,DQT.quests[2841],fresh)=="ready","Failed snapshots retain legacy completion fallback")
    C_QuestLog,GetQuestLogTitle,GetNumQuestLogEntries,IsQuestFlaggedCompleted=oldLog,oldTitle,oldCount,oldHistory
    DQT.PrepareQuestScan,DQT.db,DQT.UI.searchText=oldScan,oldDB,oldSearch
end
print("Dungeon list performance passed: equivalent cards, bounded scans, fresh states and compatibility fallback.")
