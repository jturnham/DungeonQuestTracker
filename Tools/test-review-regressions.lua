do
    local t=DQT.Travel
    local old={nodes=t.nodes,ids=t.ids,adj=t.adjacency,timing=t.EdgeTiming}
    local seed=17
    local function Random(n) seed=(seed*16807)%2147483647;return seed%n+1 end
    for fixture=1,30 do
        t.nodes,t.ids,t.adjacency={},{},{}
        for i=1,5 do
            local id=tostring(i);t.ids[i]=id;t.nodes[id]={id=id,name=id,zone=id,faction="Horde"};t.adjacency[id]={}
        end
        for i=1,5 do for j=1,5 do
            if i~=j and Random(3)~=1 then
                local a,b=tostring(i),tostring(j)
                t.adjacency[a][#t.adjacency[a]+1]={from=a,to=b,mode="flight",fare=Random(20),seconds=Random(100),durationSource="https://example.com/measured"}
            end
        end end
        for _,timed in ipairs({false,true}) do
            local best
            local function Search(id,visited,hops,fare,seconds)
                if id=="5" then
                    if not best or (timed and seconds<best.seconds) or ((not timed or seconds==best.seconds) and (hops<best.hops or hops==best.hops and fare<best.fare)) then best={hops=hops,fare=fare,seconds=seconds} end
                    return
                end
                for _,edge in ipairs(t.adjacency[id]) do
                    if not visited[edge.to] then
                        visited[edge.to]=true;Search(edge.to,visited,hops+1,fare+edge.fare,seconds+edge.seconds);visited[edge.to]=nil
                    end
                end
            end
            Search("1",{['1']=true},0,0,0)
            local context={faction="Horde",known={['1']=true,['2']=true,['3']=true,['4']=true,['5']=true},flights=true,preferTime=timed,cache={},timingRecords=false}
            local calls=0
            t.EdgeTiming=function(self,...) calls=calls+1;return old.timing(self,...) end
            local actual=t:NetworkRoute("1","5",context)
            assert((not best and not actual) or (best and actual and actual.hops==best.hops and actual.fare==best.fare and (not timed or actual.seconds==best.seconds)),"Route search must match independent exhaustive paths")
            local initial=calls;t:NetworkRoute("1","5",context)
            assert(calls==initial,"Repeated route lookup reuses its per-context graph search")
            t.EdgeTiming=old.timing
        end
    end
    t.nodes,t.ids,t.adjacency,t.EdgeTiming=old.nodes,old.ids,old.adj,old.timing
end

do
    local old={db=DQT.db,frame=DQT.UI.frame,parent=UIParent,utility=DQT.UI.utility,xp=DQT.UI.xpRecords}
    DQT.db={display={scale=150}}
    local applied
    UIParent={GetWidth=function() return 300 end,GetHeight=function() return 200 end}
    DQT.UI.frame={GetWidth=function() return 700 end,GetHeight=function() return 570 end,SetScale=function(_,v) applied=v end,SetClampedToScreen=function() end}
    DQT.UI.utility,DQT.UI.xpRecords=nil,nil
    DQT.UI:ApplyWindowPreferences()
    assert(applied>0 and applied*700<=276 and applied*570<=176,"Small screens must fit below the former 50% scale floor")
    DQT.db,DQT.UI.frame,UIParent,DQT.UI.utility,DQT.UI.xpRecords=old.db,old.frame,old.parent,old.utility,old.xp
end

do
    local n=DQT.Notifications
    local old={db=DQT.db,xp=DQT.UI.xpRecords,utility=DQT.UI.utility,combat=InCombatLockdown,affect=UnitAffectingCombat,
        popup=StaticPopup_Visible,quest=QuestFrame,gossip=GossipFrame,baseline=n.baseline,waiting=n.waiting,suppressed=n.suppressed,snapshot=n.ChainSnapshot}
    DQT.db={notifications={chains=true}};n.suppressed=false
    InCombatLockdown=function() return false end;UnitAffectingCombat=function() return false end;StaticPopup_Visible=nil;QuestFrame=nil;GossipFrame=nil;DQT.UI.utility=nil
    DQT.UI.xpRecords={IsShown=function() return true end}
    local scans=0;n.ChainSnapshot=function() scans=scans+1;return {} end
    n:Process();assert(n.waiting and scans==0,"XP export window defers notices without scanning quests")
    DQT.UI.xpRecords=nil;n:Process();assert(scans==1 and not n.waiting,"Deferred notice resumes after the export window closes")
    DQT.db,DQT.UI.xpRecords,DQT.UI.utility,InCombatLockdown,UnitAffectingCombat,StaticPopup_Visible,QuestFrame,GossipFrame=old.db,old.xp,old.utility,old.combat,old.affect,old.popup,old.quest,old.gossip
    n.baseline,n.waiting,n.suppressed,n.ChainSnapshot=old.baseline,old.waiting,old.suppressed,old.snapshot
end
print('Review regressions passed: 60 exhaustive graph comparisons, per-context path caching, small-screen fitting and notification deferral')

do
    local old={raid=IsInRaid,count=GetNumGroupMembers,full=UnitFullName}
    IsInRaid=function() return true end
    GetNumGroupMembers=function() return 1000000 end
    local lookups=0
    UnitFullName=function(unit) lookups=lookups+1;return unit,"Realm" end
    assert(not DQT:NormalizePartySender("Outside-Realm") and lookups<=41,"Malformed group counts cannot cause an unbounded roster scan")
    GetNumGroupMembers=function() return "unsupported" end
    assert(pcall(DQT.NormalizePartySender,DQT,"Outside-Realm"),"Malformed optional group API values are harmless")
    IsInRaid,GetNumGroupMembers,UnitFullName=old.raid,old.count,old.full
end
