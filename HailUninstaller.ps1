<#
.SYNOPSIS
    HailUninstaller - Deep Application Removal Tool for Windows
.DESCRIPTION
    Lightweight, zero-installation PowerShell tool to completely identify and remove
    an application's remaining footprint (files, registry, services, tasks, shortcuts).
    Features multi-factor evidence scoring, safety guardrails, restorable backups, and TUI/CLI modes.
.PARAMETER List
    List all installed applications.
.PARAMETER Scan
    Scan for leftovers of a specific application without modifying system.
.PARAMETER DeepScan
    Perform exhaustive deep subsystem scan for an application.
.PARAMETER Uninstall
    Execute native uninstaller followed optionally by leftover deep clean.
.PARAMETER DeepClean
    Automatically clean detected leftovers.
.PARAMETER CreateBackup
    Create restorable snapshot before deleting leftovers.
.PARAMETER Restore
    Restore a previously created backup by Backup ID.
.PARAMETER Silent
    Run without interactive prompts.
#>

[CmdletBinding(DefaultParameterSetName = "Interactive")]
param(
    [Parameter(ParameterSetName = "List")]
    [switch]$List,

    [Parameter(ParameterSetName = "Scan")]
    [string]$Scan,

    [Parameter(ParameterSetName = "DeepScan")]
    [string]$DeepScan,

    [Parameter(ParameterSetName = "Uninstall")]
    [string]$Uninstall,

    [Parameter(ParameterSetName = "Uninstall")]
    [switch]$DeepClean,

    [Parameter(ParameterSetName = "Uninstall")]
    [switch]$CreateBackup,

    [Parameter(ParameterSetName = "Restore")]
    [string]$Restore,

    [switch]$Silent,
    [switch]$Json
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulesDir = Join-Path $ScriptDir "Modules"
$ConfigDir = Join-Path $ScriptDir "Config"

# Load Modules
$moduleFiles = @(
    "UI.ps1",
    "Applications.ps1",
    "FileScanner.ps1",
    "RegistryScanner.ps1",
    "ServiceScanner.ps1",
    "TaskScanner.ps1",
    "ProcessScanner.ps1",
    "ShortcutScanner.ps1",
    "Evidence.ps1",
    "Scanner.ps1",
    "Backup.ps1",
    "Cleanup.ps1",
    "Restore.ps1"
)

foreach ($m in $moduleFiles) {
    $mPath = Join-Path $ModulesDir $m
    if (Test-Path -LiteralPath $mPath) {
        . $mPath
    } else {
        Write-Error "Required module missing: $mPath"
        exit 1
    }
}

# ==========================================
# CLI Execution Modes
# ==========================================

if ($List) {
    $apps = Get-InstalledApplications
    if ($Json) {
        $apps | ConvertTo-Json -Depth 3
    } else {
        $apps | Select-Object DisplayName, DisplayVersion, Publisher, Type | Format-Table -AutoSize
    }
    exit 0
}

if ($Scan -or $DeepScan) {
    $targetName = if ($Scan) { $Scan } else { $DeepScan }
    $matchingApps = Get-InstalledApplications -SearchFilter $targetName
    $app = $matchingApps | Select-Object -First 1

    if (-not $app) {
        $app = [PSCustomObject]@{
            DisplayName     = $targetName
            Publisher       = ""
            InstallLocation = ""
            Type            = "Manual"
        }
    }

    Write-Host "Scanning leftovers for: $($app.DisplayName)..." -ForegroundColor Cyan
    $results = Start-DeepScan -Application $app -ConfigDir $ConfigDir

    if ($Json) {
        $results | ConvertTo-Json -Depth 4
    } else {
        $results | Select-Object Badge, Score, Category, Type, Path, Size | Format-Table -AutoSize
    }
    exit 0
}

if ($Restore) {
    Write-Host "Restoring backup: $Restore..." -ForegroundColor Cyan
    $res = Restore-CleanupBackup -BackupId $Restore
    Write-Host "Restoration complete. Restored items: $($res.RestoredCount), Errors: $($res.FailedCount)" -ForegroundColor Green
    exit 0
}

if ($Uninstall) {
    $matchingApps = Get-InstalledApplications -SearchFilter $Uninstall
    $app = $matchingApps | Select-Object -First 1

    if (-not $app) {
        Write-Error "Could not find installed application matching '$Uninstall'."
        exit 1
    }

    Write-Host "Uninstalling $($app.DisplayName)..." -ForegroundColor Cyan
    $uninstalled = Invoke-NativeUninstall -Application $app -Quiet:$Silent

    if ($DeepClean) {
        Write-Host "Running leftover scan..." -ForegroundColor Cyan
        $results = Start-DeepScan -Application $app -ConfigDir $ConfigDir
        $selected = @($results | Where-Object { $_.ConfidenceCategory -eq "HIGH" -and -not $_.IsProtected })

        if ($selected.Count -gt 0) {
            Write-Host ""
            Write-Host "==================== HUMAN APPROVAL REQUIRED ====================" -ForegroundColor Yellow
            Write-Host "HailUninstaller detected $($selected.Count) leftover items:" -ForegroundColor White
            $selected | Select-Object Badge, Category, Path, Type, Size | Format-Table -AutoSize
            Write-Host "HUMAN CONFIRMATION: Type 'YES' to approve deletion of these items: " -ForegroundColor Red -NoNewline
            $approval = Read-Host
            if ($approval -cne "YES") {
                Write-Host "Operation cancelled. Human approval was not granted. No items were deleted." -ForegroundColor Green
                exit 0
            }

            if ($CreateBackup) {
                Write-Host "Creating backup..." -ForegroundColor Cyan
                New-CleanupBackup -Application $app -SelectedItems $selected | Out-Null
            }
            Write-Host "Cleaning $($selected.Count) leftover items..." -ForegroundColor Yellow
            $cRes = Invoke-CleanupItems -SelectedItems $selected -HumanApproved
            Write-Host "Cleanup complete: Freed $(Format-Bytes $cRes.RemovedBytes) across $($cRes.RemovedCount) items." -ForegroundColor Green
        } else {
            Write-Host "No high-confidence leftovers found." -ForegroundColor Gray
        }
    }
    exit 0
}

# ==========================================
# Interactive TUI Mode
# ==========================================

function Show-InteractiveAppPicker {
    while ($true) {
        Clear-Host
        Show-Banner
        Show-Header -Title "Installed Applications Browser"

        Write-Host "Type a filter term (or press Enter to list all, 'B' to return): " -ForegroundColor Yellow -NoNewline
        $query = Read-Host
        if ($query -ieq "B") { return $null }

        $apps = Get-InstalledApplications -SearchFilter $query
        if ($apps.Count -eq 0) {
            Write-Host "No applications found matching '$query'. Press any key to continue..." -ForegroundColor Red
            [void][Console]::ReadKey($true)
            continue
        }

        Clear-Host
        Show-Banner
        Show-Header -Title "Search Results: '$query'"

        $displayLimit = [math]::Min(25, $apps.Count)
        for ($i = 0; $i -lt $displayLimit; $i++) {
            $num = "{0,2}" -f ($i + 1)
            $name = $apps[$i].DisplayName
            if ($name.Length -gt 45) { $name = $name.Substring(0, 42) + "..." }
            $ver = $apps[$i].DisplayVersion
            Write-Host "[$num] " -ForegroundColor Cyan -NoNewline
            Write-Host ("{0,-48}" -f $name) -ForegroundColor White -NoNewline
            Write-Host " ($ver)" -ForegroundColor Gray
        }

        if ($apps.Count -gt $displayLimit) {
            Write-Host "... and $($apps.Count - $displayLimit) more. Refine search term if needed." -ForegroundColor DarkGray
        }

        Write-Host ""
        Write-Host "Select application number (1-$displayLimit), 'S' to search again, 'B' to Back: " -ForegroundColor Yellow -NoNewline
        $sel = Read-Host
        if ($sel -ieq "B") { return $null }
        if ($sel -ieq "S") { continue }

        $index = 0
        if ([int]::TryParse($sel, [ref]$index) -and $index -ge 1 -and $index -le $displayLimit) {
            return $apps[$index - 1]
        }
    }
}

function Show-CleanupPreviewTui {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Application,
        [Parameter(Mandatory = $true)]
        [array]$ScoredItems
    )

    $items = [System.Collections.Generic.List[PSCustomObject]]::new()
    foreach ($it in $ScoredItems) {
        $items.Add($it)
    }

    while ($true) {
        Clear-Host
        Show-Banner
        Show-Header -Title "CLEANUP PREVIEW - $($Application.DisplayName)"

        $highItems = @($items | Where-Object { $_.ConfidenceCategory -eq "HIGH" })
        $reviewItems = @($items | Where-Object { $_.ConfidenceCategory -eq "REVIEW" })
        $protectedItems = @($items | Where-Object { $_.ConfidenceCategory -eq "PROTECTED" })

        Write-Host (Format-Color -Text "HIGH CONFIDENCE" -ColorName "BrightGreen")
        if ($highItems.Count -eq 0) {
            Write-Host "  (None detected)" -ForegroundColor DarkGray
        } else {
            foreach ($h in $highItems) {
                $chk = if ($h.Selected) { "[x]" } else { "[ ]" }
                $chkCol = if ($h.Selected) { "BrightGreen" } else { "DarkGray" }
                $p = if ($h.Path) { $h.Path } else { $h.Name }
                if ($p.Length -gt 50) { $p = "..." + $p.Substring($p.Length - 47) }
                $sz = if ($h.Size -gt 0) { Format-Bytes $h.Size } else { $h.Type }
                Write-Host "  $(Format-Color -Text $chk -ColorName $chkCol) " -NoNewline
                Write-Host ("{0,-52}" -f $p) -NoNewline
                Write-Host ("{0,10}" -f $sz) -ForegroundColor Cyan
            }
        }
        Write-Host ""

        Write-Host (Format-Color -Text "REVIEW" -ColorName "BrightYellow")
        if ($reviewItems.Count -eq 0) {
            Write-Host "  (None detected)" -ForegroundColor DarkGray
        } else {
            for ($ri = 0; $ri -lt $reviewItems.Count; $ri++) {
                $r = $reviewItems[$ri]
                $chk = if ($r.Selected) { "[x]" } else { "[ ]" }
                $chkCol = if ($r.Selected) { "BrightYellow" } else { "DarkGray" }
                $p = if ($r.Path) { $r.Path } else { $r.Name }
                if ($p.Length -gt 46) { $p = "..." + $p.Substring($p.Length - 43) }
                $idxLabel = "R$($ri + 1)"
                Write-Host "  [$idxLabel] $(Format-Color -Text $chk -ColorName $chkCol) " -NoNewline
                Write-Host ("{0,-48}" -f $p) -NoNewline
                Write-Host ("{0,10}" -f $r.Type) -ForegroundColor Yellow
            }
        }
        Write-Host ""

        Write-Host (Format-Color -Text "PROTECTED" -ColorName "BrightRed")
        if ($protectedItems.Count -eq 0) {
            Write-Host "  (None)" -ForegroundColor DarkGray
        } else {
            foreach ($pr in $protectedItems) {
                $p = if ($pr.Path) { $pr.Path } else { $pr.Name }
                if ($p.Length -gt 55) { $p = "..." + $p.Substring($p.Length - 52) }
                Write-Host "  [-] " -ForegroundColor Red -NoNewline
                Write-Host ("{0,-54}" -f $p) -ForegroundColor DarkGray -NoNewline
                Write-Host "System Safe" -ForegroundColor Red
            }
        }
        Write-Host ("-" * 64) -ForegroundColor Cyan

        $selectedItems = @($items | Where-Object { $_.Selected -and -not $_.IsProtected })
        $totalBytes = 0L
        foreach ($s in $selectedItems) { $totalBytes += [long]$s.Size }

        Write-Host "Selected: $(Format-Color -Text "$($selectedItems.Count)" -ColorName 'BrightWhite') items | " -NoNewline
        Write-Host "Reclaimable Size: $(Format-Color -Text (Format-Bytes $totalBytes) -ColorName 'BrightGreen')"
        Write-Host ""

        Write-Host '[A] Select All High | [N] None | [R<num>] Toggle Review | [D] Delete | [B] Back: ' -ForegroundColor Yellow -NoNewline
        $cmd = Read-Host

        if ($cmd -ieq "B") { return $false }
        if ($cmd -ieq "A") {
            foreach ($it in $highItems) { $it.Selected = $true }
            continue
        }
        if ($cmd -ieq "N") {
            foreach ($it in $items) { $it.Selected = $false }
            continue
        }
        if ($cmd -imatch '^R(\d+)$') {
            $rNum = [int]$matches[1]
            if ($rNum -ge 1 -and $rNum -le $reviewItems.Count) {
                $reviewItems[$rNum - 1].Selected = -not $reviewItems[$rNum - 1].Selected
            }
            continue
        }
        if ($cmd -ieq "D") {
            if ($selectedItems.Count -eq 0) {
                Write-Host "No items selected for deletion! Press any key..." -ForegroundColor Yellow
                [void][Console]::ReadKey($true)
                continue
            }

            # Step 7: Backup Prompt
            Write-Host ""
            Write-Host "Create cleanup backup? [Y/N] (Default: Y): " -ForegroundColor Cyan -NoNewline
            $backupResp = Read-Host
            $doBackup = ($backupResp -ine "N")

            if ($doBackup) {
                Write-Host "Creating backup snapshot..." -ForegroundColor Cyan
                $bRes = New-CleanupBackup -Application $Application -SelectedItems $selectedItems
                Write-Host "Backup complete ($($bRes.BackupId))." -ForegroundColor Green
            }

            Write-Host "$(Format-Bytes $totalBytes) ready for removal. Continue deletion? [Y/N]: " -ForegroundColor Red -NoNewline
            $confirm = Read-Host
            if ($confirm -ieq "Y") {
                Clear-Host
                Show-Banner
                Show-Header -Title "Executing Cleanup"

                $progressCb = {
                    param($cur, $tot, $task)
                    Show-ProgressBar -Current $cur -Total $tot -TaskName $task
                }

                $cRes = Invoke-CleanupItems -SelectedItems $selectedItems -HumanApproved -ProgressCallback $progressCb
                Write-Host "+==============================================================+" -ForegroundColor Green
                Write-Host "|                      CLEANUP COMPLETE                        |" -ForegroundColor Green
                Write-Host "+==============================================================+" -ForegroundColor Green
                Write-Host "Removed Space: $(Format-Bytes $cRes.RemovedBytes)" -ForegroundColor White
                Write-Host "Removed Items: $($cRes.RemovedCount)" -ForegroundColor White
                if ($cRes.FailedCount -gt 0) {
                    Write-Host "Failed Items:  $($cRes.FailedCount)" -ForegroundColor Yellow
                }
                Write-Host ""
                Write-Host "Press Enter to continue..." -ForegroundColor Cyan
                [void][Console]::ReadLine()
                return $true
            } else {
                Write-Host "Deletion cancelled by user. No files or system items were modified." -ForegroundColor Green
                Start-Sleep -Milliseconds 1200
            }
        }
    }
}

function Show-RestoreMenuTui {
    while ($true) {
        Clear-Host
        Show-Banner
        Show-Header -Title 'Cleanup History and Restore'

        $backups = @(Get-CleanupBackups)
        if ($backups.Count -eq 0) {
            Write-Host "No previous cleanup backups found." -ForegroundColor Gray
            Write-Host ""
            Write-Host "Press Enter to return to main menu..." -ForegroundColor Cyan
            [void][Console]::ReadLine()
            return
        }

        for ($i = 0; $i -lt $backups.Count; $i++) {
            $b = $backups[$i]
            $num = "{0,2}" -f ($i + 1)
            $date = if ($b.CreatedAt) { ([datetime]$b.CreatedAt).ToString("yyyy-MM-dd HH:mm") } else { "Unknown" }
            $sz = Format-Bytes $b.TotalBytes
            Write-Host "[$num] " -ForegroundColor Cyan -NoNewline
            Write-Host ("{0,-28}" -f $b.ApplicationName) -ForegroundColor White -NoNewline
            Write-Host ("{0,12}" -f $sz) -ForegroundColor Green -NoNewline
            Write-Host "  ($date)" -ForegroundColor Gray
        }

        Write-Host ""
        Write-Host "Select backup number to restore (1-$($backups.Count)), or 'B' to Back: " -ForegroundColor Yellow -NoNewline
        $sel = Read-Host
        if ($sel -ieq "B") { return }

        $idx = 0
        if ([int]::TryParse($sel, [ref]$idx) -and $idx -ge 1 -and $idx -le $backups.Count) {
            $targetBackup = $backups[$idx - 1]
            Write-Host "Restore files and registry for $($targetBackup.ApplicationName)? [Y/N]: " -ForegroundColor Red -NoNewline
            $confirm = Read-Host
            if ($confirm -ieq "Y") {
                $progressCb = {
                    param($cur, $tot, $task)
                    Show-ProgressBar -Current $cur -Total $tot -TaskName $task
                }
                $rRes = Restore-CleanupBackup -BackupId $targetBackup.BackupId -ProgressCallback $progressCb
                Write-Host "`nRestore complete: $($rRes.RestoredCount) restored, $($rRes.FailedCount) errors." -ForegroundColor Green
                Write-Host "Press Enter to continue..." -ForegroundColor Cyan
                [void][Console]::ReadLine()
            }
        }
    }
}

# Interactive Main Menu Loop
while ($true) {
    Clear-Host
    Show-Banner

    Write-Host "  1. Installed Applications" -ForegroundColor White
    Write-Host "  2. Scan for Leftovers" -ForegroundColor White
    Write-Host "  3. Deep Scan (Specific App)" -ForegroundColor White
    Write-Host "  4. Cleanup History" -ForegroundColor White
    Write-Host "  5. Restore" -ForegroundColor White
    Write-Host "  Q. Exit" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Select an option: " -ForegroundColor Cyan -NoNewline
    $opt = Read-Host

    switch ($opt.ToUpper()) {
        "1" {
            $app = Show-InteractiveAppPicker
            if ($app) {
                Clear-Host
                Show-Banner
                Show-AppDetails -App $app

                Write-Host "[1] Normal Uninstall" -ForegroundColor White
                Write-Host "[2] Uninstall + Deep Scan" -ForegroundColor Green
                Write-Host "[3] Scan Only" -ForegroundColor Cyan
                Write-Host "[4] Cancel" -ForegroundColor Gray
                Write-Host ""
                Write-Host "Select action: " -ForegroundColor Yellow -NoNewline
                $action = Read-Host

                switch ($action) {
                    "1" {
                        Invoke-NativeUninstall -Application $app
                        Write-Host "Press Enter to continue..." -ForegroundColor Cyan
                        [void][Console]::ReadLine()
                    }
                    "2" {
                        Invoke-NativeUninstall -Application $app
                        Write-Host "`nInitiating deep leftover scan..." -ForegroundColor Cyan
                        $progressCb = {
                            param($cur, $tot, $task)
                            Show-ProgressBar -Current $cur -Total $tot -TaskName $task
                        }
                        $scored = Start-DeepScan -Application $app -ConfigDir $ConfigDir -ProgressCallback $progressCb
                        Show-CleanupPreviewTui -Application $app -ScoredItems $scored
                    }
                    "3" {
                        Write-Host "`nInitiating deep leftover scan..." -ForegroundColor Cyan
                        $progressCb = {
                            param($cur, $tot, $task)
                            Show-ProgressBar -Current $cur -Total $tot -TaskName $task
                        }
                        $scored = Start-DeepScan -Application $app -ConfigDir $ConfigDir -ProgressCallback $progressCb
                        Show-CleanupPreviewTui -Application $app -ScoredItems $scored
                    }
                }
            }
        }
        "2" {
            Write-Host "Enter application name or token to scan: " -ForegroundColor Yellow -NoNewline
            $appName = Read-Host
            if ($appName) {
                $mockApp = [PSCustomObject]@{
                    DisplayName     = $appName
                    Publisher       = ""
                    InstallLocation = ""
                    Type            = "Manual"
                }
                $progressCb = {
                    param($cur, $tot, $task)
                    Show-ProgressBar -Current $cur -Total $tot -TaskName $task
                }
                $scored = Start-DeepScan -Application $mockApp -ConfigDir $ConfigDir -ProgressCallback $progressCb
                Show-CleanupPreviewTui -Application $mockApp -ScoredItems $scored
            }
        }
        "3" {
            $app = Show-InteractiveAppPicker
            if ($app) {
                $progressCb = {
                    param($cur, $tot, $task)
                    Show-ProgressBar -Current $cur -Total $tot -TaskName $task
                }
                $scored = Start-DeepScan -Application $app -ConfigDir $ConfigDir -ProgressCallback $progressCb
                Show-CleanupPreviewTui -Application $app -ScoredItems $scored
            }
        }
        "4" {
            Show-RestoreMenuTui
        }
        "5" {
            Show-RestoreMenuTui
        }
        "Q" {
            Write-Host "Exiting HailUninstaller. Stay clean!" -ForegroundColor Cyan
            exit 0
        }
    }
}
