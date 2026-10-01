# Changelog

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
