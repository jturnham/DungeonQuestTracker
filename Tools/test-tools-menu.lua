do
    local ui=DQT.UI
    local old={db=DQT.db,utility=ui.utility,xp=ui.xpRecords}
    DQT.db={display={compact=false},notifications={}}
    ui.utility,ui.xpRecords=nil,nil
    for _,compact in ipairs({false,true}) do
        DQT.db.display.compact=compact
        ui:ShowTools()
        assert(ui.utility:IsShown() and ui.utility.text.GetStringHeight==nil,"Tools opens with native-like EditBox API")
        local measure=assert(ui.utility.text.dqtTextMeasure)
        ui.utility.text:SetText(string.rep("Long copyable report line with wrapping\n",600))
        assert(ui.utility.text:GetHeight()>ui.utility.scroll:GetHeight(),"Long reports have a scrollable text child")
        ui.utility.text:SetText("Short report")
        assert(ui.utility.text.dqtTextMeasure==measure and ui.utility.text:GetHeight()>=ui.utility.scroll:GetHeight(),"Reuse one measurement FontString per text box")
        ui:ShowProfiles();ui:ShowBugReport(5722);ui:ShowFilterReasons();ui:ShowPartyReadiness("ragefire-chasm")
        ui:ShowXPRecords(false);ui:ShowXPRecords(true)
        assert(ui.xpRecords:IsShown() and ui.xpRecords.text.GetStringHeight==nil and ui.xpRecords.text.dqtTextMeasure,"XP summary/export uses FontString measurement too")
    end
    DQT.db,ui.utility,ui.xpRecords=old.db,old.utility,old.xp
end
print('Tools menu passed: real EditBox method boundary, all utility views, XP exports, both layouts, long reports and measurement reuse')
