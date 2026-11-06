const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const os=require('node:os');
const {validateCandidate,writeProposal}=require('./data-proposal.cjs');
const {parseIndex,parseConnections}=require('./travel-parser.cjs');
const {createRequire}=require('node:module');
const dependencies=process.argv[2];
const {load}=createRequire(path.resolve(dependencies,'package.json'))('cheerio');
const index='<table><tr><th>Flight point</th><th>Zone</th><th>Faction</th><th>Other</th></tr><tr><td><a href="/wiki/A">A</a></td><td>Zone A</td><td>Horde</td><td></td></tr><tr><td><a href="/wiki/B">B</a></td><td>Zone B</td><td>Horde</td><td></td></tr></table>';
const nodes=parseIndex(load(index),'https://example.com');
assert.equal(nodes.length,2);
const connections='<div class="mw-heading"><h2 id="Flight_connections">Flight connections</h2></div><table><tr><th>Destination</th><th>Fare</th></tr><tr><td>B</td><td data-sort-value="330">fare</td></tr></table><div class="mw-heading">Next</div>';
assert.equal(parseConnections(load(connections),'https://example.com/wiki/A',nodes)[0].fare,330);
assert.throws(()=>parseIndex(load(index.replace('/wiki/A','https://attacker.example/wiki/A')),'https://example.com'));
assert.throws(()=>parseConnections(load(connections.replace('"330"','"-1"')),'https://example.com/wiki/A',nodes));
const candidate='local _,DQT=...; DQT.quests={[1]={name="Test",questLevel=15,minLevel=10,foreverXp=500,coordinates="50, 60"}}';
assert.deepEqual(validateCandidate(candidate,dependencies).questIDs,[1]);
for (const source of ['not Lua',candidate.replace('50, 60','150, 60'),candidate.replace('foreverXp=500','foreverXp=-5'),candidate.replace('questLevel=15','questLevel=15,questLevel=16')]) {
  assert.throws(()=>validateCandidate(source,dependencies));
}
const root=fs.mkdtempSync(path.join(os.tmpdir(),'dqt-proposal-'));
try {
  const runtime=path.join(root,'DungeonQuestTrackerForever','Data');
  fs.mkdirSync(runtime,{recursive:true});
  fs.writeFileSync(path.join(runtime,'QuestData.lua'),'unchanged');
  const result=writeProposal({root,relativePath:'Data/QuestData.lua',content:candidate,sources:['https://example.com/source'],dependencies});
  assert.equal(fs.readFileSync(path.join(runtime,'QuestData.lua'),'utf8'),'unchanged');
  assert.equal(result.manifest.confidence,'provisional');
  assert.equal(result.manifest.build,'unknown');
  assert.equal(fs.readFileSync(result.candidate,'utf8'),candidate);
  assert.throws(()=>writeProposal({root,relativePath:'../bad.lua',content:candidate,sources:['https://example.com'],dependencies}));
} finally {
  // Verify the absolute target is the unique test tree before recursive cleanup.
  const resolved=path.resolve(root),parent=path.resolve(os.tmpdir());
  if (path.dirname(resolved)!==parent||!path.basename(resolved).startsWith('dqt-proposal-')) throw new Error('Unsafe test cleanup');
  fs.rmSync(resolved,{recursive:true,force:true});
}
console.log('Data proposals passed: syntax, duplicate/value/coordinate validation, provenance, unchanged production and bounded proposal paths');
