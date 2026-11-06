// Pure quest-source parsing used by addon data-validation tests; no network or writes.
const path=require('node:path');
const {createRequire}=require('node:module');
const dependencies=process.argv[2]||__dirname;
const {load}=createRequire(path.resolve(dependencies,'package.json'))('cheerio');
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
module.exports={parseSource};
