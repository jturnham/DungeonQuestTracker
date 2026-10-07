local count, published = 0, 0
for id, quest in pairs(DQT.quests) do
    assert(quest.verification.xpReview, "XP review missing: " .. id)
    if quest.xpEstimate then
        count = count + 1
        local normalXp = quest.xpNormalBaseline or quest.classicXp
        assert(quest.foreverXp == math.floor((normalXp + quest.xpBeforeOctober1) / 2 + 0.5), "Bonus reduction: " .. id)
        assert(quest.foreverXp >= normalXp and quest.foreverXp <= quest.xpBeforeOctober1, "Only nonnegative bonus reduced: " .. id)
        local xp, source = DQT:GetQuestRewardXP(quest)
        assert(xp == quest.foreverXp and source == "Forever (Oct 1 estimate)", "Estimate label: " .. id)
        assert(quest.confidence ~= "verifiedInGame", "Estimate is not a client observation")
    elseif quest.xpPublished then
        published = published + 1
        local xp, source = DQT:GetQuestRewardXP(quest)
        assert(xp == quest.foreverXp and source == "Forever (published beta)", "Published reward label: " .. id)
        assert(not quest.xpEstimate and not quest.xpOutdated and quest.confidence ~= "verifiedInGame", "Published rewards do not claim local verification")
        assert(quest.xpSource:find("https://wowforever.wclbox.com/en/fuben/", 1, true), "Published source preserved")
    elseif quest.xpReported then
        local xp, source = DQT:GetQuestRewardXP(quest)
        assert(xp == quest.foreverXp and source == "Forever (player reported)", "Reported reward label")
        assert(not quest.xpEstimate and quest.confidence ~= "verifiedInGame", "Player reports do not claim local verification")
    elseif quest.foreverXp ~= nil then
        assert(quest.xpOutdated and quest.foreverXp == 0, "Positive old reward left unadjusted: " .. id)
        local _, source = DQT:GetQuestRewardXP(quest)
        assert(source == "Forever (outdated; unverified)", "Stale reward label: " .. id)
    end
end
assert(count == 7 and published == 35, "Only explicitly published post-update rewards supersede estimates: " .. count .. " estimates, " .. published .. " published")
assert(DQT.quests[5723].foreverXp == 2150 and DQT.quests[5723].xpReported, "RFC player report")
assert(DQT.quests[387].classicXp == 2650 and DQT.quests[387].foreverXp == 5550, "Stockade baseline retained separately from published XP")
assert(DQT.quests[386].foreverXp == 4200, "Stockade estimate")
assert(DQT.quests[1200].xpPublished and DQT.quests[1200].foreverXp == 7850, "Published BFD reward supersedes disputed estimate")
assert(DQT.quests[6564].foreverXp == 1300 and DQT.quests[6564].xpNormalBaseline == 1300, "Below-normal reward cannot increase")
assert(DQT.quests[5722].foreverXp == 1800, "RFC reported precursor")
assert(DQT.quests[1489].foreverXp == 290, "Low breadcrumb reward preserved")
assert(not DQT.quests[1053].foreverXp, "Classic-only reward cannot fabricate an old dungeon bonus")
assert(DQT.quests[95216].foreverXp == 5450 and DQT.quests[95216].xpPublished and DQT.quests[95216].xpPreviousEstimate == 5035, "New Plague replaces estimate with published reward")
assert(DQT.quests[95216].xpBaselineAssumed and not DQT.quests[95216].classicXp, "Assumed baseline is not a Classic reward for a new quest")
assert(DQT.quests[92401].foreverXp == 4600, "Ruins player report")
assert(DQT.quests[97288].foreverXp == 3450, "Ruins published reward")
assert(DQT.quests[92422].foreverXp == 0 and not DQT.quests[92422].xpEstimate, "No fabricated XP for an unknown zero placeholder")
assert(DQT.quests[96403].xpBaselineAssumed, "Hall uses comparable baseline")
for id,xp in pairs({[96395]=2300,[96403]=2950,[96394]=2300,[96393]=3200,[6921]=6550,[6561]=7850}) do
    assert(DQT.quests[id].foreverXp==xp and DQT.quests[id].xpPublished and not DQT.quests[id].xpEstimate,"October 7 exact-ID correction: " .. id)
end
assert(DQT:GetQuestRewardXP({partySupplied=true,foreverXp=99999,xpEstimate=true}) == 0, "Party XP never trusted")
print("Passed XP: " .. count .. " remaining estimates, " .. published .. " published beta rewards, separately labelled player reports, New Plague 5450 XP and party XP excluded.")
