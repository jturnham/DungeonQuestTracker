# DungeonQuestTrackerForever

A World of Warcraft: Forever addon for finding, collecting and turning in dungeon quests.

## Features

- Searchable, scrollable dungeon list with artwork, level ranges and party summaries.
- Collapsible checklists showing completed, ready, active, missing and locked quests.
- Pickup and turn-in locations, prerequisite chains and grouped dungeon quest follow-ups.
- Faction, class, race and level-aware quest tracking.
- Global turn-in priority based on your level, XP and potential reward loss after leveling.
- Nearby turn-ins grouped together when doing so preserves XP priority.
- Pickup routes for higher-level dungeons, starting in your current zone when eligible pickups are available.
- Numbered world-map pickup pins with combined tooltips for shared locations.
- Compact and full display modes with saved preferences.
- Filters for quest completion, availability, level range and pickup type.
- Movable minimap button.
- Party quest status checks and individual or Share All quest sharing.
- Optional party quest-data sync for records missing from your addon catalog.
- Quest-item loot reminders with sound, dismissal, fade-out and an Options preview.

## Screenshots

### Dungeon List

![Dungeon list with artwork, quest totals, search and party status](https://raw.githubusercontent.com/jturnham/DungeonQuestTracker/main/images/dungeon-list.png)

### Quest Checklist

![Quest checklist with completion states, expandable details and sharing controls](https://raw.githubusercontent.com/jturnham/DungeonQuestTracker/main/images/quest-checklist.png)

### Turn-In Priority

![Global turn-in list with XP rewards, locations and level-up warnings](https://raw.githubusercontent.com/jturnham/DungeonQuestTracker/main/images/turn-in-priority.png)

### Quest Loot Alert

![Quest Loot banner showing a quest item reminder and the Options preview](https://raw.githubusercontent.com/jturnham/DungeonQuestTracker/main/images/loot-alert.png)

Loot alerts cover known single-copy quest items from named mobs. Multi-item collection quests are excluded to avoid spam. Where a kill notification is unavailable, the reminder may only appear after opening the corpse's loot window. Alerts do not guarantee a drop or loot eligibility.

## Tracked Dungeons

- Ragefire Chasm
- Hall of Thanes
- Ruins of Lordaeron
- Wailing Caverns
- The Deadmines
- Shadowfang Keep
- The Stockade
- Blackfathom Deeps
- Excavation Site: Wetlands
- City of Dalaran
- Gnomeregan
- Razorfen Kraul
- Razorfen Downs
- Uldaman
- Scarlet Monastery: Graveyard, Library, Armory and Cathedral
- Zul'Farrak, Maraudon and The Sunken Temple
- Blackrock Depths, Lower Blackrock Spire and Upper Blackrock Spire
- Dire Maul: East, North and West
- Scholomance and Stratholme: Main Gate and Service Gate

Higher-level Classic quests are included through level 60 using Classic-source data. Their availability, chains and XP in Forever still need beta verification. There is no level-35 tracking cap; the normal level filters can be changed in Options.

## Planned Dungeon Coverage

Empty placeholders are included for these dungeons. Quest tracking is not implemented for them yet; their presence does not imply they are currently available in the beta.

- The Drowned City, Krol'dok Stronghold, Alcaz Prison, Blackmaw Hold and Shaper's Terrace

## Install

Download the addon ZIP from the [GitHub releases](https://github.com/jturnham/DungeonQuestTracker/releases) and extract it into your client's `Interface/AddOns` directory. The resulting layout should be:

```text
Interface/AddOns/DungeonQuestTrackerForever/DungeonQuestTrackerForever.toc
```

Use the named addon ZIP, not GitHub's source-code archive. Replace the existing addon folder when upgrading, and remove any old `DungeonQuestTracker` folder so only one copy loads. Restart WoW or use `/reload` after updating.

## Usage

Open the addon with `/dqt` or the minimap button. Left-click the minimap button for the dungeon list, right-click for turn-ins, or drag it to reposition.

- `/dqt list`: list dungeon keys.
- `/dqt dungeon <key>`: open a dungeon checklist.
- `/dqt turnins`: open global turn-in priority.
- `/dqt options`: open settings.
- `/dqt minimap`: toggle the minimap button.
- `/dqt debug <questID>`: show quest diagnostics.

Select a dungeon to view its checklist, check party progress or share quests. Use the map button on supported higher-level checklists to view pickup routes. Click a pickup stop to open its zone map; hover numbered pins for quest details.

## Options

Use the title-bar gear button or `/dqt options` to adjust:

- Quest and dungeon filters, including gray/red level ranges and completed quests.
- Compact mode and quest-loot alerts, including Preview Alert.
- Turn-in filtering.
- Minimap visibility and position.
- Party responses, automatic status broadcasts, sharing confirmation and data sync.

Settings persist across reloads. By default, active and ready quests keep their dungeon visible outside its level range. The global turn-in planner is independent of checklist and dungeon display filters.

Party status checks require responding members to have the addon installed. Quest sharing uses the game's eligibility rules. Party data sync is opt-in on both clients; received records are marked unverified and do not supply XP for ranking.

## Beta Data

**Quest XP values are in flux during the Forever beta and are updated as reliable information becomes available.** Rewards, locations and prerequisites may still be provisional. Turn-in priorities and predicted level-ups are estimates, not guarantees.

Pickup routes suggest an order from recorded locations; they do not account for terrain, exact player position or cross-zone travel time. Missing or uncertain coordinates remain text-only.

See the [changelog](https://github.com/jturnham/DungeonQuestTracker/blob/main/CHANGELOG.md) for release history.

## License

Addon code is released under the [MIT License](https://github.com/jturnham/DungeonQuestTracker/blob/main/LICENSE). World of Warcraft names and related game content belong to Blizzard Entertainment.
