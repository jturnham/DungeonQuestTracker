# Loot Reminder Coverage

Audit: 2026-10-04. Scope: quests currently bundled with the addon, including dungeon chain steps. This is an explicit allowlist, not automatic discovery of future quests.

## Single-Copy Named-Mob Drops

| Dungeon | Covered items |
| --- | --- |
| Ragefire Chasm | Taragaman's heart |
| The Deadmines | VanCleef's head and Unsent Letter; Sneed's Shredder's sprocket; Thistlenettle's badge |
| Wailing Caverns | Four distinct Fang gems; Mutanus' Glowing Shard; Mad Magglish's port |
| Shadowfang Keep | Arugal's head |
| The Stockade | Bazil Thredd, Targorr, Dextren Ward and Kam Deepfury's quest items |
| Blackfathom Deeps | Kelris' head for both factions; Baron Aquanis' Strange Water Globe |
| Hall of Thanes | Durgen Dirgehammer's head |
| Ruins of Lordaeron | Witherfang's strain; both faction-specific Baron heads |
| Excavation Site: Wetlands | Highland Horror's rootcore; Relic Guardian's Titan Relic for both factions |
| Gnomeregan | Thermaplugg's safe combination; Techbot's core |
| Razorfen Kraul | Razorflank's medallion, heart and scroll; Roogug's phlogiston for both Warrior quests |
| Razorfen Downs | Coldbringer's skull; Ambassador Malcin's head in the associated outdoor chain |
| Scarlet Monastery | Nancy Vishas' wedding ring in the associated outdoor chain |
| Uldaman | Grimlok's sapphire; Archaedas' necklace power source; Obsidian Sentinel's Mage power source; Magregan's amulet and Ambassador Infernus' bracer in the associated chain |
| City of Dalaran | No sourced quest mappings currently bundled |

Distinct single-copy items for one quest each get a reminder. Repeated notifications for the same quest/item are suppressed until entering the world again. Completed quests, ready turn-ins, owned items and unavailable faction/class quests are suppressed.

Encounter notifications provide advance reminders where the client reports the named encounter. Loot-window inspection is the fallback, and the only trigger for outdoor/entrance targets without boss notifications. It cannot alert before opening those corpses. Hall of Thanes and Wetlands use scoped English names rather than guessed NPC IDs; their exact encounter and instance names still need client verification. Restricted combat-log events are not registered.

## Deliberate Exclusions

- Multi-copy collections, including hides, bandanas, essences, stems, pendants, guano, heirlooms, guts, hearts and power stones.
- Drops from generic mob types rather than a specific named target: Ragefire's books, Large Soran'ruk Fragment, Damp Note, Grime-Encrusted Ring, Treshala's Pendant and Dragonmaw dispatches.
- Ground objects, chests, corpses used for quest interaction, books, treaties and necklace ruby/topaz containers.
- Items handed over by quest givers or retained for later turn-ins; follow-up quests do not imply a fresh mob drop.
- Unsourced or unidentified drops; no quest or NPC IDs are invented.

## References

Classic mappings use the linked item and objective data on Wowhead Classic: [Fang gems](https://www.wowhead.com/classic/quest=914/leaders-of-the-fang), [Kelris](https://www.wowhead.com/classic/quest=1200/blackfathom-villainy), [Rig Wars](https://www.wowhead.com/classic/quest=2841/rig-wars), [Coldbringer](https://www.wowhead.com/classic/quest=3341/bring-the-end), [necklace recovery](https://www.wowhead.com/classic/quest=2339/find-the-gems-and-power-source), and [Mage power source](https://www.wowhead.com/classic/quest=1956/power-in-uldaman).

Forever-specific item references: [Alliance Baron head](https://www.wowhead.com/forever/item=268518/head-of-the-baron), [Durgen's head](https://wowforever.wclbox.com/en/wupin/274286), [Horrible Rootcore](https://wowforever.wclbox.com/en/wupin/270180), and [Titan Relic](https://wowforever.wclbox.com/en/wupin/270865). Beta data can change; these mappings require an in-client smoke test before claiming verified notification delivery.
