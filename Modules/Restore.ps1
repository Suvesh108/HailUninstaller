# Modules/Restore.ps1
# Restoration engine for rolling back deletions from backup manifests

function Restore-CleanupBackup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupId,
        [scriptblock]$ProgressCallback = $null
    )

    $root = Get-BackupRootDirectory
    $backupFolder = Join-Path $root $BackupId
    $manifestPath = Join-Path $backupFolder "manifest.json"

    if (-not (Test-Path -LiteralPath $manifestPath)) {
        throw "Backup manifest not found for ID '$BackupId' at '$manifestPath'."
    }

    $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $items = @($manifest.Items)
    $total = $items.Count

    $restoredCount = 0
    $failedCount = 0

    for ($i = 0; $i -lt $total; $i++) {
        $item = $items[$i]
        $desc = "Restoring $($item.Category): $($item.OriginalPath)"
        if ($ProgressCallback) {
            & $ProgressCallback ($i + 1) $total $desc
        }

        try {
            $isFolderOrFile = ($item.Category -in @("File", "OrphanFolder", "Shortcut") -or $item.Type -eq "Directory")
            if ($isFolderOrFile -and $item.BackupLocation -and (Test-Path -LiteralPath $item.BackupLocation)) {
                $targetParent = Split-Path $item.OriginalPath -Parent
                if ($targetParent -and -not (Test-Path -LiteralPath $targetParent)) {
                    New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
                }

                if ($item.Type -eq "Directory" -or (Test-Path -LiteralPath $item.BackupLocation -PathType Container)) {
                    if (-not (Test-Path -LiteralPath $item.OriginalPath)) {
                        New-Item -ItemType Directory -Path $item.OriginalPath -Force | Out-Null
                    }
                    Get-ChildItem -LiteralPath $item.BackupLocation -Force -ErrorAction SilentlyContinue |
                        Copy-Item -Destination $item.OriginalPath -Recurse -Force -ErrorAction SilentlyContinue
                    $restoredCount++
                } else {
                    $srcFile = Get-ChildItem -LiteralPath $item.BackupLocation -File -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($srcFile) {
                        Copy-Item -LiteralPath $srcFile.FullName -Destination $item.OriginalPath -Force -ErrorAction SilentlyContinue
                        $restoredCount++
                    } else {
                        $failedCount++
                    }
                }
            } elseif ($item.Category -eq "Registry") {
                if ($item.BackupLocation -eq "MANIFEST_VALUE" -or ($item.Type -eq "Value" -and $item.ValueName)) {
                    try {
                        if (-not (Test-Path -LiteralPath $item.OriginalPath)) {
                            New-Item -Path $item.OriginalPath -Force -ErrorAction SilentlyContinue | Out-Null
                        }
                        Set-ItemProperty -LiteralPath $item.OriginalPath -Name $item.ValueName -Value $item.ValueData -Force -ErrorAction Stop
                        $restoredCount++
                    } catch {
                        $failedCount++
                    }
                } elseif ($item.BackupLocation -and (Test-Path -LiteralPath $item.BackupLocation)) {
                    $p = Start-Process -FilePath "reg.exe" -ArgumentList "import `"$($item.BackupLocation)`"" -Wait -PassThru -WindowStyle Hidden
                    if ($p.ExitCode -eq 0) {
                        $restoredCount++
                    } else {
                        $failedCount++
                    }
                } else {
                    $failedCount++
                }
            } else {
                # Skipped or not found
                if ($item.BackupLocation) {
                    $failedCount++
                }
            }
        } catch {
            $failedCount++
        }
    }

    return [PSCustomObject]@{
        BackupId      = $BackupId
        AppName       = $manifest.ApplicationName
        RestoredCount = $restoredCount
        FailedCount   = $failedCount
    }
}
