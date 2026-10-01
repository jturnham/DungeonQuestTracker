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

## Received Records

Party-supplied records are unverified and stored separately. They contain only bounded descriptive fields and restrictions, not executable Lua or XP rewards. Their sender/version identifies provenance, not trust. An updated bundled catalog replaces their effective record automatically. They cannot supply a new dungeon or propagate to another party.
