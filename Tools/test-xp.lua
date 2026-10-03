local count = 0
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
assert(count >= 40, "Remaining estimates preserved")
assert(DQT.quests[5723].foreverXp == 2150 and DQT.quests[5723].xpReported, "RFC player report")
assert(DQT.quests[387].classicXp == 2650 and DQT.quests[387].foreverXp == 5565, "Stockade baseline is not boosted XP")
assert(DQT.quests[386].foreverXp == 4200, "Stockade estimate")
assert(DQT.quests[1200].xpBaselineAssumed and DQT.quests[1200].foreverXp == 7288, "Disputed BFD uses comparable baseline, not conflicting Classic value")
assert(DQT.quests[6564].foreverXp == 1300 and DQT.quests[6564].xpNormalBaseline == 1300, "Below-normal reward cannot increase")
assert(DQT.quests[5722].foreverXp == 1800, "RFC reported precursor")
assert(DQT.quests[1489].foreverXp == 290, "Low breadcrumb reward preserved")
assert(not DQT.quests[1053].foreverXp, "Classic-only reward cannot fabricate an old dungeon bonus")
assert(DQT.quests[95216].foreverXp == 5035 and DQT.quests[95216].xpNormalBaseline == 1750, "New Plague uses same-level normal baseline")
assert(DQT.quests[95216].xpBaselineAssumed and not DQT.quests[95216].classicXp, "Assumed baseline is not a Classic reward for a new quest")
assert(DQT.quests[92401].foreverXp == 4600, "Ruins player report")
assert(DQT.quests[97288].foreverXp == 3465, "Ruins level-21 estimate")
assert(DQT.quests[92422].foreverXp == 0 and not DQT.quests[92422].xpEstimate, "No fabricated XP for an unknown zero placeholder")
assert(DQT.quests[96403].xpBaselineAssumed, "Hall uses comparable baseline")
assert(DQT:GetQuestRewardXP({partySupplied=true,foreverXp=99999,xpEstimate=true}) == 0, "Party XP never trusted")
print("Passed XP: " .. count .. " remaining bonus-only estimates, separately labelled player reports, no fabricated bonuses, New Plague 5035 XP and party XP excluded.")
