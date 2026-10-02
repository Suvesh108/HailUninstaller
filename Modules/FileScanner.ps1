# Modules/FileScanner.ps1
# File system scanner for application leftovers

function Get-FolderSizeSafe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return @{ Size = 0; Count = 0 }
    }

    try {
        $measure = Get-ChildItem -LiteralPath $Path -Recurse -File -Force -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue
        
        $totalBytes = if ($measure -and $measure.Sum) { [long]$measure.Sum } else { 0L }
        $totalFiles = if ($measure -and $measure.Count) { [int]$measure.Count } else { 0 }
        return @{ Size = $totalBytes; Count = $totalFiles }
    } catch {
        return @{ Size = 0; Count = 0 }
    }
}

function Scan-FileLeftovers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppName,
        [string]$Publisher = "",
        [string]$InstallLocation = "",
        [string[]]$KnownDirectories = @()
    )

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    $seenPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    $rootLocations = @(
        $env:LOCALAPPDATA,
        $env:APPDATA,
        (Join-Path $env:USERPROFILE "AppData\LocalLow"),
        $env:ProgramData,
        $env:ProgramFiles,
        ${env:ProgramFiles(x86)},
        $env:TEMP
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

    # Token extraction for matching
    $tokens = [System.Collections.Generic.List[string]]::new()
    if ($AppName) {
        $tokens.Add($AppName.Trim())
        # Add single word if distinctive and length >= 4
        $words = $AppName -split '[\s\-_]+' | Where-Object { $_.Length -ge 4 -and $_ -notmatch '^(Microsoft|Google|Windows|Installer|Setup)$' }
        foreach ($w in $words) { $tokens.Add($w) }
    }
    if ($Publisher -and $Publisher -notmatch '^(Microsoft|Google|Apple|Corp|Corporation|Inc|LLC)$') {
        $pubWords = $Publisher -split '[\s\-_]+' | Where-Object { $_.Length -ge 4 }
        foreach ($pw in $pubWords) { $tokens.Add($pw) }
    }

    # 1. Check known directories
    foreach ($kd in $KnownDirectories) {
        if ([string]::IsNullOrWhiteSpace($kd)) { continue }
        $expanded = [System.Environment]::ExpandEnvironmentVariables($kd)
        if ((Test-Path -LiteralPath $expanded) -and (-not $seenPaths.Contains($expanded))) {
            $seenPaths.Add($expanded) | Out-Null
            $stat = Get-FolderSizeSafe -Path $expanded
            $results.Add([PSCustomObject]@{
                Category     = "File"
                Type         = if ((Get-Item -LiteralPath $expanded) -is [System.IO.DirectoryInfo]) { "Directory" } else { "File" }
                Path         = $expanded
                Size         = $stat.Size
                ItemCount    = $stat.Count
                MatchReason  = "Configured known application directory"
                MatchedToken = "Rule"
            })
        }
    }

    # 2. Check InstallLocation
    if ($InstallLocation -and (Test-Path -LiteralPath $InstallLocation) -and -not $seenPaths.Contains($InstallLocation)) {
        $seenPaths.Add($InstallLocation) | Out-Null
        $stat = Get-FolderSizeSafe -Path $InstallLocation
        $results.Add([PSCustomObject]@{
            Category     = "File"
            Type         = "Directory"
            Path         = $InstallLocation
            Size         = $stat.Size
            ItemCount    = $stat.Count
            MatchReason  = "Application official InstallLocation"
            MatchedToken = $AppName
        })
    }

    # 3. Scan common root directories for matching candidate folders
    foreach ($root in $rootLocations) {
        try {
            $children = Get-ChildItem -LiteralPath $root -Directory -Force -ErrorAction SilentlyContinue
            foreach ($child in $children) {
                if ($seenPaths.Contains($child.FullName)) { continue }

                foreach ($token in $tokens) {
                    if ($child.Name -like "*$token*") {
                        $seenPaths.Add($child.FullName) | Out-Null
                        $stat = Get-FolderSizeSafe -Path $child.FullName
                        $results.Add([PSCustomObject]@{
                            Category     = "File"
                            Type         = "Directory"
                            Path         = $child.FullName
                            Size         = $stat.Size
                            ItemCount    = $stat.Count
                            MatchReason  = "Directory matches token '$token'"
                            MatchedToken = $token
                        })
                        break
                    }
                }
            }
        } catch {
            # Ignore access denied errors on root paths
        }
    }

    return $results
}
