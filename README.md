# DungeonQuestTracker

DungeonQuestTracker is a World of Warcraft: Forever addon for tracking dungeon quest readiness during beta leveling. It shows which dungeon quests your character has completed, has ready to turn in, is actively working on, or is still missing, along with pickup locations, turn-in locations, prerequisite notes, and turn-in priority.

The current target is the first beta wave up to roughly level 20, with extra support for the early Forever dungeon additions.

## Features

- Dungeon checklist UI with collapsible quest rows.
- Dungeon selection screen with scrollable activity-style dungeon cards.
- Global turn-in planner for all tracked dungeon quests.
- Turn-in priority based on quest XP, current player level, current XP, and whether a quest may drop to green or gray after leveling.
- Ready-for-turn-in detection for active quest-log quests.
- Completed quest detection using quest history APIs where available.
- Faction, class, race, minimum-level, and prerequisite-aware quest visibility.
- Minimap button with left-click to open DQT, right-click to open turn-ins, and drag-to-move support.
- Party quest status checking through addon messages when party members also have DQT installed.
- Share All button for the selected dungeon, using the game client's built-in quest sharing API for quests that are in your log and shareable.

## Tracked Dungeons

Current tracked dungeon data includes:

- Ragefire Chasm
- Wailing Caverns
- Deadmines
- Ruins of Lordaeron
- Hall of Thanes
- Shadowfang Keep
- The Stockade

Quest data is curated locally because the WoW API does not expose a complete dungeon quest catalog with pickup locations and prerequisite chains. XP values are intended to use Forever beta dungeon quest rewards where verified.

## Install

Download or build the addon folder so the final path looks like this:

```text
World of Warcraft/_classic_beta_/Interface/AddOns/DungeonQuestTracker/DungeonQuestTracker.toc
```

Then launch or reload the client and enable `DungeonQuestTracker` from the AddOns list.

For local development on this machine, the test install path has been:

```text
C:/Games/Blizzard/World of Warcraft/_classic_beta_/Interface/AddOns/DungeonQuestTracker
```

## Usage

Open the addon with:

```text
/dqt
```

Useful commands:

```text
/dqt list
/dqt rfc
/dqt wc
/dqt deadmines
/dqt rol
/dqt hot
/dqt sfk
/dqt stocks
/dqt turnins
/dqt debug
```

The minimap button also opens the addon:

- Left-click: dungeon list
- Right-click: global turn-ins
- Drag: reposition button

## Party Checking

Open a dungeon checklist and press `Check Party` to request quest status from party members.

Party checking works through WoW addon messages, so party members need DungeonQuestTracker installed and enabled to respond. Expanded quest rows show a summary of how many responding party members have each quest completed, ready, active, or missing/locked.

## Quest Sharing

Open a dungeon checklist and press `Share All` to attempt sharing every active or ready quest for that dungeon.

The client only allows sharing quests that are currently in your quest log and marked pushable by the game. Some quests cannot be shared because they start from drops, objects, class chains, prerequisite chains, or other restricted sources.

## Project Layout

```text
DungeonQuestTracker/
  DungeonQuestTracker.toc
  Config.lua
  Core.lua
  Data/
    DungeonData.lua
    QuestData.lua
  UI/
    MainFrame.lua
    MinimapButton.lua
Docs/
  IMPLEMENTATION_CHECKLIST.md
Tools/
  validate-data.ps1
```

## Packaging

From the repository root, create a tester zip that contains the `DungeonQuestTracker/` folder at the archive root:

```powershell
Compress-Archive -LiteralPath .\DungeonQuestTracker -DestinationPath .\DungeonQuestTracker-0.1.0.zip -Force
```

Testers can extract that zip directly into `Interface/AddOns`.

## Development Notes

- Current addon version: `0.1.0`.
- Current TOC interface: `16001`.
- Saved variables live in `DungeonQuestTrackerDB`.
- The UI intentionally uses native WoW frames and templates only, with no external addon library dependency yet.
- Quest state detection supports both `C_QuestLog` APIs and older fallback APIs where possible.
- Data accuracy is the main ongoing risk during beta because Forever quest rewards, availability, and custom dungeon data can change.

## Validation Checklist

Before sharing a build with testers:

1. Copy the addon folder into the Classic Beta AddOns directory.
2. Run `/reload` in-game.
3. Open `/dqt` and verify the minimap button, dungeon list, checklist view, and turn-ins view.
4. Check at least one character with completed dungeon quests and one with active/ready quests.
5. Test `Check Party` with another player running the addon.
6. Test `Share All` with shareable quests in your quest log.
7. Package a fresh zip after the final tested copy is confirmed.

## License

DungeonQuestTracker code is released under the MIT License. See `LICENSE`.

World of Warcraft names, quests, NPCs, locations, and related game content are trademarks and/or copyright of Blizzard Entertainment. Quest data in this addon is factual, curated, and written for addon functionality.