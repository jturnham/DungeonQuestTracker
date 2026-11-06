const fs=require('node:fs'),path=require('node:path'),{createRequire}=require('node:module');
const requireTool=createRequire(path.resolve(process.argv[2]||__dirname,'package.json'));
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=requireTool('fengari');
const root=path.resolve(__dirname,'../DungeonQuestTrackerForever');
for(const locale of ['enUS','frFR','deDE','esES','esMX','koKR']){
 const sources=['Locale.lua','Locales.lua'].map(file=>`(function(...)\n${fs.readFileSync(path.join(root,file),'utf8')}\nend)("DungeonQuestTrackerForever",DQT);`).join('\n');
 const script=`DQT={};GetLocale=function() return ${JSON.stringify(locale)} end\n${sources}\n`+`
 assert(DQT.L['An untranslated quest name']=='An untranslated quest name','Identity strings retain source values')
 assert(DQT:GetLocaleInfo().locale=='${locale}')
 assert(DQT:RegisterLocale('zzZZ',{['Count: %d / %s']='Total : %d / %s',['Literal %% %s']='Texte %% %s'}))
 assert(not DQT:RegisterLocale('zzZZ',{['Count: %d / %s']='Total: %s / %d'}),'Reject reordered or changed argument types')
 assert(not DQT:RegisterLocale('zzZZ',{['Safe']='Changed',['Bad %d']='Bad %n'}),'Unsupported format rejected atomically')
 assert(DQT:Translate('Safe','zzZZ')=='Safe','No partial pack installation')
 assert(not DQT:RegisterLocale('invalid',{}))
 assert(not DQT:RegisterLocale('zzZZ',{['Missing %s']='Missing'}))
 assert(not DQT:RegisterLocale('zzZZ',{['Value %s']='Value %999999999s'}),'Reject excessive format allocation')
 assert(not DQT:RegisterLocale('zzZZ',{['Value %f']='Value %.999999999f'}),'Reject excessive precision')
 assert(DQT:Translate('Count: %d / %s','zzZZ')=='Total : %d / %s','Keep previous valid dictionary')
 assert(DQT:Format('You: %s','ready'):find('ready',1,true),'Format arguments preserved')
 `+(locale==='enUS'||locale==='koKR'?`assert(DQT.L['Tools']=='Tools','English fallback')`:`assert(DQT.L['Tools']~='Tools' and DQT:GetLocaleInfo().translated>=50,'Bundled partial pack is selected')`);
 const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
 if(lauxlib.luaL_dostring(L,to_luastring(script))!==lua.LUA_OK)throw Error(locale+': '+to_jsstring(lua.lua_tostring(L,-1)));
 lua.lua_close(L);
}
console.log('Locales passed: client selection, French/German/Spanish packs, English fallback, identity preservation and atomic format validation');
