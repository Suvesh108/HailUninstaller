# Modules/Scanner.ps1
# Master Deep Scan orchestrator coordinating all subsystem scanners

function Start-DeepScan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Application,
        [string]$ConfigDir = "",
        [scriptblock]$ProgressCallback = $null
    )

    if (-not $ConfigDir) {
        $ConfigDir = Join-Path (Split-Path $PSScriptRoot -Parent) "Config"
    }

    $appsConfig = Load-ConfigSafe -Path (Join-Path $ConfigDir "Applications.json")
    $knownRule = $null

    if ($appsConfig -and $appsConfig.Applications) {
        foreach ($appRule in $appsConfig.Applications) {
            if ($Application.DisplayName -like "*$($appRule.Id)*" -or 
                ($appRule.Aliases -and ($appRule.Aliases | Where-Object { $Application.DisplayName -like "*$_*" }))) {
                $knownRule = $appRule
                break
            }
        }
    }

    $rawCandidates = [System.Collections.Generic.List[PSCustomObject]]::new()

    $appName = "$($Application.DisplayName)"
    $appPublisher = "$($Application.Publisher)"
    $appInstallLoc = "$($Application.InstallLocation)"

    $knownDirs = @()
    if ($knownRule -and $knownRule.KnownDirectories) {
        $knownDirs = @($knownRule.KnownDirectories)
    }

    $knownKeys = @()
    if ($knownRule -and $knownRule.KnownRegistryKeys) {
        $knownKeys = @($knownRule.KnownRegistryKeys)
    }

    $knownSvcs = @()
    if ($knownRule -and $knownRule.KnownServices) {
        $knownSvcs = @($knownRule.KnownServices)
    }

    $knownTasks = @()
    if ($knownRule -and $knownRule.KnownTasks) {
        $knownTasks = @($knownRule.KnownTasks)
    }

    $steps = @(
        @{ Name = "File System (AppData / ProgramData / InstallDir)"; Action = {
            $fArgs = @{
                AppName          = $appName
                Publisher        = $appPublisher
                InstallLocation  = $appInstallLoc
                KnownDirectories = $knownDirs
            }
            Scan-FileLeftovers @fArgs
        }},
        @{ Name = "Windows Registry (HKCU / HKLM / WOW6432Node)"; Action = {
            $rArgs = @{
                AppName           = $appName
                Publisher         = $appPublisher
                KnownRegistryKeys = $knownKeys
            }
            Scan-RegistryLeftovers @rArgs
        }},
        @{ Name = "Windows Services"; Action = {
            $sArgs = @{
                AppName       = $appName
                Publisher     = $appPublisher
                KnownServices = $knownSvcs
            }
            Scan-ServiceLeftovers @sArgs
        }},
        @{ Name = "Scheduled Tasks"; Action = {
            $tArgs = @{
                AppName    = $appName
                KnownTasks = $knownTasks
            }
            Scan-TaskLeftovers @tArgs
        }},
        @{ Name = "Desktop & Start Menu Shortcuts"; Action = {
            $scArgs = @{
                AppName         = $appName
                InstallLocation = $appInstallLoc
            }
            Scan-ShortcutLeftovers @scArgs
        }}
    )

    $total = $steps.Count
    for ($i = 0; $i -lt $total; $i++) {
        $s = $steps[$i]
        if ($ProgressCallback) {
            & $ProgressCallback ($i + 1) $total $s.Name
        }

        $items = & $s.Action
        if ($items) {
            foreach ($it in $items) {
                $rawCandidates.Add($it)
            }
        }
    }

    # Evaluate all candidates through Evidence scoring engine
    $scoredItems = Evaluate-CandidateEvidence -Candidates $rawCandidates -Application $Application -ConfigDir $ConfigDir

    return $scoredItems
}
