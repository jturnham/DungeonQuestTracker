local _, DQT = ...
local source="https://www.wowhead.com/forever/guide/city-of-dalaran-dungeon-overview-location-rewards"
local magus={name="Magus Wordeen Voidglare",zone="Hillsbrad Foothills",subzone="Tarren Mill"}
local modera={name="Image of Archmage Modera",zone="Alterac Mountains",subzone="Outside Dalaran, beside Lordamere Lake (confirm exact position)"}
local celindra={name="Archmage Celindra",zone="City of Dalaran",subzone="Violet Citadel (confirm exact position)"}
local melisara={name="Melisara",zone="Hillsbrad Foothills",subzone="Tarren Mill"}
local felben={name="Doctor Martin Felben",zone="Undercity",subzone="The Apothecarium"}
local rexxie={name="Rexxie Copperclutch",zone="City of Dalaran",subzone="Near the sewer entrance"}
local andromath={name="High Sorcerer Andromath",zone="Stormwind City",subzone="Mage Quarter"}
local shylamiir={name="Shylamiir",zone="Stormwind City",subzone="The Park, herbalist shop"}
local records={
    [544]={name="Prison Break In",faction="Horde",pickup=magus,turnIn=magus,objectives="Recover the traitors' bloodstone artifacts at Lordamere Internment Camp and return to Tarren Mill."},
    [545]={name="Dalaran Patrols",faction="Horde",followUpOf=544,pickup=magus,turnIn=magus,objectives="Kill 6 Dalaran Summoners and 12 Elemental Slaves, then return to Tarren Mill.",prerequisites={{questID=544,relationship="required",note="Complete Prison Break In first; exact Forever chain requirements await final verification."}}},
    [93680]={name="Key to the City",faction="Horde",pickup=magus,turnIn=magus,objectives="Recover the Grimy Key from the Dalaran camps for Magus Wordeen Voidglare."},
    [92434]={name="Blood in the Streets",faction="Horde",followUpOf=545,pickup=magus,turnIn=modera,objectives="Take the key to the sewer approach along Lordamere Lake and speak to Modera's image.",prerequisites={
        {questID=545,relationship="required",note="Complete Magus Voidglare's patrol branch; awaiting final verification."},
        {questID=93680,relationship="required",note="Recover and turn in the Grimy Key; awaiting final verification."},
        {relationship="breadcrumb",note="Keeper Bel'varil's companion quests are omitted from the October 9 key walkthrough and do not gate this quest."}}},
    [96984]={name="Heart of Disruption",faction="Horde",followUpOf=92434,pickup=modera,turnIn=magus,objectives="Receive the Dalaran Sewer Key and recover the Arcane Mote inside the dungeon. The quest objective names a Tarren Mill return; confirm the return contact in-client.",prerequisites={{questID=92434,relationship="required",note="Complete Blood in the Streets; the guide places pickup at Modera's image, while the quest objective names a Tarren Mill return. Confirm both contacts in-client."}}},
    [92432]={name="An Alarming Request",faction="Alliance",breadcrumbOnly=true,pickup={name="Unknown Kirin Tor emissary (awaiting verification)",zone="Unknown pickup location"},turnIn=modera,objectives="Report to Modera's image beside Lordamere Lake. The exact emissary and pickup location are not yet confirmed."},
    [92458]={name="Heart of Disruption",faction="Alliance",followUpOf=92432,pickup=modera,turnIn=modera,objectives="Receive the Dalaran Sewer Key and recover the Arcane Mote for Modera. Access and exact return location await verification.",prerequisites={{questID=92432,relationship="breadcrumb",note="An Alarming Request introduces Modera. The attunement report describes direct Alliance pickup; this lead-in is not enforced as a required gate until verified."}}},
    [96986]={name="The Grave Knight",faction="Horde",pickup=melisara,turnIn=melisara,objectives="Defeat Atrexis the Grave Knight inside the City of Dalaran and return to Melisara in Tarren Mill."},
    [96988]={name="Source of Power",faction="Horde",pickup=felben,turnIn=felben,objectives="Collect 6 Cracked Sentry Cores inside the City of Dalaran and return to Doctor Martin Felben in Undercity."},
    [96987]={name="Opportunistic Education",faction="Horde",pickup=rexxie,turnIn=rexxie,objectives="Recover The Founding of Dalaran from the library and return to Rexxie Copperclutch near the sewer entrance."},
    [92489]={name="Power Overwhelming",faction="Alliance",pickup=andromath,turnIn=andromath,objectives="Defeat Arcanic Enigma inside the City of Dalaran and return to High Sorcerer Andromath in Stormwind."},
    [92456]={name="A Green Sample",faction="Alliance",pickup=shylamiir,turnIn=shylamiir,objectives="Recover a Fel Infused Blossom from Dalaran's central garden and return to Shylamiir in Stormwind."},
    [92457]={name="Starving Arcane",faction="Alliance",pickup=modera,turnIn=modera,objectives="Defeat 8 Seeking Remnants, 8 Saturated Remnants and 8 Mana Echoes inside the dungeon. Report to Archmage Modera outside Dalaran; confirm the pickup contact in-client."},
    [97287]={name="Shrewd Negotiations",faction="Horde",followUpOf=96984,pickup=magus,turnIn=celindra,objectives="Take the provided Arcane Mote to Archmage Celindra in the City of Dalaran. Pickup contact awaits final verification.",prerequisites={{questID=96984,relationship="required",note="Complete the Horde Heart of Disruption before this continuation."}}},
    [92459]={name="Friend of the Kirin Tor",faction="Alliance",followUpOf=92458,pickup=modera,turnIn=celindra,objectives="Take the provided Arcane Mote to Archmage Celindra within the Violet Citadel.",prerequisites={{questID=92458,relationship="required",note="Complete the Alliance Heart of Disruption before this continuation."}}},
}
for id,quest in pairs(records) do
    -- Level 24 is published for the new chain; reused outdoor quest gates are provisional.
    quest.minLevel,quest.questLevel,quest.questLevelUnverified=24,33,true
    quest.dungeon,quest.awaitingFinalVerification="city-of-dalaran",true
    quest.source,quest.verifiedForever=source,false
    quest.prerequisites=quest.prerequisites or {}
    DQT.quests[id]=quest
end
