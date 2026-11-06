// Imported source is quarantined as a review proposal; never overwrite runtime data.
const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const {createRequire}=require('node:module');
function validateCandidate(source,dependencies) {
  if (typeof source!=='string'||Buffer.byteLength(source)>2000000) throw new Error('Candidate exceeds source limit');
  const parser=createRequire(path.resolve(dependencies,'package.json'))('luaparse');
  const tree=parser.parse(source.replace(/^\uFEFF/,''),{luaVersion:'5.1',encodingMode:'pseudo-latin1'});
  const issues=[],ids=new Set();
  function literal(field) { return field && field.value && field.value.value; }
  function walk(node) {
    if (!node||typeof node!=='object') return;
    if (node.type==='TableConstructorExpression') {
      const fields=new Map();
      for (const field of node.fields) {
        const key=field.type==='TableKeyString'?field.key.name:field.type==='TableKey'?field.key.value:undefined;
        if (key!==undefined) {
          if (fields.has(key)) issues.push(`Duplicate table key ${key}`);
          fields.set(key,field);
        }
        if (typeof key==='number'&&field.value.type==='TableConstructorExpression'&&field.value.fields.some(item=>item.key?.name==='name')) {
          if (!Number.isInteger(key)||key<=0||ids.has(key)) issues.push(`Invalid/duplicate quest ID ${key}`);
          ids.add(key);
        }
      }
      for (const key of ['foreverXp','classicXp','fare','questLevel','minLevel','mapID']) {
        if (fields.has(key)) {
          const value=literal(fields.get(key));
          if (!Number.isInteger(value)||value<0||value>10000000) issues.push(`Invalid ${key}`);
        }
      }
      if (fields.has('faction')&&!['Alliance','Horde','Both','Neutral'].includes(literal(fields.get('faction')))) issues.push('Invalid faction');
      if (fields.has('classes')) {
        const value=fields.get('classes').value;
        const allowed=new Set(['WARRIOR','PALADIN','HUNTER','ROGUE','PRIEST','SHAMAN','MAGE','WARLOCK','DRUID']);
        if (value.type!=='TableConstructorExpression'||value.fields.some(field=>!allowed.has(literal(field)))) issues.push('Invalid classes');
      }
      if (fields.has('coordinates')) {
        // luaparse's default string value may be null; parse the quoted raw safely as JSON where possible.
        const field=fields.get('coordinates');
        let value=literal(field);
        if (value===null) { try { value=JSON.parse(field.value.raw); } catch {} }
        const match=typeof value==='string'&&value.match(/^\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*$/);
        if (!match||Number(match[1])>100||Number(match[2])>100) issues.push('Invalid coordinates');
      }
    }
    for (const [key,value] of Object.entries(node)) {
      if (key==='loc') continue;
      if (Array.isArray(value)) value.forEach(walk); else if (value&&typeof value==='object') walk(value);
    }
  }
  walk(tree);
  if (issues.length) throw new Error(issues.slice(0,20).join('; '));
  return {questIDs:[...ids],syntax:'Lua 5.1',semanticValidation:'pending full catalogue/reference/chain tests; candidate never executed'};
}
function writeProposal({root,relativePath,content,sources,build,dependencies}) {
  if (!/^Data\/[A-Za-z0-9]+\.lua$/.test(relativePath)) throw new Error('Unexpected candidate target');
  if (!Array.isArray(sources)||!sources.length||sources.some(url=>typeof url!=='string'||!url.startsWith('https://'))) throw new Error('Missing source provenance');
  const validation=validateCandidate(content,dependencies);
  const directory=path.join(root,'Docs','data-proposals',new Date().toISOString().replace(/[:.]/g,'-')+'-'+crypto.randomBytes(3).toString('hex'));
  fs.mkdirSync(directory,{recursive:true});
  const candidate=path.join(directory,path.basename(relativePath));
  fs.writeFileSync(candidate,content);
  const target=path.join(root,'DungeonQuestTrackerForever',relativePath);
  const old=fs.existsSync(target)?fs.readFileSync(target):Buffer.from('');
  const manifest={schema:1,target:relativePath,sources:[...new Set(sources)],preparedAt:new Date().toISOString(),retrievedAt:'unknown; source pages may use a local cache',
    build:build||'unknown',confidence:'provisional',baselineSHA256:crypto.createHash('sha256').update(old).digest('hex'),
    candidateSHA256:crypto.createHash('sha256').update(content).digest('hex'),validation,
    requiredReview:['Compare provenance and source changes','Review missing/replaced IDs and faction/class/race gates','Review prerequisite references/cycles and map/floor coordinate spaces','Cross-check XP context independently','Apply only reviewed hunks, run full validation and inspect final diff']};
  fs.writeFileSync(path.join(directory,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
  console.log(`Review proposal: ${candidate}\nProduction data unchanged. Compare with ${target}; inspect manifest.json before applying any hunks.`);
  return {directory,candidate,manifest};
}
module.exports={validateCandidate,writeProposal};
