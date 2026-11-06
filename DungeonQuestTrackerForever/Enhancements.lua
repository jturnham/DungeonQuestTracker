local _,DQT=...
local function Safe(fn,...)
    if type(fn)~="function" then return end
    local ok,a,b=pcall(fn,...)
    if ok then return a,b end
end
DQT.SafeOptional=Safe
local function Clean(text,limit)
    return tostring(text or "unknown"):gsub("[%c|]"," "):sub(1,limit or 240)
end
function DQT:CharacterKey()
    local _,key=self.Travel:Character()
    return key or "session"
end
function DQT:FavoriteRecords()
    self.db.favorites=type(self.db.favorites)=="table" and self.db.favorites or {}
    local key=self:CharacterKey()
    self.db.favorites[key]=type(self.db.favorites[key])=="table" and self.db.favorites[key] or {}
    return self.db.favorites[key]
end
function DQT:IsFavorite(key) return self.db and self:FavoriteRecords()[key]==true end
function DQT:ToggleFavorite(key)
    if not self.db or not self.dungeons[key] then return false end
    local records=self:FavoriteRecords()
    records[key]=not records[key] or nil
    self:RequestUIRefresh()
    return true
end
function DQT:GetListDungeonKeys()
    local keys=self:GetOrderedDungeonKeys()
    if self:GetOption("display.favoritesFirst") then
        local order={}
        for index,key in ipairs(keys) do order[key]=index end
        table.sort(keys,function(a,b)
            local left,right=self:IsFavorite(a),self:IsFavorite(b)
            if left~=right then return left end
            return order[a]<order[b]
        end)
    end
    return keys
end
local function ProfileOption(key)
    return key:match("^display%.") or key:match("^filters%.") or key:match("^lootReminders%.") or key:match("^pickups%.") or key:match("^travel%.") or key=="minimap.hide"
end
function DQT:ProfileSnapshot()
    local values={}
    for _,option in ipairs(self.optionDefinitions) do
        if option.key and ProfileOption(option.key) then values[option.key]=self:GetOption(option.key) end
    end
    return values
end
function DQT:SaveActiveProfile()
    if not self.db or self.loadingProfile then return end
    self.db.profiles=type(self.db.profiles)=="table" and self.db.profiles or {}
    self.db.profiles[self.activeProfile or "Default"]=self:ProfileSnapshot()
end
local function ProfileName(name)
    return type(name)=="string" and #name>0 and #name<=32 and name:match("^[%w _%-]+$") and name:match("%S")
end
function DQT:UseProfile(name)
    if not self.db or not ProfileName(name) or type(self.db.profiles[name])~="table" then return false end
    self:SaveActiveProfile()
    self.loadingProfile=true
    local saved=self.db.profiles[name]
    -- Validate through the same definitions as Options; missing fields use defaults.
    for _,option in ipairs(self.optionDefinitions) do
        local key=option.key
        if key and ProfileOption(key) then
            local group,field=key:match("^(%w+)%.(%w+)$")
            local value=saved[key]
            if option.number then
                if type(value)~="number" or value~=value or math.abs(value)==math.huge then value=self.defaults[group][field] end
                value=math.max(option.min or 0,math.min(option.max or 60,math.floor(value)))
            elseif type(value)~="boolean" then value=self.defaults[group][field] end
            self.db[group]=type(self.db[group])=="table" and self.db[group] or {}
            self.db[group][field]=value
        end
    end
    self.activeProfile=name
    self.db.characterProfiles[self:CharacterKey()]=name
    self.loadingProfile=nil
    self:SaveActiveProfile()
    self:ApplyOptions()
    return true
end
function DQT:CreateProfile(name)
    if not self.db or not ProfileName(name) or self.db.profiles[name] then return false end
    local count=0; for _ in pairs(self.db.profiles) do count=count+1 end
    if count>=20 then return false end
    self.db.profiles[name]=self:ProfileSnapshot()
    return true
end
function DQT:DeleteProfile(name)
    if not self.db or name=="Default" or name==self.activeProfile or not self.db.profiles[name] then return false end
    self.db.profiles[name]=nil
    for key,value in pairs(self.db.characterProfiles) do if value==name then self.db.characterProfiles[key]="Default" end end
    return true
end
function DQT:InitializeEnhancements()
    self.db.profiles=type(self.db.profiles)=="table" and self.db.profiles or {}
    self.db.characterProfiles=type(self.db.characterProfiles)=="table" and self.db.characterProfiles or {}
    if type(self.db.profiles.Default)~="table" then self.db.profiles.Default=self:ProfileSnapshot() end
    local selected=self.db.characterProfiles[self:CharacterKey()]
    if not selected or type(self.db.profiles[selected])~="table" then selected="Default" end
    self.activeProfile=nil
    -- The pre-load working settings belong to the previous session, not selected.
    self.loadingProfile=true
    self:UseProfile(selected)
end
function DQT:ProfileSummary()
    local names={}
    for name in pairs(self.db.profiles or {}) do names[#names+1]=name end
    table.sort(names)
    return "Current: "..(self.activeProfile or "Default").."\nProfiles: "..table.concat(names,", ").."\n\nCreate copies current presentation/filter/travel preferences. Flight knowledge, bind locations, XP records, party consent and favorites are not copied.\nUse selects a profile for this character. Default and the active profile cannot be deleted."
end
function DQT:BuildBugReport(id,expected,actual)
    local _,build=Safe(GetBuildInfo)
    local context=self:PrepareQuestScan(self:GetPlayerContext())
    local lines={"DQT diagnostic report v1","Addon: "..Clean(self.version),"Build: "..Clean(build),
        "Expected: "..Clean(expected,300),"Actual: "..Clean(actual,300),"Dungeon: "..Clean(self.UI and self.UI.currentDungeonKey),
        "View: "..Clean(self.UI and self.UI.currentView),"Level: "..tostring(context.level),
        "APIs: questLog="..tostring(type(C_QuestLog and C_QuestLog.GetInfo)=="function")..", map="..tostring(type(C_Map and C_Map.GetBestMapForUnit)=="function")}
    if id~=nil then
        local quest=type(id)=="number" and self.quests[id]
        if quest then
            local state=self:GetQuestState(id,quest,context)
            local xp,source=self:GetQuestRewardXP(quest)
            lines[#lines+1]="Quest: "..id.." | state="..Clean(state).." | XP="..(self:IsQuestRewardXPKnown(quest) and tostring(xp) or "unknown").." | "..Clean(source)
            lines[#lines+1]="Source: "..Clean(quest.xpSource or quest.source,400)
        else lines[#lines+1]="Quest: unknown or invalid ID" end
    end
    for _,option in ipairs(self.optionDefinitions) do
        if option.key then lines[#lines+1]=option.key.."="..tostring(self:GetOption(option.key)) end
    end
    lines[#lines+1]="No automatic submission. Review before copying; omit personal details from Expected/Actual."
    return table.concat(lines,"\n"):sub(1,12000)
end
function DQT:PartyReadiness(key)
    local dungeon=self:GetDungeon(key)
    if not dungeon then return "Select a dungeon first." end
    local members={}
    local raid=Safe(IsInRaid)
    local count=raid and Safe(GetNumGroupMembers) or Safe(GetNumSubgroupMembers) or Safe(GetNumPartyMembers) or 0
    for index=1,math.min(40,tonumber(count) or 0) do
        local name,realm=Safe(UnitFullName or UnitName,(raid and "raid" or "party")..index)
        if type(name)=="string" then
            local full=name..(type(realm)=="string" and realm~="" and ("-"..realm:gsub("[%s%-]","")) or "")
            local normalized=self:NormalizePartySender(full)
            if normalized then members[#members+1]=normalized end
        end
    end
    table.sort(members)
    local context=self:PrepareQuestScan(self:GetPlayerContext())
    local now=Safe(GetTime) or Safe(time) or 0
    local entries=self.partyStatus and self.partyStatus[key] or {}
    local lines={dungeon.name.." | Party readiness", "Snapshot: refresh to update. Replies older than 120 seconds are stale.",
        "No response means unknown; it does not establish that an addon is missing.",""}
    if #members==0 then lines[#lines+1]="Solo or no identifiable group members." end
    for _,id in ipairs(dungeon.quests or {}) do
        local quest=self:GetQuest(id)
        if quest then
            lines[#lines+1]=quest.name.." ("..id..")"
            lines[#lines+1]="You: "..self:GetQuestState(id,quest,context)
            for _,name in ipairs(members) do
                local entry=entries[name]
                local age=entry and type(entry.time)=="number" and now-entry.time
                local state=entry and entry.quests and entry.quests[id]
                local text=age and age>=0 and (age<=120 and (state or "unknown / partial reply") or "stale") or "unknown / no response"
                lines[#lines+1]=Clean(name,100)..": "..text
            end
            lines[#lines+1]=""
        end
    end
    return table.concat(lines,"\n")
end
