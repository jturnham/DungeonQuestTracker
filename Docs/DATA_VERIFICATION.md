# Quest Data Verification

The beta catalog is provisional. `Data/QuestMetadata.lua` adds provenance and review notes without claiming that source-backed values were observed in the game.

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

## Received Records

Party-supplied records are unverified and stored separately. They contain only bounded descriptive fields and restrictions, not executable Lua or XP rewards. Their sender/version identifies provenance, not trust. An updated bundled catalog replaces their effective record automatically. They cannot supply a new dungeon or propagate to another party.
