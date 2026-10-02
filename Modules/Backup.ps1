# Modules/Backup.ps1
# Backup creation and manifest generation module

function Get-BackupRootDirectory {
    $dir = Join-Path $env:LOCALAPPDATA "HailUninstaller\Backups"
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    return $dir
}

function New-CleanupBackup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Application,
        [Parameter(Mandatory = $true)]
        [array]$SelectedItems
    )

    $root = Get-BackupRootDirectory
    $safeName = ($Application.DisplayName -replace '[^a-zA-Z0-9_\-]', '_').Trim('_')
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

        if ($item.Category -eq "File" -and (Test-Path -LiteralPath $item.Path)) {
            $fileIndex++
            $destSub = Join-Path $filesDir "item_$fileIndex"
            try {
                if ($item.Type -eq "Directory") {
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
                    $backups.Add($m)
                } catch { }
            }
        }
    }

    return ($backups | Sort-Object CreatedAt -Descending)
}
