# Development and review

Install Node 24 and pnpm 11.25.0, then run:

```powershell
pnpm install --dir Tools --frozen-lockfile --ignore-scripts
./Tools/validate-data.ps1 -DependencyDirectory ./Tools
./Tools/package-release.ps1 -OutputDirectory ./release/test
```

Dependencies and transitive resolutions are locked in Tools/pnpm-lock.yaml. They
are development-only. Existing validation also accepts an external dependency
directory, allowing offline checks once dependencies are installed. The test
output directory keeps experimental packages separate from published ZIPs.

Validation CI runs on main pushes, pull requests and manual dispatch with read-only
repository permissions. Packages are test artifacts, not published releases.
The separate **Publish tagged release (manual)** workflow requires an existing
semantic version tag matching the TOC, validates the tagged source, and publishes
only its validated package. Only the publish job has contents-write permission.
It refuses to replace an existing release. No CurseForge credentials or automated
CurseForge publication are configured. Workflows need pushing before GitHub can
execute them; local checks do not establish that a hosted workflow has run.

## Data proposals

`node Tools/audit-launch-data.cjs Tools 2026-11-05` audits the trusted bundled
catalogue against fresh public quest pages and writes an ignored per-dungeon/quest
report under Docs. Replace the date as appropriate. `--reparse` reuses that review
directory's downloaded pages; it is not a new fetch/verification date. Missing XP
is distinct from zero, mixed Classic references remain labelled, and series links
are only review candidates. No audit result changes runtime data automatically.

Personal beta-repair scripts/data stay under ignored Docs and explicit filename
ignore rules. Release packaging rejects embedded private repair markers as well
as repair filenames, so copying a patched live Core.lua into source cannot silently
ship the personal payload. Do not copy a live addon folder back into the repo.

`import-classic-dungeons.cjs` and `import-travel-data.cjs` now write generated
candidates under ignored `Docs/data-proposals`, not into runtime source. Fetching,
parsing, static validation and proposal output remain development-only. Cached
pages may be older than the proposal; unknown retrieval/build dates stay unknown.

Inspect manifest provenance and compare the candidate to its named production
file using `git diff --no-index -- <production-file> <candidate-file>`. An exit
code of 1 means differences were found. Do not execute or install a candidate as
part of review. Apply selected reviewed hunks manually, then run the complete
catalogue/reference/acyclic-prerequisite/XP/map validation suite and inspect the
resulting diff. Static candidate checks alone do not prove correctness, faction
eligibility, chains, coordinate spaces or compatibility with other records.

Never overwrite a published/verified reward from an import or anonymous XP report
without independent quest/build/level-specific evidence. See XP-REVIEW.md for the
separate observation workflow and its trust boundary.

## Localization and accessibility

UI strings use `DQT.L["English source key"]` and English fallback. Add a reviewed
locale file using `DQT:RegisterLocale("deDE", { ["Tools"]="..." })`, loaded after
Locale.lua and before Options/UI in the TOC. Do not translate stable IDs or source
quest/NPC/zone/taxi names by string replacement. Unknown or ambiguous localized
instance/taxi names must remain unresolved until client-supported IDs or verified
aliases are available. No complete non-English translation pack is bundled yet.

`node Tools/extract-locales.cjs Tools` prints an English-key JSON reference for
translators without changing source. Keep formatting placeholders intact and
test each translated pack before adding it to the TOC. Some composed diagnostic
and data text remains English and needs a separate localization review.

New utility views are scrollable, provide keyboard-copyable text, and have Escape
handling. Options numeric fields and profile/report inputs support Tab. Quest
states have text labels in both detailed and compact views. UI scaling applies
to addon windows, not global UI scale or map coordinate spaces. Full accessibility,
resolution and non-English behavior still require actual-client review.
