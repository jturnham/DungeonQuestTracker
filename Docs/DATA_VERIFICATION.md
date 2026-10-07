# Quest Data Verification

The beta catalog is provisional. `Data/QuestMetadata.lua` adds provenance and review notes without claiming that source-backed values were observed in the game.

## Dungeon Follow-Up Review - 2026-10-02

`Data/QuestFollowUps.lua` registers sourced continuations by exact quest ID and automatically includes them in each applicable originating dungeon. Shared Paladin continuations appear under Deadmines, Shadowfang Keep and Blackfathom Deeps, while the Stockade leg of the Defias chain keeps its explicit Stockade association. Global turn-ins deduplicate these IDs and do not use checklist visibility to select ready quests.

- Ruins of Lordaeron: [Unending Torment](https://www.wowhead.com/forever/quest=97288/unending-torment) has five steps, 97288 through 97292. All four city continuations are recorded, with distinct pickup/turn-in contacts and required predecessors. Newly added rewards remain unknown, not copied from the first dungeon step.
- Deadmines and Stockade: [The Unsent Letter](https://www.wowhead.com/forever/quest=373/the-unsent-letter) continues through Bazil Thredd and The Stockade Riots to the city investigation and Seal of Wrynn reward. All listed continuation IDs are recorded.
- Scarlet Library: [Test of Lore](https://www.wowhead.com/forever/quest=1160/test-of-lore) continues through 6628 to Final Passage 1394. Rituals of Power continues to Mage's Wand 1952, with the additional Items of Power prerequisite retained.
- Shared Paladin chain: [The Test of Righteousness](https://www.wowhead.com/forever/quest=1654/the-test-of-righteousness) continues to the forging/reward step 1806 and retains all three dungeon origins.
- Razorfen Kraul: Warrior armor crafting, referral, collection and final reward branches are recorded for both factions. [An Unholy Alliance 6522](https://www.wowhead.com/forever/quest=6522/an-unholy-alliance) is the scroll delivery, not 6521; [6521](https://www.wowhead.com/forever/quest=6521/an-unholy-alliance) is the Ambassador Malcin continuation outside Razorfen Downs.
- Existing Ragefire Chasm, Wailing Caverns and Gnomeregan returns remain covered. No new follow-up IDs were established for Hall of Thanes, the remaining standalone dungeon quests, or the newer Wetlands chains. Wetlands guide mentions without confirmed IDs remain explicit data gaps; City of Dalaran still has no sourced quest catalog.

New continuation levels without explicit values are provisional inherited levels, flagged to prevent gray/red checklist filtering. Exact rewards, optional/race-specific referral requirements and Forever contact changes need client confirmation. Tests cover every catalogued follow-up's ready/completed state, deduplication and same-title ID isolation; this review does not establish exhaustive coverage of undocumented beta content.

## Record Fields

- `source`, `sourceNotes`, `sourceURLs`: original attribution and reference links. A link alone does not mean the record is verified.
- `confidence`: `needsReview`, `verifiedSource`, or `verifiedInGame`. Current unverified records remain `needsReview`.
- `verification`: separate XP, pickup, turn-in, and prerequisite checks; `sourceReview` records targeted source checks and `conflict` records discrepancies.
- `shareability`: advisory assumptions only. Actual sharing always checks the client quest log's pushable flag and recipient acceptance remains outside DQT's control.
- `prerequisites[].external`: prerequisite ID intentionally outside the bundled catalog. Completion can still be checked through client history.

## In-Game Evidence

When reporting a correction, include the quest ID, beta build, faction/class/race, character level, and date. Run `/dqt debug <questID>` for state diagnostics.

For XP, record the displayed reward before turn-in, character XP before/after, and any relevant bonuses or level-cap effects. A reward observed at one level is not automatically the base XP at another level.

For pickup and turn-in, record NPC/object name, zone, coordinates, and any item needed to start the quest. For prerequisites, record completed quest IDs and whether the follow-up can be accepted or shared without them. Screenshots are useful evidence. Do not promote a field until the evidence supports it.

## First-Wave Review

The two Deadmines UI samples have been replaced with sourced objectives, locations, chain notes, and provisional Classic XP. Smart Drinks now records Raptor Horns as required. Defias Brotherhood, Red Silk Bandanas, and the Fang lead-in have explicit chain requirements. Unrelated class quests are excluded from dungeon totals.

The [Forever dungeon guide](https://www.wowhead.com/forever/guide/dungeons/every-dungeon-quest-location) warns that beta data can be incomplete. It conflicts with existing entries on the Lost Satchel start, Tabitha Heartweaver's location, and Hall of Thanes minimum levels. These are flagged for client confirmation rather than silently replacing one uncertain value with another.

[Red Silk Bandanas](https://www.wowhead.com/classic/quest=214/red-silk-bandanas) and [Collecting Memories](https://www.wowhead.com/classic/quest=168/collecting-memories) provide the baseline objectives; their Forever XP still needs confirmation.

## October 1 XP Review

All 93 bundled records were reviewed for XP provenance after the [official October 1 change](https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-october-1/2360696). Blizzard reduced the extra dungeon quest reward by half, rather than halving the whole reward. The public database checked on October 1 still lists the previously bundled rewards for most covered quests and does not establish post-patch observation dates.

For 31 records with a usable published old reward and Classic baseline, the local build uses `round(normal + (old - normal) / 2)`. This assumes the Classic reward is the normal baseline and uses nearest-integer rounding; neither assumption is confirmed by the patch notes. These records retain `xpBeforeOctober1`, set `xpEstimate`, and display `Forever (Oct 1 estimate)`. They are not promoted to verified confidence.

Four Stockade records previously used Classic numbers as Forever rewards: 386, 377, 387, and 388. Their published old Forever rewards are 6400, 6720, 8480, and 8480; the patch-based estimates are 4200, 4410, 5565, and 5565 respectively. The public listing is https://wowforever.wclbox.com/en/fuben/the-stockade.

Other existing Forever rewards retain their old numeric value but are explicitly marked `xpOutdated` and labelled outdated/unverified, not silently halved. This includes new Forever quests without documented normal baselines, breadcrumbs/follow-ups without supported bonus applicability, and conflicting BFD baselines (1200, 6561, 6564). Classic-only records remain fallback estimates. These unresolved values still affect the planner, so projections are provisional until client evidence is available.

To replace an estimate, record the current beta build, quest ID, character level, displayed XP and applicable bonuses. Remove its estimate/outdated designation only with suitable evidence. The patch itself does not supply exact per-quest rewards.

## October 2 Comparable Baselines

At the maintainer's request, 14 additional rewards in Ruins of Lordaeron and Hall of Thanes now use an assumed same-level normal quest baseline. Reference rewards: level 15, 1050 XP (One Shot. One Kill., 5713); level 16, 1150 XP (Classic Hidden Enemies, 5728); level 21, 1650 XP (Devils in Westfall, 1076); level 22, 1750 XP (Elune's Tear, 1033). Each record includes its reference URL and a verification note. These comparisons assume similar reward difficulty; they do not establish the new quest's actual normal reward.

The New Plague (95216) is now estimated at 5035 XP: `1750 + (8320 - 1750) / 2`. The maintainer observed approximately 5000 XP; this supports the scale, not an exact in-game verification. Comparable estimates use `xpNormalBaseline` and `xpBaselineAssumed`, rather than inventing a Classic reward for a Forever-only quest. Together with the 31 quest-specific estimates, 45 records now use the bonus-reduction model. Zero/unknown rewards and disputed Classic baselines remain unresolved.

## Full-Catalog Bonus Estimate Coverage

The October 2 local build now covers all 56 positive pre-patch Forever rewards: 31 quest-specific baselines and 25 assumed same-level baselines. This supersedes the earlier limited scope and the decision to retain positive outdated values. It includes BFD conflicts as explicit comparable-baseline assumptions, without claiming those source conflicts were resolved.

Additional comparable rewards are level 17: 1250 (Fruit of the Sea, 1138); level 18: 1350 (Defias Brotherhood, 65); level 20: 1550 (Stop the Spread, 98299); level 25: 2000 (Stonetalon Standstill, 25); level 27: 2200 (Je'neu of the Earthen Ring, 824). References are attached to each affected record.

When the comparable reward exceeds the old reward, the assumed normal component is capped at the old reward. The bonus is then zero and the estimate remains unchanged; the patch estimate never increases a reward. This matters for breadcrumbs and smaller follow-ups where a full normal reward is not comparable in difficulty. All such estimates remain unverified, including bonus applicability.

Classic-only records retain their fallback because no old Forever bonus is known. The zero/unknown Wrath of Rath'mael entry remains unresolved. No global dungeon multiplier or fabricated pre-patch value is applied to either category. Regression tests require every positive old Forever reward to be covered exactly once by the estimate model.

## October 4 XP Review

Reviewed the full 189-record catalog against the current [public quest spreadsheet](https://docs.google.com/spreadsheets/d/1-185bNiXoGX4kEoeeQ3DmJdSqN4ZavOKXgZNJTnwLlQ/edit) and all tracked [WCLBox dungeon pages](https://wowforever.wclbox.com/en/fuben). The spreadsheet's sixteen catalogued reports are unchanged. Thirty additional records now use individual rewards explicitly attributed by WCLBox to the October 1 level-30 build; no dungeon-wide factor or second bonus reduction is applied.

| Dungeon | Quest IDs and published XP |
| --- | --- |
| Ragefire Chasm | 5724: 2950 |
| Ruins of Lordaeron | 95250: 3900; 95195, 92415, 95189: 6200; 95216, 95204: 5450; 97288: 3450 |
| Wailing Caverns | 914: 4300; 6981: 5150 |
| The Deadmines | 214: 2950; 166: 6200; 2040: 3700 |
| Blackfathom Deeps | 971: 6550; 1200, 6921: 7850; 1199: 6050; 6564: 1300; 6565: 6300 |
| The Stockade | 391: 4950; 386: 4200; 377: 4400; 387, 388: 5550 |
| Gnomeregan | 2904: 5800; 2922: 4750; 2926: 3950; 2928, 2962: 4400 |
| Razorfen Kraul | 1144: 7250 |

These display as `Forever (published beta)` and retain historical estimate/baseline metadata, without promoting confidence to locally verified. They replace 29 formula estimates and one Classic fallback (214). Source pages do not record per-quest character level and observation details. Twelve estimates remain; no current XP was found for Wetlands, Dalaran, Scarlet Monastery, Razorfen Downs, Uldaman, or unreported follow-up/class quests. Hall of Thanes explicitly still lists pre-October 1 rewards, so those cannot replace adjusted estimates. Ambiguous unlabeled XP numbers and Classic-only rewards were not treated as current beta observations.

## October 7 Pending-Correction Review

Rechecked the pending October 5 research against current quest-ID pages and dungeon listings. Source-backed is not locally verified; observation level/build details remain incomplete.

- Hall of Thanes now explicitly attributes rewards to the October 1 level-30 build: An Ancient Grudge 96395: 2300; Important Heirlooms 96403: 2950; The Restless Dead 96394: 2300; Old Ironforge Incursion 96393: 3200. These replace comparable-baseline estimates. [Dungeon listing](https://wowforever.wclbox.com/en/fuben/hall-of-thanes). The Treaty of Understanding still has no explicit current XP; its estimate remains labelled as such. Minimum-level and coordinate conflicts remain unresolved.
- Corrected [Amongst the Ruins 6921](https://wowforever.wclbox.com/en/renwu/6921) from 7850 to 6550, and replaced the Horde [Blackfathom Villainy 6561](https://wowforever.wclbox.com/en/renwu/6561) estimate with its own published 7850 reward. The [BFD listing](https://wowforever.wclbox.com/en/fuben/blackfathom-deeps) independently associates these rewards with the same identities. Damp Note 6564 remains 1300; no multiplier applied to unlabeled rewards. Catalog now has 35 published rewards and 7 formula estimates.
- Added [Fallen in the Fen 95795](https://www.wowhead.com/forever/quest=95795/fallen-in-the-fen), corroborated by the [Wetlands listing](https://wowforever.wclbox.com/en/fuben/excavation-site). Alliance continuation of Songblade Search 95772, picked up at Daewyn's body inside the dungeon, returned to Dorin in Lakeshire. Minimum level 24 and provisional quest level 31; XP unknown. Included in dungeon grouping and global ready turn-ins. Existing Heartwoven, Prehistoric Prism and Earthen Echo continuations remain covered; missing-relic bug reports are not evidence of a current fix.
- Dalaran is no longer adequately described as having no sourced quest information. An [October 7 attunement report](https://www.wowhead.com/news/how-to-become-attuned-to-city-of-dalaran-dungeon-as-horde-in-wow-forever-383256) documents Horde preparation and [Heart of Disruption 96984](https://www.wowhead.com/forever/quest=96984/heart-of-disruption). It describes the instance as not yet available. The quest page and article differ on contact details; full faction/chain/XP validation is still needed. Dalaran remains an empty bundled placeholder in this correction pass, not a claim of absent quests. Treat implementing sourced attunement/dungeon records as a separate coverage task rather than importing unvalidated cache rows.

Total catalog: 190 quests, 18 dungeon entries. No reward is promoted to verifiedInGame by this review.

## Dalaran Attunement Addition - October 7

Added 544 Prison Break In, 545 Dalaran Patrols, 93680 Key to the City, 556 Stone Tokens, 557 Bracers of Binding, 92434 Blood in the Streets, 96984 Horde Heart of Disruption, 92432 An Alarming Request and 92458 Alliance Heart of Disruption. These supersede the earlier empty-placeholder decision. Total catalog: 199 quests, 18 entries.

All records carry awaitingFinalVerification, needsReview confidence, unknown XP, provisional quest levels and explicit contact/chain review notes. No coordinates were inferred from another game edition. Level 24 is reported for the new steps; applying it to reused outdoor preparation quests is a provisional gate and flagged for confirmation. Sources: [attunement walkthrough](https://www.wowhead.com/news/how-to-become-attuned-to-city-of-dalaran-dungeon-as-horde-in-wow-forever-383256), linked Forever quest pages and their player reports.

Blood in the Streets requires the Magus patrol/key branches in the provisional model, not Keeper Bel'varil's companion branch: a player report on [92434](https://www.wowhead.com/forever/quest=92434/blood-in-the-streets) says the latter is optional. Alliance [92458](https://www.wowhead.com/forever/quest=92458/heart-of-disruption) is grouped under [92432](https://www.wowhead.com/forever/quest=92432/an-alarming-request) without imposing a completion gate; the report describes direct pickup. The Horde objective names a Tarren Mill return while the guide describes Modera pickup; exact return contact is still flagged. Quest/key possession is not treated as proof the dungeon is currently accessible. Routes retain text-only stops where coordinates are unknown.

## Received Records

Party-supplied records are unverified and stored separately. They contain only bounded descriptive fields and restrictions, not executable Lua or XP rewards. Their sender/version identifies provenance, not trust. An updated bundled catalog replaces their effective record automatically. They cannot supply a new dungeon or propagate to another party.
