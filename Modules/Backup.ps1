# Modules/Backup.ps1
# Backup creation and manifest generation module

function Get-BackupRootDirectory {
    $dir = Join-Path $env:LOCALAPPDATA "HailUninstaller\Backups"
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    return $dir
}

function New-SystemRestorePoint {
    [CmdletBinding()]
    param(
        [string]$Description = "HailUninstaller Safety Snapshot"
    )

    try {
        # Check if System Restore service is available and create restore point
        if (Get-Command Checkpoint-Computer -ErrorAction SilentlyContinue) {
            Checkpoint-Computer -Description $Description -RestorePointType "APPLICATION_UNINSTALL" -ErrorAction Stop
            return $true
        }
    } catch {
        # SystemRestore might be disabled on Windows client/server SKU or recent point exists within 24hr cooldown
        try {
            $sr = Get-CimClass -Namespace root/default -ClassName SystemRestore -ErrorAction SilentlyContinue
            if ($sr) {
                Invoke-CimMethod -Namespace root/default -ClassName SystemRestore -MethodName CreateRestorePoint -Arguments @{
                    Description      = $Description
                    RestorePointType = 1 # APPLICATION_UNINSTALL
                    EventType        = 100 # BEGIN_SYSTEM_CHANGE
                } -ErrorAction SilentlyContinue | Out-Null
                return $true
            }
        } catch { }
    }
    return $false
}

function New-CleanupBackup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Application,
        [Parameter(Mandatory = $true)]
        [array]$SelectedItems,
        [switch]$CreateSystemRestorePoint = $false
    )

    if ($CreateSystemRestorePoint) {
        New-SystemRestorePoint -Description "HailUninstaller - $($Application.DisplayName)" | Out-Null
    }

    $root = Get-BackupRootDirectory
    $safeName = ($Application.DisplayName -replace '[^a-zA-Z0-9_\-]', '_').Trim('_')
    if (-not $safeName) { $safeName = "Cleanup" }
    $backupId = "$(Get-Date -Format 'yyyy-MM-dd_HHmmss')_$safeName"
    $backupFolder = Join-Path $root $backupId

    $filesDir = Join-Path $backupFolder "files"
    $regDir = Join-Path $backupFolder "registry"

    New-Item -ItemType Directory -Path $filesDir -Force | Out-Null
    New-Item -ItemType Directory -Path $regDir -Force | Out-Null

    $manifestItems = [System.Collections.Generic.List[PSCustomObject]]::new()
    $totalBytes = 0L
    $fileIndex = 0
    $regIndex = 0

    foreach ($item in $SelectedItems) {
        if ($item.IsProtected) { continue }

        $manifestEntry = [PSCustomObject]@{
            Index          = $manifestItems.Count + 1
            Category       = $item.Category
            Type           = $item.Type
            OriginalPath   = $item.Path
            Name           = $item.Name
            ValueName      = $item.ValueName
            Size           = [long]$item.Size
            BackupLocation = ""
        }

        # Backup Files and Directories (including OrphanFolders)
        if (($item.Category -in @("File", "OrphanFolder") -or $item.Type -eq "Directory") -and (Test-Path -LiteralPath $item.Path)) {
            $fileIndex++
            $destSub = Join-Path $filesDir "item_$fileIndex"
            try {
                if ($item.Type -eq "Directory" -or (Test-Path -LiteralPath $item.Path -PathType Container)) {
                    Copy-Item -LiteralPath $item.Path -Destination $destSub -Recurse -Force -ErrorAction SilentlyContinue
                } else {
                    New-Item -ItemType Directory -Path $destSub -Force | Out-Null
                    Copy-Item -LiteralPath $item.Path -Destination $destSub -Force -ErrorAction SilentlyContinue
                }
                $manifestEntry.BackupLocation = $destSub
                $totalBytes += [long]$item.Size
            } catch {
                Write-Warning "Failed to backup file item '$($item.Path)': $_"
            }
        } elseif ($item.Category -eq "Registry") {
            $regIndex++
            $regFile = Join-Path $regDir "reg_$regIndex.reg"
            try {
                # Convert PowerShell PSDrive path (e.g. HKLM:\SOFTWARE) to native reg path
                $nativeReg = $item.Path -replace '^HKLM:\\', 'HKEY_LOCAL_MACHINE\' `
                                        -replace '^HKCU:\\', 'HKEY_CURRENT_USER\'
                
                $p = Start-Process -FilePath "reg.exe" -ArgumentList "export `"$nativeReg`" `"$regFile`" /y" -Wait -PassThru -WindowStyle Hidden
                if ($p.ExitCode -eq 0 -and (Test-Path -LiteralPath $regFile)) {
                    $manifestEntry.BackupLocation = $regFile
                }
            } catch {
                Write-Warning "Failed to backup registry key '$($item.Path)': $_"
            }
        }

        $manifestItems.Add($manifestEntry)
    }

    $manifest = [PSCustomObject]@{
        BackupId        = $backupId
        CreatedAt       = (Get-Date).ToString("o")
        ApplicationName = $Application.DisplayName
        Publisher       = $Application.Publisher
        TotalBytes      = $totalBytes
        TotalItems      = $manifestItems.Count
        Items           = $manifestItems
    }

    $manifestJsonPath = Join-Path $backupFolder "manifest.json"
    $manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestJsonPath -Encoding UTF8

    return [PSCustomObject]@{
        Success      = $true
        BackupId     = $backupId
        BackupFolder = $backupFolder
        TotalBytes   = $totalBytes
        ItemCount    = $manifestItems.Count
    }
}

function Get-CleanupBackups {
    [CmdletBinding()]
    param()

    $root = Get-BackupRootDirectory
    $backups = [System.Collections.Generic.List[PSCustomObject]]::new()

    if (Test-Path -LiteralPath $root) {
        $folders = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue
        foreach ($f in $folders) {
            $mPath = Join-Path $f.FullName "manifest.json"
            if (Test-Path -LiteralPath $mPath) {
                try {
                    $m = Get-Content -LiteralPath $mPath -Raw -Encoding UTF8 | ConvertFrom-Json
                    $app = if ($m.ApplicationName) { $m.ApplicationName } elseif ($m.Application) { $m.Application } else { "Cleanup Snapshot" }
                    $ts = if ($m.CreatedAt) {
                        try { ([datetime]$m.CreatedAt).ToString("yyyy-MM-dd HH:mm") } catch { "$($m.CreatedAt)" }
                    } else { "Unknown" }
                    $bytes = if ($null -ne $m.TotalBytes) { [long]$m.TotalBytes } else { 0L }
                    $fmtSz = if (Get-Command Format-Bytes -ErrorAction SilentlyContinue) { Format-Bytes $bytes } else { "$([math]::Round($bytes / 1MB, 2)) MB" }

                    $m | Add-Member -NotePropertyName "Application" -NotePropertyValue $app -Force -ErrorAction SilentlyContinue
                    $m | Add-Member -NotePropertyName "Timestamp" -NotePropertyValue $ts -Force -ErrorAction SilentlyContinue
                    $m | Add-Member -NotePropertyName "FormattedSize" -NotePropertyValue $fmtSz -Force -ErrorAction SilentlyContinue

                    $backups.Add($m)
                } catch { }
            }
        }
    }

    return ($backups | Sort-Object CreatedAt -Descending)
}
