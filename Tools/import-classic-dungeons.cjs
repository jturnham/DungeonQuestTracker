const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');
const requireTool = createRequire(path.resolve(process.argv[2], 'package.json'));
const { parseHTML } = requireTool('linkedom');
const guideURL = 'https://www.wowhead.com/forever/guide/dungeons/every-dungeon-quest-location';
const root = path.resolve(__dirname, '..');
const cachePath = path.join(root, 'Docs', 'classic-dungeon-import-cache.json');
fs.mkdirSync(path.dirname(cachePath), {recursive:true});
const cache = fs.existsSync(cachePath) ? JSON.parse(fs.readFileSync(cachePath, 'utf8')) : {};
async function page(url) {
  if (!cache[url]) {
    const response = await fetch(url);
    if (!response.ok) throw new Error(`${response.status}: ${url}`);
    cache[url] = await response.text();
    fs.writeFileSync(cachePath, JSON.stringify(cache));
  }
  return parseHTML(cache[url]).document;
}
const sections = [
  ["Zul'Farrak Dungeon Quests", 'zul-farrak'], ['Maraudon Dungeon Quests', 'maraudon'],
  ["Temple of Atal'Hakkar", 'sunken-temple'], ['Blackrock Depths BRD', 'blackrock-depths'],
  ['Dire Maul East', 'dire-maul-east'], ['Dire Maul West', 'dire-maul-west'],
  ['Dire Maul North', 'dire-maul-north'], ['Lower Blackrock Spire', 'lower-blackrock-spire'],
  ['Scholomance Dungeon Quests', 'scholomance'], ['Stratholme Dungeon Quests', 'stratholme-main-gate'],
  ['Stratholme Undead', 'stratholme-service-gate'], ['Upper Blackrock Spire', 'upper-blackrock-spire'],
];
const seeds = new Map();
async function main() {
let section;
for (const node of (await page(guideURL)).querySelectorAll('h2,h3,tr')) {
  if (/^H[23]$/.test(node.tagName)) {
    const matched = sections.find(([heading]) => node.textContent.includes(heading));
    if (matched) section = matched[1];
    if (node.textContent.trim() === 'Comments') section = null;
    continue;
  }
  if (!section) continue;
  const cells = [...node.querySelectorAll('td')];
  const link = cells[0]?.querySelector('a[href*="/quest="]');
  const id = Number(link?.getAttribute('href').match(/quest=(\d+)/)?.[1]);
  if (!id || !/^\d+$/.test(cells[1]?.textContent.trim())) continue;
  let dungeon = section;
  if (['Elven Legends','Free Knot!','The Gordok Ogre Suit','The Gordok Taste Test','Unfinished Gordok Business'].includes(link.textContent)) dungeon = 'dire-maul-north';
  seeds.set(id, { dungeon, minLevel:Number(cells[1].textContent.trim()), note:cells.slice(4).map(cell => cell.textContent.trim()).join(' '), pre:cells[4]?.textContent.includes('Pre') });
}
// Level-50 class objectives are kept in the same dungeon catalogue.
for (const id of [8422,8425,9053,8413,8253,8232,8257,8236,8418]) seeds.set(id, {dungeon:'sunken-temple',pre:true});
for (const id of [7481,7482]) seeds.set(id,{dungeon:'dire-maul-west'});
// Additional category records: return steps, class chains and dungeon-set quests.
// Explicit IDs exclude seasonal elders, unused records and Season of Discovery variants.
const additional = {
  'sunken-temple':[3380,3446,8733],
  'blackrock-depths':[3801,3982,4001,4002,4004,4083,4121,4122,4128,4133,4242,4264,4282,4295,4324,4342,4361,4363,7604,8951,8952,8953,8954,8955,8956,8957,8958,8959,9015,9016,9017,9019,9020,9021,9022,9030],
  'dire-maul-east':[7492,7494],
  'dire-maul-west':[7462,7483,7484,7485,7498,7499,7500,7501,7502,7503,7504,7505,7506,7507,7508,7509,7631,7643,7644,7649,7650,7651,7877],
  'dire-maul-north':[1193,5518,5519,5525,5528,7429,7703,8948,8949,8950,8967,8990],
  'lower-blackrock-spire':[4743,4983,5001,5002,5081,8966,8989],
  'upper-blackrock-spire':[4734,4765,4766,4769,4907,5103,6569,8995,8996],
  'scholomance':[5515,5531,7647,8969,8992],
  'stratholme-main-gate':[5214,8968,8991],
  'stratholme-service-gate':[5464,8946],
};
for (const [dungeon, ids] of Object.entries(additional)) for (const id of ids) if (!seeds.has(id)) seeds.set(id,{dungeon});
seeds.delete(9030); // Unused level-15 variant, not the dungeon-set return quest.
const classBits = {1:'WARRIOR',2:'PALADIN',4:'HUNTER',8:'ROGUE',16:'PRIEST',64:'SHAMAN',128:'MAGE',256:'WARLOCK',1024:'DRUID'};
const records = new Map();
const seriesParents = new Map();
const strings = /"(?:\\.|[^"\\])*"/g;
function quickFacts(document) {
  for (const script of document.querySelectorAll('script')) {
    if (!script.textContent.includes('WH.markup.printHtml(')) continue;
    const literal = script.textContent.slice(script.textContent.indexOf('WH.markup.printHtml(')).match(strings)?.[0];
    if (literal) {
      const decoded = JSON.parse(literal);
      if (decoded.includes('Requires level')) return decoded;
    }
  }
  throw new Error('Quest quick facts missing');
}
async function contact(facts, field) {
  const fragment = facts.slice(facts.indexOf(`${field}: `)).split('[/icon]')[0];
  const link = fragment.match(/\[url=([^\]]+)\]([^[]+)\[\/url\]/);
  if (!link) return {name:'Contact awaiting verification',zone:'Location awaiting verification'};
  const name = link[2];
  if (!link[1].includes('/npc=') && !link[1].includes('/object=')) return {name,zone:'Location awaiting verification'};
  const document = await page(`https://www.wowhead.com${link[1]}`);
  const locations = [...document.querySelectorAll('#locations a')].map(node => node.textContent.trim()).filter(Boolean);
  return {name,zone:locations[0] || 'Location awaiting verification', ...(locations.length > 1 ? {subzone:'Multiple Classic locations; confirm faction contact in beta'} : {})};
}
for (const [id, seed] of seeds) {
  const url = `https://www.wowhead.com/classic/quest=${id}`;
  const document = await page(url);
  const facts = quickFacts(document);
  const script = [...document.querySelectorAll('script')].map(node => node.textContent).join('\n');
  const dataMatch = script.match(new RegExp(`\\.extend\\(g_quests\\[${id}\\], (\\{[^\\n]+\\})\\);`));
  if (!dataMatch) throw new Error(`Structured quest data missing: ${id}`);
  const data = JSON.parse(dataMatch[1]);
  const pickup = await contact(facts, 'Start');
  const turnIn = await contact(facts, 'End');
  const tooltip = await (await fetch(`https://nether.wowhead.com/classic/tooltip/quest/${id}`)).json();
  const tooltipDocument = parseHTML(tooltip.tooltip || '<html></html>').document;
  const summary = tooltipDocument.querySelectorAll('table')[2]?.textContent || '';
  // Only a short objective excerpt; never import the quest's dialogue.
  const firstSentence = summary.split('Requirements:')[0].trim().match(/^.*?[.!?](?:\s|$)/)?.[0]?.trim();
  const objective = firstSentence && firstSentence.split(/\s+/).length <= 12
    ? firstSentence : `Complete the dungeon objective, then speak with ${turnIn.name} in ${turnIn.zone}.`;
  const objectiveOverrides = {
    1193:'Repair the Broken Trap in Dire Maul North.',
    8232:'Recover the Tooth of Morphaz from Sunken Temple for Ogtinc.',
    8257:'Recover Morphaz\'s blood in Sunken Temple for Greta Mosshoof.',
    8422:'Collect the Sunken Temple voodoo feathers for Impsy.',
    8425:'Collect the Sunken Temple voodoo feathers for the Fallen Hero.',
    9053:'Recover a Putrid Vine from Atal\'alarion in Sunken Temple for Torwa.',
  };
  const classes = Object.entries(classBits).filter(([bit]) => Number(data.reqclass || 0) & Number(bit)).map(([,tag]) => tag);
  const classNames = facts.match(/Classes?: (.*?)(?:\[\/li\])/s)?.[1] || '';
  for (const tag of Object.values(classBits)) if (classNames.toUpperCase().includes(tag) && !classes.includes(tag)) classes.push(tag);
  const prerequisites = [];
  const requires = [...document.querySelectorAll('table.infobox-inner-table')].find(table => table.querySelector('th')?.textContent.trim() === 'Requires');
  for (const requirement of requires?.querySelectorAll('script') || []) {
    const literal = requirement.textContent.match(strings)?.[0];
    if (!literal) continue;
    for (const match of JSON.parse(literal).matchAll(/\[quest=(\d+)/g)) {
      prerequisites.push({questID:Number(match[1]),relationship:'required',external:true,note:'Classic database prerequisite; confirm the chain in Forever.'});
    }
  }
  const series = [...document.querySelectorAll('table.series tr')];
  const position = series.findIndex(row => row.querySelector('b')?.textContent === data.name);
  if (position > 0) {
    const previous = Number(series[position-1].querySelector('a[href*="quest="]')?.getAttribute('href').match(/quest=(\d+)/)?.[1]);
    if (previous) seriesParents.set(id,previous);
  }
  if (position >= 0) {
    let parent = id;
    for (const row of series.slice(position+1)) {
      const childID = Number(row.querySelector('a[href*="quest="]')?.getAttribute('href').match(/quest=(\d+)/)?.[1]);
      if (!childID) break;
      if (!seeds.has(childID)) seeds.set(childID, {dungeon:seed.dungeon,pre:true,parent});
      parent = childID;
    }
  }
  if (position > 0 && seed.pre) {
    const previousID = Number(series[position-1].querySelector('a[href*="quest="]')?.getAttribute('href').match(/quest=(\d+)/)?.[1]);
    if (previousID && !prerequisites.some(item => item.questID === previousID)) prerequisites.push({questID:previousID,relationship:'required',external:true,note:'Classic chain predecessor; confirm eligibility in Forever.'});
  }
  if (seed.pre && !prerequisites.length) prerequisites.push({relationship:'required',note:'Complete the Classic prerequisite chain before pickup; exact Forever chain needs verification.'});
  const record = {name:data.name,dungeon:seed.dungeon,minLevel:seed.minLevel || data.reqlevel,questLevel:data.level > 0 ? data.level : 60, pickup,turnIn,objectives:objective || 'Complete this dungeon objective and return to the listed contact.',prerequisites,source:url,verifiedForever:false,classicXp:data.xp, ...(data.side === 1 ? {faction:'Alliance'} : data.side === 2 ? {faction:'Horde'} : {}), ...(classes.length ? {classes} : {})};
  if (seed.parent) {
    record.followUpOf = seed.parent;
    record.prerequisites = [{questID:seed.parent,relationship:'required',note:'Complete the preceding Classic dungeon-chain step; confirm in Forever.'}];
  }
  if (facts.includes('Start: [url=/classic/item=')) record.pickupType = 'drop';
  else if (facts.includes('Start: [url=/classic/object=')) record.pickupType = 'object';
  records.set(id,record);
  record.objectives = objectiveOverrides[id] || record.objectives;
  record.classicSourceOnly = true;
  if (record.name === "Anthion's Parting Words" && data.itemrewards?.length) {
    const item = await (await fetch(`https://nether.wowhead.com/classic/tooltip/item/${data.itemrewards[0][0]}`)).json();
    const itemText = parseHTML(item.tooltip || '<html></html>').document.querySelector('table')?.textContent || '';
    const restriction = itemText.match(/Classes?:\s*([A-Za-z]+)/)?.[1]?.toUpperCase();
    if (Object.values(classBits).includes(restriction)) record.classes = [restriction];
    else {
      const sets = {Feralheart:'DRUID',Beastmaster:'HUNTER',Soulforge:'PALADIN',Virtuous:'PRIEST',Darkmantle:'ROGUE','Five Thunders':'SHAMAN',Sorcerer:'MAGE',Deathmist:'WARLOCK',Heroism:'WARRIOR'};
      const branch = Object.keys(sets).find(set => item.name?.includes(set));
      if (branch) {
        record.classes = [sets[branch]];
        record.classRequirementInferred = true;
      }
    }
  }
  console.log(`${id}: ${data.name} (${seed.dungeon})`);
}
for (const [id,parent] of seriesParents) {
  const quest = records.get(id), origin = records.get(parent);
  if (!origin || origin.dungeon !== quest.dungeon) continue;
  quest.followUpOf = parent;
  if (!quest.prerequisites.some(item => item.questID === parent)) quest.prerequisites.push({questID:parent,relationship:seeds.get(id).pre ? 'required' : 'breadcrumb',note:'Classic-source chain link; mandatory eligibility in Forever awaits verification.'});
}
for (const quest of records.values()) {
  if (quest.followUpOf) continue;
  const origin = quest.prerequisites.find(item => records.get(item.questID)?.dungeon === quest.dungeon);
  if (origin) quest.followUpOf = origin.questID;
}
function lua(value) {
  if (value === null || value === undefined) return 'nil';
  if (typeof value === 'string') return JSON.stringify(value).replace(/\\u([0-9a-f]{4})/gi, (_,code) => String.fromCharCode(parseInt(code,16)));
  if (typeof value !== 'object') return String(value);
  return `{${Array.isArray(value) ? value.map(lua).join(',') : Object.entries(value).map(([key,item]) => `${key}=${lua(item)}`).join(',')}}`;
}
const body = [...records].sort(([a],[b]) => a-b).map(([id,record]) => `    [${id}]=${lua(record)},`).join('\n');
const output = `local _, DQT = ...

-- Classic-source coverage; Forever rewards and eligibility remain unverified.
local quests = {
${body}
}
local ids = {}
for id in pairs(quests) do ids[#ids+1] = id end
table.sort(ids)
for _, id in ipairs(ids) do
    local quest = quests[id]
    if not DQT.quests[id] then
        DQT.quests[id] = quest
        table.insert(DQT.dungeons[quest.dungeon].quests, id)
    end
    local dungeon = DQT.dungeons[quest.dungeon]
    dungeon.placeholder = nil
    dungeon.notes = "Classic-source quests are included through level 60. Forever availability, prerequisites and XP still need beta verification. Unknown locations do not produce map pins."
end
`;
fs.writeFileSync(path.join(root,'DungeonQuestTrackerForever','Data','QuestDataClassic.lua'),output);
console.log(`Imported ${records.size} Classic quest records.`);
}
main().catch(error => { console.error(error); process.exitCode = 1; });
