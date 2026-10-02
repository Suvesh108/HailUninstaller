# Modules/RegistryScanner.ps1
# Windows Registry scanner for leftover application keys and entries

function Scan-RegistryLeftovers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppName,
        [string]$Publisher = "",
        [string[]]$KnownRegistryKeys = @()
    )

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    $seenKeys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    # 1. Check known registry keys
    foreach ($k in $KnownRegistryKeys) {
        if ([string]::IsNullOrWhiteSpace($k)) { continue }
        if (Test-Path -LiteralPath $k) {
            $seenKeys.Add($k) | Out-Null
            $results.Add([PSCustomObject]@{
                Category     = "Registry"
                Type         = "Key"
                Path         = $k
                ValueName    = ""
                Size         = 0
                ItemCount    = 1
                MatchReason  = "Configured known registry key"
                MatchedToken = "Rule"
            })
        }
    }

    # 2. Extract tokens for scanning
    $tokens = [System.Collections.Generic.List[string]]::new()
    if ($AppName) {
        $tokens.Add($AppName.Trim())
        $words = $AppName -split '[\s\-_]+' | Where-Object { $_.Length -ge 4 -and $_ -notmatch '^(Microsoft|Windows|Installer|Setup)$' }
        foreach ($w in $words) { $tokens.Add($w) }
    }
    if ($Publisher -and $Publisher -notmatch '^(Microsoft|Corporation|Inc|LLC)$') {
        $pubWords = $Publisher -split '[\s\-_]+' | Where-Object { $_.Length -ge 4 }
        foreach ($pw in $pubWords) { $tokens.Add($pw) }
    }

    # 3. Target registry hives
    $softwareHives = @(
        "HKCU:\Software",
        "HKLM:\SOFTWARE",
        "HKLM:\SOFTWARE\WOW6432Node"
    )

    foreach ($hive in $softwareHives) {
        if (-not (Test-Path -LiteralPath $hive)) { continue }

        try {
            $subkeys = Get-ChildItem -LiteralPath $hive -ErrorAction SilentlyContinue
            foreach ($sub in $subkeys) {
                if ($seenKeys.Contains($sub.PSPath)) { continue }

                foreach ($token in $tokens) {
                    if ($sub.PSChildName -like "*$token*") {
                        $seenKeys.Add($sub.PSPath) | Out-Null
                        $results.Add([PSCustomObject]@{
                            Category     = "Registry"
                            Type         = "Key"
                            Path         = $sub.PSPath
                            ValueName    = ""
                            Size         = 0
                            ItemCount    = 1
                            MatchReason  = "Registry key matches token '$token'"
                            MatchedToken = $token
                        })
                        break
                    }
                }
            }
        } catch {
            # Silently continue on permission errors
        }
    }

    # 4. Check Run / Startup keys
    $startupKeys = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
    )

    foreach ($sKey in $startupKeys) {
        if (-not (Test-Path -LiteralPath $sKey)) { continue }

        try {
            $props = (Get-Item -LiteralPath $sKey -ErrorAction SilentlyContinue).Property
            foreach ($p in $props) {
                $val = (Get-ItemProperty -LiteralPath $sKey -Name $p -ErrorAction SilentlyContinue).$p
                foreach ($token in $tokens) {
                    if ($p -like "*$token*" -or ($val -and "$val" -like "*$token*")) {
                        $results.Add([PSCustomObject]@{
                            Category     = "Registry"
                            Type         = "Value"
                            Path         = $sKey
                            ValueName    = $p
                            Size         = 0
                            ItemCount    = 1
                            MatchReason  = "Startup registry entry matches token '$token'"
                            MatchedToken = $token
                        })
                        break
                    }
                }
            }
        } catch { }
    }

    return $results
}
