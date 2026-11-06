do
    local old={db=DQT.db,group=IsInGroup,raid=IsInRaid,full=UnitFullName,time=GetTime,send=C_ChatInfo,
        normalize=DQT.NormalizePartySender,caps=DQT.partyCapabilities,replies=DQT.capabilityResponseTimes,refresh=DQT.RequestUIRefresh}
    local now,sent=100,{}
    DQT.db={party={respond=true},partyDataSync=false}
    IsInGroup=function() return true end; IsInRaid=function() return false end
    GetTime=function() return now end
    DQT.NormalizePartySender=function(_,name) if name=="Peer-Realm" then return name end end
    C_ChatInfo={SendAddonMessage=function(prefix,message,channel,target) sent[#sent+1]={prefix,message,channel,target};return true end}
    DQT.partyCapabilities={};DQT.capabilityResponseTimes={}
    local refreshes=0;DQT.RequestUIRefresh=function() refreshes=refreshes+1 end
    DQT:HandleAddonMessage("DQT1","CAPQ|1","PARTY","Peer-Realm")
    assert(#sent==1 and sent[1][2]=="CAP|1|"..DQT.version.."|0" and sent[1][3]=="WHISPER","Version reply contains only protocol/version/sync state")
    DQT:HandleAddonMessage("DQT1","CAPQ|1","PARTY","Peer-Realm");assert(#sent==1,"Capability replies throttled per member")
    DQT:HandleAddonMessage("DQT1","CAP|1|0.6.0|0","WHISPER","Peer-Realm")
    assert(DQT.partyCapabilities['Peer-Realm'].protocol==1 and DQT.partyCapabilities['Peer-Realm'].version=='0.6.0',"Different addon version can share a compatible protocol")
    for i=1,100 do DQT:HandleAddonMessage("DQT1","CAP|1|0.6.0|0","WHISPER","Peer-Realm") end
    assert(refreshes==1,"Capability bursts do not trigger redundant UI refreshes")
    now=now+30;DQT:HandleAddonMessage("DQT1","CAP|1|0.6.0|0","WHISPER","Peer-Realm")
    assert(refreshes==1 and DQT.partyCapabilities['Peer-Realm'].time==now,"Identical fresh replies update freshness without rebuilding UI")
    for _,bad in ipairs({'CAP|1|evil|0','CAP|1|0.6.0|2','CAP|0|0.6.0|0','CAP|1|0.6.0|0|extra'}) do
        DQT:HandleAddonMessage("DQT1",bad,"PARTY","Peer-Realm")
    end
    assert(DQT.partyCapabilities['Peer-Realm'].version=='0.6.0',"Malformed messages cannot replace a valid reply")
    now=now+5
    DQT:HandleAddonMessage("DQT1","CAP|99|1.0.0|1","WHISPER","Peer-Realm")
    assert(DQT.partyCapabilities['Peer-Realm'].protocol==99,"Unsupported protocol is explicit, not inferred from silence")
    DQT:HandleAddonMessage("DQT1","CAP|1|1.0.0|1","WHISPER","Stranger")
    assert(not DQT.partyCapabilities.Stranger,"Outside-roster sender rejected")
    DQT.db.party.respond=false;now=200
    DQT:HandleAddonMessage("DQT1","CAPQ|1","PARTY","Peer-Realm");assert(#sent==1,"Response opt-out applies to capabilities too")
    DQT.db,IsInGroup,IsInRaid,UnitFullName,GetTime,C_ChatInfo=old.db,old.group,old.raid,old.full,old.time,old.send
    DQT.NormalizePartySender,DQT.partyCapabilities,DQT.capabilityResponseTimes=old.normalize,old.caps,old.replies
    DQT.RequestUIRefresh=old.refresh
end
print('Party capabilities passed: bounded protocol/version format, compatible older versions, throttling, opt-out and roster guards')
