# Modules/ShortcutScanner.ps1
# Desktop and Start Menu shortcut scanner for application leftovers

function Scan-ShortcutLeftovers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppName,
        [string]$InstallLocation = ""
    )

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    $seenPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    $desktopDirs = @(
        [Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop),
        [Environment]::GetFolderPath([Environment+SpecialFolder]::CommonDesktopDirectory)
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

    $startMenuDirs = @(
        [Environment]::GetFolderPath([Environment+SpecialFolder]::StartMenu),
        [Environment]::GetFolderPath([Environment+SpecialFolder]::CommonStartMenu),
        [Environment]::GetFolderPath([Environment+SpecialFolder]::Startup),
        [Environment]::GetFolderPath([Environment+SpecialFolder]::CommonStartup)
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

    $tokens = [System.Collections.Generic.List[string]]::new()
    if ($AppName) {
        $tokens.Add($AppName.Trim())
        $words = $AppName -split '[\s\-_]+' | Where-Object { $_.Length -ge 4 -and $_ -notmatch '^(Microsoft|Windows|Installer|Setup)$' }
        foreach ($w in $words) { $tokens.Add($w) }
    }

    $wscriptShell = $null
    try {
        $wscriptShell = New-Object -ComObject WScript.Shell
    } catch { }

    $shortcutFiles = [System.Collections.Generic.List[System.IO.FileInfo]]::new()

    # Desktop non-recursive (only desktop surface, not nested folders)
    foreach ($d in $desktopDirs) {
        try {
            $files = Get-ChildItem -LiteralPath $d -File -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension -ieq ".lnk" -or $_.Extension -ieq ".url" }
            if ($files) { foreach ($f in $files) { $shortcutFiles.Add($f) } }
        } catch { }
    }

    # Start Menu recursive
    foreach ($s in $startMenuDirs) {
        try {
            $files = Get-ChildItem -LiteralPath $s -Recurse -File -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension -ieq ".lnk" -or $_.Extension -ieq ".url" }
            if ($files) { foreach ($f in $files) { $shortcutFiles.Add($f) } }
        } catch { }
    }

    foreach ($f in $shortcutFiles) {
        if ($seenPaths.Contains($f.FullName)) { continue }

        $matched = $false
        $matchReason = ""
        $targetPath = ""

        # 1. Match shortcut name
        foreach ($token in $tokens) {
            if ($f.BaseName -like "*$token*") {
                $matched = $true
                $matchReason = "Shortcut name matches '$token'"
                break
            }
        }

        # 2. Inspect shortcut target if COM object available
        if (-not $matched -and $wscriptShell -and $f.Extension -ieq ".lnk") {
            try {
                $shortcut = $wscriptShell.CreateShortcut($f.FullName)
                $targetPath = $shortcut.TargetPath
                if ($InstallLocation -and $targetPath -like "$InstallLocation*") {
                    $matched = $true
                    $matchReason = "Shortcut target points to install location"
                } else {
                    foreach ($token in $tokens) {
                        if ($targetPath -like "*$token*") {
                            $matched = $true
                            $matchReason = "Shortcut target path matches '$token'"
                            break
                        }
                    }
                }
            } catch { }
        }

        if ($matched) {
            $seenPaths.Add($f.FullName) | Out-Null
            $results.Add([PSCustomObject]@{
                Category     = "Shortcut"
                Type         = "Shortcut"
                Path         = $f.FullName
                Target       = $targetPath
                Size         = $f.Length
                ItemCount    = 1
                MatchReason  = $matchReason
                MatchedToken = $AppName
            })
        }
    }

    if ($wscriptShell) {
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($wscriptShell) | Out-Null
    }

    return $results
}
