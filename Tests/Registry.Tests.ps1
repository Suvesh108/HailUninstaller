# Tests/Registry.Tests.ps1

$baseDir = Split-Path $PSScriptRoot -Parent
. (Join-Path $baseDir "Modules\RegistryScanner.ps1")

Describe "Registry Scanner Tests" {
    Context "Scan-RegistryLeftovers" {
        It "Successfully queries registry without crashing" {
            $results = Scan-RegistryLeftovers -AppName "TestAppDummy123"
            ($results.Count -ge 0) | Should Be $true
        }
    }
}
