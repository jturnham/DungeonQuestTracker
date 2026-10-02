# Changelog

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
