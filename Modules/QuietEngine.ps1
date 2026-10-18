# Modules/QuietEngine.ps1
# Heuristic Quiet Uninstaller Engine (Reverse-engineered from Bulk Crap Uninstaller)
# Detects installer technology frameworks and automatically synthesizes unattended/silent uninstallation switches.

function Detect-InstallerType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$UninstallString,
        [string]$InstallLocation = ""
    )

    $raw = $UninstallString.Trim()

    # 1. Windows Installer / MSI detection
    if ($raw -match '(?<guid>\{[A-F0-9]{8}\-[A-F0-9]{4}\-[A-F0-9]{4}\-[A-F0-9]{4}\-[A-F0-9]{12}\})') {
        $guid = $matches['guid']
        return [PSCustomObject]@{
            InstallerType   = "MSI"
            QuietSwitches   = "/qn /norestart"
            RecommendedArgs = "/x $guid /qn /norestart"
            Confidence      = "HIGH"
            Description     = "Windows Installer (MSI package)"
        }
    } elseif ($raw -match 'msiexec(\.exe)?') {
        return [PSCustomObject]@{
            InstallerType   = "MSI"
            QuietSwitches   = "/qn /norestart"
            RecommendedArgs = "$raw /qn /norestart"
            Confidence      = "HIGH"
            Description     = "Windows Installer (MSI package)"
        }
    }

    # Extract executable path (handles both quoted and unquoted paths with spaces)
    $exePath = ""
    if ($raw -match '^"([^"]+)"') {
        $exePath = $matches[1]
    } elseif ($raw -match '^(.*?\.(?:exe|bat|cmd))\b') {
        $exePath = $matches[1]
    } else {
        $exePath = ($raw -split '\s+')[0]
    }

    $exeName = Split-Path $exePath -Leaf

    # 2. Inno Setup detection (unins000.exe, unins001.exe, or Inno signature)
    if ($exeName -match '^unins[0-9]{3,}\.exe$' -or $raw -like "*unins000*") {
        return [PSCustomObject]@{
            InstallerType   = "InnoSetup"
            QuietSwitches   = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-"
            RecommendedArgs = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-"
            Confidence      = "HIGH"
            Description     = "Inno Setup Uninstaller"
        }
    }

    # 3. NSIS (Nullsoft Scriptable Install System)
    if ($exeName -match '^uninstall\.exe$' -or $exeName -match '^uninst\.exe$' -or $raw -match '[\/\-]nsis') {
        $nsisArgs = if (-not [string]::IsNullOrWhiteSpace($InstallLocation)) { "/S _?=$InstallLocation" } else { "/S" }
        return [PSCustomObject]@{
            InstallerType   = "NSIS"
            QuietSwitches   = $nsisArgs
            RecommendedArgs = $nsisArgs
            Confidence      = "HIGH"
            Description     = "Nullsoft Scriptable Install System (NSIS)"
        }
    }

    # 4. InstallShield detection
    if ($exeName -match '^(_isuninst|setup)\.exe$' -or $raw -match 'InstallShield' -or $raw -match '\-removeonly') {
        return [PSCustomObject]@{
            InstallerType   = "InstallShield"
            QuietSwitches   = "/s /v`"/qn`""
            RecommendedArgs = "/s /v`"/qn`""
            Confidence      = "MEDIUM"
            Description     = "InstallShield Uninstaller"
        }
    }

    # 5. WiX Burn Bootstrapper
    if ($raw -match 'bundle\.exe' -or $raw -match '[\/\-]burn\.embedded') {
        return [PSCustomObject]@{
            InstallerType   = "WiX"
            QuietSwitches   = "/quiet /norestart"
            RecommendedArgs = "/uninstall /quiet /norestart"
            Confidence      = "HIGH"
            Description     = "WiX Burn Bootstrapper"
        }
    }

    # 6. Squirrel / Electron (Discord, Slack, Postman, Teams)
    if ($raw -match 'Update\.exe' -and $raw -match '\-\-uninstall') {
        return [PSCustomObject]@{
            InstallerType   = "Squirrel"
            QuietSwitches   = "-s"
            RecommendedArgs = "--uninstall -s"
            Confidence      = "HIGH"
            Description     = "Squirrel / Modern App Bootstrapper"
        }
    }

    # 7. Wise Installation Wizard
    if ($exeName -match '^unwise(32)?\.exe$') {
        return [PSCustomObject]@{
            InstallerType   = "Wise"
            QuietSwitches   = "/s"
            RecommendedArgs = "/s"
            Confidence      = "HIGH"
            Description     = "Wise Installation System"
        }
    }

    # Default heuristic: fallback standard switches
    return [PSCustomObject]@{
        InstallerType   = "Generic"
        QuietSwitches   = "/quiet /qn /s /silent"
        RecommendedArgs = "/quiet"
        Confidence      = "LOW"
        Description     = "Generic Windows Executable"
    }
}

function Build-QuietUninstallCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Application
    )

    # 1. If application already defines an official QuietUninstallString, prioritize it
    if ($Application.QuietUninstallString) {
        return [PSCustomObject]@{
            Executable = ""
            Arguments  = ""
            FullCommand = $Application.QuietUninstallString
            Type       = "OfficialQuiet"
        }
    }

    $raw = $Application.UninstallString
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $null
    }

    # 2. If MSI package
    if ($raw -match '(?<guid>\{[A-F0-9\-]{36}\})') {
        $guid = $matches['guid']
        return [PSCustomObject]@{
            Executable  = "msiexec.exe"
            Arguments   = "/x $guid /qn /norestart"
            FullCommand = "msiexec.exe /x $guid /qn /norestart"
            Type        = "MSI"
        }
    } elseif ($raw -match 'msiexec') {
        $targetId = if ($Application.Id) { $Application.Id } else { "" }
        $argsStr = if ($targetId) { "/x $targetId /qn /norestart" } else { "$raw /qn /norestart" }
        return [PSCustomObject]@{
            Executable  = "msiexec.exe"
            Arguments   = $argsStr
            FullCommand = "msiexec.exe $argsStr"
            Type        = "MSI"
        }
    }

    # 3. Detect installer technology and synthesize switches
    $detected = Detect-InstallerType -UninstallString $raw -InstallLocation $Application.InstallLocation
    
    # Split raw command line into executable and arguments
    $exe = ""
    $existingArgs = ""
    if ($raw -match '^"([^"]+)"\s*(.*)$') {
        $exe = $matches[1]
        $existingArgs = $matches[2]
    } elseif ($raw -match '^(.*?\.(?:exe|bat|cmd))\b\s*(.*)$') {
        $exe = $matches[1]
        $existingArgs = $matches[2]
    } else {
        $exe = $raw
    }

    $combinedArgs = if ($existingArgs) { "$existingArgs $($detected.QuietSwitches)" } else { $detected.QuietSwitches }

    return [PSCustomObject]@{
        Executable  = $exe
        Arguments   = $combinedArgs.Trim()
        FullCommand = "`"$exe`" $($combinedArgs.Trim())"
        Type        = $detected.InstallerType
    }
}
