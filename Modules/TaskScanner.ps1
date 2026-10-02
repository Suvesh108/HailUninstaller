# Modules/TaskScanner.ps1
# Windows Scheduled Tasks scanner for leftover application tasks

function Scan-TaskLeftovers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppName,
        [string[]]$KnownTasks = @()
    )

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    $seenTasks = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    $tokens = [System.Collections.Generic.List[string]]::new()
    if ($AppName) {
        $tokens.Add($AppName.Trim())
        $words = $AppName -split '[\s\-_]+' | Where-Object { $_.Length -ge 4 -and $_ -notmatch '^(Microsoft|Windows|System|Host)$' }
        foreach ($w in $words) { $tokens.Add($w) }
    }

    try {
        $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue
        foreach ($t in $tasks) {
            # Skip core Microsoft root tasks
            if ($t.TaskPath -like "\Microsoft\Windows\*") { continue }

            $uniqueId = "$($t.TaskPath)$($t.TaskName)"
            if ($seenTasks.Contains($uniqueId)) { continue }

            # Check known tasks
            $matched = $false
            $matchReason = ""
            $matchedToken = ""

            foreach ($kt in $KnownTasks) {
                if ($t.TaskName -like $kt) {
                    $matched = $true
                    $matchReason = "Configured known scheduled task"
                    $matchedToken = "Rule"
                    break
                }
            }

            if (-not $matched) {
                foreach ($token in $tokens) {
                    if ($t.TaskName -like "*$token*" -or $t.TaskPath -like "*$token*") {
                        $matched = $true
                        $matchReason = "Scheduled task name/path matches '$token'"
                        $matchedToken = $token
                        break
                    }

                    # Check actions
                    $actionCmd = ($t.Actions | ForEach-Object { "$($_.Execute) $($_.Arguments)" }) -join " "
                    if ($actionCmd -like "*$token*") {
                        $matched = $true
                        $matchReason = "Scheduled task action execute path matches '$token'"
                        $matchedToken = $token
                        break
                    }
                }
            }

            if ($matched) {
                $seenTasks.Add($uniqueId) | Out-Null
                $results.Add([PSCustomObject]@{
                    Category     = "Task"
                    Type         = "ScheduledTask"
                    Path         = $t.TaskPath
                    Name         = $t.TaskName
                    State        = "$($t.State)"
                    Size         = 0
                    ItemCount    = 1
                    MatchReason  = $matchReason
                    MatchedToken = $matchedToken
                })
            }
        }
    } catch { }

    return $results
}
