# Tests/Cleanup.Tests.ps1

Describe "Evidence and Cleanup Tests" {
    BeforeAll {
        $script:baseDir = Split-Path $PSScriptRoot -Parent
        . (Join-Path $script:baseDir "Modules\UI.ps1")
        . (Join-Path $script:baseDir "Modules\Evidence.ps1")
        . (Join-Path $script:baseDir "Modules\Backup.ps1")
        . (Join-Path $script:baseDir "Modules\Cleanup.ps1")
    }

    Context "Evidence Scoring and Protection Guardrails" {
        It "Strictly protects Windows system paths from deletion" {
            $candidates = @(
                [PSCustomObject]@{
                    Category    = "File"
                    Type        = "Directory"
                    Path        = "C:\Windows\System32"
                    Name        = "System32"
                    MatchReason = "Token match"
                }
            )

            $mockApp = [PSCustomObject]@{
                DisplayName     = "System32"
                Publisher       = "Microsoft"
                InstallLocation = ""
            }

            $scored = Evaluate-CandidateEvidence -Candidates $candidates -Application $mockApp -ConfigDir (Join-Path $script:baseDir "Config")
            $scored[0].IsProtected | Should -Be $true
            $scored[0].Score | Should -Be 0
            $scored[0].ConfidenceCategory | Should -Be "PROTECTED"
            $scored[0].Selected | Should -Be $false
        }

        It "Scores exact application name and known rules with High Confidence" {
            $candidates = @(
                [PSCustomObject]@{
                    Category    = "File"
                    Type        = "Directory"
                    Path        = "$env:LOCALAPPDATA\Discord"
                    Name        = "Discord"
                    MatchReason = "Configured known application directory"
                }
            )

            $mockApp = [PSCustomObject]@{
                DisplayName     = "Discord"
                Publisher       = "Discord Inc."
                InstallLocation = "$env:LOCALAPPDATA\Discord"
            }

            $scored = Evaluate-CandidateEvidence -Candidates $candidates -Application $mockApp -ConfigDir (Join-Path $script:baseDir "Config")
            $scored[0].Score | Should -BeGreaterThan 80
            $scored[0].ConfidenceCategory | Should -Be "HIGH"
            $scored[0].Selected | Should -Be $true
        }
    }

    Context "Human Approval Guardrails" {
        It "Refuses deletion if called without human approval" {
            { Invoke-CleanupItems -SelectedItems @() } | Should -Throw
        }

        It "Allows cleanup execution only when human approval is explicitly confirmed" {
            $res = Invoke-CleanupItems -SelectedItems @() -HumanApproved
            $res.RemovedCount | Should -Be 0
        }

        It "Successfully deletes directories containing ReadOnly child files" {
            $testFolder = Join-Path $env:TEMP "HailUninstaller_ReadOnlyTest_$(Get-Random)"
            New-Item -ItemType Directory -Path $testFolder -Force | Out-Null
            $subFile = Join-Path $testFolder "readonly_child.txt"
            Set-Content -Path $subFile -Value "Locked content"
            Set-ItemProperty -Path $subFile -Name IsReadOnly -Value $true

            $mockItem = [PSCustomObject]@{
                Category    = "File"
                Type        = "Directory"
                Path        = $testFolder
                Name        = (Split-Path $testFolder -Leaf)
                Size        = 20
                IsProtected = $false
                Selected    = $true
            }

            try {
                $res = Invoke-CleanupItems -SelectedItems @($mockItem) -HumanApproved
                $res.RemovedCount | Should -Be 1
                (Test-Path -LiteralPath $testFolder) | Should -Be $false
            } finally {
                if (Test-Path -LiteralPath $testFolder) {
                    Get-ChildItem -LiteralPath $testFolder -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object { $_.IsReadOnly = $false }
                    Remove-Item -LiteralPath $testFolder -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }

        It "Filters out evidence with score below 20 to eliminate noise" {
            $candidates = @(
                [PSCustomObject]@{
                    Category    = "File"
                    Type        = "Directory"
                    Path        = "C:\SomeRandomFolder"
                    Name        = "UnrelatedFolder"
                    MatchReason = "Loose substring"
                }
            )

            $mockApp = [PSCustomObject]@{
                DisplayName     = "SpecificProductXYZ"
                Publisher       = "SpecificPublisherABC"
                InstallLocation = "C:\SpecificProductXYZ"
            }

            $scored = Evaluate-CandidateEvidence -Candidates $candidates -Application $mockApp -ConfigDir (Join-Path $script:baseDir "Config")
            $scored.Count | Should -Be 0
        }
    }
}
