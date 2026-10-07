do
    local oldContext, oldState, oldComplete, oldZone = DQT.GetPlayerContext, DQT.GetQuestState, DQT.IsQuestComplete, GetRealZoneText
    local oldDB = DQT.db
    local context = {faction="Horde",class="WARRIOR",race="Orc",level=28}
    local states = {}
    DQT.GetPlayerContext = function() return context end
    DQT.IsQuestComplete = function(_,id) return states[id] == "completed" end
    DQT.GetQuestState = function(self,id,quest,player)
        if states[id] then return states[id],states[id] end
        local availability, reason=self:GetQuestAvailability(quest,player)
        return availability=="available" and "missing" or availability,reason
    end
    GetRealZoneText = function() return "Orgrimmar" end
    local function Has(list,id)
        for _, entry in ipairs(list) do
            if entry.questID == id then return true end
            for _, quest in ipairs(entry.quests or {}) do if quest.questID == id then return true end end
        end
        return false
    end
    local route=DQT:GetDungeonPickupRoute("gnomeregan")
    assert(Has(route.stops,2841) and Has(route.stops,2842),"Level 28 Horde Gnomeregan pickups")
    assert(Has(route.blocked,2843) and Has(route.inside,2904),"Blocked teleporter and in-dungeon escort separated")
    states[2841],states[2842]="active","completed"
    route=DQT:GetDungeonPickupRoute("gnomeregan")
    assert(not Has(route.stops,2841) and not Has(route.stops,2842) and Has(route.stops,2843),"Live pickup/prerequisite updates")
    states={}
    route=DQT:GetDungeonPickupRoute("razorfen-kraul")
    assert(Has(route.blocked,1102) and Has(route.blocked,1109),"Level 29/30 Horde quests blocked at 28")
    assert(Has(route.stops,1221) and Has(route.inside,6522),"Available tubers and item start separated")
    for _, key in ipairs(DQT:GetOrderedDungeonKeys()) do
        if DQT.pickupRouteDungeons[key] then
            for _, faction in ipairs({"Horde","Alliance"}) do
                context.faction,context.race=faction,faction=="Horde" and "Orc" or "Human"
                route=DQT:GetDungeonPickupRoute(key)
                for _, stop in ipairs(route.stops) do
                    for _, entry in ipairs(stop.quests) do
                        assert(not entry.quest.faction or entry.quest.faction==faction,"Faction-safe pickups")
                        assert(not entry.quest.minLevel or entry.quest.minLevel<=28,"Level-safe pickups")
                    end
                end
            end
        end
    end
    context.faction,context.race="Alliance","Human"
    route=DQT:GetDungeonPickupRoute("gnomeregan","Ironforge")
    assert(route.zones[1]=="Ironforge","Manual start zone respected")
    states[2922],states[2930],states[2924]="ready","active","completed"
    route=DQT:GetDungeonPickupRoute("gnomeregan")
    assert(not Has(route.stops,2922) and not Has(route.stops,2930) and not Has(route.stops,2924),"Owned quest states excluded")
    local oldDungeon,oldQuests=DQT.dungeons["gnomeregan"],DQT.quests
    DQT.quests={}
    DQT.dungeons["gnomeregan"]={name="Gnomeregan",quests={800001,800002,800003,800004,800005,800006}}
    for id,coordinate in pairs({[800001]="0, 0",[800002]="0, 10",[800003]="10, 10",[800004]="10, 0"}) do
        DQT.quests[id]={name="Test "..id,pickup={name="NPC "..id,zone="Ironforge",coordinates=coordinate}}
    end
    DQT.quests[800005]={name="Shared",pickup={name="NPC 800001",zone="Ironforge",coordinates="0, 0"}}
    DQT.quests[800006]={name="Unknown",pickup={name="Unknown contact",zone="Unknown"}}
    route=DQT:GetDungeonPickupRoute("gnomeregan")
    assert(#route.stops==4 and #route.unknown==1,"Shared stops merged and unknown locations separate")
    local cost=0
    for i=2,#route.stops do
        local a,b=route.stops[i-1],route.stops[i]
        cost=cost+math.sqrt((a.x-b.x)^2+(a.y-b.y)^2)
    end
    assert(math.abs(cost-30)<0.001,"Small coordinate route reaches known minimum")
    for id=800007,800012 do
        DQT.dungeons["gnomeregan"].quests[#DQT.dungeons["gnomeregan"].quests+1]=id
        DQT.quests[id]={name="Horde pickup "..id,faction="Horde",pickup={name="Horde giver "..id,zone="Orgrimmar",coordinates=(id-800007)..", 0"}}
    end
    context.faction,context.race="Horde","Orc"
    GetRealZoneText=function() return "Ironforge" end
    route=DQT:GetDungeonPickupRoute("gnomeregan")
    assert(route.startZone=="Ironforge" and route.automaticStart,"Current zone beats larger remote cluster")
    assert(route.stops[1].location.zone=="Ironforge" and route.startReason:find("current zone",1,true),"Current-zone start and reason")
    GetRealZoneText=function() return "Durotar" end
    route=DQT:GetDungeonPickupRoute("gnomeregan")
    assert(route.startZone=="Orgrimmar","No local pickups uses cluster fallback")
    GetRealZoneText=function() return "Ironforge" end
    route=DQT:GetDungeonPickupRoute("gnomeregan","Ironforge")
    assert(route.startZone=="Ironforge" and not route.automaticStart,"Manual zone overrides faction cluster")
    context.faction,context.race="Alliance","Human"
    route=DQT:GetDungeonPickupRoute("gnomeregan")
    assert(route.startZone=="Ironforge" and not Has(route.stops,800007),"Other faction pickups cannot influence start")
    context.faction,context.race="Horde","Orc"
    for id=800007,800012 do states[id]="active" end
    route=DQT:GetDungeonPickupRoute("gnomeregan")
    assert(route.startZone=="Ironforge","Collecting cluster quests changes suggested start")
    states={}
    -- Equal-size remote stops must not beat a tightly grouped set solely on count.
    for id=800007,800012 do DQT.quests[id].pickup.coordinates=tostring((id-800007)*20)..", 0" end
    route=DQT:GetDungeonPickupRoute("gnomeregan")
    assert(route.startZone=="Ironforge","Nearby cluster matters more than distant quest count")
    DQT.quests,DQT.dungeons["gnomeregan"]=oldQuests,oldDungeon
    states={}
    GetRealZoneText=function() error("Unavailable zone") end
    assert(pcall(DQT.GetDungeonPickupRoute,DQT,"gnomeregan"),"Missing zone API guarded")
    DQT.db={display={compact=false},filters={}}
    DQT.UI.currentDungeonKey="gnomeregan"
    DQT.UI:ShowPickups()
    assert(DQT.UI.currentView=="pickups" and DQT.UI.frame.pickupButton:IsShown(),"Pickup navigation")
    assert(DQT.UI.frame.turnInContent:GetHeight()>=DQT.UI.frame.content:GetHeight(),"Pickup content scrolls")
    DQT.UI:ShowOptions()
    DQT.UI:CloseOptions()
    assert(DQT.UI.currentView=="pickups","Options returns to pickups")
    DQT.db.display.compact=true
    DQT.UI:RefreshCurrentDungeon()
    assert(DQT.UI.frame:GetWidth()==520 and DQT.UI.frame.turnInRows[1].detail:IsShown(),"Compact retains pickup locations")
    DQT.UI.frame.primaryButton.scripts.OnClick()
    assert(DQT.UI.currentView=="checklist","Back returns to selected dungeon")
    DQT.db=oldDB
    DQT.GetPlayerContext,DQT.GetQuestState,DQT.IsQuestComplete,GetRealZoneText=oldContext,oldState,oldComplete,oldZone
end
print("Pickup routes passed: level 28 factions, states/chains, shared stops, ordering, missing APIs, navigation, compact and scrolling")
