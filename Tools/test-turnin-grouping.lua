do
    local function Item(id,xp,zone,subzone,level)
        local quest={name="Quest "..id,questLevel=level or 28,foreverXp=xp,turnIn={name="NPC "..id,zone=zone,subzone=subzone}}
        return DQT:BuildTurnInItem({questID=id,quest=quest},"test",{name="Test"},{level=28,currentXp=0,maxXp=10000},10000)
    end
    local context={level=28,currentXp=0,maxXp=10000}
    local items={Item(1,1000,"Undercity","Apothecarium"),Item(2,900,"Thunder Bluff","Elder Rise"),Item(3,800,"Undercity","Apothecarium"),Item(4,700,"Undercity","Royal Quarter")}
    DQT:GroupTurnInsByLocation(items,context)
    assert(items[1].questID==1 and items[2].questID==3 and items[2].locationGrouped,"Same area clustered when safe")
    assert(items[3].questID==2,"Different subzones are not one stop")
    for _, level in ipairs({26,23}) do
        items={Item(1,1000,"Undercity","Apothecarium"),Item(2,100,"Thunder Bluff","Elder Rise",level),Item(3,800,"Undercity","Apothecarium")}
        DQT:GroupTurnInsByLocation(items,{level=28,currentXp=8300,maxXp=10000})
        assert(items[2].questID==2,"Do not delay green/gray-risk quest across level-up")
    end
    items={Item(1,500,"Undercity","Apothecarium"),Item(2,500,"Thunder Bluff","Elder Rise"),Item(3,100,"Orgrimmar","Drag",26),Item(4,300,"Undercity","Apothecarium")}
    DQT:GroupTurnInsByLocation(items,{level=28,currentXp=8700,maxXp=10000})
    assert(items[2].questID==2 and items[3].questID==3,"Cumulative skipped awards protect later quest")
    items={Item(1,1000,"Undercity","Apothecarium"),Item(2,900,"Thunder Bluff","Elder Rise"),Item(3,800,"Undercity","Apothecarium")}
    DQT:GroupTurnInsByLocation(items,{level=28,currentXp=0,maxXp=0})
    assert(items[2].questID==2,"Unknown/capped XP retains original order")
    DQT:GroupTurnInsByLocation(items,{level=28,currentXp=9500,maxXp=10000})
    assert(items[2].questID==2,"No grouping after projected level-up")
    items={Item(1,10,"Unknown","Unknown"),Item(2,9,"Thunder Bluff","Elder Rise"),Item(3,8,"Unknown","Unknown")}
    DQT:GroupTurnInsByLocation(items,context)
    assert(items[2].questID==2,"Unknown destinations never grouped")
    items={Item(1,100,"Undercity","Apothecarium"),Item(2,90,"Thunder Bluff","Elder Rise"),Item(3,80,"Undercity","Apothecarium")}
    items[2].xpSource="unknown"
    DQT:GroupTurnInsByLocation(items,context)
    assert(items[2].questID==2,"Unknown awards cannot establish safe reordering")
end
print("Turn-in grouping passed: same stops, cumulative XP protection, green/gray risk, unknown/capped XP and destination isolation")
