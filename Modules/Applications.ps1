# Modules/Applications.ps1
# Discovery and native uninstaller execution module

function Get-InstalledApplications {
    [CmdletBinding()]
    param(
        [string]$SearchFilter = "",
        [switch]$IncludeAppX = $true
    )

    $apps = [System.Collections.Generic.List[PSCustomObject]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $registryPaths) {
        if (-not (Test-Path (Split-Path $path))) { continue }
        
        $keys = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
        foreach ($k in $keys) {
            $name = $k.DisplayName
            if ([string]::IsNullOrWhiteSpace($name)) { continue }
            if ($k.SystemComponent -eq 1) { continue }
            if ($k.ParentKeyName) { continue }

            $uniqueKey = "$name|$($k.DisplayVersion)"
            if ($seen.Contains($uniqueKey)) { continue }
            $seen.Add($uniqueKey) | Out-Null

            $installLocation = $k.InstallLocation
            if (-not $installLocation -and $k.UninstallString) {
                $raw = $k.UninstallString
                if ($raw -match '["'']([^"'']+\.exe)["'']') {
                    $installLocation = Split-Path $matches[1] -ErrorAction SilentlyContinue
                }
            }

            $sizeBytes = 0
            if ($k.EstimatedSize) {
                $sizeBytes = [long]$k.EstimatedSize * 1024
            }

            $appType = "Registry"
            if ($k.PSChildName -match '^\{[A-F0-9\-]{36}\}$') {
                $appType = "MSI"
            }

            $quietString = if ($k.QuietUninstallString) { "$($k.QuietUninstallString)" } else { "" }
            
            # If no quiet string, attempt heuristic synthesis via QuietEngine
            if (-not $quietString -and $k.UninstallString -and (Get-Command Build-QuietUninstallCommand -ErrorAction SilentlyContinue)) {
                $tempApp = [PSCustomObject]@{
                    DisplayName          = $name
                    InstallLocation      = $installLocation
                    UninstallString      = "$($k.UninstallString)"
                    QuietUninstallString = ""
                    Id                   = $k.PSChildName
                }
                $synth = Build-QuietUninstallCommand -Application $tempApp
                if ($synth -and $synth.FullCommand) {
                    $quietString = $synth.FullCommand
                }
            }

            $item = [PSCustomObject]@{
                Id                   = $k.PSChildName
                DisplayName          = $name
                DisplayVersion       = if ($k.DisplayVersion) { "$($k.DisplayVersion)" } else { "Unknown" }
                Publisher            = if ($k.Publisher) { "$($k.Publisher)" } else { "Unknown" }
                InstallLocation      = if ($installLocation) { "$installLocation" } else { "" }
                UninstallString      = if ($k.UninstallString) { "$($k.UninstallString)" } else { "" }
                QuietUninstallString = $quietString
                InstallDate          = if ($k.InstallDate) { "$($k.InstallDate)" } else { "" }
                Size                 = $sizeBytes
                Type                 = $appType
                RegistryPath         = $k.PSPath
                Selected             = $false
            }

            if ([string]::IsNullOrWhiteSpace($SearchFilter) -or 
                $item.DisplayName -like "*$SearchFilter*" -or 
                $item.Publisher -like "*$SearchFilter*") {
                $apps.Add($item)
            }
        }
    }

    if ($IncludeAppX) {
        try {
            $appxList = Get-AppxPackage -ErrorAction SilentlyContinue
            foreach ($appx in $appxList) {
                if ($appx.NonRemovable -or $appx.IsFramework) { continue }
                $appxName = if ($appx.Name) { $appx.Name } else { $appx.PackageFullName }
                if ($seen.Contains($appxName)) { continue }
                $seen.Add($appxName) | Out-Null

                $item = [PSCustomObject]@{
                    Id                   = $appx.PackageFullName
                    DisplayName          = $appx.Name
                    DisplayVersion       = $appx.Version
                    Publisher            = if ($appx.PublisherId) { $appx.PublisherId } else { "Microsoft Store" }
                    InstallLocation      = $appx.InstallLocation
                    UninstallString      = "Remove-AppxPackage -Package $($appx.PackageFullName)"
                    QuietUninstallString = "Remove-AppxPackage -Package $($appx.PackageFullName)"
                    InstallDate          = ""
                    Size                 = 0
                    Type                 = "MSIX"
                    RegistryPath         = ""
                    Selected             = $false
                }

                if ([string]::IsNullOrWhiteSpace($SearchFilter) -or 
                    $item.DisplayName -like "*$SearchFilter*" -or 
                    $item.Publisher -like "*$SearchFilter*") {
                    $apps.Add($item)
                }
            }
        } catch { }
    }

    return ($apps | Sort-Object DisplayName)
}

function Invoke-NativeUninstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Application,
        [switch]$Quiet = $false,
        [switch]$DeprovisionStoreApp = $true
    )

    $cmd = ""
    if ($Quiet) {
        if ($Application.QuietUninstallString) {
            $cmd = $Application.QuietUninstallString
        } elseif (Get-Command Build-QuietUninstallCommand -ErrorAction SilentlyContinue) {
            $synth = Build-QuietUninstallCommand -Application $Application
            if ($synth) { $cmd = $synth.FullCommand }
        }
    }

    if (-not $cmd) {
        $cmd = $Application.UninstallString
    }

    if (-not $cmd) {
        Write-Warning "No uninstall command found for '$($Application.DisplayName)'."
        return $false
    }

    Write-Host "Executing uninstaller for: $($Application.DisplayName)" -ForegroundColor Cyan
    Write-Host "Command: $cmd" -ForegroundColor Gray

    try {
        if ($Application.Type -eq "MSIX") {
            # User level removal
            Remove-AppxPackage -Package $Application.Id -ErrorAction Stop
            
            # System wide deprovisioning if requested
            if ($DeprovisionStoreApp) {
                try {
                    Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -ieq $Application.DisplayName -or $_.PackageName -ieq $Application.Id } |
                        ForEach-Object { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue }
                } catch { }
            }
            return $true
        }

        # Check for MsiExec
        if ($cmd -match 'msiexec(\.exe)?\s+(\/I|\/X|\/i|\/x)\s*(\{[A-F0-9\-]{36}\})' -or $cmd -match '(\{[A-F0-9\-]{36}\})') {
            $guid = $matches[$matches.Count - 1]
            $args = "/x $guid"
            if ($Quiet) { $args += " /qn /norestart" }
            $proc = Start-Process -FilePath "msiexec.exe" -ArgumentList $args -Wait -PassThru
            return ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010)
        }

        # Handle quoted executable command line
        $exe = ""
        $arguments = ""
        if ($cmd -match '^"([^"]+)"\s*(.*)$') {
            $exe = $matches[1]
            $arguments = $matches[2]
        } elseif ($cmd -match '^(\S+\.exe)\s*(.*)$') {
            $exe = $matches[1]
            $arguments = $matches[2]
        } else {
            $exe = $cmd
        }

        if (Test-Path -LiteralPath $exe) {
            $proc = Start-Process -FilePath $exe -ArgumentList $arguments -Wait -PassThru
            return ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010)
        } else {
            # Fallback to cmd execution
            $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$cmd`"" -Wait -PassThru
            return ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010)
        }
    } catch {
        Write-Error "Failed to launch native uninstaller: $_"
        return $false
    }
}
