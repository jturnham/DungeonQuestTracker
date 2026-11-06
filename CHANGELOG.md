# Changelog

## 0.6.1 - 2026-11-05

- Extend the zero-XP sweep with 15 additional source-linked provisional rewards: seven Dalaran quests, four separate Unending Torment stages, both Destruction in Deadmines stages, Seeking the Kor Gem and An Underrated Talent. Keep unresolved/conflicting rewards unknown across turn-ins, recorder summaries and diagnostics; add catalogue-wide missing-reward regression coverage.
- Add 12 provisional, source-linked published guide rewards, including Fallen in the Fen (6,150), Heartwoven (6,150), Prehistoric Prism (6,950), and The Wrath of Rath'mael (4,600). Show unknown/unverified or gray-scaled turn-in XP as unknown rather than a false zero, and keep uncertain rewards from establishing safe route regrouping.
- Add launch-reported Ruins preparation chains: both Rear Guard Patrol steps before The Wrath of Rath'mael, and all three A Recipe For Death steps before The New Plague. Include their pickup/return records and retain unknown preparation XP explicitly.
- Review dated individual reward pages: Nara Wildmane is 120 XP (replacing the 115 estimate), and Chief Engineer Scooty is 280 XP (separate from its 275 Classic fallback). Other uncertain/dated rewards retain their provenance; no blanket launch multiplier applied.
- Explicitly ignore personal beta-repair helpers and reject repair code in release packaging. Personal repair data remains local-only.

- Add per-character favorites, reusable preference profiles, bounded addon scaling, larger quest text and position resets without copying travel knowledge, XP observations or sharing consent.
- Add configurable loot-alert duration, sound presets/mute/channel; scrollable on-demand party readiness; opt-in combat-deferred entry/chain notices and session suppression.
- Add local diagnostic previews/manual reports, structured filter explanations, English-fallback UI localization hooks, compact status labels and keyboard navigation for supported inputs.
- Add locked validation dependencies, read-only validation CI/test artifacts and separately dispatched tagged-release publication. Importers now emit provenance-labelled review proposals rather than overwriting runtime data.

- Add opt-in local dungeon quest XP recording, bounded retention, raw event/reward-panel context and an XP Records summary/manual export screen. No automatic uploads or changes to turn-in ranking.
- Add a manual observation issue template and data-only offline reviewer that cross-checks trusted bundled quest/reward provenance, flags conflicts and suspicious context, deduplicates exact reports and requires independent maintainer verification. No automatic data promotion or crowd-vote acceptance.

## 0.6.0 - 2026-11-03

- Include an optional ready Hearthstone in pickup itineraries only when its destination, bag ownership and client cooldown are known. Record new binds automatically or confirm an existing bind zone in Travel while at the bound inn. Reserve it once across the complete itinerary; unmeasured travel never resets its hour cooldown.

- Add a versioned provisional travel network with 67 flight records and 288 directed base-fare connections, plus sourced Classic boat, zeppelin and tram links. No runtime downloads or guessed durations.
- Record character-specific learned flights from supported taxi-map observations, add manual flight knowledge controls, and distinguish unknown from explicitly unlearned routes. Unknown flights require opt-in.
- Add transport-aware pickup-zone ordering, explicit unresolved legs, recent quoted fare labels and ready prerequisite return itineraries without simulating future quest completion.
- Add optional same-map guide segments and feature-detected TomTom focus, cleaning up only DQT-created lines and waypoints.

- Expand pickup routes to all 35 dungeon/wing entries, with independent gray/breadcrumb/class preferences, refresh/reset controls and next-stop map focus.
- Use guarded same-map player positions, explicit map/floor IDs and recorded alternative contacts. Keep different coordinate spaces separate and retain zone-cluster fallbacks.
- Add optional entrance destinations and distinct/shared entrance pins, with sourced provisional approaches for Ragefire Chasm, The Stockade and Hall of Thanes. Unknown entrances remain text-only.
- Show active/ready required prerequisites as objective/turn-in tasks rather than new pickups; preserve required preparation when optional route filters would otherwise hide it.

- Label all non-beta dungeon coverage as provisional in the dungeon list and checklist, including compact mode. Retain sourced higher-level Classic quests and five empty announced-Forever placeholders; uncertain Cathedral beta coverage is explicitly provisional.

- Reuse per-refresh quest-log snapshots in turn-in, checklist, pickup and status scans; skip unused turn-in rankings when sharing quests or sending party status.
- Set Ruins of Lordaeron quest pickup levels to 15 from Blizzard's November 2 notes. Flag exact prerequisite changes for verification when updated quest data is available; do not invent replacement links or XP values.

## 0.5.5 - 2026-10-18

- Add published October 16 rewards for Starving Arcane (9400 XP) and Highland Hides (1150 XP), retaining explicit unverified scaling/source labels.
- Update Dalaran, Wetlands and Hall of Thanes pickup/return coordinates from published beta logs, including Modera's Silverpine Forest map location.
- Note the October 15 removal of Horde outdoor Dalaran access without assuming dungeon access or historical follow-ups were removed.
- Remove outdated Wetlands missing-relic warnings following Blizzard's documented fix.

## 0.5.4 - 2026-10-13

- Let dungeon searches bypass visibility filters without changing saved settings; clearing the search restores normal filtering.
- Refresh pickup pins when opening or changing maps, preserve known locations during temporary map-data gaps and keep automatic route starts responsive to the current zone.
- Dismiss loot alerts with a click-to-fade, replace the close button with dragging and save the alert position across reloads.

- Speed up dungeon-list refreshes with a per-refresh quest-log snapshot and shared quest-state, completion and availability checks. Reuse card click handlers and unchanged dungeon art without caching stale quest states across refreshes.

- Reduce the regular window to 700 by 570 while retaining detailed quest information and readable text.
- Use compact layouts on every addon screen, including responsive Options and condensed pickup routes with full tooltip details.

- Review prerequisite records across the complete catalogue; distinguish required chain steps, optional referrals, active-log conditions and alternative faction/class branches.
- Correct Hidden Enemies and high-level return-chain gates; keep optional referrals optional and add the Horde Bodley's Unfortunate Fate return.
- Preserve active/alternative prerequisite conditions in pickup routes and bounded party data sharing; show explicit required/optional chain notes.
- Keep incomplete Forever source checks flagged for verification rather than claiming client-confirmed eligibility.

## 0.5.3 - 2026-10-12

- Keep the entire Docs directory local-only and remove previously tracked research/testing files without deleting local copies.
- Add Classic-source dungeon quest coverage beyond the original beta range, including class objectives and return chains. Forever rewards and changed eligibility remain unverified.
- Add remaining announced Forever dungeon placeholders without inventing unavailable quest lists.
- Add coverage checks for ready dungeon turn-ins at level 60; no level-35 runtime cap applies.
- Avoid catalogue-wide title scans when quest-log IDs are available, including renamed beta quests; retain safe legacy title-only matching.

## 0.5.2 - 2026-10-09

- Remove Stone Tokens and Bracers of Binding from Dalaran tracking: neither belongs to the dungeon or its required key chain.
- Recheck Dalaran quest coverage and add default-filter visibility tests for The Grave Knight's missing, active, ready and completed states.

## 0.5.1 - 2026-10-09

- Add six City of Dalaran dungeon quests for Horde and Alliance, plus Shrewd Negotiations and Friend of the Kirin Tor as grouped Heart of Disruption continuations. Include faction-aware pickups and ready turn-ins.
- Refresh Dalaran access notes following the October 8 opening: one keyholder can open the group entrance; Keeper Bel'varil's companion branch and the Alliance referral are optional. Update the recommended range to 28-34.
- Review current dungeon sources without applying the creature-kill XP increase to quest rewards. Dalaran XP, exact coordinates, outdoor level assumptions and remaining contact/chain details await client confirmation. Quest XP values remain in flux and will be updated as reliable information becomes available.
- Add regression coverage for level-28 pickups, independent dungeon quests, prerequisite gates and both factions' follow-up turn-ins.

## 0.5.0 - 2026-10-07

- Add nine City of Dalaran attunement/preparation records for both factions, visibly awaiting final verification. Keep separate Heart of Disruption IDs, optional companion/referral branches, unknown XP/coordinates and explicit access/contact/level caveats. Enable its text pickup route and global ready turn-ins.
- Review pending data corrections: replace four Hall of Thanes XP estimates with published post-update rewards, correct Amongst the Ruins to 6550 XP and source Horde Blackfathom Villainy at 7850 XP. Add Fallen in the Fen as the Songblade Search continuation with unknown XP. Document unresolved Hall/location conflicts and newly sourced Dalaran attunement coverage separately.
- Index the client map hierarchy once per map root, cache ambiguous/missing map lookups, resolve each zone once per pin pass and reuse pickup plans across map redraws until quest, level, XP, zone or DQT party-data events invalidate them. Precompute within-zone route distances and avoid a redundant global cluster scan when local pickups exist.
- Start pickup routes in the player's current zone when eligible pickups are present, refresh on zone changes and replace manual zone selection with an automatic starting-zone display. Retain cluster selection as a fallback where no local pickups exist.
- Group overlapping pickup map pins, mark shared locations with a plus sign and show each numbered quest giver and its quests in separate tooltip sections.
- Add numbered world-map pickup pins with quest-giver tooltips and click-to-open pickup stops. Resolve zone maps from the client hierarchy, omit ambiguous/unpositioned locations, refresh on quest changes and keep existing user waypoints untouched. Beta-client verification is still required.
- Use nearby eligible missing-quest clusters and faction-city tie-breaks for pickup-start fallback and within-zone ordering.

- Keep ready turn-ins at the same recorded area together when cumulative XP permits, without delaying another quest across a projected level-up. Preserve the original XP-priority order when future thresholds, rewards or locations are unknown.

- Add a pickup-route view for thirteen dungeon entries including provisional Dalaran preparation, using character eligibility and completion state, shared giver stops, known prerequisite preparation and separate blocked/dungeon/unmapped tasks.
- Suggest pickup ordering within each zone from recorded coordinates, with current-zone starts and live quest refresh. Cross-zone travel, terrain, exact start position and entrance arrival are not optimized.
- Add level-28 Horde/Alliance route, state, coordinate-order, UI, compact-mode and navigation regressions.

## 0.4.4 - 2026-10-04

- Audit single-copy named-mob quest drops across the catalogue and expand reminders for Ragefire Chasm, Deadmines, Wailing Caverns, Blackfathom Deeps, Hall of Thanes, Wetlands, Gnomeregan, Razorfen Kraul, Razorfen Downs and Uldaman, plus named-mob chain objectives outside instances.
- Add the Alliance Baron's head item ID for loot-window detection. Deduplicate reminders by quest and item so distinct boss items in one quest each get an alert.

- Add the missing Head of Arugal loot reminder for Arugal Must Die, including boss/encounter notifications and a Shadowfang Keep loot-window fallback.

## 0.4.3 - 2026-10-04

- Review all 189 quest records against current published XP sources; update thirty records with individually published October 1 build rewards across eight dungeons. Label these as published beta values, not local verification; retain estimates and Classic fallbacks where current rewards are unknown.
- Avoid repeated shared-quest state checks and unused status row allocations in global turn-in scans; traverse each shared prerequisite only once per checklist refresh.
- Make the unfinished-dungeon filter include active and ready quests, not only missing/locked quests, so current Book of Ur progress does not hide Shadowfang Keep. Rename the option to describe its behavior.
- Keep dungeons and active quest rows visible outside the level range by default when current quests are tracked. Migrate the previous default without overriding an explicitly chosen strict-filter setting.

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
