const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');
const requireTool = createRequire(path.resolve(process.argv[2] || '.', 'package.json'));
const parser = requireTool('luaparse');
const addon = path.resolve(__dirname, '..', 'DungeonQuestTrackerForever');
const files = fs.readFileSync(path.join(addon, 'DungeonQuestTrackerForever.toc'), 'utf8')
  .split(/\r?\n/).filter(line => line.endsWith('.lua'));
const questIDs = new Map();
const errors = [];
for (const file of files) {
  const tree = parser.parse(fs.readFileSync(path.join(addon, file), 'utf8').replace(/^\uFEFF/, ''),
    { luaVersion: '5.1', locations: true, encodingMode: 'pseudo-latin1' });
  function walk(node) {
    if (!node || typeof node !== 'object') return;
    if (file === 'Data/QuestDataBeta30.lua' && node.type === 'LocalStatement'
      && node.variables.some(variable => variable.name === 'rows')) {
      for (const field of node.init[0].fields) {
        const id = field.value.fields[0].value.value;
        const location = `${file}:${field.loc.start.line}`;
        if (questIDs.has(id)) errors.push(`${location}: duplicate quest ID ${id} (first at ${questIDs.get(id)})`);
        questIDs.set(id, location);
      }
    }
    if (node.type === 'TableConstructorExpression') {
      const seen = new Set();
      for (const field of node.fields) {
        const key = field.type === 'TableKeyString' ? field.key.name
          : field.type === 'TableKey' && /^(Numeric|String)Literal$/.test(field.key.type) ? field.key.value : undefined;
        if (key === undefined) continue;
        const token = typeof key + ':' + key;
        const location = `${file}:${field.loc.start.line}`;
        if (seen.has(token)) errors.push(`${location}: duplicate table key ${key}`);
        seen.add(token);
        if (typeof key === 'number' && field.value.type === 'TableConstructorExpression'
          && field.value.fields.some(item => item.type === 'TableKeyString' && item.key.name === 'name')) {
          if (questIDs.has(key)) errors.push(`${location}: duplicate quest ID ${key} (first at ${questIDs.get(key)})`);
          questIDs.set(key, location);
        }
      }
    }
    for (const [key, value] of Object.entries(node)) {
      if (key === 'loc') continue;
      if (Array.isArray(value)) value.forEach(walk);
      else if (value && typeof value === 'object') walk(value);
    }
  }
  walk(tree);
}
if (errors.length) throw new Error(errors.join('\n'));
console.log(`Static data validation passed: ${questIDs.size} unique quest records; ${files.length} Lua 5.1 files; no duplicate table keys.`);
