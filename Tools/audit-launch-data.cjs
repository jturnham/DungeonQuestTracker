// Fresh source audit only. No source claims are automatically applied to runtime.
const fs=require('node:fs'),path=require('node:path');
const {createRequire}=require('node:module');
const {loadBaseline}=require('./xp-baseline.cjs');
const dependencies=process.argv[2]||__dirname;
const {load}=createRequire(path.resolve(dependencies,'package.json'))('cheerio');
const date=process.argv[3]||new Date().toISOString().slice(0,10);
if(!/^\d{4}-\d{2}-\d{2}$/.test(date))throw Error('Invalid review date');
const root=path.resolve(__dirname,'..'),directory=path.join(root,'Docs','launch-audit-'+date);
function parseSource(html,url) {
 const $=load(html),title=$('h1').first().text().trim();
 $('script,style,nav,header,footer').remove();
 const text=$('main').length?$('main').text():$('body').text();
 const xp=text.match(/\bExperience(?:\s*\(Classic Era\))?\s*[:：]?\s*([\d,]+)(?![\d,])/i)
  ||text.match(/\bXP\s*([\d,]+)(?![\d,])/);
 const required=new Set(),previous=new Set();
 function IDs(elements,target) {
  elements.find('a[href]').each((_,anchor)=>{
   const href=$(anchor).attr('href');
   const id=href.match(/(?:quest[=/]|\/renwu\/)(\d+)/)?.[1]||href.match(/\/quests\/[^/]+-(\d+)\/$/)?.[1];
   if(id)target.add(Number(id));
  });
 }
 $('h2,h3,h4,th').each((_,heading)=>{
  const name=$(heading).text().trim();
  if(/^(?:prerequisites?|requires?|required quests?)$/i.test(name)) IDs($(heading).nextUntil('h2,h3,h4'),required);
  if(/The chain/.test(name)) IDs($(heading).next().find('li').filter((_,item)=>/Comes after/.test($(item).text())),previous);
 });
 return {title,xp:xp?Number(xp[1].replaceAll(',','')):null,
  rewardScope:url.includes('wclbox.com')||/Classic Era|classic-db|Classic reference/i.test(text)?'classic-or-mixed':'unverified-context',
  requiredLinkCandidates:[...required],seriesPredecessorCandidates:[...previous],build:text.match(/1\.60\.1\.(\d+)/)?.[1]||null};
}
async function page(url,key) {
 try {
  const saved=path.join(directory,key+'.html');
  let html;
  if(process.argv.includes('--reparse')&&fs.existsSync(saved)) html=fs.readFileSync(saved,'utf8');
  else {
   const response=await fetch(url,{signal:AbortSignal.timeout(15000)});
   if(!response.ok) return {url,status:'unavailable',http:response.status};
   html=await response.text();
  }
  if(Buffer.byteLength(html)>2000000) return {url,status:'oversized'};
  if(!process.argv.includes('--reparse')||!fs.existsSync(saved)) fs.writeFileSync(saved,html);
  return {url,status:'retrieved',retrievedAt:fs.statSync(saved).mtime.toISOString(),...parseSource(html,url)};
 } catch(error) {return {url,status:'unavailable',error:error.message};}
}
async function main() {
 fs.mkdirSync(directory,{recursive:true});
 const baseline=loadBaseline(dependencies);
 const indexURL='https://wowforevertalents.com/quests/';
 const response=await fetch(indexURL,{signal:AbortSignal.timeout(15000)});
 if(!response.ok)throw Error('Quest index unavailable');
 const index=await response.text();fs.writeFileSync(path.join(directory,'wft-index.html'),index);
 const $=load(index),links=new Map();
 $('a[href*="/quests/"]').each((_,a)=>{const href=$(a).attr('href'),id=href.match(/-(\d+)\/$/)?.[1];if(id)links.set(Number(id),new URL(href,indexURL).href);});
 const work=[...baseline.rows.values()],results=[];
 let cursor=0;
 async function worker() {
  while(cursor<work.length) {
   const quest=work[cursor++];
   const sources=[await page('https://wowforever.wclbox.com/en/renwu/'+quest.id,'wcl-'+quest.id)];
   if(links.has(quest.id))sources.push(await page(links.get(quest.id),'wft-'+quest.id));
   results.push({quest,sources,rawXPConflicts:sources.filter(source=>source.xp!==null&&source.xp!==undefined&&quest.xp>=0&&source.xp!==quest.xp),
    policy:'No auto-apply. Reward scope, build, level and provenance require independent review; missing XP is not zero.'});
   if(results.length%50===0)console.log('Audited '+results.length+'/'+work.length+' quest IDs');
   await new Promise(resolve=>setTimeout(resolve,150));
  }
 }
 await Promise.all(Array.from({length:4},worker));
 results.sort((a,b)=>a.quest.id-b.quest.id);
 const dungeons={},byID=new Map(results.map(row=>[row.quest.id,row]));
 for(const [key,ids] of baseline.dungeons) {
  const members=ids.map(id=>byID.get(id)).filter(Boolean);
  dungeons[key]={quests:ids.length,emptyPlaceholder:ids.length===0,
   withRetrievedSource:members.filter(row=>row.sources.some(source=>source.status==='retrieved')).length,
   withExplicitNumericXP:members.filter(row=>row.sources.some(source=>source.xp!==null&&source.xp!==undefined)).length,
   rawXPConflicts:members.reduce((sum,row)=>sum+row.rawXPConflicts.length,0)};
 }
 const report={reviewDate:date,baselineSHA256:baseline.digest,quests:results.length,dungeons,results};
 fs.writeFileSync(path.join(directory,'report.json'),JSON.stringify(report,null,2));
 console.log(JSON.stringify({report:path.join(directory,'report.json'),quests:results.length,dungeons,
  unavailable:results.filter(row=>row.sources.every(source=>source.status!=='retrieved')).length},null,2));
}
if(require.main===module) main().catch(error=>{console.error(error.message);process.exitCode=1;});
module.exports={parseSource};
