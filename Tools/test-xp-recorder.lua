do
    local recorder=DQT.XPRecorder
    local saved={db=DQT.db,pending=recorder.pending,seen=recorder.seen,time=time,clock=GetTime,build=GetBuildInfo,id=GetQuestID,reward=GetRewardXP,level=UnitLevel,xp=UnitXP,max=UnitXPMax}
    local now,id,panel,level=1800000000,5722,5000,16
    time=function() return now end
    GetTime=function() return now-1700000000 end
    GetBuildInfo=function() return "1.60.1","70374" end
    GetQuestID=function() return id end
    GetRewardXP=function() return panel end
    UnitLevel=function() return level end
    UnitXP=function() return 12000 end
    UnitXPMax=function() return 20000 end
    DQT.db={xpRecorder={enabled=false},xpObservations={}}
    recorder:Clear()
    recorder:CapturePanel(); recorder:TurnedIn(id,5000)
    assert(#recorder:Records()==0,"Recorder is opt-in")
    DQT.db.xpRecorder.enabled=true
    recorder:CapturePanel()
    level=17
    recorder:TurnedIn(id,5000)
    local row=recorder:Records()[1]
    assert(row.questID==id and row.levelBefore==16 and row.levelAtEvent==17 and row.eventXP==5000 and row.displayedXP==5000)
    assert(row.modifiers=="unknown" and row.build==70374,"Do not infer bonus absence or base XP")
    assert(DQT.quests[id].foreverXp~=5000,"Observations cannot overwrite bundled XP")
    recorder:TurnedIn(id,5000)
    assert(#recorder:Records()==1,"Repeated turn-in event deduplicated")
    local export=recorder:Export()
    assert(export:find("DQT%-XP%-OBSERVATIONS\t1") and not export:find("player",1,true))
    local before=export
    DQT.UI:ShowXPRecords(true)
    assert(DQT.UI.xpRecords.text:GetText()==before,"Copy UI uses the machine-readable export")
    DQT.UI:ShowXPRecords(false)
    assert(DQT.UI.xpRecords.text:GetText():find("not a verified base reward",1,true))
    local compact=DQT.db.display
    DQT.db.display={compact=true}
    DQT.UI:ShowXPRecords(true)
    assert(DQT.UI.xpRecords:GetWidth()==420 and DQT.UI.xpRecords.text:GetText()==before,"Compact export remains complete")
    DQT.db.display=compact
    recorder:Clear()
    assert(#recorder:Records()==0)
    id=5723; panel=0; level=16
    recorder:CapturePanel(); recorder:TurnedIn(id,0)
    assert(recorder:Records()[1].eventXP==0,"Zero XP is evidence, not a missing number")
    recorder:Clear()
    recorder:TurnedIn(id,100)
    assert(recorder:Records()[1].levelBefore==-1 and recorder:Records()[1].displayedXP==-1,"Missing panel context stays unknown")
    recorder:Clear()
    recorder:CapturePanel(); now=now+301; recorder:TurnedIn(id,100)
    assert(recorder:Records()[1].levelBefore==-1,"Stale panels cannot establish reward context")
    recorder:Clear()
    recorder:TurnedIn(9999999,100); recorder:TurnedIn(id,0/0); recorder:TurnedIn(id,math.huge); recorder:TurnedIn(id,-1)
    assert(#recorder:Records()==0,"Reject unknown quests and invalid rewards")
    GetBuildInfo=function() error("missing") end
    GetRewardXP=function() error("missing") end
    recorder:CapturePanel(); recorder:TurnedIn(id,100)
    assert(recorder:Records()[1].build==-1 and recorder:Records()[1].displayedXP==-1,"Unsupported APIs leave explicit unknowns")
    local valid=recorder:Records()[1]
    DQT.db.xpObservations={}
    for i=1,500 do DQT.db.xpObservations[i]=valid end
    recorder.seen={}; recorder:TurnedIn(id,101)
    assert(#recorder:Records()==500 and recorder:Records()[500].eventXP==101,"Recorder bounded at 500 rows")
    now=now+91*86400
    assert(#recorder:Records()==0,"Expire old observations")
    DQT.db.xpObservations={{questID=5722,eventXP=100,modifiers="none"},"bad"}
    assert(#recorder:Records()==0,"Sanitize malformed saved rows")
    DQT.db,recorder.pending,recorder.seen=saved.db,saved.pending,saved.seen
    time,GetTime,GetBuildInfo,GetQuestID,GetRewardXP,UnitLevel,UnitXP,UnitXPMax=saved.time,saved.clock,saved.build,saved.id,saved.reward,saved.level,saved.xp,saved.max
    if DQT.UI.xpRecords then DQT.UI.xpRecords:Hide() end
    print("XP recorder passed: opt-in, raw event/panel evidence, unknown context, zero/invalid XP, deduplication, privacy, limits, retention, export UI and no data mutation")
end
