# Changelog

## 0.6.3 - 2026-11-07

### Pickup routing

- Select multiple dungeons with the spyglass on their dungeon cards. The combined route groups pickups at shared stops and lists each quest once.
- Follow the next steps in a movable overlay that stays visible while the main addon window is closed. The background fades away when you move the cursor off it.
- Automatically update TomTom or supported Blizzard waypoints as you pick up quests. The overlay and its map button also work on their own.

### Quest data and fixes

- Added The Drowned City's eight dungeon quests and five lead-ins. Individual quest pages supply the published XP where available.
- Added initial Krol'dok Stronghold coverage with Vengeance of the Highborne. Additional quests still need exact IDs, and unverified XP remains unknown.
- Fixed a blocked world-map action, a crash when Forever returns waypoint coordinates as a plain table, and display overlap between the main window and pickup tracker.
- Reduced unnecessary list refreshes on XP gains and let the world map and pickup overlay share a route rebuild when they show the same route.

## 0.6.2 - 2026-11-06

### Quest updates and fixes

- Fixed Tools and XP Records failing when opening copyable text windows: wrapped text is now measured with a FontString rather than an unsupported EditBox method. Tightened the UI mock and added menu/export regressions.
- Deferred notices while XP Records is open, fixed window fitting on very small screens, and tightened flight-measurement and translation-format validation.
- Reduced redundant party-capability refreshes and route-search allocations; added exhaustive small-graph routing and adversarial regression checks.
- Added partial French, German and Spanish UI translations with English fallback, format-placeholder validation and wider/wrapping XP Records buttons.
- Added on-demand party version/protocol reporting. Different addon versions can remain compatible; absent or stale replies stay unknown, and response opt-out is respected.
- Added optional local flight-time recording, fastest-measured transport routing with a clear fallback, recorded flight-approach markers and conditional previews of later prerequisite steps.
- Improved bind-location confirmation and cooldown refreshes. Estimated flight times cannot make the planner assume a second Hearthstone is ready.
- Checked all 460 quest records against current reward sources. Added published XP for An Alarming Request (650) and Friend of the Kirin Tor (270).
- Replaced estimate, player-report and Classic-fallback labels on eight rewards with matching published Forever rewards. Their amounts are unchanged.
- Removed blanket beta and attunement warnings from source-reviewed quests, and updated known Wetlands contacts and the Southshore pickup for An Alarming Request.
- Kept warnings for missing rewards, conflicting requirements, uncertain access and Classic-source data that still needs Forever review.

## 0.6.1 - 2026-11-05

### New features

- Mark favourite dungeons and save preference profiles for different ways of using the addon.
- Adjust the window scale, enlarge quest text, and reset window positions from Options.
- Choose loot-alert sounds, sound channels and display duration, or mute alerts entirely.
- Check party quest readiness in a dedicated, scrollable view.
- Enable reminders when entering a dungeon or when a quest-chain step becomes available. Notifications wait until combat ends.
- Optionally record quest XP and export it from the new XP Records screen to help improve the data. Records stay on your computer unless you share them. Reports are reviewed before they change addon data.
- Create diagnostic reports to help troubleshoot problems, and see clearer explanations of why filters hide quests or dungeons.

### Bugs fixed and quest updates

- Fixed missing XP rewards appearing as **0 XP**. Unconfirmed rewards now show **XP unknown** in turn-ins, XP Records and diagnostic reports.
- Added provisional rewards for 27 quests, including Fallen in the Fen, Heartwoven, Prehistoric Prism, The Grave Knight, Unending Torment follow-ups and both Destruction in Deadmines steps.
- Fixed turn-in route grouping treating uncertain rewards as though they could safely be handed in without affecting a level-up.
- Added both Rear Guard Patrol steps before The Wrath of Rath'mael and all three A Recipe For Death steps before The New Plague.
- Updated the published rewards for Nara Wildmane and Chief Engineer Scooty.

XP rewards are still being checked against the live game. Published values, player reports, estimates and Classic fallbacks remain labelled, and will be updated as better information becomes available.

## 0.6.0 - 2026-11-03

### New features

- Expanded pickup routing to all 35 supported dungeon and wing entries.
- Added flight paths, boats, zeppelins and the tram to help plan travel between pickup zones.
- Track learned flight paths per character, with manual controls for routes the addon has not observed yet.
- Include your Hearthstone when its destination and cooldown are known. The planner reserves it for one use across the route.
- Added optional dungeon-entrance stops, next-stop map focus, map guide lines and TomTom waypoint support where available.
- Show active prerequisite objectives and ready prerequisite turn-ins alongside the pickups needed to prepare for a dungeon.
- Added separate routing preferences for gray quests, breadcrumbs and class quests.

### Improvements and quest updates

- Reduced repeated quest-log checks when opening dungeon lists, checklists, pickup routes and turn-ins.
- Improved route starts using your current position and kept map floors and alternative quest givers separate.
- Marked dungeons not tested in beta as using provisional data. Announced dungeons without known quests remain visible for future updates.
- Updated Ruins of Lordaeron pickup levels to 15 and flagged its changed prerequisites for review.

Travel information remains provisional. Routes show unresolved journeys rather than assuming travel times or learned flight paths.

## 0.5.5 - 2026-10-18

### Quest updates

- Added published XP rewards for Starving Arcane and Highland Hides.
- Improved pickup and turn-in locations for Dalaran, Wetlands and Hall of Thanes quests, including Modera's map location.
- Updated Dalaran access notes following the removal of its Horde outdoor access.
- Removed outdated warnings about the missing Titan Relic after Blizzard's fix.

## 0.5.4 - 2026-10-13

### New features and improvements

- Dungeon searches now show matching results even when your normal filters would hide them. Clearing the search restores your filters.
- Made the standard window smaller while keeping detailed quest information readable.
- Added compact layouts to every screen, including Options and pickup routes.
- Loot alerts can now be dragged to a new position and dismissed by clicking anywhere on the alert. Their position is saved between sessions.
- Made the dungeon list faster to refresh.

### Bugs fixed and quest updates

- Improved pickup-pin refreshes when opening or changing maps, including temporary gaps in map data.
- Reviewed prerequisite chains and made required steps, optional referrals and alternative branches clearer.
- Corrected Hidden Enemies and several higher-level return chains, including the Horde version of Bodley's Unfortunate Fate.
- Fixed pickup routes and party sharing losing some alternative or active-quest requirements.

## 0.5.3 - 2026-10-12

### New features and improvements

- Expanded quest coverage beyond the original beta level range, including Classic dungeon class quests and follow-up chains.
- Added placeholders for the remaining announced Forever dungeons where quest details were unavailable.
- Improved quest matching and reduced unnecessary searches through the full quest catalogue.

### Bugs fixed

- Confirmed ready dungeon quests remain available in turn-ins up to level 60, without a level-35 cap.
- Removed local research and testing documents from the published project.

Higher-level Classic quest data remains provisional until checked in Forever.

## 0.5.2 - 2026-10-09

### Bugs fixed and quest updates

- Removed Stone Tokens and Bracers of Binding from Dalaran tracking because they were not part of the dungeon's required quest chain.
- Checked that The Grave Knight appears correctly before pickup, while active, when ready to turn in and after completion.

## 0.5.1 - 2026-10-09

### New features and quest updates

- Added six City of Dalaran quests for Horde and Alliance characters.
- Added Shrewd Negotiations and Friend of the Kirin Tor beneath their Heart of Disruption chains, including ready turn-ins.
- Updated Dalaran's recommended level range to 28–34 and clarified that one keyholder can open the group entrance.
- Updated access notes to distinguish optional referrals and companion quests from required preparation.

## 0.5.0 - 2026-10-07

### New features

- Added a pickup-route screen for 13 dungeon entries, showing available quests, prerequisite preparation and tasks that need to be completed inside the dungeon.
- Added numbered world-map pins with quest-giver tooltips. Click a pin to open its pickup stop.
- Grouped pickups at the same location so their quest givers and quests appear together in the tooltip.
- Start routes in your current zone when suitable pickups are nearby, with a nearby quest cluster as the fallback.
- Keep ready turn-ins at the same location together when doing so will not delay another quest across a predicted level-up.
- Added provisional City of Dalaran attunement and preparation chains for both factions.

### Improvements and quest updates

- Reduced repeated map lookups and route rebuilding when redrawing the world map.
- Updated published rewards for Hall of Thanes and Blackfathom Deeps quests.
- Added Fallen in the Fen as the follow-up to Songblade Search.

## 0.4.4 - 2026-10-04

### Bugs fixed

- Added the missing Head of Arugal reminder for Arugal Must Die.
- Expanded named-mob quest-item reminders across the supported dungeon catalogue and selected outdoor chain objectives.
- Improved detection of the Alliance Baron's head item.
- Fixed reminders for different items in the same quest suppressing one another, while still avoiding duplicate alerts for the same item.

## 0.4.3 - 2026-10-04

### Bugs fixed and improvements

- Fixed Shadowfang Keep being hidden while you had an active quest such as The Book of Ur.
- Keep dungeons with active or ready quests visible outside your usual level range by default. Explicit strict-filter settings are still respected.
- Reduced repeated quest-state and prerequisite checks when building turn-ins and checklists.
- Updated 30 quest rewards across eight dungeons using individually published beta values.

## 0.4.2 - 2026-10-03

### New features and quest updates

- Added Razorfen Downs, Uldaman and Scarlet Monastery Cathedral, including known faction quests, class objectives and follow-ups.
- Expanded Excavation Site: Wetlands with Open the Maw, Dragonmaw Rumors, Seeking Caitlin, Heartwoven, Prehistoric Prism and Earthen Echo.
- Replaced 16 XP estimates with quest-specific player reports, labelled separately from verified rewards and estimates.

## 0.4.1 - 2026-10-02

### New features

- Added Stockade loot reminders for Bazil Thredd's head, Targorr's head, Dextren Ward's hand and Deepfury's head.
- Added reminders for Mad Magglish's port, Thistlenettle's badge, Techbot's core and Roogug's vial.
- Added loot-window detection to support named mobs that do not generate a boss-kill notification, including auto-loot checks.

### Bugs fixed

- Improved encounter detection and prevented duplicate alerts from multiple notifications for the same kill.
- Suppressed reminders for quest items already collected.

Multi-item collection quests remain excluded to avoid repeated alerts.

## 0.4.0 - 2026-10-02

### New features

- Added quest-item loot alerts for supported bosses, with a notification sound and automatic fade-out.
- Added a Preview Alert button in Options so you can test the banner without killing a boss.
- Grouped follow-up quests beneath their original quest in both standard and compact checklists.
- Added the Unending Torment chain, Deadmines and Stockade follow-ups through the Seal of Wrynn reward, and additional class-quest return chains.
- Included ready follow-ups in global turn-ins even when checklist filters hide their dungeon.

### Bugs fixed and improvements

- Fixed the Blizzard-only action warning on reload by replacing restricted combat-log use with public boss notifications.
- Reduced unnecessary turn-in calculations and combined repeated updates into a single refresh.
- Corrected the quest IDs and links for An Unholy Alliance.

Loot alerts depend on known item mappings and the notifications available from the client; they cannot guarantee a drop or loot eligibility.

## 0.3.1 - 2026-10-02

### Addon rename

- Renamed the addon, window title, installation folder and release zip to **DungeonQuestTrackerForever**.
- Kept the `/dqt` command and existing settings format compatible. The GitHub repository address stayed the same.

When upgrading from the original name, remove the old `DungeonQuestTracker` addon folder before installing the renamed version. To retain settings, close WoW and copy the old `DungeonQuestTracker.lua` SavedVariables file to `DungeonQuestTrackerForever.lua` if the new file does not already exist. Keep only one addon copy installed.

## 0.3.0 - 2026-10-02

### New features

- Added a scrollable Options screen with saved quest and dungeon filters, level-range controls, minimap settings and party-sharing preferences.
- Hide gray and red quests and dungeons by default while preserving ready turn-ins and required prerequisite steps.
- Added compact mode with a title-bar toggle and simplified, scrollable lists.
- Added the first Excavation Site: Wetlands quests and more follow-ups for Ragefire Chasm and Wailing Caverns.

### Bugs fixed and improvements

- Fixed confusion between different steps of quest chains that share the same name.
- Moved the minimap button outside the minimap.
- Improved dungeon tooltips and repositioned the compact-mode and Options buttons.
- Corrected Stockade rewards that had been labelled as Forever values instead of Classic values.
- Updated XP estimates to account for the reduction to the dungeon-quest XP bonus.

## 0.2.0 - 2026-10-01

### New features

- Added Blackfathom Deeps, Gnomeregan, Razorfen Kraul, and Scarlet Monastery Graveyard, Library and Armory for the level-30 beta.
- Added visible placeholders for Excavation Site: Wetlands and City of Dalaran.
- Added dungeon search, quest-status icons, individual quest sharing and party summaries on dungeon cards.
- Added optional party quest-data sharing so missing quest information can be received from other addon users. Shared XP is not used for turn-in ranking.
- Added source and confidence notes to help identify provisional quest information.

### Bugs fixed

- Removed duplicate shared quests from global turn-ins.
- Fixed long text overflowing checklist, dungeon and turn-in rows. Background updates now preserve your scroll position.
- Fixed empty dungeon entries disappearing from the list.
- Improved class and race filtering, quest readiness, compatibility with missing client APIs and party-data handling.
- Clarified that requesting a quest share does not mean the other player accepted it.

## 0.1.0

### Initial release

- Dungeon quest checklists with pickup locations and prerequisite information.
- Completed, in-progress and ready-to-turn-in quest tracking.
- Global turn-in priorities based on quest XP and your character's progress toward the next level.
- Minimap button, party quest checking and Share All.
