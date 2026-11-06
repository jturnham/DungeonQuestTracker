# Quest XP observation review

The addon records only future, opt-in turn-ins of bundled dungeon quests. Nothing
is uploaded automatically or used to override quest XP or turn-in ranking.
`/dqt xp` opens local records; **Copy export** selects a plain-text TSV export.
Copy with Ctrl+C and submit it through the GitHub **Quest XP observation** issue
template. Preview the export first. It contains timestamps and reward context but
no account, character or realm names. Reload/logout saves observations normally.
Keep submissions outside the addon folder and tracked source tree.

## Run the offline reviewer

Install the existing Fengari validation dependencies, then run in PowerShell:

```powershell
node Tools/review-xp.cjs "$env:TEMP/dqt-lua-validation" 70374 'path/to/export.txt' |
    Set-Content -Encoding utf8 'path/to/review.json'
```

Replace **70374** with the actual build you intend to review; this is an example,
not an assertion about the current launch build. Up to 20 files can be compared
in a batch. Use a separate output path: do not overwrite the input file.
The reviewer accepts only the recorder's versioned data-only format. It does not
evaluate submitted Lua, templates or commands, fetch submitted URLs, or apply
changes to addon data. Invalid format/bounds fail the batch. Parsed-but-suspicious
records are flagged/quarantined in the report. SavedVariables files are not imports.

The baseline is generated from trusted local repository data in TOC order,
including metadata corrections. Its SHA-256 is recorded for reproducibility.
It preserves reward provenance: a Classic fallback, estimate or prior player report
is not upgraded to verified evidence merely because a new report agrees with it.

## Required maintainer review

1. Confirm the baseline comes from your trusted checkout and select the intended
   build independently. Never replace it with a contributor-provided baseline.
2. Inspect quarantine flags: unknown quest/build, future time, invalid level/XP
   context or reward-panel/event disagreement. Resolve them using direct evidence;
   do not drop the flags just to accept a report. Old/different builds can be useful
   historically but cannot silently replace current-build values.
3. Cross-check quest ID, build, pre-turn-in level, panel/event reward and bundled
   minimum/quest level against known quest-specific published or maintainer-observed
   data. A raw numerical match is only a comparison, not validation of base XP.
4. Verify modifiers and level scaling separately. Unknown bonuses stay unknown.
   Zero XP, caps, level-ups or event ordering cannot establish an unmodified reward.
   Never infer quest XP by subtracting unrelated character-XP updates.
5. Investigate disagreements against published/verified points; preserve the old
   value and provenance until a patch change or correction is corroborated. Require
   direct maintainer observation or independently verified, quest/build-specific
   evidence before promoting a new base reward. A screenshot or URL submitted by
   a stranger is itself untrusted; verify it independently.
6. Do not vote or average values. Exact duplicates are collapsed and competing
   rewards grouped, but altered timestamps/values can evade deduplication. Anonymous
   exports cannot establish independent contributors, identity or authenticity;
   many matching reports can all come from one actor. Hashes provide fingerprints,
   not signatures or proof of client execution.
7. If evidence warrants a correction, make a separate, human-reviewed source change
   recording the source/build/level context and confidence. Add a regression fixture
   against the verified point, inspect the diff and run the full validation suite.
   Publish through a normal release. Do not copy arbitrary source patches from an
   observation submission or auto-convert report rows into production rewards.

There is intentionally no approve/apply switch, automatic import, crowd-consensus
threshold, personal XP override or party transport for these records. A poisoned
export can produce a misleading review report if its contents are believed; it
cannot directly update bundled rewards through this workflow. Human verification
against independent evidence remains the trust boundary.
