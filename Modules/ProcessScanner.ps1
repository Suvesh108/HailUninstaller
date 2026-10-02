# Modules/ProcessScanner.ps1
# Running processes detector for active application instances

function Scan-RunningAppProcesses {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppName,
        [string[]]$KnownExecutables = @(),
        [string]$InstallLocation = ""
    )

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    $seenPids = [System.Collections.Generic.HashSet[int]]::new()

    $tokens = [System.Collections.Generic.List[string]]::new()
    if ($AppName) {
        $tokens.Add($AppName.Trim())
        $words = $AppName -split '[\s\-_]+' | Where-Object { $_.Length -ge 4 -and $_ -notmatch '^(Microsoft|Windows|System)$' }
        foreach ($w in $words) { $tokens.Add($w) }
    }

    try {
        $processes = Get-Process -ErrorAction SilentlyContinue
        foreach ($p in $processes) {
            if ($seenPids.Contains($p.Id)) { continue }

            $matched = $false
            $matchReason = ""
            $procPath = ""

            try { $procPath = $p.Path } catch { }

            # 1. Match known executables
            foreach ($ke in $KnownExecutables) {
                $baseKe = [System.IO.Path]::GetFileNameWithoutExtension($ke)
                if ($p.ProcessName -ieq $baseKe -or ($procPath -and (Split-Path $procPath -Leaf) -ieq $ke)) {
                    $matched = $true
                    $matchReason = "Matches known executable rule '$ke'"
                    break
                }
            }

            # 2. Match install location
            if (-not $matched -and $InstallLocation -and $procPath) {
                if ($procPath -like "$InstallLocation*") {
                    $matched = $true
                    $matchReason = "Running executable located in install folder"
                }
            }

            # 3. Match tokens
            if (-not $matched) {
                foreach ($token in $tokens) {
                    if ($p.ProcessName -like "*$token*") {
                        $matched = $true
                        $matchReason = "Process name matches token '$token'"
                        break
                    }
                }
            }

            if ($matched) {
                $seenPids.Add($p.Id) | Out-Null
                $results.Add([PSCustomObject]@{
                    Category    = "Process"
                    Type        = "Process"
                    Id          = $p.Id
                    Name        = $p.ProcessName
                    Path        = $procPath
                    Size        = $p.WorkingSet64
                    ItemCount   = 1
                    MatchReason = $matchReason
                })
            }
        }
    } catch { }

    return $results
}

function Stop-AppProcesses {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Processes,
        [switch]$Force = $true
    )

    foreach ($p in $Processes) {
        try {
            Write-Host "Stopping process: $($p.Name) (PID: $($p.Id))..." -ForegroundColor Yellow
            Stop-Process -Id $p.Id -Force:$Force -ErrorAction SilentlyContinue
        } catch {
            Write-Warning "Could not terminate PID $($p.Id): $_"
        }
    }
}
