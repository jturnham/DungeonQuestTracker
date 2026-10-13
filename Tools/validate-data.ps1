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
    }
    & node (Join-Path $PSScriptRoot 'validate-data.cjs') $dependencies
    if ($LASTEXITCODE -ne 0) { throw 'Static validation failed.' }
    & node (Join-Path $PSScriptRoot 'test-level35.cjs') $dependencies 'Tools/test-dungeon-review.lua'
    if ($LASTEXITCODE -ne 0) { throw 'Dungeon review tests failed.' }
    & node (Join-Path $PSScriptRoot 'test-level35.cjs') $dependencies 'Tools/test-prerequisites.lua'
    if ($LASTEXITCODE -ne 0) { throw 'Prerequisite tests failed.' }
    & node (Join-Path $PSScriptRoot 'test-level35.cjs') $dependencies 'Tools/test-list-performance.lua'
    if ($LASTEXITCODE -ne 0) { throw 'Dungeon list performance tests failed.' }
    & node (Join-Path $PSScriptRoot 'test-level35.cjs') $dependencies 'Tools/test-data.lua' 'Tools/test-ui.lua' 'Tools/test-sync.lua' 'Tools/test-options.lua' 'Tools/test-compact.lua' 'Tools/test-level-range.lua' 'Tools/test-stability.lua' 'Tools/test-xp.lua' 'Tools/test-followups.lua' 'Tools/test-loot-reminders.lua' 'Tools/test-stockade-loot.lua' 'Tools/test-arugal-loot.lua' 'Tools/test-single-loot.lua' 'Tools/test-beta30.lua' 'Tools/test-performance.lua'
    if ($LASTEXITCODE -ne 0) { throw 'Data audit or regression tests failed.' }
    & node (Join-Path $PSScriptRoot 'test-level35.cjs') $dependencies 'Tools/test-loot-coverage.lua'
    if ($LASTEXITCODE -ne 0) { throw 'Loot coverage tests failed.' }
    & node (Join-Path $PSScriptRoot 'test-level35.cjs') $dependencies 'Tools/test-pickup-routes.lua' 'Tools/test-pickup-map.lua' 'Tools/test-dalaran.lua'
    if ($LASTEXITCODE -ne 0) { throw 'Pickup route tests failed.' }
    & node (Join-Path $PSScriptRoot 'test-level35.cjs') $dependencies 'Tools/test-turnin-grouping.lua'
    if ($LASTEXITCODE -ne 0) { throw 'Turn-in grouping tests failed.' }
} finally { Pop-Location }
