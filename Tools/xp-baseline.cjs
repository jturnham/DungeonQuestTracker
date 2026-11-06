// Load only trusted repository data, never any submitted Lua or report contents.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { createRequire } = require('node:module');
function loadBaseline(dependencyDirectory) {
  const requireTool = createRequire(path.resolve(dependencyDirectory, 'package.json'));
  const { lua, lauxlib, lualib, to_luastring, to_jsstring } = requireTool('fengari');
  const root = path.resolve(__dirname, '..');
  const addon = path.join(root, 'DungeonQuestTrackerForever');
  const toc = fs.readFileSync(path.join(addon, 'DungeonQuestTrackerForever.toc'), 'utf8');
  const files = toc.split(/\r?\n/).filter(file => file === 'Config.lua' || /^Data\/[A-Za-z0-9]+\.lua$/.test(file));
  const hash = crypto.createHash('sha256');
  const sources = files.map(file => {
    const source = fs.readFileSync(path.join(addon, file), 'utf8').replace(/^\uFEFF/,'');
    hash.update(file).update('\0').update(source.replace(/\r\n/g, '\n')).update('\0');
    return `(function(...)\n${source}\nend)("DungeonQuestTrackerForever",DQT);`;
  });
  const script = 'DQT={}\n' + sources.join('\n') + `
    local rows={}
    for id,q in pairs(DQT.quests) do
      local kind=q.xpGuide and "published-guide-provisional" or q.xpPublished and "published" or q.xpReported and "player-report" or q.xpEstimate and "estimate" or q.xpOutdated and "outdated" or q.foreverXp and "forever-unverified" or q.classicXp and "classic-fallback" or "unknown"
      local required={}
      for _,p in ipairs(q.prerequisites or {}) do if p.relationship=="required" and p.questID and not p.anyOf then required[#required+1]=p.questID end end
      rows[#rows+1]={id=id,name=q.name,dungeon=q.dungeon,requires=table.concat(required,","),questLevel=q.questLevel or -1,minLevel=q.minLevel or -1,
        xp=q.foreverXp or q.classicXp or -1,kind=kind,source=q.xpSource or q.source or "unknown"}
    end
    rows.__dungeons={}
    for key,dungeon in pairs(DQT.dungeons) do rows.__dungeons[key]=table.concat(dungeon.quests,",") end
    return rows
  `;
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  const status = lauxlib.luaL_dostring(L, to_luastring(script));
  if (status !== lua.LUA_OK) throw new Error(to_jsstring(lua.lua_tostring(L, -1)));
  const rows = new Map();
  for (let i=1;i<=lua.lua_rawlen(L,-1);i++) {
    lua.lua_rawgeti(L,-1,i);
    const row={};
    for (const key of ['id','name','dungeon','requires','questLevel','minLevel','xp','kind','source']) {
      lua.lua_getfield(L,-1,to_luastring(key));
      row[key]=lua.lua_type(L,-1)===lua.LUA_TNUMBER ? lua.lua_tonumber(L,-1) : to_jsstring(lua.lua_tostring(L,-1));
      lua.lua_pop(L,1);
    }
    rows.set(row.id,row);
    lua.lua_pop(L,1);
  }
  const dungeons=new Map();
  lua.lua_getfield(L,-1,to_luastring('__dungeons'));
  lua.lua_pushnil(L);
  while(lua.lua_next(L,-2)) {
    const key=to_jsstring(lua.lua_tostring(L,-2)),ids=to_jsstring(lua.lua_tostring(L,-1));
    dungeons.set(key,ids?ids.split(',').map(Number):[]);
    lua.lua_pop(L,1);
  }
  lua.lua_close(L);
  return {rows,dungeons,digest:hash.digest('hex')};
}
module.exports={loadBaseline};
