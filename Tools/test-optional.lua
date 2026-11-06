do
    local saved={db=DQT.db,guid=UnitGUID,apply=DQT.ApplyOptions,active=DQT.activeProfile,loading=DQT.loadingProfile,
        full=UnitFullName,name=UnitName,group=GetNumSubgroupMembers,raid=IsInRaid,clock=GetTime,party=DQT.partyStatus,
        combat=InCombatLockdown,instance=IsInInstance,info=GetInstanceInfo,questState=DQT.GetQuestState,quests=DQT.quests,dungeons=DQT.dungeons}
    local character="Optional A"
    UnitGUID=function() return character end
    local applied=0
    DQT.ApplyOptions=function() applied=applied+1 end
    DQT.db={optionsVersion=3,display={},profiles={},characterProfiles={}}
    DQT:InitializeOptions(); DQT:InitializeEnhancements()
    assert(DQT.activeProfile=="Default")
    assert(DQT:ToggleFavorite("ragefire-chasm"))
    assert(DQT:GetListDungeonKeys()[1]=="ragefire-chasm")
    character="Optional B"; assert(not DQT:IsFavorite("ragefire-chasm"))
    assert(DQT:ToggleFavorite("uldaman")); assert(DQT:GetListDungeonKeys()[1]=="uldaman")
    character="Optional A"; assert(not DQT:IsFavorite("uldaman"))
    assert(not DQT:ToggleFavorite("not-a-dungeon"))
    assert(DQT:CreateProfile("Raid display"))
    assert(not DQT:CreateProfile("Raid display") and not DQT:CreateProfile("../bad"))
    DQT.db.profiles["Raid display"]["display.scale"]=500
    DQT.db.profiles["Raid display"]["display.compact"]=true
    DQT.db.profiles["Raid display"]["partyDataSync"]=true
    DQT.db.profiles["Raid display"]["xpRecorder.enabled"]=true
    DQT.db.travelCharacters={secret={learned=true}}
    DQT.db.hearthCharacters={secret={name="Bind",zone="Zone"}}
    DQT.db.xpObservations={{private=true}}
    local before=applied
    assert(DQT:UseProfile("Raid display"))
    assert(applied==before+1 and DQT:GetOption("display.scale")==150 and DQT:GetOption("display.compact"))
    assert(not DQT.db.partyDataSync and not DQT:GetOption("xpRecorder.enabled"))
    assert(DQT.db.travelCharacters.secret.learned and DQT.db.hearthCharacters.secret.name=="Bind" and DQT.db.xpObservations[1].private)
    assert(not DQT:DeleteProfile("Default") and not DQT:DeleteProfile("Raid display"))
    assert(DQT:UseProfile("Default")); assert(DQT:DeleteProfile("Raid display"))
    DQT.db.profiles.Default["display.scale"]=85
    DQT:InitializeEnhancements()
    assert(DQT:GetOption("display.scale")==85,"Login must load, not overwrite, the selected snapshot")
    assert(DQT:SetOption("display.scale",0) and DQT:GetOption("display.scale")==70)
    assert(not DQT:SetOption("display.scale",0/0))
    assert(DQT:SetOption("lootReminders.duration",0) and DQT:GetOption("lootReminders.duration")==3)
    assert(DQT:SetOption("lootReminders.soundPreset",99) and DQT:GetOption("lootReminders.soundPreset")==3)
    local oldSound,oldCSound,oldFrame=PlaySound,C_Sound,DQT.lootReminderFrame
    local sounds,channel=0,nil
    C_Sound=nil
    PlaySound=function(_,value) sounds=sounds+1; channel=value end
    DQT.db.lootReminders.sound=false
    DQT:PreviewQuestLootReminder()
    assert(sounds==0 and DQT.lootReminderFrame.remaining==3,"Muted preview uses the configured duration")
    DQT.db.lootReminders.sound=true; DQT.db.lootReminders.masterChannel=false
    DQT:PreviewQuestLootReminder()
    assert(sounds==1 and channel=="SFX")
    DQT.lootReminderFrame:Hide()
    PlaySound,C_Sound,DQT.lootReminderFrame=oldSound,oldCSound,oldFrame
    local report=DQT:BuildBugReport(5722,"Expected |Hplayer:secret|h", "Actual\nline")
    assert(#report<12000 and report:find("Quest: 5722",1,true) and not report:find("|H",1,true))
    assert(not report:find("Optional A",1,true) and not report:find("Bind",1,true) and not report:find("learned",1,true))
    assert(DQT:BuildBugReport(99999999):find("unknown or invalid ID",1,true))
    UnitFullName=function(unit) if unit=="player" then return "Me","Realm" else return "Other","Realm" end end
    UnitName=UnitFullName
    GetNumSubgroupMembers=function() return 1 end
    IsInRaid=function() return false end
    GetTime=function() return 1000 end
    DQT.partyStatus={["ragefire-chasm"]={["Other-Realm"]={time=999,quests={[5722]="ready"}}}}
    local matrix=DQT:PartyReadiness("ragefire-chasm")
    assert(matrix:find("Other%-Realm: ready") and matrix:find("partial reply",1,true))
    DQT.partyStatus["ragefire-chasm"]["Other-Realm"].time=800
    assert(DQT:PartyReadiness("ragefire-chasm"):find("Other%-Realm: stale"))
    DQT.partyStatus={}
    assert(DQT:PartyReadiness("ragefire-chasm"):find("unknown / no response",1,true))
    local context=DQT:PrepareQuestScan(DQT:GetPlayerContext()); context.level=80
    local status=DQT:GetDisplayDungeonStatus("ragefire-chasm",context)
    local visible,reasons=DQT:ShouldShowDungeon(status,context)
    assert(not visible and #reasons>0 and #status.exclusions>0,"Filter explanations come from actual predicates")
    DQT.UI:ShowTools(); assert(DQT.UI.utility:IsShown())
    DQT.UI:ShowProfiles(); assert(DQT.UI.utility.inputs[1]:IsShown())
    DQT.UI:ShowBugReport(5722); assert(DQT.UI.utility.inputs[2]:IsShown())
    DQT.UI:ShowFilterReasons(); DQT.UI:ShowPartyReadiness("ragefire-chasm")
    DQT.UI.utility:Hide()
    assert(DQT.L["Untranslated text"]=="Untranslated text")
    assert(DQT:RegisterLocale("zzZZ",{["Tools"]="Test tools"}))
    assert(DQT.L["Tools"]=="Tools","Other locale must not change current UI")
    -- Notification comparisons never fire for the initial available set or in combat.
    local notices=DQT.Notifications
    local oldNotice={baseline=notices.baseline,announced=notices.announced,suppressed=notices.suppressed,seen=notices.entrySeen,
        pending=notices.entryPending,waiting=notices.waiting,elapsed=notices.elapsed,chainsEnabled=notices.chainsEnabled}
    local oldChain,oldPrep=DQT.UI.ShowChainNotice,DQT.UI.ShowPreparation
    local ready,shown,prep=false,0,0
    DQT.quests={[5722]={name="Chain",followUpOf=1,dungeon="test",prerequisites={}}}
    DQT.dungeons={test={name="Exact Instance",quests={5722}}}
    DQT.GetQuestState=function() return ready and "missing" or "locked" end
    DQT.UI.ShowChainNotice=function(_,ids) assert(#ids==1); shown=shown+1 end
    DQT.UI.ShowPreparation=function() prep=prep+1 end
    DQT.db.notifications={chains=true,entry=true}
    notices.baseline=nil; notices.announced={}; notices.entrySeen={}; notices.suppressed=false
    InCombatLockdown=function() return false end
    IsInInstance=function() return true,"party" end
    GetInstanceInfo=function() return "Exact Instance" end
    notices:Process(); assert(shown==0)
    ready=true; InCombatLockdown=function() return true end
    notices:Process(); assert(shown==0 and notices.waiting)
    InCombatLockdown=function() return false end
    notices:Process(); assert(shown==1)
    notices:Process(); assert(shown==1,"Repeated events do not repeat unlocks")
    notices.entryPending=true; notices:Process(); assert(prep==1)
    notices.entryPending=true; notices:Process(); assert(prep==1,"Entry summary once per dungeon/session")
    GetInstanceInfo=function() return "Unknown Instance" end
    assert(not notices:InstanceKey())
    DQT.dungeons.duplicate={name="Exact Instance"}
    GetInstanceInfo=function() return "Exact Instance" end
    assert(not notices:InstanceKey(),"Ambiguous instance names cannot select a wing")
    notices:Suppress(); notices.entryPending=true; notices:Process(); assert(prep==1)
    notices.baseline,notices.announced,notices.suppressed,notices.entrySeen=oldNotice.baseline,oldNotice.announced,oldNotice.suppressed,oldNotice.seen
    notices.entryPending,notices.waiting,notices.elapsed,notices.chainsEnabled=oldNotice.pending,oldNotice.waiting,oldNotice.elapsed,oldNotice.chainsEnabled
    DQT.UI.ShowChainNotice,DQT.UI.ShowPreparation=oldChain,oldPrep
    DQT.db,UnitGUID,DQT.ApplyOptions,DQT.activeProfile,DQT.loadingProfile=saved.db,saved.guid,saved.apply,saved.active,saved.loading
    UnitFullName,UnitName,GetNumSubgroupMembers,IsInRaid,GetTime=saved.full,saved.name,saved.group,saved.raid,saved.clock
    DQT.partyStatus,InCombatLockdown,IsInInstance,GetInstanceInfo=saved.party,saved.combat,saved.instance,saved.info
    DQT.GetQuestState,DQT.quests,DQT.dungeons=saved.questState,saved.quests,saved.dungeons
    print("Optional features passed: profiles/consent isolation, favorites, bounds, sanitized diagnostics, party freshness, filter reasons, utility views, locale fallback and combat-safe notifications")
end
