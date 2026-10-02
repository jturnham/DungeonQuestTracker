const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');

// Supply a directory containing fengari and luaparse; these are development tools only.
const requireTool = createRequire(path.resolve(process.argv[2] || '.', 'package.json'));
const parser = requireTool('luaparse');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = requireTool('fengari');
const root = path.resolve(__dirname, '..');
const addon = path.join(root, 'DungeonQuestTrackerForever');
const files = fs.readFileSync(path.join(addon, 'DungeonQuestTrackerForever.toc'), 'utf8')
  .split(/\r?\n/).filter(line => line.endsWith('.lua'));
const sources = files.map(file => {
  const source = fs.readFileSync(path.join(addon, file), 'utf8').replace(/^\uFEFF/, '');
  parser.parse(source, { luaVersion: '5.1' });
  return `(function(...)\n${source}\nend)("DungeonQuestTrackerForever", DQT);`;
});
const prelude = fs.readFileSync(path.join(__dirname, 'test-level35.lua'), 'utf8');
const split = prelude.indexOf('-- RUN TESTS');
const extraTests = process.argv.slice(3).map(file => fs.readFileSync(path.resolve(file), 'utf8')).join('\n');
const script = prelude.slice(0, split) + '\n' + sources.join('\n') + '\n' + prelude.slice(split) + '\n' + extraTests;
const state = lauxlib.luaL_newstate();
lualib.luaL_openlibs(state);
const result = lauxlib.luaL_dostring(state, to_luastring(script));
if (result !== lua.LUA_OK) {
  throw new Error(to_jsstring(lua.lua_tostring(state, -1)));
}
console.log(`Lua 5.1 syntax passed for ${files.length} addon files.`);
