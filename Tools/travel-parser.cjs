// Pure HTML parsers: fixtures can exercise source changes without network or writes.
function parseIndex($,base) {
  const nodes=[],seen=new Set();
  $('table').each((_,table)=>{
    const headings=$(table).find('tr').first().text();
    if (!headings.includes('Flight point')||!headings.includes('Faction')) return;
    $(table).find('tr').slice(1).each((_,row)=>{
      const cells=$(row).children('td');
      if (cells.length!==4) return;
      const name=cells.eq(0).text().trim(),zone=cells.eq(1).text().trim(),faction=cells.eq(2).text().trim();
      const href=cells.eq(0).find('a').attr('href');
      if (!name||!zone||!['Alliance','Horde','Both'].includes(faction)||!href) throw new Error('Incomplete flight point');
      const source=new URL(href,base);
      if (source.origin!==new URL(base).origin||!source.pathname.startsWith('/wiki/')) throw new Error('Unexpected source link');
      const id=`${name}|${faction}`;
      if (seen.has(id)) throw new Error('Duplicate flight point');
      seen.add(id); nodes.push({id,name,zone,faction,source:source.href});
    });
  });
  return nodes;
}
function parseConnections(doc,url,nodes) {
  const heading=doc('#Flight_connections').closest('.mw-heading');
  const links=[];
  let faction;
  heading.nextUntil('.mw-heading').each((_,element)=>{
    const text=doc(element).text().trim();
    if (/^Alliance flight master/.test(text)) faction='Alliance';
    if (/^Horde flight master/.test(text)) faction='Horde';
    if (element.tagName!=='table') return;
    for (const from of nodes.filter(node=>node.source===url&&(!faction||node.faction===faction))) {
      doc(element).find('tr').slice(1).each((_,row)=>{
        const cells=doc(row).children('td');
        const name=cells.eq(0).find('a').first().text().trim()||cells.eq(0).text().trim();
        const rawFare=cells.last().attr('data-sort-value');
        const fare=Number(rawFare);
        const rowFaction=cells.length===4?cells.eq(2).text().trim():from.faction;
        const targets=nodes.filter(node=>node.name===name&&(node.faction===rowFaction||node.faction==='Both'||rowFaction==='Both'));
        if (!rawFare||!Number.isInteger(fare)||fare<0||fare>10000000||!['Alliance','Horde','Both'].includes(rowFaction)||!targets.length) throw new Error(`Unresolved flight ${from.id} -> ${name}`);
        for (const to of targets) links.push({from:from.id,to:to.id,fare,faction:rowFaction,source:url});
      });
    }
  });
  return links;
}
module.exports={parseIndex,parseConnections};
