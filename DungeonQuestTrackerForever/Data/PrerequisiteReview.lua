local _, DQT = ...

local added = {[9032] = {
    name="Bodley's Unfortunate Fate",dungeon="blackrock-depths",faction="Horde",minLevel=58,questLevel=60,
    followUpOf=9016,classicXp=1650,classicSourceOnly=true,verifiedForever=false,
    pickup={name="Mokvar",zone="Orgrimmar"},turnIn={name="Bodley",zone="Blackrock Mountain",subzone="Near Blackrock Spire; requires the Extra-Dimensional Ghost Revealer"},
    objectives="Use the ghost revealer to find Bodley near Blackrock Spire.",
    prerequisites={},source="https://www.wowhead.com/classic/quest=9032",
}}
for id, quest in pairs(added) do
    DQT.quests[id] = quest
    table.insert(DQT.dungeons[quest.dungeon].quests,id)
end

-- October 12 source sweep. Classic gates remain provisional for Forever.
for _, id in ipairs({3982,4001,4002,4003,4004,4242,4263,4282,4361,4363,4743,4765,4983,5002,5081,5213,5464,7509,7644,7877,8946,8949,8950,8996}) do
    for _, prereq in ipairs(DQT.quests[id].prerequisites) do
        if prereq.relationship == "breadcrumb" then
            prereq.relationship = "required"
            prereq.note = "Complete the preceding Classic chain step; Forever eligibility still needs confirmation."
        end
    end
end
local required = {[1654]=1653,[5728]=5727,[7647]=7646,[6569]=6568,[8948]=8947,[8995]=8994}
for id, parent in pairs(required) do
    DQT.quests[id].prerequisites = {{questID=parent,relationship="required",external=true,note="Complete the preceding chain step (#" .. parent .. "). Source reviewed October 12; confirm beta eligibility."}}
end
local alternatives = {
    [3444]={3380,3445},
    [4024]={4022,4023},
    [8960]={8951,8952,8953,8954,8955,8956,8958,8959},
    [9032]={9016,9017,9018,9019,9020,9021,9022,8957},
    [8961]={8960,9032},
    [8966]={8962,8963,8964,8965}, [8967]={8962,8963,8964,8965},
    [8968]={8962,8963,8964,8965}, [8969]={8962,8963,8964,8965},
    [8970]={8967,8966,8968,8969},
    [8989]={8985,8986,8987,8988}, [8990]={8985,8986,8987,8988},
    [8991]={8985,8986,8987,8988}, [8992]={8985,8986,8987,8988},
    [8994]={8990,8989,8991,8992},
}
for id, ids in pairs(alternatives) do
    DQT.quests[id].prerequisites = {{questID=ids[1],anyOf=ids,relationship="required",external=true,note="Complete the applicable faction/class branch, not every alternative. Classic-source gate; confirm in Forever."}}
end
DQT.quests[2842].prerequisites = {{questID=2841,state="active",relationship="required",note="Keep Rig Wars in your quest log to receive Sovik's teleporter lead-in; turning it in is not the prerequisite."}}
DQT.quests[95042].prerequisites = {{questID=95036,state="active",relationship="required",note="Have A Moon-Kissed Blade in your quest log while obtaining and purifying the Kor Gem."}}
for _, quest in pairs(DQT.quests) do
    for _, prereq in ipairs(quest.prerequisites or {}) do
        if prereq.questID then
            local parent = DQT.quests[prereq.questID]
            local name = parent and parent.name or ("Quest #" .. prereq.questID)
            local label = prereq.anyOf and "Required: one applicable branch" or prereq.relationship == "breadcrumb" and "Optional: " .. name or "Required: " .. name
            if prereq.state == "active" then label = label .. " (in your quest log)" end
            if prereq.anyOf then
                local names = {}
                for _, id in ipairs(prereq.anyOf) do names[#names+1] = (DQT.quests[id] and DQT.quests[id].name or "Quest") .. " (#" .. id .. ")" end
                label = label .. ": " .. table.concat(names, " or ")
            end
            prereq.note = label .. ". " .. (prereq.note or "")
        elseif prereq.note then
            prereq.note = (prereq.relationship == "required" and "Required (details awaiting verification): " or "Optional: ") .. prereq.note
        end
    end
end
