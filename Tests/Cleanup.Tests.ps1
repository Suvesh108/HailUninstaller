# Tests/Cleanup.Tests.ps1

$baseDir = Split-Path $PSScriptRoot -Parent
. (Join-Path $baseDir "Modules\UI.ps1")
. (Join-Path $baseDir "Modules\Evidence.ps1")
. (Join-Path $baseDir "Modules\Backup.ps1")
. (Join-Path $baseDir "Modules\Cleanup.ps1")

Describe "Evidence and Cleanup Tests" {
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

            $scored = Evaluate-CandidateEvidence -Candidates $candidates -Application $mockApp -ConfigDir (Join-Path $baseDir "Config")
            $scored[0].IsProtected | Should Be $true
            $scored[0].Score | Should Be 0
            $scored[0].ConfidenceCategory | Should Be "PROTECTED"
            $scored[0].Selected | Should Be $false
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

            $scored = Evaluate-CandidateEvidence -Candidates $candidates -Application $mockApp -ConfigDir (Join-Path $baseDir "Config")
            $scored[0].Score | Should BeGreaterThan 80
            $scored[0].ConfidenceCategory | Should Be "HIGH"
            $scored[0].Selected | Should Be $true
        }
    }

    Context "Human Approval Guardrails" {
        It "Refuses deletion if called without human approval" {
            { Invoke-CleanupItems -SelectedItems @() } | Should Throw
        }

        It "Allows cleanup execution only when human approval is explicitly confirmed" {
            $res = Invoke-CleanupItems -SelectedItems @() -HumanApproved
            $res.RemovedCount | Should Be 0
        }
    }
}
