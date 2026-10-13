const fs = require('node:fs');
const path = require('node:path');
const {createRequire} = require('node:module');
const requireTool = createRequire(path.resolve(process.argv[2], 'package.json'));
const {parseHTML} = requireTool('linkedom');
const {lua,lauxlib,lualib,to_luastring,to_jsstring} = requireTool('fengari');
const root = path.resolve(__dirname,'..');
const addon = path.join(root,'DungeonQuestTrackerForever');
const bootstrap = fs.readFileSync(path.join(root,'Tools','test-level35.lua'),'utf8').split('-- RUN TESTS')[0];
const files = fs.readFileSync(path.join(addon,'DungeonQuestTrackerForever.toc'),'utf8').split(/\r?\n/).filter(file => file.endsWith('.lua'));
const state = lauxlib.luaL_newstate(); lualib.luaL_openlibs(state);
const source = bootstrap + ';\n' + files.map(file => `\n(function(...)\n${fs.readFileSync(path.join(addon,file),'utf8').replace(/^\uFEFF/,'')}\nend)("DungeonQuestTrackerForever",DQT);`).join('');
if (lauxlib.luaL_dostring(state,to_luastring(source)) !== lua.LUA_OK) throw new Error(to_jsstring(lua.lua_tostring(state,-1)));
function plain(index) {
  const kind = lua.lua_type(state,index);
  if (kind === lua.LUA_TSTRING) return to_jsstring(lua.lua_tostring(state,index));
  if (kind === lua.LUA_TNUMBER) return lua.lua_tonumber(state,index);
  if (kind === lua.LUA_TBOOLEAN) return lua.lua_toboolean(state,index);
  if (kind !== lua.LUA_TTABLE) return null;
  const absolute = lua.lua_absindex(state,index), entries = {};
  lua.lua_pushnil(state);
  while (lua.lua_next(state,absolute)) {
    const key = lua.lua_type(state,-2) === lua.LUA_TNUMBER ? lua.lua_tonumber(state,-2) : to_jsstring(lua.lua_tostring(state,-2));
    entries[key] = plain(-1); lua.lua_pop(state,1);
  }
  const keys = Object.keys(entries);
  return keys.length && keys.every((key,index) => Number(key) === index+1) ? Object.values(entries) : entries;
}
lua.lua_getglobal(state,to_luastring('DQT')); lua.lua_getfield(state,-1,to_luastring('quests'));
const quests = plain(-1);
const docs = path.join(root,'Docs'); fs.mkdirSync(docs,{recursive:true});
const cachePath = path.join(docs,'prerequisite-source-cache.json');
const classicPath = path.join(docs,'classic-dungeon-import-cache.json');
const classicCache = fs.existsSync(classicPath) ? JSON.parse(fs.readFileSync(classicPath,'utf8')) : {};
const cache = fs.existsSync(cachePath) ? JSON.parse(fs.readFileSync(cachePath,'utf8')) : {};
const literal = /"(?:\\.|[^"\\])*"/;
async function main() {
  const report = [];
  for (const [key,quest] of Object.entries(quests)) {
    const id = Number(key), url = `https://www.wowhead.com/${quest.classicSourceOnly ? 'classic' : 'forever'}/quest=${id}`;
    try {
      let html = cache[url] || classicCache[url];
      if (!html) {
        const response = await fetch(url,{signal:AbortSignal.timeout(20000)});
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        html = cache[url] = await response.text();
      }
      const document = parseHTML(html).document;
      const requirements = [], alternatives = [];
      for (const table of document.querySelectorAll('table.infobox-inner-table')) {
        const heading = table.querySelector('th')?.textContent.trim();
        if (!heading?.startsWith('Requires')) continue;
        for (const script of table.querySelectorAll('script')) {
          const json = script.textContent.match(literal)?.[0];
          if (!json) continue;
          const ids = [...JSON.parse(json).matchAll(/\[quest=(\d+)/g)].map(match => Number(match[1]));
          (heading === 'Requires' ? requirements : alternatives).push(...ids);
        }
      }
      const rows = [...document.querySelectorAll('table.series tr')];
      const index = rows.findIndex(row => row.querySelector('b'));
      const seriesPrevious = index > 0 ? Number(rows[index-1].querySelector('a[href*="quest="]')?.getAttribute('href').match(/quest=(\d+)/)?.[1]) || null : null;
      const current = Object.values(quest.prerequisites || {});
      const missing = requirements.filter(parent => !current.some(item => item.relationship === 'required' && (item.questID === parent || item.anyOf?.includes(parent))));
      report.push({id,name:quest.name,dungeon:quest.dungeon,classic:!!quest.classicSourceOnly,current,requirements,alternatives,seriesPrevious,missing,url,status:'reviewed'});
    } catch (error) { report.push({id,name:quest.name,url,status:'unavailable',error:error.message}); }
    if (report.length % 25 === 0) {
      fs.writeFileSync(cachePath,JSON.stringify(cache));
      console.log(`Reviewed ${report.length}/${Object.keys(quests).length}`);
    }
  }
  fs.writeFileSync(cachePath,JSON.stringify(cache));
  fs.writeFileSync(path.join(docs,'prerequisite-audit.json'),JSON.stringify(report,null,2));
  for (const row of report) if (row.missing?.length || row.alternatives?.length) console.log(JSON.stringify(row));
  console.log(JSON.stringify({quests:report.length,reviewed:report.filter(row => row.status==='reviewed').length,unavailable:report.filter(row => row.status==='unavailable').length,missing:report.filter(row => row.missing?.length).length,alternatives:report.filter(row => row.alternatives?.length).length}));
}
main().catch(error => {console.error(error);process.exitCode=1;});
