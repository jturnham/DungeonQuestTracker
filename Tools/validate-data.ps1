param(
    [Parameter(Mandatory = $true)]
    [string]$DependencyDirectory
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$dependencies = (Resolve-Path -LiteralPath $DependencyDirectory).Path
Push-Location $root
try {
    if (Test-Path -LiteralPath (Join-Path $root '.git')) {
        $trackedDocs = @(& git ls-files -- Docs)
        if ($LASTEXITCODE -ne 0) { throw 'Could not check tracked documentation.' }
        if ($trackedDocs.Count -gt 0) { throw 'Docs contains tracked local-only files.' }
        & git check-ignore -- Docs/DATA_VERIFICATION.md | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'Docs must be ignored.' }
        $trackedTools = @(& git ls-files -- Tools)
        if ($LASTEXITCODE -ne 0) { throw 'Could not check tracked tools.' }
        $ignoredTools = @(& git check-ignore --no-index -- $trackedTools)
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1) { throw 'Could not check the Tools allowlist.' }
        if ($ignoredTools.Count -gt 0) { throw ('Nonessential/local-only tools are tracked: ' + ($ignoredTools -join ', ')) }
    }
    & node (Join-Path $PSScriptRoot 'validate-data.cjs') $dependencies
    if ($LASTEXITCODE -ne 0) { throw 'Static validation failed.' }
    & node (Join-Path $PSScriptRoot 'test-xp-review.cjs') $dependencies
    if ($LASTEXITCODE -ne 0) { throw 'XP review tests failed.' }
    & node (Join-Path $PSScriptRoot 'test-launch-sources.cjs') $dependencies
    if ($LASTEXITCODE -ne 0) { throw 'Launch source parsing tests failed.' }
    & node (Join-Path $PSScriptRoot 'test-locales.cjs') $dependencies
    if ($LASTEXITCODE -ne 0) { throw 'Locale pack validation failed.' }
    & node (Join-Path $PSScriptRoot 'test-data-proposal.cjs') $dependencies
    if ($LASTEXITCODE -ne 0) { throw 'Data proposal tests failed.' }
    & node (Join-Path $PSScriptRoot 'test-level35.cjs') $dependencies 'Tools/test-optional.lua'
    if ($LASTEXITCODE -ne 0) { throw 'Optional feature tests failed.' }
    & node (Join-Path $PSScriptRoot 'test-level35.cjs') $dependencies 'Tools/test-tools-menu.lua'
    if ($LASTEXITCODE -ne 0) { throw 'Tools menu tests failed.' }
    & node (Join-Path $PSScriptRoot 'test-level35.cjs') $dependencies 'Tools/test-capabilities.lua'
    if ($LASTEXITCODE -ne 0) { throw 'Party capability tests failed.' }
    & node (Join-Path $PSScriptRoot 'test-level35.cjs') $dependencies 'Tools/test-xp-recorder.lua'
    if ($LASTEXITCODE -ne 0) { throw 'XP recorder tests failed.' }
    & node (Join-Path $PSScriptRoot 'test-level35.cjs') $dependencies 'Tools/test-dungeon-review.lua'
    if ($LASTEXITCODE -ne 0) { throw 'Dungeon review tests failed.' }
    & node (Join-Path $PSScriptRoot 'test-level35.cjs') $dependencies 'Tools/test-prerequisites.lua'
    if ($LASTEXITCODE -ne 0) { throw 'Prerequisite tests failed.' }
    & node (Join-Path $PSScriptRoot 'test-level35.cjs') $dependencies 'Tools/test-launch-review.lua'
    if ($LASTEXITCODE -ne 0) { throw 'Launch review tests failed.' }
    & node (Join-Path $PSScriptRoot 'test-level35.cjs') $dependencies 'Tools/test-list-performance.lua'
    if ($LASTEXITCODE -ne 0) { throw 'Dungeon list performance tests failed.' }
    & node (Join-Path $PSScriptRoot 'test-level35.cjs') $dependencies 'Tools/test-data.lua' 'Tools/test-ui.lua' 'Tools/test-sync.lua' 'Tools/test-options.lua' 'Tools/test-compact.lua' 'Tools/test-level-range.lua' 'Tools/test-stability.lua' 'Tools/test-xp.lua' 'Tools/test-followups.lua' 'Tools/test-loot-reminders.lua' 'Tools/test-stockade-loot.lua' 'Tools/test-arugal-loot.lua' 'Tools/test-single-loot.lua' 'Tools/test-beta30.lua' 'Tools/test-performance.lua'
    if ($LASTEXITCODE -ne 0) { throw 'Data audit or regression tests failed.' }
    & node (Join-Path $PSScriptRoot 'test-level35.cjs') $dependencies 'Tools/test-loot-coverage.lua'
    if ($LASTEXITCODE -ne 0) { throw 'Loot coverage tests failed.' }
    & node (Join-Path $PSScriptRoot 'test-level35.cjs') $dependencies 'Tools/test-pickup-routes.lua' 'Tools/test-pickup-map.lua' 'Tools/test-dalaran.lua' 'Tools/test-pickup-extensions.lua'
    if ($LASTEXITCODE -ne 0) { throw 'Pickup route tests failed.' }
    & node (Join-Path $PSScriptRoot 'test-level35.cjs') $dependencies 'Tools/test-travel.lua' 'Tools/test-hearth.lua'
    if ($LASTEXITCODE -ne 0) { throw 'Travel routing tests failed.' }
    & node (Join-Path $PSScriptRoot 'test-level35.cjs') $dependencies 'Tools/test-travel-planning.lua'
    if ($LASTEXITCODE -ne 0) { throw 'Extended travel planning tests failed.' }
    & node (Join-Path $PSScriptRoot 'test-level35.cjs') $dependencies 'Tools/test-review-regressions.lua'
    if ($LASTEXITCODE -ne 0) { throw 'Review regression tests failed.' }
    & node (Join-Path $PSScriptRoot 'test-level35.cjs') $dependencies 'Tools/test-turnin-grouping.lua'
    if ($LASTEXITCODE -ne 0) { throw 'Turn-in grouping tests failed.' }
    & (Join-Path $PSScriptRoot 'test-package.ps1')
} finally { Pop-Location }
