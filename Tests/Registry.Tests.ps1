# Tests/Registry.Tests.ps1

Describe "Registry Scanner Tests" {
    BeforeAll {
        $baseDir = Split-Path $PSScriptRoot -Parent
        . (Join-Path $baseDir "Modules\RegistryScanner.ps1")
    }

    Context "Scan-RegistryLeftovers" {
        It "Successfully queries registry without crashing" {
            $results = Scan-RegistryLeftovers -AppName "TestAppDummy123"
            ($results.Count -ge 0) | Should -Be $true
        }

        It "Emits normalized PSDrive paths without provider prefixes" {
            $results = Scan-RegistryLeftovers -AppName "Microsoft"
            foreach ($r in $results) {
                $r.Path | Should -Not -Match '^Microsoft\.PowerShell\.Core\\Registry::'
                $r.Path | Should -Match '^(HKLM|HKCU):\\'
            }
        }
    }
}
