# Modules/OrphanScanner.ps1
# Storage-wide scanner to detect folders from previously uninstalled applications

function Scan-OrphanedStorageFolders {
    [CmdletBinding()]
    param(
        [string]$ConfigDir = "",
        [switch]$IncludeProgramFiles = $false,
        [scriptblock]$ProgressCallback = $null
    )

    if (-not $ConfigDir) {
        $ConfigDir = Join-Path (Split-Path $PSScriptRoot -Parent) "Config"
    }

    # 1. Gather all currently installed applications
    $installedApps = @(Get-InstalledApplications -IncludeAppX)
    
    # 2. Build token and signature sets of INSTALLED applications
    $installedTokens = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $installedPaths  = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($app in $installedApps) {
        if ($app.DisplayName) {
            $name = $app.DisplayName.Trim()
            $installedTokens.Add($name) | Out-Null
            $parts = $name -split '[\s\-_,\.\(\)\[\]]+' | Where-Object { 
                $_.Length -ge 3 -and $_ -notmatch '^(The|And|For|With|App|Apps|Edition|Version|Setup|Tool|Tools)$' 
            }
            foreach ($p in $parts) { $installedTokens.Add($p) | Out-Null }
        }

        if ($app.Publisher -and $app.Publisher -notmatch '^(Microsoft|Google|Apple|Corp|Corporation|Inc|LLC|Unknown)$') {
            $pub = $app.Publisher.Trim()
            $installedTokens.Add($pub) | Out-Null
            $pubParts = $pub -split '[\s\-_,\.\(\)\[\]]+' | Where-Object { $_.Length -ge 3 }
            foreach ($pp in $pubParts) { $installedTokens.Add($pp) | Out-Null }
        }

        if ($app.InstallLocation) {
            $normalized = $app.InstallLocation.TrimEnd('\')
            if (Test-Path -LiteralPath $normalized) {
                $installedPaths.Add($normalized) | Out-Null
            }
        }
    }

    # Also capture running process names
    $runningProcesses = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    try {
        Get-Process -ErrorAction SilentlyContinue | ForEach-Object {
            $runningProcesses.Add($_.ProcessName) | Out-Null
        }
    } catch { }

    # 3. Load ProtectedPaths guardrail
    $protectedConfig = Load-ConfigSafe -Path (Join-Path $ConfigDir "ProtectedPaths.json")
    $protectedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $protectedNames.Add("Microsoft") | Out-Null
    $protectedNames.Add("Windows") | Out-Null
    $protectedNames.Add("Windows Defender") | Out-Null
    $protectedNames.Add("WindowsApps") | Out-Null
    $protectedNames.Add("Package Cache") | Out-Null
    $protectedNames.Add("Packages") | Out-Null
    $protectedNames.Add("Common Files") | Out-Null
    $protectedNames.Add("Temp") | Out-Null
    $protectedNames.Add("System") | Out-Null
    $protectedNames.Add("assembly") | Out-Null
    $protectedNames.Add("Downloaded Program Files") | Out-Null
    $protectedNames.Add("System Volume Information") | Out-Null
    $protectedNames.Add("OEM") | Out-Null
    $protectedNames.Add("USOShared") | Out-Null
    $protectedNames.Add("DirectX") | Out-Null

    # 4. Roots to inspect
    $scanRoots = @(
        $env:LOCALAPPDATA,
        $env:APPDATA,
        (Join-Path $env:USERPROFILE "AppData\LocalLow"),
        $env:ProgramData
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

    if ($IncludeProgramFiles) {
        $scanRoots += @(
            $env:ProgramFiles,
            ${env:ProgramFiles(x86)}
        ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
    }

    $orphanList = [System.Collections.Generic.List[PSCustomObject]]::new()
    $seenFolders = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    $rootIndex = 0
    foreach ($root in $scanRoots) {
        $rootIndex++
        if ($ProgressCallback) {
            & $ProgressCallback $rootIndex $scanRoots.Count "Scanning root: $root"
        }

        try {
            $subDirs = Get-ChildItem -LiteralPath $root -Directory -Force -ErrorAction SilentlyContinue
            foreach ($dir in $subDirs) {
                $dirPath = $dir.FullName
                $dirName = $dir.Name

                if ($seenFolders.Contains($dirPath)) { continue }
                $seenFolders.Add($dirPath) | Out-Null

                # A. Skip protected / core Windows names
                if ($protectedNames.Contains($dirName)) { continue }

                # Check if dirPath is in protected paths config
                $isSystemProtected = $false
                if ($protectedConfig) {
                    if ($protectedConfig.ProtectedExactRoots) {
                        foreach ($pe in $protectedConfig.ProtectedExactRoots) {
                            if ($dirPath.TrimEnd('\') -ieq $pe.TrimEnd('\')) {
                                $isSystemProtected = $true
                                break
                            }
                        }
                    }
                    if (-not $isSystemProtected -and $protectedConfig.ProtectedSubtrees) {
                        foreach ($ps in $protectedConfig.ProtectedSubtrees) {
                            if ($dirPath -ieq $ps -or $dirPath -like "$ps\*") {
                                $isSystemProtected = $true
                                break
                            }
                        }
                    }
                }
                if ($isSystemProtected) { continue }

                # B. Check if related application is STILL INSTALLED
                $isStillInstalled = $false

                # Check 1: Does directory name match installed tokens?
                if ($installedTokens.Contains($dirName)) {
                    $isStillInstalled = $true
                } else {
                    foreach ($token in $installedTokens) {
                        if ($token.Length -ge 4) {
                            if ($dirName -ieq $token -or $dirName -like "$token *" -or $dirName -like "* $token") {
                                $isStillInstalled = $true
                                break
                            }
                        }
                    }
                }

                # Check 2: Is directory inside an active InstallLocation?
                if (-not $isStillInstalled) {
                    foreach ($instPath in $installedPaths) {
                        if ($dirPath -like "$instPath*" -or $instPath -like "$dirPath*") {
                            $isStillInstalled = $true
                            break
                        }
                    }
                }

                # Check 3: Is it currently run by an active process?
                if (-not $isStillInstalled) {
                    if ($runningProcesses.Contains($dirName)) {
                        $isStillInstalled = $true
                    }
                }

                # If application is STILL INSTALLED -> DO NOT show its folder!
                if ($isStillInstalled) {
                    continue
                }

                # C. If application is UNINSTALLED and folder remains -> GHOST FOLDER FOUND!
                $stat = Get-FolderSizeSafe -Path $dirPath
                if ($stat.Count -eq 0 -and $stat.Size -eq 0) {
                    # Skip empty 0-byte ghost folders if desired, or keep if files existed
                }

                $orphanList.Add([PSCustomObject]@{
                    Category           = "OrphanFolder"
                    Type               = "Directory"
                    Path               = $dirPath
                    Name               = $dirName
                    Size               = $stat.Size
                    ItemCount          = $stat.Count
                    Score              = 85
                    ConfidenceCategory = "HIGH"
                    Badge              = "[HIGH]"
                    IsProtected        = $false
                    Selected           = $false
                    MatchReason        = "Application is uninstalled but folder remains in disk storage"
                    EvidenceDetails    = @("No installed application signature matches '$dirName'", "Resides in unmanaged storage location")
                })
            }
        } catch { }
    }

    return ($orphanList | Sort-Object Size -Descending)
}
