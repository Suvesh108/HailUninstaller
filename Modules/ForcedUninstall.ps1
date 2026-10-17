# Modules/ForcedUninstall.ps1
# Forced Uninstall and Residual Purge Engine (Reverse-engineered from Revo Uninstaller Pro)
# Allows purging corrupted, half-uninstalled, or unlisted applications directly from their folder path or executable.

function Start-ForcedUninstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Target,
        [string]$ConfigDir = "",
        [scriptblock]$ProgressCallback = $null
    )

    if (-not $ConfigDir) {
        $ConfigDir = Join-Path (Split-Path $PSScriptRoot -Parent) "Config"
    }

    $targetName = ""
    $targetPublisher = ""
    $targetPath = ""

    # Check if target is an existing path (directory or file)
    if (Test-Path -LiteralPath $Target) {
        $item = Get-Item -LiteralPath $Target -ErrorAction SilentlyContinue
        if ($item -is [System.IO.FileInfo]) {
            $targetPath = Split-Path $item.FullName -Parent
            $targetName = [System.IO.Path]::GetFileNameWithoutExtension($item.Name)
            try {
                $vi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($item.FullName)
                if ($vi.ProductName) { $targetName = $vi.ProductName }
                if ($vi.CompanyName) { $targetPublisher = $vi.CompanyName }
            } catch { }
        } else {
            $targetPath = $item.FullName
            $targetName = $item.Name

            # Try to discover an executable inside the directory to extract metadata
            $sampleExe = Get-ChildItem -LiteralPath $targetPath -Filter *.exe -File -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($sampleExe) {
                try {
                    $vi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($sampleExe.FullName)
                    if ($vi.ProductName) { $targetName = $vi.ProductName }
                    if ($vi.CompanyName) { $targetPublisher = $vi.CompanyName }
                } catch { }
            }
        }
    } else {
        # Target was supplied as a raw application name or keyword
        $targetName = $Target.Trim()
    }

    # Construct synthetic application definition
    $mockApp = [PSCustomObject]@{
        DisplayName     = $targetName
        Publisher       = $targetPublisher
        InstallLocation = $targetPath
        Type            = "ForcedTarget"
    }

    $rawCandidates = [System.Collections.Generic.List[PSCustomObject]]::new()
    $seenPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    # 1. Primary Target Directory
    if ($targetPath -and (Test-Path -LiteralPath $targetPath)) {
        $seenPaths.Add($targetPath) | Out-Null
        $stat = Get-FolderSizeSafe -Path $targetPath
        $rawCandidates.Add([PSCustomObject]@{
            Category     = "File"
            Type         = "Directory"
            Path         = $targetPath
            Size         = $stat.Size
            ItemCount    = $stat.Count
            MatchReason  = "Primary forced uninstall target path"
            MatchedToken = $targetName
        })
    }

    # 2. File System Deep Scan for Target
    if ($ProgressCallback) { & $ProgressCallback 1 5 "Scanning file system remnants for '$targetName'..." }
    $fileLeftovers = Scan-FileLeftovers -AppName $targetName -Publisher $targetPublisher -InstallLocation $targetPath
    foreach ($fl in $fileLeftovers) {
        if (-not $seenPaths.Contains($fl.Path)) {
            $seenPaths.Add($fl.Path) | Out-Null
            $rawCandidates.Add($fl)
        }
    }

    # 3. Registry Scan
    if ($ProgressCallback) { & $ProgressCallback 2 5 "Scanning Windows Registry remnants..." }
    $regLeftovers = Scan-RegistryLeftovers -AppName $targetName -Publisher $targetPublisher
    foreach ($rl in $regLeftovers) {
        if (-not $seenPaths.Contains($rl.Path)) {
            $seenPaths.Add($rl.Path) | Out-Null
            $rawCandidates.Add($rl)
        }
    }

    # 4. Services Scan
    if ($ProgressCallback) { & $ProgressCallback 3 5 "Scanning associated Windows services..." }
    $svcLeftovers = Scan-ServiceLeftovers -AppName $targetName -Publisher $targetPublisher
    foreach ($sl in $svcLeftovers) {
        $rawCandidates.Add($sl)
    }

    # 5. Scheduled Tasks & Shortcuts
    if ($ProgressCallback) { & $ProgressCallback 4 5 "Scanning scheduled tasks and shortcuts..." }
    $taskLeftovers = Scan-TaskLeftovers -AppName $targetName
    foreach ($tl in $taskLeftovers) { $rawCandidates.Add($tl) }

    $shortcutLeftovers = Scan-ShortcutLeftovers -AppName $targetName -InstallLocation $targetPath
    foreach ($scl in $shortcutLeftovers) { $rawCandidates.Add($scl) }

    # 6. Safety and Evidence Scoring
    if ($ProgressCallback) { & $ProgressCallback 5 5 "Evaluating safety guardrails and scoring..." }
    $evaluated = Evaluate-CandidateEvidence -Candidates $rawCandidates -Application $mockApp -ConfigDir $ConfigDir

    return [PSCustomObject]@{
        TargetName      = $targetName
        TargetPath      = $targetPath
        TargetPublisher = $targetPublisher
        Candidates      = [array]@($evaluated)
    }
}
