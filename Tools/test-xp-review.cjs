const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const os=require('node:os');
const {spawnSync}=require('node:child_process');
const {parseExport,review,columns}=require('./review-xp.cjs');
const {loadBaseline}=require('./xp-baseline.cjs');
const baseline=loadBaseline(process.argv[2]);
assert.equal(baseline.rows.size,493);
assert.match(baseline.digest,/^[a-f0-9]{64}$/);
assert.equal(baseline.rows.get(95216).xp,5450,'Known published point must include metadata corrections');
assert.equal(baseline.rows.get(95216).kind,'published');
assert.equal(baseline.rows.get(92457).xp,9400,'Later source correction must survive baseline generation');
assert.match(baseline.rows.get(92457).source,/wowforevertalents/);
const known=baseline.rows.get(5722);
const now=Math.floor(Date.now()/1000);
const row={questID:5722,build:70374,addonVersion:'0.6.0',capturedAt:now,levelBefore:16,levelAtEvent:16,xpBefore:12000,xpAtEvent:12000,xpMaxBefore:20000,eventXP:known.xp,displayedXP:known.xp,modifiers:'unknown'};
function encode(rows) { return ['DQT-XP-OBSERVATIONS\t1',columns.join('\t'),...rows.map(value=>columns.map(key=>value[key]).join('\t'))].join('\n'); }
function run(rows) { return review([{name:'test.txt',text:encode(rows)}],baseline,70374,now); }
let report=run([row,{...row}]);
assert.equal(report.uniqueRows,1);
assert.equal(report.findings[0].comparison,'matches-bundled-raw-value');
assert.equal(report.findings[0].eligibleForAutoImport,false);
assert.equal(report.groups[0].independentContributors,'unknown');
report=run(Array.from({length:100},(_,i)=>({...row,capturedAt:now-i})));
assert(report.findings.every(finding=>!finding.eligibleForAutoImport),'Forged report volume must never create approval');
assert.equal(report.groups[0].independentContributors,'unknown');
report=run([row,{...row,capturedAt:now-1,eventXP:known.xp+1,displayedXP:known.xp+1}]);
assert.equal(report.groups[0].conflictingRewards,true);
assert(report.findings[1].flags.includes('bundled-reference-conflict'));
for (const patch of [{build:70375},{questID:9999999},{capturedAt:now+90000},{displayedXP:known.xp+1},{xpBefore:21000}]) {
  assert.equal(run([{...row,...patch}]).findings[0].disposition,'quarantined');
}
for (const patch of [{levelBefore:-1},{eventXP:0,displayedXP:0},{levelBefore:60},{capturedAt:now-91*86400}]) {
  assert.equal(run([{...row,...patch}]).findings[0].eligibleForAutoImport,false);
}
for (const value of ['os.execute("malicious")','DQT-XP-OBSERVATIONS\t2',encode([{...row,modifiers:'none'}]),encode([{...row,eventXP:Infinity}]),encode([{...row,addonVersion:'0.6.0\ncode'}]),encode([{...row,eventXP:'=1+1'}]),'x'.repeat(160001),encode(Array(501).fill(row))]) {
  assert.throws(()=>parseExport(value));
}
assert.equal(parseExport(encode([])).length,0);
assert.throws(()=>review([],baseline,0));
assert.throws(()=>review(Array(21).fill({name:'x',text:encode([])}),baseline,70374));
// Exercise the real data-only CLI, with output isolated from production source.
const directory=fs.mkdtempSync(path.join(os.tmpdir(),'dqt-xp-review-'));
try {
  const file=path.join(directory,'export.txt');
  fs.writeFileSync(file,encode([row]));
  const result=spawnSync(process.execPath,[path.join(__dirname,'review-xp.cjs'),process.argv[2],'70374',file],{encoding:'utf8'});
  assert.equal(result.status,0,result.stderr);
  const output=JSON.parse(result.stdout);
  assert.equal(output.findings[0].reference.xp,known.xp);
  assert.equal(output.baselineSHA256,baseline.digest);
  fs.writeFileSync(file,'return os.execute("do not execute")');
  const invalid=spawnSync(process.execPath,[path.join(__dirname,'review-xp.cjs'),process.argv[2],'70374',file],{encoding:'utf8'});
  assert.equal(invalid.status,1);
  assert.equal(invalid.stdout,'');
} finally {
  // Only delete the known file and empty directory created by this test.
  fs.unlinkSync(path.join(directory,'export.txt'));
  fs.rmdirSync(directory);
}
console.log('XP review passed: trusted runtime baseline, provenance, conflicts, quarantine, no auto-accept, duplicate/sybil limits, strict hostile-input rejection and CLI');
