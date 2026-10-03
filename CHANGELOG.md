# Changelog

## 0.4.2 - 2026-10-03

- Add Razorfen Downs and Uldaman with known faction quests, class objectives and return chains; add Scarlet Monastery Cathedral. Current beta quest levels and rewards still need verification; new classic-dungeon rewards use labelled Classic fallbacks.
- Expand Excavation Site: Wetlands with Open the Maw, Dragonmaw Rumors, Seeking Caitlin, Heartwoven, Prehistoric Prism and Earthen Echo; update provisional quest levels and chain notes. Wetlands XP remains unknown.
- Replace sixteen quest XP estimates with individual post-update player reports, labelled separately from local verification and formula estimates. Do not extrapolate a dungeon-wide bonus.

## 0.4.1 - 2026-10-02

- Add single-copy loot-window reminders for Mad Magglish's port, Thistlenettle's badge, Techbot's core and Roogug's vial (both Warrior quests), including entrance-area zone scopes. Multi-item collection drops remain excluded.
- Add Stockade reminders for Bazil Thredd's head, Targorr's head, Dextren Ward's hand and Deepfury's head; make their quest objectives explicitly mention looting.
- Support successful ENCOUNTER_END notifications alongside BOSS_KILL, with cross-trigger duplicate suppression.
- Add a read-only, instance-scoped loot-window fallback for known item IDs, without corpse GUIDs or combat-log access. Briefly delay auto-loot checks, suppress collected items and guard unavailable/secret loot data. Runtime client verification remains required.

## 0.4.0 - 2026-10-02

- Play a notification sound for new loot alerts and previews; fade the banner during its final second. Updating remaining loot does not replay the sound.

- Add a Preview Alert button beside the loot-reminder setting, showing the real dismissible banner with sample quest information without changing quest state.

- Reduce redundant turn-in rankings and reuse player context within dungeon scans. Search skips nonmatching dungeon scans; quest/XP and incoming party updates coalesce into a single UI refresh with no idle update callback. Added regression tests for scan/ranking counts and refresh batching.

- Remove restricted combat-log registration from loot reminders to prevent Blizzard-only action warnings on reload. Use public boss-kill notifications instead; reminder coverage depends on client encounter notifications.

- Group dungeon checklist follow-ups beneath their originating quests with indented labels in full and compact modes; retain chain names when ancestors are filtered out. Turn-in priority order is unchanged.

- Added optional, dismissible boss quest-loot banners with completion/faction/bag checks, active-objective and missing-starter handling, boss-notification deduplication and automatic dismissal after loot or 15 seconds. Initial known-drop coverage includes VanCleef, Mutanus, Charlga Razorflank, Witherfang and The Baron.

- Added every sourced Unending Torment continuation under Ruins of Lordaeron, using distinct quest IDs for same-title steps.
- Added Deadmines/Stockade continuations through the Seal of Wrynn reward, Scarlet Library Test of Lore and Mage's Wand returns, the shared Paladin forging reward, and Razorfen Kraul Warrior armor branches.
- Corrected An Unholy Alliance's scroll step to quest 6522 and linked its 6521 continuation to Razorfen Kraul.
- Catalogued follow-ups automatically join their originating dungeon lists, including shared class-quest origins, and appear once in the global ready turn-in planner independently of checklist filters.
- Continuation XP without confirmed data remains unknown; provisional inherited levels are explicitly noted. Automated coverage checks every catalogued continuation's ready/completed state and same-title isolation.

### Validation And Limitations

- XP values remain in flux during the Forever beta and are updated as new information becomes available. Turn-in priorities and predicted level-ups are provisional.
- Loot reminders depend on public boss-kill notifications and known drop mappings; they do not guarantee a drop or loot eligibility.
- Two-client party/sync testing remains deferred; quest-data sync is off by default.

## 0.3.1 - 2026-10-02

### Addon Rename

- Renamed the addon, UI, folder, TOC and release ZIP to DungeonQuestTrackerForever. The GitHub repository URL is unchanged.
- Updated documentation, packaging and validation tools for the new name. The `/dqt` command, party messaging and internal `DungeonQuestTrackerDB` variable remain compatible.
- When upgrading, remove the old `DungeonQuestTracker` folder from `Interface/AddOns` before extracting the new ZIP. With WoW closed, copy `WTF/Account/<account>/SavedVariables/DungeonQuestTracker.lua` to `DungeonQuestTrackerForever.lua` to retain settings; do not overwrite an existing new-name file. Only one addon copy should be installed.

### Validation And Limitations

- Automated syntax, data, UI, Options, compact-mode, party sync, compatibility, XP and follow-up tests pass; the renamed ZIP layout is verified.
- XP values are still in flux during the Forever beta and are being updated as soon as new information becomes available. Turn-in priorities and predicted level-ups remain provisional.
- Two-client party/sync testing remains deferred; quest-data sync is off by default.

## 0.3.0 - 2026-10-02

### XP Values Are In Flux

Forever beta quest XP is changing. Values are provisional and are being updated as soon as new information becomes available. All 56 known positive pre-patch Forever rewards now use a labelled bonus-reduction estimate: normal XP plus half the old bonus. Quest-specific baselines are used where available; otherwise a comparable same-level reward is assumed. Small rewards never increase. Classic-only and unknown rewards remain provisional; priority and predicted level-ups are not guarantees. Please report quest ID, client build, character level, exact reward and applicable bonuses.

### Added

- Scrollable Options with persistent checklist/dungeon filters, level gaps, minimap controls, party response/broadcast settings, and Share All confirmation.
- Gray/red quests and dungeons hidden by default, with ready turn-ins preserved in the independent global planner and required gray prerequisites retained.
- Compact/full modes with a title-bar toggle and simplified scrollable lists.
- Seven sourced Excavation Site: Wetlands quest records, faction branches and prerequisite notes. Unknown XP, provisional quest levels, incomplete contacts and unidentified follow-ups are explicitly noted; City of Dalaran remains a placeholder.
- Hidden Enemies return steps under Ragefire Chasm and both In Nightmares branches under Wailing Caverns.

### Fixed

- Same-name quest-log matching no longer confuses chain steps with different IDs.
- Minimap button positioned outside the map using its actual dimensions.
- Title-bar compact toggle beside Close, smaller Options gear, and clearer dungeon tooltips.
- Four Stockade Classic rewards previously labelled as Forever rewards; remaining old XP estimates now cover the full known catalog.

### Validation And Limitations

- Automated syntax, data, Options, compact layout, XP coverage, follow-up state, UI, sync and compatibility suites pass.
- Real-client layout and newly added Wetlands quests still need continued beta testing. Two-client party/sync testing remains deferred; data sync is off by default.
- The private implementation checklist is excluded from the repository and release ZIP.

## 0.2.0 - 2026-10-01

### Added

- Level-30 beta coverage with dungeon quest pickup requirements through level 35: Blackfathom Deeps, Gnomeregan, Razorfen Kraul, and Scarlet Monastery Graveyard, Library, and Armory.
- Excavation Site: Wetlands and City of Dalaran as visible placeholders with no recorded quests.
- Dungeon search, quest status icons, per-quest sharing, party summaries on dungeon cards, and control tooltips.
- Opt-in party quest-data sync with a validated, separate saved cache, provenance labels, bounded transfers, and rate limiting. Received XP is excluded from ranking and received records are not relayed.
- Quest source/confidence metadata, per-field verification notes, source-conflict warnings, and corrected first-wave chain notes.
- Comprehensive data validation, mocked-client regression suites, and a checked release packaging script.

### Fixed

- Shared dungeon quests appear once in the global turn-in planner.
- Long checklist, dungeon-card, and turn-in text wraps with measured row heights; background refreshes preserve scroll positions.
- Empty dungeon placeholders remain visible.
- Class/race context retrieval and unrelated class-quest visibility.
- Optional API guards and legacy fallbacks, failed-quest readiness handling, diagnostics, minimap guards, party sender validation, payload splitting, cooldowns, and stale-state handling.
- Sharing feedback distinguishes client requests from recipient acceptance.

### Validation And Known Limitations

- Maintainer reports a successful beta-client smoke test. Automated Lua 5.1, structural data, state, UI, sync, and compatibility checks pass.
- Two-client testing is deferred, including instance-realm data transfers; quest-data sync remains off by default.
- Some Forever XP values, minimum levels, pickup locations, and prerequisites are provisional or have conflicting sources. Turn-in priorities are provisional where rewards are not verified.
- Excavation Site and City of Dalaran have no recorded quests; this does not establish that they have no quests in the game.
- Gray-quest/level-gap filters and a full Options view are deferred.

## 0.1.0

- Initial dungeon checklist, completed/ready tracking, global turn-in planning, minimap navigation, party checking, and Share All.
