// Produce a translation reference from trusted UI source without editing runtime.
const fs=require('node:fs');
const path=require('node:path');
const {createRequire}=require('node:module');
const dependencies=process.argv[2]||__dirname;
const parser=createRequire(path.resolve(dependencies,'package.json'))('luaparse');
const root=path.resolve(__dirname,'../DungeonQuestTrackerForever');
const files=['Options.lua',...fs.readdirSync(path.join(root,'UI')).filter(name=>name.endsWith('.lua')).map(name=>'UI/'+name)];
const strings=new Set();
function add(value) { if (value?.type==='StringLiteral'&&typeof value.value==='string'&&value.value) strings.add(value.value); }
function walk(node) {
  if (!node||typeof node!=='object') return;
  if (node.type==='IndexExpression'&&(node.base?.name==='L'||node.base?.identifier?.name==='L')) add(node.index);
  if (node.type==='TableKeyString'&&['label','tip','section'].includes(node.key.name)) add(node.value);
  if (node.type==='CallExpression') {
    const name=node.base?.name||node.base?.identifier?.name;
    if (name==='AddTooltip') { add(node.arguments[1]); add(node.arguments[2]); }
    if (name==='CreateButton') add(node.arguments[1]);
    if (name==='ShowUtility') { add(node.arguments[0]); add(node.arguments[1]); }
  }
  for (const value of Object.values(node)) {
    if (Array.isArray(value)) value.forEach(walk); else if (value&&typeof value==='object') walk(value);
  }
}
for (const file of files) walk(parser.parse(fs.readFileSync(path.join(root,file),'utf8').replace(/^\uFEFF/,''),{luaVersion:'5.1',encodingMode:'pseudo-latin1'}));
process.stdout.write(JSON.stringify(Object.fromEntries([...strings].sort().map(key=>[key,key])),null,2)+'\n');
