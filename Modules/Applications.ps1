# Modules/Applications.ps1
# Discovery and native uninstaller execution module

function Get-InstalledApplications {
    [CmdletBinding()]
    param(
        [string]$SearchFilter = "",
        [switch]$IncludeAppX = $false
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

            $item = [PSCustomObject]@{
                Id                   = $k.PSChildName
                DisplayName          = $name
                DisplayVersion       = if ($k.DisplayVersion) { "$($k.DisplayVersion)" } else { "Unknown" }
                Publisher            = if ($k.Publisher) { "$($k.Publisher)" } else { "Unknown" }
                InstallLocation      = if ($installLocation) { "$installLocation" } else { "" }
                UninstallString      = if ($k.UninstallString) { "$($k.UninstallString)" } else { "" }
                QuietUninstallString = if ($k.QuietUninstallString) { "$($k.QuietUninstallString)" } else { "" }
                InstallDate          = if ($k.InstallDate) { "$($k.InstallDate)" } else { "" }
                Size                 = $sizeBytes
                Type                 = $appType
                RegistryPath         = $k.PSPath
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
                    Publisher            = $appx.PublisherId
                    InstallLocation      = $appx.InstallLocation
                    UninstallString      = "Remove-AppxPackage -Package $($appx.PackageFullName)"
                    QuietUninstallString = "Remove-AppxPackage -Package $($appx.PackageFullName)"
                    InstallDate          = ""
                    Size                 = 0
                    Type                 = "MSIX"
                    RegistryPath         = ""
                }

                if ([string]::IsNullOrWhiteSpace($SearchFilter) -or 
                    $item.DisplayName -like "*$SearchFilter*" -or 
                    $item.Publisher -like "*$SearchFilter*") {
                    $apps.Add($item)
                }
            }
        } catch {
            # AppX retrieval might fail under limited permissions
        }
    }

    return ($apps | Sort-Object DisplayName)
}

function Invoke-NativeUninstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Application,
        [switch]$Quiet = $false
    )

    $cmd = if ($Quiet -and $Application.QuietUninstallString) { 
        $Application.QuietUninstallString 
    } elseif ($Application.UninstallString) { 
        $Application.UninstallString 
    } else { 
        $null 
    }

    if (-not $cmd) {
        Write-Warning "No uninstall command found for '$($Application.DisplayName)'."
        return $false
    }

    Write-Host "Executing official uninstaller for: $($Application.DisplayName)" -ForegroundColor Cyan
    Write-Host "Command: $cmd" -ForegroundColor Gray

    try {
        if ($Application.Type -eq "MSIX") {
            Invoke-Expression $cmd
            return $true
        }

        # Check for MsiExec
        if ($cmd -match 'msiexec(\.exe)?\s+(\/I|\/X|\/i|\/x)\s*(\{[A-F0-9\-]{36}\})' -or $cmd -match '(\{[A-F0-9\-]{36}\})') {
            $guid = $matches[$matches.Count - 1]
            $args = "/x $guid"
            if ($Quiet) { $args += " /qn" }
            $proc = Start-Process -FilePath "msiexec.exe" -ArgumentList $args -Wait -PassThru
            return ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010)
        }

        # Handle quoted executable command line
        $exe = ""
        $arguments = ""
        if ($cmd -match '^"([^"]+)"\s*(.*)$') {
            $exe = $matches[1]
            $arguments = $matches[2]
        } elseif ($cmd -match '^(\S+)\s*(.*)$') {
            $exe = $matches[1]
            $arguments = $matches[2]
        }

        if (Test-Path $exe) {
            $proc = Start-Process -FilePath $exe -ArgumentList $arguments -Wait -PassThru
            return ($proc.ExitCode -eq 0)
        } else {
            # Fallback to cmd execution
            $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$cmd`"" -Wait -PassThru
            return ($proc.ExitCode -eq 0)
        }
    } catch {
        Write-Error "Failed to launch native uninstaller: $_"
        return $false
    }
}
