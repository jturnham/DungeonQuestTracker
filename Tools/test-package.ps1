$ErrorActionPreference = 'Stop'
$root = Join-Path ([IO.Path]::GetTempPath()) ('dqt-package-test-' + [guid]::NewGuid().ToString('N'))
try {
    $addon = Join-Path $root 'DungeonQuestTrackerForever'
    $tools = Join-Path $root 'Tools'
    $output = Join-Path $root 'output'
    New-Item -ItemType Directory -Path $addon,$tools | Out-Null
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'package-release.ps1') -Destination $tools
    Set-Content -LiteralPath (Join-Path $root 'LICENSE') -Value 'Test license'
    Set-Content -LiteralPath (Join-Path $addon 'Config.lua') -Value 'DQT.version = "1.2.3"'
    Set-Content -LiteralPath (Join-Path $addon 'DungeonQuestTrackerForever.toc') -Value "## Version: 1.2.3`nConfig.lua"
    $script = Join-Path $tools 'package-release.ps1'
    & $script -OutputDirectory $output | Out-Null
    if (-not (Test-Path -LiteralPath (Join-Path $output 'DungeonQuestTrackerForever-1.2.3.zip'))) { throw 'Package not created' }
    Set-Content -LiteralPath (Join-Path $addon 'Config.lua') -Value 'DQT.version = "1.2.4"'
    $rejected = $false
    try { & $script -OutputDirectory $output | Out-Null } catch { $rejected = $true }
    if (-not $rejected) { throw 'Version mismatch was accepted' }
    Set-Content -LiteralPath (Join-Path $addon 'Config.lua') -Value "DQT.version = `"1.2.3`"`n-- BEGIN PRIVATE LOCAL BETA SETTINGS REPAIR"
    $rejected = $false
    try { & $script -OutputDirectory $output | Out-Null } catch { $rejected = $true }
    if (-not $rejected) { throw 'Personal beta repair code was packaged' }
    Set-Content -LiteralPath (Join-Path $addon 'Config.lua') -Value 'DQT.version = "1.2.3"'
    New-Item -ItemType Directory -Path (Join-Path $addon 'Docs') | Out-Null
    Set-Content -LiteralPath (Join-Path $addon 'Docs/private.txt') -Value 'Must not package'
    $rejected = $false
    try { & $script -OutputDirectory $output | Out-Null } catch { $rejected = $true }
    if (-not $rejected) { throw 'Development files were packaged' }
    Write-Output 'Packaging tests passed: valid artifact, version mismatch rejection, personal beta repair rejection and Docs exclusion.'
} finally {
    $resolved = [IO.Path]::GetFullPath($root)
    $parent = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/')
    if ([IO.Path]::GetDirectoryName($resolved) -ne $parent -or [IO.Path]::GetFileName($resolved) -notlike 'dqt-package-test-*') { throw 'Unsafe fixture cleanup path' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
