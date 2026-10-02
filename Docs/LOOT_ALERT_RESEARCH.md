# Stockade Loot-Alert Investigation

Reviewed 2026-10-02. The researched approach is included in 0.4.1: four Stockade mappings, successful encounter-end notifications and an item-ID-based loot fallback. Automated tests pass; in-client notification/API verification is still pending.

## Quest-Item Mappings

| Named mob | Quest | Quest ID | Required item | Item ID |
| --- | --- | --- | --- | --- |
| Bazil Thredd | The Stockade Riots | 391 | Head of Bazil Thredd | 2926 |
| Targorr the Dread | What Comes Around... | 386 | Head of Targorr | 3630 |
| Dextren Ward | Crime and Punishment | 377 | Hand of Dextren Ward | 3628 |
| Kam Deepfury | The Fury Runs Deep | 378 | Head of Deepfury | 3640 |

The [Forever Stockade guide](https://www.wowhead.com/forever/guide/the-stockade-dungeon-overview-location-rewards) describes these four item objectives. The guide warns that beta data may be incomplete and some information may come from Classic. These are sourced mappings, not new observations from the installed client; drop eligibility and current beta behavior still need a run to verify.

Item identity references: [Bazil](https://www.wowhead.com/forever/item=2926/head-of-bazil-thredd), [Targorr](https://forever-codex.com/items/?id=3630), [Dextren](https://forever-codex.com/items/?id=3628), [Deepfury](https://www.wowhead.com/forever/item=3640/head-of-deepfury). Codex distinguishes client item identity from Classic-derived drop sources. Targorr's item ID is 3630, not 3639.

The Color of Blood (388) requires bandanas from multiple Defias, so it is not a single-named-mob mapping. Quell the Uprising (387) is kill credit, not an item reminder. The four bundled named-mob objective descriptions now explicitly describe looting the required item.

## Forever Client Notifications

Sources inspected are Blizzard UI files mirrored on Gethe/wow-ui-source's `forever` branch, not merely retail API documentation. They describe the published source branch, not necessarily the exact installed client build or server behavior.

- [Encounter API declarations](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/EncounterInfoDocumentation.lua) expose BOSS_KILL with encounter ID/name and ENCOUNTER_END with success and encounter metadata. Neither is marked HasRestrictions in these declarations. The local implementation now listens to both with cross-trigger duplicate suppression. There is no sourced proof here that each Stockade boss actually emits either notification.
- [Loot event declarations](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/LootDocumentation.lua) expose LOOT_READY, LOOT_OPENED, LOOT_SLOT_CHANGED, LOOT_SLOT_CLEARED and QUEST_LOOT_RECEIVED. Opening events describe loot access, not a boss death. QUEST_LOOT_RECEIVED is too late to remind someone to loot an item they have already collected.
- [Blizzard's loot window](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/LootFrame.lua) uses GetNumLootItems, GetLootSlotInfo and GetLootSlotLink. This supports investigating an item-ID-based fallback without needing corpse GUIDs. Blizzard UI use alone does not prove unrestricted third-party access; addon access and nonsecret values still need client confirmation. No GetLootSourceInfo-based solution was established.
- [Combat-log declarations](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/CombatLogDocumentation.lua) explicitly mark both combat-log events HasRestrictions. Do not reintroduce them or probe their registration to detect deaths.

## Recommended Implementation

1. Add the four item mappings, gated to active quests, missing items and the Stockade instance. Suppress completed/ready quests.
2. Prefer confirmed BOSS_KILL notifications; add successful ENCOUNTER_END as a secondary trigger only with duplicate suppression across both events.
3. Investigate a read-only loot-opening fallback that matches visible item IDs rather than guessing the corpse. Guard unavailable or secret values before reading/comparing them. Do not call LootSlot or auto-loot APIs.
4. Suppress notifications when auto-loot already acquired the item and avoid replaying sounds across duplicate events. Test full bags, manual loot and auto-loot.

A loot-opening fallback cannot warn before clicking a corpse, or identify a corpse the player never opens. If neither public encounter notification occurs, an entry reminder listing outstanding named-mob items is the honest pre-loot fallback.

## Remaining Client Test

Use Blizzard's Event Trace tool for a Stockade run. Record the client build and instance name, then capture BOSS_KILL and ENCOUNTER_END for each of the four targets. Capture LOOT_READY/LOOT_OPENED while opening their corpses, first with auto-loot disabled and then enabled. Confirm loot-slot item IDs are readable by an ordinary addon and that no ADDON_ACTION_FORBIDDEN or ADDON_ACTION_BLOCKED event occurs. A Blizzard-only tracer displaying a value is not proof that addons may read it.

No live Stockade run or event capture was available during this investigation. Notification delivery and third-party loot API access remain unverified; Stockade alert coverage starts with 0.4.1. Automated tests cover the new behavior, including absent/throwing APIs, secret values, auto-loot and full bags. No Blizzard loot actions or combat-log access are used.
