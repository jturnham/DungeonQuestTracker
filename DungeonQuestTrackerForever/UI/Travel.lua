local _, DQT = ...
local UI=DQT.UI

function UI:ShowTravelOptions()
    self:Create()
    if self.currentView~="travel" then self.travelOrigin={view=self.currentView,key=self.currentDungeonKey} end
    self:ClearRows()
    self.currentView="travel"
    self:UpdateNav()
    self.frame.subtitle:SetText("Travel")
    self:FitContent()
    self.frame.content:Hide()
    self.frame.turnInScroll:Show()
    self.frame.filterSummary.text:SetText("Character flight knowledge | Provisional network")
    self.frame.travelRows=self.frame.travelRows or {}
    local player=DQT:GetPlayerContext()
    local faction=player.faction
    local known=DQT.Travel:Character()
    local width=self.frame.checklistContent:GetWidth()
    local header=self.frame.hearthSettings
    if not header then
        header=CreateFrame("Button",nil,self.frame.turnInContent,"UIPanelButtonTemplate")
        header:SetHeight(36)
        header:SetScript("OnClick",function()
            DQT.Travel:RecordHearth()
            UI:ShowTravelOptions()
        end)
        UI.AddTooltip(header,"Confirm your existing bind location","Only click while standing at the inn where your Hearthstone is bound. Records this zone for the current bind name on this character. Binding again records the zone automatically. Unknown destinations are skipped.")
        self.frame.hearthSettings=header
    end
    header:ClearAllPoints()
    header:SetPoint("TOPLEFT",self.frame.turnInContent,"TOPLEFT",0,0)
    header:SetWidth(width)
    local hearth=DQT.Travel:Hearth(player.faction,player.class)
    header:SetText(hearth and ("Hearth ready: "..hearth.name) or "At your bound inn? Confirm bind is here")
    header:Show()
    local y,index=42,0
    for _,id in ipairs(DQT.Travel.ids) do
        local node=DQT.Travel.nodes[id]
        if (node.faction=="Both" or node.faction==faction) and (not node.class or node.class==player.class) then
            index=index+1
            local row=self.frame.travelRows[index]
            if not row then
                row=CreateFrame("Frame",nil,self.frame.turnInContent)
                row.known=CreateFrame("CheckButton",nil,row,"UICheckButtonTemplate")
                row.known:SetSize(24,24)
                row.known:SetPoint("TOPLEFT",row,"TOPLEFT",0,0)
                row.known:SetScript("OnClick",function(control)
                    DQT.Travel:SetKnown(row.nodeID,control:GetChecked() and true or false)
                    UI:ShowTravelOptions()
                end)
                row.label=row:CreateFontString(nil,"OVERLAY","GameFontHighlight")
                row.label:SetPoint("TOPLEFT",row,"TOPLEFT",30,-5)
                row.label:SetJustifyH("LEFT")
                row.clear=CreateFrame("Button",nil,row,"UIPanelCloseButton")
                row.clear:SetSize(24,24)
                row.clear:SetPoint("TOPRIGHT",row,"TOPRIGHT",0,0)
                row.clear:SetScript("OnClick",function()
                    DQT.Travel:SetKnown(row.nodeID,nil)
                    UI:ShowTravelOptions()
                end)
                UI.AddTooltip(row.known,"Known flight point",function() return row.source end)
                UI.AddTooltip(row.clear,"Clear flight knowledge","Restore unknown status for this flight point on this character.")
                self.frame.travelRows[index]=row
            end
            row.nodeID,row.source=id,node.source
            row.known:SetChecked(known[id]==true)
            row.label:SetText(node.name.." | "..node.zone.." | "..(known[id]==true and "Known" or known[id]==false and "Not learned" or "Unknown"))
            row:SetWidth(width)
            row.label:SetWidth(width-66)
            local height=math.max(30,row.label:GetStringHeight()+12)
            row:SetHeight(height)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT",self.frame.turnInContent,"TOPLEFT",0,-y)
            row:Show()
            y=y+height
        end
    end
    self.frame.turnInContent:SetHeight(math.max(self.frame.content:GetHeight(),y))
    self.frame:Show()
end
function UI:CloseTravelOptions()
    local origin=self.travelOrigin or {}
    self.travelOrigin=nil
    self.currentDungeonKey=origin.key or self.currentDungeonKey
    if origin.view=="pickups" then self:ShowPickups(true)
    elseif origin.view=="checklist" and self.currentDungeonKey then DQT:OpenDungeon(self.currentDungeonKey)
    else self:ShowDungeonList() end
end
