# Modules/ServiceScanner.ps1
# Windows Services scanner for leftover application services

function Scan-ServiceLeftovers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppName,
        [string]$Publisher = "",
        [string[]]$KnownServices = @()
    )

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    $seenServices = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    # 1. Known services
    foreach ($ks in $KnownServices) {
        if ([string]::IsNullOrWhiteSpace($ks)) { continue }
        try {
            $svc = Get-CimInstance Win32_Service -Filter "Name='$ks'" -ErrorAction SilentlyContinue
            if ($svc) {
                $seenServices.Add($svc.Name) | Out-Null
                $results.Add([PSCustomObject]@{
                    Category     = "Service"
                    Type         = "Service"
                    Path         = $svc.PathName
                    Name         = $svc.Name
                    DisplayName  = $svc.DisplayName
                    State        = $svc.State
                    Size         = 0
                    ItemCount    = 1
                    MatchReason  = "Configured known service"
                    MatchedToken = "Rule"
                })
            }
        } catch { }
    }

    # 2. Token search across all services
    $tokens = [System.Collections.Generic.List[string]]::new()
    if ($AppName) {
        $tokens.Add($AppName.Trim())
        $words = $AppName -split '[\s\-_]+' | Where-Object { $_.Length -ge 4 -and $_ -notmatch '^(Microsoft|Windows|System|Host|Service)$' }
        foreach ($w in $words) { $tokens.Add($w) }
    }

    try {
        $allServices = Get-CimInstance Win32_Service -ErrorAction SilentlyContinue
        foreach ($svc in $allServices) {
            if ($seenServices.Contains($svc.Name)) { continue }

            foreach ($token in $tokens) {
                if ($svc.Name -like "*$token*" -or 
                    $svc.DisplayName -like "*$token*" -or 
                    ($svc.PathName -and $svc.PathName -like "*$token*")) {
                    $seenServices.Add($svc.Name) | Out-Null
                    $results.Add([PSCustomObject]@{
                        Category     = "Service"
                        Type         = "Service"
                        Path         = $svc.PathName
                        Name         = $svc.Name
                        DisplayName  = $svc.DisplayName
                        State        = $svc.State
                        Size         = 0
                        ItemCount    = 1
                        MatchReason  = "Service matches token '$token'"
                        MatchedToken = $token
                    })
                    break
                }
            }
        }
    } catch { }

    return $results
}
