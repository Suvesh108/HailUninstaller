# Modules/OrphanScanner.ps1
# Storage-wide scanner to detect folders from previously uninstalled applications

function Scan-OrphanedStorageFolders {
    [CmdletBinding()]
    param(
        [string]$ConfigDir = "",
        [switch]$IncludeProgramFiles = $false,
        [switch]$ScanAllDrives = $true,
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
    
    # Built-in OS and Framework Protection Whitelist
    $coreProtectedList = @(
        "Microsoft", "Windows", "Windows Defender", "WindowsApps", "Package Cache",
        "Packages", "Common Files", "Temp", "System", "assembly", "Downloaded Program Files",
        "System Volume Information", "OEM", "USOShared", "USOPrivate", "DirectX",
        "ConnectedDevicesPlatform", "CrashDumps", "D3DSCache", "VirtualStore",
        "SoftwareDistribution", "PackageManagement", "PeerDistRepub", "Temporary Internet Files",
        "fontconfig", "Crypto", "System Certificates", "DeliveryOptimization",
        "Start Menu", "Templates", "Documents", "History", "Publishers",
        "ToastNotificationManagerCompat", "ssh", "Comms", "Diagnostics",
        "INetCache", "INetCookies", "CredentialManager", "Windows Powershell", "PowerShell",
        "Programs", "pip", "npm", "yarn", "nuget", "cargo", "git", "Docker", "NVIDIA", "OneDrive"
    )
    foreach ($cp in $coreProtectedList) { $protectedNames.Add($cp) | Out-Null }

    if ($protectedConfig -and $protectedConfig.ProtectedFolderNames) {
        foreach ($pfn in $protectedConfig.ProtectedFolderNames) {
            $protectedNames.Add($pfn) | Out-Null
        }
    }

    # 4. Roots to inspect across System and All Fixed Drives
    $scanRoots = [System.Collections.Generic.List[string]]::new()
    $candidateRoots = @(
        $env:LOCALAPPDATA,
        $env:APPDATA,
        (Join-Path $env:USERPROFILE "AppData\LocalLow"),
        $env:ProgramData
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

    foreach ($cr in $candidateRoots) { $scanRoots.Add($cr) }

    if ($IncludeProgramFiles) {
        $pfRoots = @(
            $env:ProgramFiles,
            ${env:ProgramFiles(x86)}
        ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
        foreach ($pfr in $pfRoots) { $scanRoots.Add($pfr) }
    }

    # Multi-Drive support: check secondary drives for games/app storage folders
    if ($ScanAllDrives) {
        try {
            $fixedDrives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue
            $sysDrive = $env:SystemDrive
            foreach ($d in $fixedDrives) {
                if ($d.DeviceID -ieq $sysDrive) { continue }
                $driveRoot = $d.DeviceID + "\"
                $extraDirs = @(
                    (Join-Path $driveRoot "ProgramData"),
                    (Join-Path $driveRoot "Games")
                ) | Where-Object { Test-Path -LiteralPath $_ }
                foreach ($ed in $extraDirs) { $scanRoots.Add($ed) }
            }
        } catch { }
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
            $subDirs = @(Get-ChildItem -LiteralPath $root -Directory -Force -ErrorAction SilentlyContinue)
            $subTotal = $subDirs.Count
            $subIdx = 0
            foreach ($dir in $subDirs) {
                $subIdx++
                $dirPath = $dir.FullName
                $dirName = $dir.Name

                if ($ProgressCallback -and ($subIdx % 4 -eq 0 -or $subIdx -eq 1 -or $subIdx -eq $subTotal)) {
                    & $ProgressCallback $rootIndex $scanRoots.Count "Examining [$rootIndex/$($scanRoots.Count)]: $dirName ($subIdx/$subTotal)"
                }

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
                    # Skip completely empty 0-byte placeholder directories to reduce noise
                    continue
                }

                # IMPORTANT: Category is 'File' (with SubCategory 'OrphanFolder') so Backup.ps1 and Cleanup.ps1 handle it seamlessly
                $orphanList.Add([PSCustomObject]@{
                    Category           = "File"
                    SubCategory        = "OrphanFolder"
                    Type               = "Directory"
                    Path               = $dirPath
                    Name               = $dirName
                    Size               = $stat.Size
                    ItemCount          = $stat.Count
                    Score              = 90
                    ConfidenceCategory = "HIGH"
                    Badge              = "[HIGH]"
                    IsProtected        = $false
                    Selected           = $false
                    MatchReason        = "Application is uninstalled but folder remains in disk storage"
                    EvidenceDetails    = @("No installed application signature matches '$dirName'", "Resides in unmanaged storage location ($root)")
                })
            }
        } catch { }
    }

    return ($orphanList | Sort-Object Size -Descending)
}
