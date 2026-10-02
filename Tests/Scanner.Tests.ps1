# Tests/Scanner.Tests.ps1

$baseDir = Split-Path $PSScriptRoot -Parent
. (Join-Path $baseDir "Modules\UI.ps1")
. (Join-Path $baseDir "Modules\FileScanner.ps1")
. (Join-Path $baseDir "Modules\Applications.ps1")

Describe "Scanner Tests" {
    Context "Get-FolderSizeSafe" {
        It "Returns size and count for an existing directory" {
            $tempDir = Join-Path $env:TEMP "HailUninstaller_Test_$(Get-Random)"
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            "test content 12345" | Set-Content (Join-Path $tempDir "sample.txt")

            $res = Get-FolderSizeSafe -Path $tempDir
            $res.Count | Should Be 1
            $res.Size | Should BeGreaterThan 0

            Remove-Item -LiteralPath $tempDir -Recurse -Force
        }

        It "Returns zero for non-existent path without error" {
            $nonExistent = "C:\NonExistentPath_HailUninstaller_99999"
            $res = Get-FolderSizeSafe -Path $nonExistent
            $res.Count | Should Be 0
            $res.Size | Should Be 0
        }
    }

    Context "Applications Enumeration" {
        It "Discovers installed system applications" {
            $apps = Get-InstalledApplications
            $apps | Should Not BeNullOrEmpty
            $apps.Count | Should BeGreaterThan 0
        }
    }
}
