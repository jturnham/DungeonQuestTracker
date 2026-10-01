param(
    [Parameter(Mandatory = $true)]
    [string]$DependencyDirectory
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$dependencies = (Resolve-Path -LiteralPath $DependencyDirectory).Path
Push-Location $root
try {
    & node (Join-Path $PSScriptRoot 'validate-data.cjs') $dependencies
    if ($LASTEXITCODE -ne 0) { throw 'Static validation failed.' }
    & node (Join-Path $PSScriptRoot 'test-level35.cjs') $dependencies 'Tools/test-data.lua' 'Tools/test-ui.lua' 'Tools/test-sync.lua' 'Tools/test-stability.lua'
    if ($LASTEXITCODE -ne 0) { throw 'Data audit or regression tests failed.' }
} finally { Pop-Location }
