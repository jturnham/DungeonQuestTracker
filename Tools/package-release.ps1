$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$addon = Join-Path $root 'DungeonQuestTracker'
$toc = Get-Content -LiteralPath (Join-Path $addon 'DungeonQuestTracker.toc')
$match = [regex]::Match(($toc -join "`n"), '(?m)^## Version: (\d+\.\d+\.\d+)\s*$')
if (-not $match.Success) { throw 'Missing semantic version in TOC.' }
$version = $match.Groups[1].Value
$config = Get-Content -LiteralPath (Join-Path $addon 'Config.lua') -Raw
if ($config -notmatch ('DQT\.version = "' + [regex]::Escape($version) + '"')) { throw 'Config and TOC versions disagree.' }
$release = Join-Path $root 'release'
New-Item -ItemType Directory -Path $release -Force | Out-Null
$stage = Join-Path $release ('staging-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage | Out-Null
$destination = Join-Path $release "DungeonQuestTracker-$version.zip"
try {
    Copy-Item -LiteralPath $addon -Destination $stage -Recurse
    Copy-Item -LiteralPath (Join-Path $root 'LICENSE') -Destination (Join-Path $stage 'DungeonQuestTracker/LICENSE')
    Compress-Archive -LiteralPath (Join-Path $stage 'DungeonQuestTracker') -DestinationPath $destination -Force
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($destination)
    try {
        $entries = @($archive.Entries | Where-Object { $_.Name -ne '' })
        foreach ($entry in $entries) {
            $name = $entry.FullName.Replace('\', '/')
            if (-not $name.StartsWith('DungeonQuestTracker/') -or $name.Contains('../')) { throw "Unexpected archive path: $name" }
            if ($name -match 'IMPLEMENTATION_CHECKLIST|(^|/)(Docs|Tools|\.git)/') { throw "Development file in archive: $name" }
        }
        $expected = @('DungeonQuestTracker/DungeonQuestTracker.toc', 'DungeonQuestTracker/LICENSE')
        $expected += @($toc | Where-Object { $_ -match '\.lua$' } | ForEach-Object { 'DungeonQuestTracker/' + $_.Replace('\', '/') })
        foreach ($name in $expected) {
            if (-not ($entries | Where-Object { $_.FullName.Replace('\', '/') -eq $name })) { throw "Missing archive file: $name" }
        }
        if ($entries.Count -ne $expected.Count) { throw 'Unexpected addon package contents.' }
        Write-Output "Verified $($entries.Count) packaged files for v$version."
    } finally { $archive.Dispose() }
} finally {
    $resolvedStage = [System.IO.Path]::GetFullPath($stage)
    $resolvedRelease = [System.IO.Path]::GetFullPath($release) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $resolvedStage.StartsWith($resolvedRelease, [System.StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe staging cleanup path.' }
    Remove-Item -LiteralPath $resolvedStage -Recurse -Force
}
Get-FileHash -LiteralPath $destination -Algorithm SHA256 | Select-Object Path, Hash
