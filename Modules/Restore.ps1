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
            if ($item.Category -eq "File" -and $item.BackupLocation -and (Test-Path -LiteralPath $item.BackupLocation)) {
                $targetParent = Split-Path $item.OriginalPath -Parent
                if (-not (Test-Path -LiteralPath $targetParent)) {
                    New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
                }

                if ($item.Type -eq "Directory") {
                    Copy-Item -LiteralPath "$($item.BackupLocation)\*" -Destination $item.OriginalPath -Recurse -Force -ErrorAction SilentlyContinue
                } else {
                    $srcFile = Get-ChildItem -LiteralPath $item.BackupLocation -File | Select-Object -First 1
                    if ($srcFile) {
                        Copy-Item -LiteralPath $srcFile.FullName -Destination $item.OriginalPath -Force -ErrorAction SilentlyContinue
                    }
                }
                $restoredCount++
            } elseif ($item.Category -eq "Registry" -and $item.BackupLocation -and (Test-Path -LiteralPath $item.BackupLocation)) {
                $p = Start-Process -FilePath "reg.exe" -ArgumentList "import `"$($item.BackupLocation)`"" -Wait -PassThru -WindowStyle Hidden
                if ($p.ExitCode -eq 0) {
                    $restoredCount++
                } else {
                    $failedCount++
                }
            } else {
                $restoredCount++
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
