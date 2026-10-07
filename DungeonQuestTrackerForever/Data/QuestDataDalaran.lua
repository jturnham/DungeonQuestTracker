local _, DQT = ...
local source="https://www.wowhead.com/news/how-to-become-attuned-to-city-of-dalaran-dungeon-as-horde-in-wow-forever-383256"
local magus={name="Magus Wordeen Voidglare",zone="Hillsbrad Foothills",subzone="Tarren Mill"}
local keeper={name="Keeper Bel'varil",zone="Hillsbrad Foothills",subzone="Tarren Mill"}
local modera={name="Image of Archmage Modera",zone="Alterac Mountains",subzone="Outside Dalaran, beside Lordamere Lake (confirm exact position)"}
local records={
    [544]={name="Prison Break In",faction="Horde",pickup=magus,turnIn=magus,objectives="Recover the traitors' bloodstone artifacts at Lordamere Internment Camp and return to Tarren Mill."},
    [545]={name="Dalaran Patrols",faction="Horde",followUpOf=544,pickup=magus,turnIn=magus,objectives="Kill 6 Dalaran Summoners and 12 Elemental Slaves, then return to Tarren Mill.",prerequisites={{questID=544,relationship="required",note="Complete Prison Break In first; exact Forever chain requirements await final verification."}}},
    [93680]={name="Key to the City",faction="Horde",pickup=magus,turnIn=magus,objectives="Recover the Grimy Key from the Dalaran camps for Magus Wordeen Voidglare."},
    [556]={name="Stone Tokens",faction="Horde",pickup=keeper,turnIn=keeper,objectives="Collect 10 Worn Stone Tokens. Companion preparation: a player report says Keeper Bel'varil's quests are not required for the sewer key; awaiting final verification."},
    [557]={name="Bracers of Binding",faction="Horde",followUpOf=556,pickup=keeper,turnIn=keeper,objectives="Collect 4 Bracers of Earth Binding. Companion preparation, not treated as a mandatory sewer-key prerequisite.",prerequisites={{questID=556,relationship="required",note="Complete Stone Tokens before this companion quest; awaiting final verification."}}},
    [92434]={name="Blood in the Streets",faction="Horde",followUpOf=545,pickup=magus,turnIn=modera,objectives="Take the key to the sewer approach along Lordamere Lake and speak to Modera's image.",prerequisites={
        {questID=545,relationship="required",note="Complete Magus Voidglare's patrol branch; awaiting final verification."},
        {questID=93680,relationship="required",note="Recover and turn in the Grimy Key; awaiting final verification."},
        {relationship="breadcrumb",note="Keeper Bel'varil's Stone Tokens/Bracers branch is listed in the guide, but a player report says it is optional. It does not lock this quest in DQT."}}},
    [96984]={name="Heart of Disruption",faction="Horde",followUpOf=92434,pickup=modera,turnIn=magus,objectives="Receive the Dalaran Sewer Key and collect the Arcane Mote inside the City of Dalaran. Dungeon availability and final return contact await verification.",prerequisites={{questID=92434,relationship="required",note="Complete Blood in the Streets; the guide places pickup at Modera's image, while the quest objective names a Tarren Mill return. Confirm both contacts in-client."}}},
    [92432]={name="An Alarming Request",faction="Alliance",breadcrumbOnly=true,pickup={name="Unknown Kirin Tor emissary (awaiting verification)",zone="Unknown pickup location"},turnIn=modera,objectives="Report to Modera's image beside Lordamere Lake. The exact emissary and pickup location are not yet confirmed."},
    [92458]={name="Heart of Disruption",faction="Alliance",followUpOf=92432,pickup=modera,turnIn=modera,objectives="Receive the Dalaran Sewer Key and recover the Arcane Mote for Modera. Access and exact return location await verification.",prerequisites={{questID=92432,relationship="breadcrumb",note="An Alarming Request introduces Modera. The attunement report describes direct Alliance pickup; this lead-in is not enforced as a required gate until verified."}}},
}
for id,quest in pairs(records) do
    -- Level 24 is published for the new chain; reused outdoor quest gates are provisional.
    quest.minLevel,quest.questLevel,quest.questLevelUnverified=24,33,true
    quest.dungeon,quest.awaitingFinalVerification="city-of-dalaran",true
    quest.source,quest.verifiedForever=source,false
    quest.prerequisites=quest.prerequisites or {}
    DQT.quests[id]=quest
end
