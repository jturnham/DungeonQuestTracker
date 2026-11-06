local _,DQT=...
-- UI strings use English source keys. Missing translations always retain English.
-- Quest, NPC, zone and taxi names are data, never translated by this table.
local locales={enUS={},enGB={}}
local locale="enUS"
if type(GetLocale)=="function" then local ok,value=pcall(GetLocale); if ok and type(value)=="string" then locale=value end end
DQT.L=setmetatable({}, {__index=function(_,key) return (locales[locale] and locales[locale][key]) or key end})
function DQT:RegisterLocale(name,strings)
    if type(name)~="string" or type(strings)~="table" then return false end
    locales[name]=locales[name] or {}
    for key,value in pairs(strings) do
        if type(key)=="string" and type(value)=="string" and #value<2000 then locales[name][key]=value end
    end
    return true
end
