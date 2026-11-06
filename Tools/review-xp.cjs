// Strict data-only review. This tool has no write/apply/import-to-addon operation.
const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const {loadBaseline}=require('./xp-baseline.cjs');
const columns=['questID','build','addonVersion','capturedAt','levelBefore','levelAtEvent','xpBefore','xpAtEvent','xpMaxBefore','eventXP','displayedXP','modifiers'];
const MAX_FILE=160000, MAX_ROWS=500, MAX_FILES=20;
function integer(value,min,max) {
  if (!/^-?\d{1,10}$/.test(value)) throw new Error('Invalid integer');
  const number=Number(value);
  if (!Number.isSafeInteger(number)||number<min||number>max) throw new Error('Integer out of range');
  return number;
}
function parseExport(text) {
  if (Buffer.byteLength(text,'utf8')>MAX_FILE) throw new Error('Export exceeds size limit');
  const lines=text.replace(/^\uFEFF/,'').replace(/\r\n/g,'\n').trimEnd().split('\n');
  if (lines.shift()!=='DQT-XP-OBSERVATIONS\t1' || lines.shift()!==columns.join('\t')) throw new Error('Unsupported export format or columns');
  if (lines.length>MAX_ROWS) throw new Error('Too many observations');
  return lines.map((line,index)=>{
    const values=line.split('\t');
    if (values.length!==columns.length) throw new Error(`Wrong column count at observation ${index+1}`);
    const row={};
    columns.forEach((key,i)=>{
      if (key==='addonVersion') {
        if (!/^\d{1,5}\.\d{1,5}\.\d{1,5}$/.test(values[i])) throw new Error('Invalid addon version');
        row[key]=values[i];
      } else if (key==='modifiers') {
        if (values[i]!=='unknown') throw new Error('Untrusted modifier claim');
        row[key]=values[i];
      } else {
        const max=key==='capturedAt'?4102444800:key.startsWith('level')?100:10000000;
        const min=key==='questID'?1:key==='eventXP'?0:-1;
        row[key]=integer(values[i],min,max);
        if ((key==='build'||key.startsWith('level')) && row[key]===0) throw new Error(`Invalid ${key}`);
      }
    });
    return row;
  });
}
function review(exports,baseline,expectedBuild,now=Math.floor(Date.now()/1000)) {
  if (!Number.isSafeInteger(expectedBuild)||expectedBuild<=0) throw new Error('A maintainer-selected target build is required');
  if (exports.length>MAX_FILES) throw new Error('Too many files');
  const seen=new Set(),findings=[],groups=new Map();
  for (const submission of exports) {
    for (const row of parseExport(submission.text)) {
      const fingerprint=crypto.createHash('sha256').update(columns.map(key=>row[key]).join('\t')).digest('hex');
      if (seen.has(fingerprint)) continue;
      seen.add(fingerprint);
      const known=baseline.rows.get(row.questID);
      const flags=['unauthenticated-export','unknown-modifiers','human-review-required'];
      if (!known) flags.push('unknown-quest');
      if (row.build!==expectedBuild) flags.push('wrong-or-unknown-build');
      if (row.capturedAt<0) flags.push('unknown-time');
      else if (row.capturedAt>now+86400) flags.push('future-time');
      else if (now-row.capturedAt>90*86400) flags.push('old-observation');
      if (row.levelBefore<1) flags.push('unknown-pre-turn-in-level');
      if (row.levelAtEvent<1) flags.push('unknown-event-level');
      if (row.levelBefore>0 && row.levelAtEvent>0 && row.levelBefore!==row.levelAtEvent) flags.push('level-changed-or-event-ordering');
      if (known && row.levelBefore>0 && row.levelBefore<known.minLevel) flags.push('below-bundled-minimum');
      if (known && row.levelBefore>known.questLevel+2 && known.questLevel>0) flags.push('possible-level-scaling');
      if (row.xpMaxBefore===0 || row.eventXP===0) flags.push('zero-xp-or-level-cap');
      if (row.xpMaxBefore>0 && row.xpBefore>=row.xpMaxBefore) flags.push('invalid-pre-turn-in-xp-context');
      if (row.displayedXP<0) flags.push('no-reward-panel-evidence');
      else if (row.displayedXP!==row.eventXP) flags.push('panel-event-disagreement');
      if (!known || known.xp<0) flags.push('no-bundled-xp-reference');
      const comparison=known && known.xp>=0 ? row.eventXP===known.xp?'matches-bundled-raw-value':'differs-from-bundled-raw-value':'no-reference';
      if (comparison==='differs-from-bundled-raw-value') flags.push('bundled-reference-conflict');
      const quarantined=flags.some(flag=>['unknown-quest','wrong-or-unknown-build','future-time','panel-event-disagreement','invalid-pre-turn-in-xp-context'].includes(flag));
      const finding={fingerprint,submission:path.basename(submission.name),observation:row,
        reference:known||null,comparison,flags,disposition:quarantined?'quarantined':'manual-review-only',eligibleForAutoImport:false};
      findings.push(finding);
      const groupKey=[row.questID,row.build,row.levelBefore,row.modifiers].join(':');
      if (!groups.has(groupKey)) groups.set(groupKey,{questID:row.questID,build:row.build,levelBefore:row.levelBefore,modifiers:row.modifiers,reportedRewards:new Set(),records:0});
      const group=groups.get(groupKey); group.records++; group.reportedRewards.add(row.eventXP);
    }
  }
  return {schema:1,targetBuild:expectedBuild,baselineSHA256:baseline.digest,
    policy:'No export is authenticated. Matching data and repeated reports are not verification. No automatic acceptance, averaging, code generation or addon writes.',
    inputRows:exports.reduce((n,item)=>n+parseExport(item.text).length,0),uniqueRows:findings.length,
    groups:[...groups.values()].map(group=>({...group,reportedRewards:[...group.reportedRewards].sort((a,b)=>a-b),conflictingRewards:group.reportedRewards.size>1,independentContributors:'unknown'})),findings};
}
if (require.main===module) {
  try {
    const [dependencies,build,...files]=process.argv.slice(2);
    if (!dependencies||!/^\d+$/.test(build||'')||!files.length||files.length>MAX_FILES) throw new Error('Usage: node Tools/review-xp.cjs <dependency-directory> <target-build> <export.txt> [more-exports.txt]');
    const exports=files.map(file=>{
      const stat=fs.statSync(file);
      if (!stat.isFile()||stat.size>MAX_FILE) throw new Error('Invalid or oversized export file');
      return {name:file,text:fs.readFileSync(file,'utf8')};
    });
    process.stdout.write(JSON.stringify(review(exports,loadBaseline(dependencies),Number(build)),null,2)+'\n');
  } catch(error) { process.stderr.write(`XP review failed: ${error.message}\n`); process.exitCode=1; }
}
module.exports={parseExport,review,columns};
