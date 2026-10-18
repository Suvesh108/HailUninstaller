# Modules/Evidence.ps1
# Multi-Factor Evidence Scoring Engine for HailUninstaller

function Load-ConfigSafe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (Test-Path -LiteralPath $Path) {
        try {
            return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json)
        } catch {
            Write-Warning "Could not parse JSON configuration at '$Path': $_"
        }
    }
    return $null
}

function Evaluate-CandidateEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [AllowNull()]
        [array]$Candidates = @(),
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Application,
        [string]$ConfigDir = ""
    )

    if (-not $ConfigDir) {
        $ConfigDir = Join-Path (Split-Path $PSScriptRoot -Parent) "Config"
    }

    $protectedConfig = Load-ConfigSafe -Path (Join-Path $ConfigDir "ProtectedPaths.json")
    $rulesConfig = Load-ConfigSafe -Path (Join-Path $ConfigDir "Rules.json")

    $highThreshold = 85
    $reviewThreshold = 60
    if ($rulesConfig -and $rulesConfig.Thresholds) {
        $highThreshold = [int]$rulesConfig.Thresholds.HighConfidence
        $reviewThreshold = [int]$rulesConfig.Thresholds.ReviewConfidence
    }

    $scoredList = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($item in $Candidates) {
        $isProtected = $false
        $protectReason = ""
        $pathToCheck = if ($item.Path) { $item.Path } else { "" }
        $nameToCheck = if ($item.Name) { $item.Name } else { "" }

        # 1. Guardrail Check: Protected Paths
        if ($protectedConfig) {
            if ($pathToCheck -and $protectedConfig.ProtectedExactRoots) {
                foreach ($pe in $protectedConfig.ProtectedExactRoots) {
                    if ($pathToCheck.TrimEnd('\') -ieq $pe.TrimEnd('\')) {
                        $isProtected = $true
                        $protectReason = "Protected Windows system root ($pe)"
                        break
                    }
                }
            }

            if (-not $isProtected -and $pathToCheck -and $protectedConfig.ProtectedSubtrees) {
                foreach ($ps in $protectedConfig.ProtectedSubtrees) {
                    if ($pathToCheck -ieq $ps -or $pathToCheck -like "$ps\*") {
                        $isProtected = $true
                        $protectReason = "Critical Windows system path ($ps)"
                        break
                    }
                }
            }

            if (-not $isProtected -and $pathToCheck -and $protectedConfig.ProtectedRegistryRoots) {
                $normPath = $pathToCheck -replace '^Microsoft\.PowerShell\.Core\\Registry::HKEY_LOCAL_MACHINE\\?', 'HKLM:\' `
                                         -replace '^Microsoft\.PowerShell\.Core\\Registry::HKEY_CURRENT_USER\\?', 'HKCU:\'
                foreach ($pr in $protectedConfig.ProtectedRegistryRoots) {
                    $normPr = $pr.TrimEnd('\')
                    if ($normPath -ieq $normPr -or $normPath -like "$normPr\*") {
                        $isProtected = $true
                        $protectReason = "Critical Windows registry hive ($pr)"
                        break
                    }
                }
            }

            if (-not $isProtected -and $nameToCheck -and $protectedConfig.ProtectedServices) {
                foreach ($ps in $protectedConfig.ProtectedServices) {
                    if ($nameToCheck -ieq $ps) {
                        $isProtected = $true
                        $protectReason = "Protected Windows Core Service ($ps)"
                        break
                    }
                }
            }

            if (-not $isProtected -and $nameToCheck -and $protectedConfig.ProtectedProcesses) {
                foreach ($proc in $protectedConfig.ProtectedProcesses) {
                    if ($nameToCheck -ieq $proc) {
                        $isProtected = $true
                        $protectReason = "Protected Windows Core Process ($proc)"
                        break
                    }
                }
            }

            if (-not $isProtected -and $pathToCheck -and $protectedConfig.ProtectedFolderNames) {
                $leaf = Split-Path $pathToCheck -Leaf
                foreach ($pfn in $protectedConfig.ProtectedFolderNames) {
                    if ($leaf -ieq $pfn) {
                        $isProtected = $true
                        $protectReason = "Protected Windows system component name ($pfn)"
                        break
                    }
                }
            }
        }

        # If protected, immediately flag and set 0% score
        if ($isProtected) {
            $scoredList.Add([PSCustomObject]@{
                Category           = $item.Category
                Type               = $item.Type
                Path               = $pathToCheck
                Name               = $nameToCheck
                ValueName          = if ($item.ValueName) { $item.ValueName } else { "" }
                Size               = if ($item.Size) { [long]$item.Size } else { 0L }
                ItemCount          = if ($item.ItemCount) { [int]$item.ItemCount } else { 1 }
                Score              = 0
                ConfidenceCategory = "PROTECTED"
                Badge              = "[-] PROTECTED"
                IsProtected        = $true
                Selected           = $false
                EvidenceDetails    = @($protectReason)
            })
            continue
        }

        # 2. Multi-factor scoring
        $rawScore = 0
        $evidence = [System.Collections.Generic.List[string]]::new()

        $leafName = switch ($item.Category) {
            "Task"     { $nameToCheck }
            "Service"  { if ($item.DisplayName) { $item.DisplayName } else { $nameToCheck } }
            "Registry" { if ($item.Type -eq "Value" -and $item.ValueName) { $item.ValueName } else { Split-Path $pathToCheck -Leaf } }
            "Shortcut" { [System.IO.Path]::GetFileNameWithoutExtension($pathToCheck) }
            Default    { if ($pathToCheck) { Split-Path $pathToCheck -Leaf } else { $nameToCheck } }
        }
        $appDisplayName = if ($Application.DisplayName) { $Application.DisplayName } else { "" }
        $appPublisher = if ($Application.Publisher) { $Application.Publisher } else { "" }
        $installLocation = if ($Application.InstallLocation) { $Application.InstallLocation } else { "" }

        # A. Rule Match
        if ($item.MatchReason -and $item.MatchReason -like "*Configured known*") {
            $rawScore += 45
            $evidence.Add("Matches verified application rule database (+45%)")
        }

        # B. Direct Exact Name Match
        if ($leafName -and $appDisplayName -and $leafName -ieq $appDisplayName) {
            $rawScore += 40
            $evidence.Add("Exact application name match on item identifier (+40%)")
        } elseif ($leafName -and $appDisplayName -and $leafName -like "*$appDisplayName*") {
            $rawScore += 25
            $evidence.Add("Target contains full application name (+25%)")
        }

        # C. Install Path Association
        if ($installLocation -and $pathToCheck -and $pathToCheck -like "$installLocation*") {
            $rawScore += 40
            $evidence.Add("Directly located within official installation path (+40%)")
        }

        # D. Publisher Association
        if ($appPublisher) {
            $pubWords = $appPublisher -split '[\s\-_]+' | Where-Object { 
                $_.Length -ge 4 -and $_ -notmatch '^(Microsoft|Google|Apple|Corp|Corporation|Inc|LLC|Technologies|Technology|Software)$' 
            }
            foreach ($pw in $pubWords) {
                if ($pathToCheck -like "*$pw*" -or $nameToCheck -like "*$pw*") {
                    $rawScore += 20
                    $evidence.Add("Publisher name match '$pw' (+20%)")
                    break
                }
            }
        }

        # E. App Data & Specific Directories
        if ($pathToCheck -match 'AppData[\\/](Local|Roaming|LocalLow)' -or $pathToCheck -match 'ProgramData') {
            $rawScore += 15
            $evidence.Add("Resides in user/machine application data repository (+15%)")
        }

        # Clamp score between 0 and 99
        $finalScore = [math]::Min(99, [math]::Max(0, $rawScore))

        # Filter out items with score < 20 (unmatched items)
        if ($finalScore -lt 20) {
            continue
        }

        # Categorize
        $confCategory = "LOW"
        $badge = "[LOW]"
        $preSelect = $false

        if ($finalScore -ge $highThreshold) {
            $confCategory = "HIGH"
            $badge = "[HIGH]"
            $preSelect = $true
        } elseif ($finalScore -ge $reviewThreshold) {
            $confCategory = "REVIEW"
            $badge = "[REVIEW]"
            $preSelect = $false
        }

        $scoredList.Add([PSCustomObject]@{
            Category           = $item.Category
            Type               = $item.Type
            Path               = $pathToCheck
            Name               = $nameToCheck
            ValueName          = if ($item.ValueName) { $item.ValueName } else { "" }
            Size               = if ($item.Size) { [long]$item.Size } else { 0L }
            ItemCount          = if ($item.ItemCount) { [int]$item.ItemCount } else { 1 }
            Score              = $finalScore
            ConfidenceCategory = $confCategory
            Badge              = $badge
            IsProtected        = $false
            Selected           = $preSelect
            EvidenceDetails    = $evidence.ToArray()
        })
    }

    return $scoredList
}
