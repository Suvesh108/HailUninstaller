# Tests/QuietEngine.Tests.ps1

$baseDir = Split-Path $PSScriptRoot -Parent
. (Join-Path $baseDir "Modules\QuietEngine.ps1")

Describe "Heuristic Quiet Engine Tests" {
    Context "Detect-InstallerType" {
        It "Detects Inno Setup from uninstaller filename" {
            $res = Detect-InstallerType -UninstallString '"C:\Program Files\App\unins000.exe"'
            $res.InstallerType | Should Be "InnoSetup"
            $res.Confidence | Should Be "HIGH"
            $res.QuietSwitches | Should Match "/VERYSILENT"
        }

        It "Detects NSIS from uninstall filename" {
            $res = Detect-InstallerType -UninstallString '"C:\Program Files\VLC\uninstall.exe"'
            $res.InstallerType | Should Be "NSIS"
            $res.Confidence | Should Be "HIGH"
            $res.QuietSwitches | Should Be "/S"
        }

        It "Detects MSI from msiexec command and guid" {
            $res = Detect-InstallerType -UninstallString 'MsiExec.exe /I{12345678-ABCD-1234-ABCD-1234567890AB}'
            $res.InstallerType | Should Be "MSI"
            $res.Confidence | Should Be "HIGH"
            $res.QuietSwitches | Should Match "/qn"
        }

        It "Detects Squirrel from Update.exe" {
            $res = Detect-InstallerType -UninstallString '"C:\Users\User\AppData\Local\Discord\Update.exe" --uninstall -s'
            $res.InstallerType | Should Be "Squirrel"
            $res.Confidence | Should Be "HIGH"
        }
    }

    Context "Build-QuietUninstallCommand" {
        It "Synthesizes quiet command when official quiet string is missing" {
            $mockApp = [PSCustomObject]@{
                DisplayName          = "Test Inno App"
                InstallLocation      = "C:\Program Files\TestApp"
                UninstallString      = '"C:\Program Files\TestApp\unins000.exe"'
                QuietUninstallString = ""
                Id                   = "TestApp"
            }

            $cmd = Build-QuietUninstallCommand -Application $mockApp
            $cmd.Type | Should Be "InnoSetup"
            $cmd.FullCommand | Should Match "/VERYSILENT"
        }
    }
}
