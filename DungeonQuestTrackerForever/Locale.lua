local _,DQT=...
-- UI strings use English source keys. Missing translations always retain English.
-- Quest, NPC, zone and taxi names are data, never translated by this table.
local locales={enUS={},enGB={}}
local locale="enUS"
if type(GetLocale)=="function" then local ok,value=pcall(GetLocale); if ok and type(value)=="string" then locale=value end end
DQT.L=setmetatable({}, {__index=function(_,key) return (locales[locale] and locales[locale][key]) or key end})
local function Signature(text)
    local signature,index={},1
    while true do
        local start=text:find("%",index,true)
        if not start then return table.concat(signature,",") end
        if text:sub(start+1,start+1)=="%" then index=start+2
        else
            local token,kind=text:sub(start):match("^(%%[-+ #0]*%d*%.?%d*([cdiouxXeEfgGqs]))")
            if not token then return nil end
            local width,precision=token:match("^%%[-+ #0]*(%d*)%.?(%d*)")
            if (tonumber(width) or 0)>200 or (tonumber(precision) or 0)>200 then return nil end
            signature[#signature+1]=kind=="i" and "d" or kind
            index=start+#token
        end
    end
end
function DQT:Translate(key,name)
    return (locales[name or locale] and locales[name or locale][key]) or key
end
function DQT:Format(key,...)
    return string.format(self:Translate(key),...)
end
function DQT:RegisterLocale(name,strings)
    if type(name)~="string" or not name:match("^%a%a%u%u$") or type(strings)~="table" then return false end
    local count=0
    for key,value in pairs(strings) do
        count=count+1
        if count>2000 or type(key)~="string" or type(value)~="string" or #key>=2000 or #value>=2000
            or not Signature(key) or Signature(key)~=Signature(value) then return false end
    end
    locales[name]=locales[name] or {}
    for key,value in pairs(strings) do
        locales[name][key]=value
    end
    return true
end
function DQT:GetLocaleInfo(name)
    local result={locale=name or locale,translated=0,fallback="enUS"}
    for _ in pairs(locales[result.locale] or {}) do result.translated=result.translated+1 end
    return result
end
