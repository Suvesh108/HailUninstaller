# Tests/ForcedUninstall.Tests.ps1

$baseDir = Split-Path $PSScriptRoot -Parent
. (Join-Path $baseDir "Modules\UI.ps1")
. (Join-Path $baseDir "Modules\Evidence.ps1")
. (Join-Path $baseDir "Modules\FileScanner.ps1")
. (Join-Path $baseDir "Modules\RegistryScanner.ps1")
. (Join-Path $baseDir "Modules\ServiceScanner.ps1")
. (Join-Path $baseDir "Modules\TaskScanner.ps1")
. (Join-Path $baseDir "Modules\ShortcutScanner.ps1")
. (Join-Path $baseDir "Modules\Backup.ps1")
. (Join-Path $baseDir "Modules\Restore.ps1")
. (Join-Path $baseDir "Modules\ForcedUninstall.ps1")

Describe "Forced Uninstall and Backup/Restore Tests" {
    Context "Start-ForcedUninstall" {
        It "Generates scored candidates for a mock target path" {
            $tempDir = Join-Path $env:TEMP "HailUninstaller_TestTarget_$(Get-Random)"
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            $subFile = Join-Path $tempDir "dummy.txt"
            Set-Content -Path $subFile -Value "Dummy data"

            try {
                $res = Start-ForcedUninstall -Target $tempDir
                $candidatesList = @($res.Candidates)
                $candidatesList.Count | Should BeGreaterThan 0
                $primary = $candidatesList | Where-Object { $_.Path -eq $tempDir }
                $primary | Should Not BeNullOrEmpty
            } finally {
                Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It "Preserves generic parent directory and targets only the file for standalone executables" {
            $standaloneExe = Join-Path $env:TEMP "standalone_tool_$(Get-Random).exe"
            Set-Content -Path $standaloneExe -Value "MZ_TEST"

            try {
                $res = Start-ForcedUninstall -Target $standaloneExe
                $res.TargetPath | Should Be $standaloneExe
                # Verify $env:TEMP is not targeted as a directory candidate
                $candidatesList = @($res.Candidates)
                $tempCand = $candidatesList | Where-Object { $_.Path -eq $env:TEMP }
                $tempCand | Should BeNullOrEmpty
            } finally {
                Remove-Item -LiteralPath $standaloneExe -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context "Directory Backup and Restore" {
        It "Successfully creates and restores a directory backup" {
            $testFolder = Join-Path $env:TEMP "HailUninstaller_BackupRestore_$(Get-Random)"
            New-Item -ItemType Directory -Path $testFolder -Force | Out-Null
            Set-Content -Path (Join-Path $testFolder "file1.txt") -Value "Hello Backup"

            $mockItem = [PSCustomObject]@{
                Category    = "File"
                Type        = "Directory"
                Path        = $testFolder
                Name        = (Split-Path $testFolder -Leaf)
                Size        = 12
                IsProtected = $false
                Selected    = $true
            }

            $mockApp = [PSCustomObject]@{
                DisplayName     = "UnitTestApp"
                Publisher       = "TestPub"
                InstallLocation = $testFolder
            }

            $backup = New-CleanupBackup -Application $mockApp -SelectedItems @($mockItem)
            $backup.Success | Should Be $true
            $backup.BackupId | Should Not BeNullOrEmpty

            # Verify Get-CleanupBackups populates UI properties
            $allB = @(Get-CleanupBackups)
            $foundB = $allB | Where-Object { $_.BackupId -eq $backup.BackupId }
            $foundB | Should Not BeNullOrEmpty
            $foundB.Application | Should Be "UnitTestApp"
            $foundB.Timestamp | Should Not BeNullOrEmpty
            $foundB.FormattedSize | Should Not BeNullOrEmpty

            # Simulate deletion
            Remove-Item -Path $testFolder -Recurse -Force

            (Test-Path -LiteralPath $testFolder) | Should Be $false

            # Restore
            $rRes = Restore-CleanupBackup -BackupId $backup.BackupId
            $rRes.RestoredCount | Should BeGreaterThan 0

            # Verify restoration
            (Test-Path -LiteralPath (Join-Path $testFolder "file1.txt")) | Should Be $true

            # Cleanup
            Remove-Item -Path $testFolder -Recurse -Force -ErrorAction SilentlyContinue
            $backupDir = Join-Path (Get-BackupRootDirectory) $backup.BackupId
            Remove-Item -Path $backupDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
