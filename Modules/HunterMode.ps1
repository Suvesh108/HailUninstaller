# Modules/HunterMode.ps1
# Hunter Mode and Process Targeter (Reverse-engineered from Revo Uninstaller)
# Enables targeting running windows or active background processes, resolving their file origin, and purging them.

function Get-RunningHunterTargets {
    [CmdletBinding()]
    param(
        [string]$ConfigDir = ""
    )

    if (-not $ConfigDir) {
        $ConfigDir = Join-Path (Split-Path $PSScriptRoot -Parent) "Config"
    }

    if (-not (Get-Command Load-ConfigSafe -ErrorAction SilentlyContinue)) {
        . (Join-Path (Split-Path $PSScriptRoot -Parent) "Modules\UI.ps1")
    }

    $protectedConfig = Load-ConfigSafe -Path (Join-Path $ConfigDir "ProtectedPaths.json")
    $protectedProcs = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    if ($protectedConfig -and $protectedConfig.ProtectedProcesses) {
        foreach ($p in $protectedConfig.ProtectedProcesses) { $protectedProcs.Add($p) | Out-Null }
    }

    $targets = [System.Collections.Generic.List[PSCustomObject]]::new()
    $seenExe = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    $procs = Get-Process -ErrorAction SilentlyContinue | Where-Object { 
        $_.Id -gt 4 -and -not $protectedProcs.Contains($_.ProcessName)
    }

    foreach ($proc in $procs) {
        $exePath = ""
        try {
            $exePath = $proc.MainModule.FileName
        } catch { }

        if (-not $exePath) { continue }
        if ($exePath -like "$env:SystemRoot\System32\*" -or $exePath -like "$env:SystemRoot\SysWOW64\*") { continue }
        if ($seenExe.Contains($exePath)) { continue }
        $seenExe.Add($exePath) | Out-Null

        $company = ""
        $prodName = ""
        try {
            $vi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($exePath)
            $company = $vi.CompanyName
            $prodName = $vi.ProductName
        } catch { }

        $targets.Add([PSCustomObject]@{
            Id              = $proc.Id
            ProcessName     = $proc.ProcessName
            WindowTitle     = if ($proc.MainWindowTitle) { $proc.MainWindowTitle } else { "Background Process" }
            Path            = $exePath
            Directory       = Split-Path $exePath -Parent
            Publisher       = if ($company) { $company } else { "Unknown" }
            ProductName     = if ($prodName) { $prodName } else { $proc.ProcessName }
            MemoryMB        = [math]::Round($proc.WorkingSet64 / 1MB, 1)
            FormattedMemory = "$([math]::Round($proc.WorkingSet64 / 1MB, 1)) MB"
        })
    }

    return ($targets | Sort-Object ProcessName)
}

function Invoke-HunterTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Target,
        [switch]$TerminateProcess = $true,
        [string]$ConfigDir = ""
    )

    if (-not $ConfigDir) {
        $ConfigDir = Join-Path (Split-Path $PSScriptRoot -Parent) "Config"
    }

    $protectedConfig = Load-ConfigSafe -Path (Join-Path $ConfigDir "ProtectedPaths.json")
    if ($protectedConfig -and $protectedConfig.ProtectedProcesses) {
        if ($protectedConfig.ProtectedProcesses -contains $Target.ProcessName) {
            throw "SECURITY_VIOLATION: Cannot target protected system process '$($Target.ProcessName)'."
        }
    }

    if ($TerminateProcess -and $Target.Id) {
        try {
            Stop-Process -Id $Target.Id -Force -ErrorAction SilentlyContinue
        } catch { }
    }

    $targetRoute = if ($Target.Path) { $Target.Path } else { $Target.ProcessName }
    return (Start-ForcedUninstall -Target $targetRoute -ConfigDir $ConfigDir)
}
