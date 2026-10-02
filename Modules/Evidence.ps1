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
        [Parameter(Mandatory = $true)]
        [array]$Candidates,
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Application,
        [string]$ConfigDir = ""
    )

    if (-not $ConfigDir) {
        $ConfigDir = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Resolve) "Config"
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
                foreach ($pr in $protectedConfig.ProtectedRegistryRoots) {
                    if ($pathToCheck -ieq $pr -or $pathToCheck -like "$pr\*") {
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

        $leafName = if ($pathToCheck) { Split-Path $pathToCheck -Leaf } else { $nameToCheck }
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
        if ($appPublisher -and $appPublisher -notmatch '^(Microsoft|Google|Apple|Corp|Inc|LLC)$') {
            if ($pathToCheck -like "*$appPublisher*" -or $nameToCheck -like "*$appPublisher*") {
                $rawScore += 20
                $evidence.Add("Publisher name match '$appPublisher' (+20%)")
            }
        }

        # E. App Data & Specific Directories
        if ($pathToCheck -match 'AppData[\\/](Local|Roaming|LocalLow)' -or $pathToCheck -match 'ProgramData') {
            $rawScore += 15
            $evidence.Add("Resides in user/machine application data repository (+15%)")
        }

        # Clamp score between 10 and 99
        $finalScore = [math]::Min(99, [math]::Max(20, $rawScore))

        # Categorize
        $confCategory = "REVIEW"
        $badge = "[REVIEW]"
        $preSelect = $false

        if ($finalScore -ge $highThreshold) {
            $confCategory = "HIGH"
            $badge = "[HIGH]"
            $preSelect = $true
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
