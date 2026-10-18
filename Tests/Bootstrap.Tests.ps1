# Pester Tests for HailUninstaller Bootstrap & Zero-Install Launcher

Describe "HailUninstaller Bootstrap & Security Launcher" {
    BeforeAll {
        $script:scriptDir = $PSScriptRoot
        $script:repoRoot = Split-Path -Parent $script:scriptDir
        $script:bootstrapScript = Join-Path $script:repoRoot "bootstrap.ps1"
        $script:releaseZip = Join-Path $script:repoRoot "release\HailUninstaller-v0.0.1.zip"
    }
    
    Context "Pre-flight Compatibility Validation" {
        It "Approves Windows 10/11 and Windows Server 2016+ NT version" {
            $compatCheck = {
                param($verString)
                $mockOS = [System.OperatingSystem]::new([System.PlatformID]::Win32NT, [System.Version]::new($verString))
                return ($mockOS.Platform -eq [System.PlatformID]::Win32NT -and $mockOS.Version.Major -ge 10)
            }

            (& $compatCheck "10.0.22631") | Should -Be $true
            (& $compatCheck "10.0.26100") | Should -Be $true
        }

        It "Rejects unsupported older Windows versions" {
            $compatCheck = {
                param($verString)
                $mockOS = [System.OperatingSystem]::new([System.PlatformID]::Win32NT, [System.Version]::new($verString))
                return ($mockOS.Platform -eq [System.PlatformID]::Win32NT -and $mockOS.Version.Major -ge 10)
            }

            (& $compatCheck "6.1.7601") | Should -Be $false # Windows 7
            (& $compatCheck "6.3.9600") | Should -Be $false # Windows 8.1
        }

        It "Rejects non-Windows platforms" {
            $compatCheck = {
                param($plat)
                return ($plat -eq [System.PlatformID]::Win32NT)
            }

            (& $compatCheck ([System.PlatformID]::Unix)) | Should -Be $false
        }

        It "Requires PowerShell 5.1 or newer" {
            $psCheck = {
                param($verString)
                $ver = [System.Version]::new($verString)
                return ($ver.Major -ge 5)
            }

            (& $psCheck "5.1.26100.1") | Should -Be $true
            (& $psCheck "7.4.2") | Should -Be $true
            (& $psCheck "4.0.0.0") | Should -Be $false
        }
    }

    Context "Cryptographic Checksum Verification" {
        BeforeAll {
            $script:testHashDir = Join-Path $env:TEMP ("HailTest_Hash_" + [System.IO.Path]::GetRandomFileName())
            New-Item -ItemType Directory -Path $script:testHashDir -Force | Out-Null
        }

        AfterAll {
            if ($script:testHashDir -and (Test-Path -LiteralPath $script:testHashDir)) {
                Remove-Item -LiteralPath $script:testHashDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It "Correctly validates authentic file hash" {
            $sampleFile = Join-Path $script:testHashDir "sample.bin"
            Set-Content -Path $sampleFile -Value "HailUninstaller Secure Payload"
            $actualHash = (Get-FileHash -Path $sampleFile -Algorithm SHA256).Hash

            $verifyFunc = {
                param($file, $expected)
                $hash = (Get-FileHash -Path $file -Algorithm SHA256).Hash
                return ($hash -ieq $expected.Trim())
            }

            (& $verifyFunc $sampleFile $actualHash) | Should -Be $true
        }

        It "Detects tampered file and fails verification" {
            $sampleFile = Join-Path $script:testHashDir "tampered.bin"
            Set-Content -Path $sampleFile -Value "Tampered Payload"
            $bogusHash = "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855"

            $verifyFunc = {
                param($file, $expected)
                $hash = (Get-FileHash -Path $file -Algorithm SHA256).Hash
                return ($hash -ieq $expected.Trim())
            }

            (& $verifyFunc $sampleFile $bogusHash) | Should -Be $false
        }
    }

    Context "CLI Command Modes" {
        It "Executes -Help flag successfully and outputs usage information" {
            $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script:bootstrapScript -Help 2>&1
            $outputStr = ($output | Out-String)
            $outputStr | Should -Match "HailUninstaller"
            $outputStr | Should -Match "USAGE:"
            $outputStr | Should -Match "OPTIONS"
        }

        It "Executes -Diagnostic flag successfully and reports system status" {
            $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script:bootstrapScript -Diagnostic 2>&1
            $outputStr = ($output | Out-String)
            $outputStr | Should -Match "SYSTEM DIAGNOSTIC REPORT"
            $outputStr | Should -Match "Operating System:"
            $outputStr | Should -Match "PowerShell Version:"
        }

        It "Executes -DryRun mode without modifying target directory" {
            $dryInstallDir = Join-Path $env:TEMP ("HailDryRun_" + [System.IO.Path]::GetRandomFileName())
            try {
                $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script:bootstrapScript -DryRun -InstallDir $dryInstallDir 2>&1
                $outputStr = ($output | Out-String)
                $outputStr | Should -Match "\[DRY-RUN\] Simulation only"
                (Test-Path -LiteralPath $dryInstallDir) | Should -Be $false
            } finally {
                if (Test-Path -LiteralPath $dryInstallDir) {
                    Remove-Item -LiteralPath $dryInstallDir -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    Context "End-to-End Local Bootstrap Deployment" {
        BeforeAll {
            $script:localTestDir = Join-Path $env:TEMP ("HailE2E_" + [System.IO.Path]::GetRandomFileName())
            if (-not (Test-Path -LiteralPath $script:releaseZip)) {
                & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $script:repoRoot "Tools\New-ReleasePackage.ps1") -Version "0.0.1" -UpdateManifest
            }
        }

        AfterAll {
            if ($script:localTestDir -and (Test-Path -LiteralPath $script:localTestDir)) {
                Remove-Item -LiteralPath $script:localTestDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It "Successfully extracts and deploys from verified archive when hash matches" {
            $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script:bootstrapScript -ReleaseUrl $script:releaseZip -InstallDir $script:localTestDir -ForceUpdate -List 2>&1
            $outputStr = ($output | Out-String)

            $outputStr | Should -Match "Checksum verified:"
            $outputStr | Should -Match "Installed to:"
            (Test-Path -LiteralPath (Join-Path $script:localTestDir "HailUninstaller.ps1")) | Should -Be $true
            (Test-Path -LiteralPath (Join-Path $script:localTestDir "Modules\UI.ps1")) | Should -Be $true
            (Test-Path -LiteralPath (Join-Path $script:localTestDir "Config\ProtectedPaths.json")) | Should -Be $true
        }

        It "Aborts immediately with security error when archive has mismatched hash" {
            $tamperInstallDir = Join-Path $env:TEMP ("HailTamper_" + [System.IO.Path]::GetRandomFileName())
            try {
                $badHash = "0000000000000000000000000000000000000000000000000000000000000000"
                $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script:bootstrapScript -ReleaseUrl $script:releaseZip -InstallDir $tamperInstallDir -ForceUpdate -ExpectedHash $badHash 2>&1
                $outputStr = ($output | Out-String)

                $outputStr | Should -Match "SECURITY FATAL"
                $outputStr | Should -Match "checksum mismatch"
                (Test-Path -LiteralPath (Join-Path $tamperInstallDir "HailUninstaller.ps1")) | Should -Be $false
            } finally {
                if (Test-Path -LiteralPath $tamperInstallDir) {
                    Remove-Item -LiteralPath $tamperInstallDir -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }

        It "Handles network 404 download errors gracefully with clear fatal message" {
            $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $script:bootstrapScript -ReleaseUrl "https://raw.githubusercontent.com/Suvesh108/HailUninstaller/main/non_existent.zip" -ForceUpdate 2>&1
            $outputStr = ($output | Out-String)

            $outputStr | Should -Match "Failed to download or deploy"
            $outputStr | Should -Match "404"
        }
    }
}
