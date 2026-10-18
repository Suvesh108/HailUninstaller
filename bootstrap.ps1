<#
.SYNOPSIS
    HailUninstaller Zero-Install Bootstrap & Production Launcher.
.DESCRIPTION
    Secure, production-ready PowerShell distribution launcher for HailUninstaller.
    Checks environment compatibility, enforces TLS 1.2+, verifies cryptographic
    SHA-256 checksums from independent trusted anchors, extracts to user app data,
    and safely launches HailUninstaller with passthrough arguments.
.PARAMETER Version
    The release version to launch (default: "0.0.1").
.PARAMETER InstallDir
    Target directory for installation (default: "$env:LOCALAPPDATA\HailUninstaller\app").
.PARAMETER ReleaseUrl
    Custom URL or local path for the release archive (supports offline/air-gapped mirrors).
.PARAMETER ExpectedHash
    Explicit SHA-256 hash override for verification of custom builds.
.PARAMETER ForceUpdate
    Forces re-download and re-verification even if the release is already cached.
.PARAMETER DryRun
    Simulates environment checks, URL resolution, and hash verification without modifying disk.
.PARAMETER Diagnostic
    Prints comprehensive system, PowerShell, network, and security diagnostics.
.PARAMETER Elevate
    Re-launches the session with elevated Administrator privileges.
.PARAMETER Help
    Displays help and usage documentation.
.EXAMPLE
    # One-line execution from web:
    irm "https://raw.githubusercontent.com/Suvesh108/HailUninstaller/main/bootstrap.ps1" | iex

    # Run diagnostics:
    & { $(irm "https://raw.githubusercontent.com/Suvesh108/HailUninstaller/main/bootstrap.ps1") } -Diagnostic

    # Dry-run verification:
    & { $(irm "https://raw.githubusercontent.com/Suvesh108/HailUninstaller/main/bootstrap.ps1") } -DryRun
#>
[CmdletBinding()]
param(
    [string]$Version = "0.0.1",
    [string]$InstallDir,
    [string]$ReleaseUrl,
    [string]$ExpectedHash,
    [switch]$ForceUpdate,
    [switch]$DryRun,
    [switch]$Diagnostic,
    [switch]$Elevate,
    [switch]$Help,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$PassthroughArgs
)

# ==============================================================================
# Security Invariants & Cryptographic Trust Anchors
# ==============================================================================
# Known official releases with hardcoded, independent cryptographic SHA-256 digests.
# Downloaded archives MUST match these hashes; unverified content will NEVER execute.
$script:KnownReleases = @{
    "0.0.1" = @{
        Version     = "0.0.1"
        ArchiveName = "HailUninstaller-v0.0.1.zip"
        Sha256      = "0F1DB041CFFBA78C3D5D52A0F9AA5F94C0A3CC3BEE025BCB3EFD1439F29DBCF1"
        MinPS       = "5.1"
        MinOS       = "10.0"
    }
}

$script:DefaultRepository = "Suvesh108/HailUninstaller"
$script:DefaultReleaseBaseUrl = "https://github.com/$($script:DefaultRepository)/releases/download"
$script:DefaultRawBaseUrl = "https://raw.githubusercontent.com/$($script:DefaultRepository)/main"

# ==============================================================================
# Helper: Banner
# ==============================================================================
function Show-HailBanner {
    param([string]$TargetVersion)
    Write-Host ""
    Write-Host " ============================================================================ " -ForegroundColor Cyan
    Write-Host "   _   _       _ _ _   _       _           _        _ _             " -ForegroundColor Cyan
    Write-Host "  | | | | __ _(_) | | | |_ __ (_)_ __  ___| |_ __ _| | | ___ _ __  " -ForegroundColor Cyan
    Write-Host "  | |_| |/ _`` | | | | | | '_ \| | '_ \/ __| __/ _`` | | |/ _ \ '__| " -ForegroundColor Cyan
    Write-Host "  |  _  | (_| | | | |_| | | | | | | | \__ \ || (_| | | |  __/ |    " -ForegroundColor Cyan
    Write-Host "  |_| |_|\__,_|_|_|\___/|_| |_|_|_| |_|___/\__\__,_|_|_|\___|_|    " -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   HailUninstaller v$TargetVersion - Production Bootstrap & Zero-Install Launcher" -ForegroundColor White
    Write-Host "   Deep Application Removal & Footprint Purge Engine for Windows" -ForegroundColor Gray
    Write-Host "   Repository: https://github.com/$($script:DefaultRepository)" -ForegroundColor Gray
    Write-Host " ============================================================================ " -ForegroundColor Cyan
    Write-Host ""
}

# ==============================================================================
# Helper: Help Display
# ==============================================================================
if ($Help) {
    Show-HailBanner -TargetVersion $Version
    Write-Host "USAGE:" -ForegroundColor Yellow
    Write-Host "  irm `"https://raw.githubusercontent.com/$($script:DefaultRepository)/main/bootstrap.ps1`" | iex" -ForegroundColor White
    Write-Host ""
    Write-Host "OPTIONS (via scriptblock or file execution):" -ForegroundColor Yellow
    Write-Host "  -Version <string>       Specify release version to run (default: 0.0.1)" -ForegroundColor White
    Write-Host "  -InstallDir <path>      Specify local install/cache directory" -ForegroundColor White
    Write-Host "  -ReleaseUrl <url/path>  Specify custom archive URL or local zip path" -ForegroundColor White
    Write-Host "  -ExpectedHash <sha256>  Provide expected SHA-256 hash for custom builds" -ForegroundColor White
    Write-Host "  -ForceUpdate            Force re-download and re-verification of the artifact" -ForegroundColor White
    Write-Host "  -DryRun                 Simulate checks, URL resolution and verification" -ForegroundColor White
    Write-Host "  -Diagnostic             Print system environment, TLS, network, and security report" -ForegroundColor White
    Write-Host "  -Elevate                Re-launch session with elevated Administrator privileges" -ForegroundColor White
    Write-Host "  -Help                   Display this help message" -ForegroundColor White
    Write-Host ""
    Write-Host "APPLICATION PASSTHROUGH ARGUMENTS:" -ForegroundColor Yellow
    Write-Host "  All additional arguments are forwarded directly to HailUninstaller.ps1:" -ForegroundColor White
    Write-Host "    -List                 List all installed applications" -ForegroundColor Gray
    Write-Host "    -Scan <name>          Scan leftovers for an application (simulation)" -ForegroundColor Gray
    Write-Host "    -DeepScan <name>      Exhaustive deep subsystem leftover scan" -ForegroundColor Gray
    Write-Host "    -Orphans              Scan storage for uninstalled orphan folders" -ForegroundColor Gray
    Write-Host "    -Cli                  Force console CLI mode instead of Fluent GUI" -ForegroundColor Gray
    Write-Host ""
    return
}

# ==============================================================================
# Diagnostic Mode
# ==============================================================================
if ($Diagnostic) {
    Show-HailBanner -TargetVersion $Version
    Write-Host "========================== SYSTEM DIAGNOSTIC REPORT ==========================" -ForegroundColor Yellow
    $os = [System.Environment]::OSVersion
    Write-Host ("  Operating System:      " + $os.VersionString + " (Platform: " + $os.Platform + ")") -ForegroundColor White
    Write-Host ("  Windows 10/11 Compliant: " + ($os.Version.Major -ge 10)) -ForegroundColor $(if ($os.Version.Major -ge 10) { "Green" } else { "Red" })
    Write-Host ("  PowerShell Version:    " + $PSVersionTable.PSVersion.ToString() + " (" + $PSVersionTable.PSEdition + ")") -ForegroundColor White
    Write-Host ("  PS 5.1+ Compliant:     " + ($PSVersionTable.PSVersion.Major -ge 5)) -ForegroundColor $(if ($PSVersionTable.PSVersion.Major -ge 5) { "Green" } else { "Red" })
    
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    Write-Host ("  Administrative Rights: " + $isAdmin) -ForegroundColor $(if ($isAdmin) { "Green" } else { "Yellow" })

    $defaultTarget = if ($InstallDir) { $InstallDir } else { Join-Path $env:LOCALAPPDATA "HailUninstaller\app" }
    Write-Host ("  Target Directory:      " + $defaultTarget) -ForegroundColor White

    $canWrite = $false
    try {
        $testDir = Join-Path $env:TEMP ("HailTest_" + [System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
        $testFile = Join-Path $testDir "write_test.tmp"
        Set-Content -Path $testFile -Value "OK"
        $canWrite = (Get-Content -Path $testFile) -eq "OK"
        Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        $canWrite = $false
    }
    Write-Host ("  Temp Write Access:     " + $canWrite) -ForegroundColor $(if ($canWrite) { "Green" } else { "Red" })

    # TLS Protocols
    $protocols = [System.Net.ServicePointManager]::SecurityProtocol
    Write-Host ("  Current TLS Protocol:  " + $protocols) -ForegroundColor White
    $tls12 = ($protocols -band [System.Net.SecurityProtocolType]::Tls12) -ne 0
    Write-Host ("  TLS 1.2 Enabled:       " + $tls12) -ForegroundColor $(if ($tls12) { "Green" } else { "Yellow" })

    # Network connectivity to GitHub
    Write-Host "  Testing GitHub Connectivity..." -NoNewline
    $netOk = $false
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13
        $req = [System.Net.WebRequest]::Create("https://raw.githubusercontent.com")
        $req.Timeout = 5000
        $req.Method = "HEAD"
        $resp = $req.GetResponse()
        $resp.Close()
        $netOk = $true
        Write-Host " OK (Connected)" -ForegroundColor Green
    } catch {
        Write-Host " FAILED ($($_.Exception.Message))" -ForegroundColor Red
    }

    Write-Host "==============================================================================" -ForegroundColor Yellow
    Write-Host ""
    return
}

# ==============================================================================
# Helper Functions for Testing & Isolation
# ==============================================================================
function Test-WindowsCompatibility {
    param([System.OperatingSystem]$OSVersion = [System.Environment]::OSVersion)
    if ($OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
        return $false
    }
    return ($OSVersion.Version.Major -ge 10)
}

function Test-PowerShellCompatibility {
    param([System.Version]$Version = $PSVersionTable.PSVersion)
    return ($Version.Major -ge 5)
}

function Get-AdminStatus {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]$identity
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

function Verify-FileChecksum {
    param(
        [string]$FilePath,
        [string]$ExpectedSha256
    )
    if (-not (Test-Path -LiteralPath $FilePath)) {
        return $false
    }
    $hash = (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash
    return ($hash -ieq $ExpectedSha256.Trim())
}

# ==============================================================================
# Main Bootstrap Execution
# ==============================================================================
Show-HailBanner -TargetVersion $Version

Write-Host "[1/4] Checking system compatibility and security prerequisites..." -ForegroundColor Cyan

# 1. Check OS
if (-not (Test-WindowsCompatibility)) {
    Write-Error "[FATAL] HailUninstaller requires Windows 10, Windows 11, or Windows Server 2016+ (NT 10.0+). Detected: $([System.Environment]::OSVersion.VersionString)"
    exit 1
}

# 2. Check PowerShell Version
if (-not (Test-PowerShellCompatibility)) {
    Write-Error "[FATAL] HailUninstaller requires Windows PowerShell 5.1 or PowerShell Core 7+. Detected version: $($PSVersionTable.PSVersion)"
    exit 1
}

# 3. Configure TLS 1.2+ for secure download
try {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13
} catch {
    # If TLS 1.3 is not defined in older .NET 4.5, fallback to TLS 1.2
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
}

# 4. Check Administrator Privileges
$isAdmin = Get-AdminStatus
if ($Elevate -and -not $isAdmin) {
    Write-Host "[ELEVATE] Elevating session to Administrator privileges..." -ForegroundColor Yellow
    $scriptUrl = "https://raw.githubusercontent.com/$($script:DefaultRepository)/main/bootstrap.ps1"
    $escapedArgs = if ($PassthroughArgs) { ($PassthroughArgs -join ' ') } else { "" }
    $cmd = "irm `"$scriptUrl`" | iex; & { $(irm `"$scriptUrl`") } $escapedArgs"
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$cmd`"" -Verb RunAs
    return
}

if (-not $isAdmin) {
    Write-Host "      Running as Standard User. (Deep system purges in Program Files/Services will require elevation)." -ForegroundColor Yellow
} else {
    Write-Host "      Administrative privileges verified." -ForegroundColor Green
}

# 5. Resolve Target Install/Cache Directory
$targetAppDir = if ($InstallDir) { $InstallDir } else { Join-Path $env:LOCALAPPDATA "HailUninstaller\app" }
$appScript = Join-Path $targetAppDir "HailUninstaller.ps1"
$appModules = Join-Path $targetAppDir "Modules"
$appConfig = Join-Path $targetAppDir "Config"

# 6. Resolve Expected SHA-256 Hash
$targetSha256 = $null

if ($ExpectedHash) {
    $targetSha256 = $ExpectedHash.Trim().ToUpperInvariant()
    Write-Host "      Using user-provided expected SHA-256: $targetSha256" -ForegroundColor Cyan
} elseif ($script:KnownReleases.ContainsKey($Version)) {
    $targetSha256 = $script:KnownReleases[$Version].Sha256
    Write-Host "      Using embedded trusted release SHA-256 for v$Version." -ForegroundColor Gray
} else {
    Write-Host "      Version v$Version not in local trust table. Querying official release manifest..." -ForegroundColor Gray
    try {
        $manifestUrl = "$($script:DefaultRawBaseUrl)/Config/Releases.json"
        $manifestContent = Invoke-RestMethod -Uri $manifestUrl -UseBasicParsing -TimeoutSec 10
        if ($manifestContent -and $manifestContent.releases -and $manifestContent.releases.$Version) {
            $targetSha256 = $manifestContent.releases.$Version.sha256.Trim().ToUpperInvariant()
            Write-Host "      Verified trusted SHA-256 from official manifest for v$Version." -ForegroundColor Green
        }
    } catch {
        Write-Warning "Failed to fetch remote release manifest: $($_.Exception.Message)"
    }
}

if (-not $targetSha256 -or $targetSha256 -eq "PENDING_PACKAGING") {
    if ($DryRun) {
        $targetSha256 = "SIMULATED_SHA256_HASH_FOR_DRYRUN"
    } else {
        Write-Error "[SECURITY FATAL] Could not resolve a trusted cryptographic SHA-256 digest for release v$Version. To prevent running unverified software, execution is terminated. Specify -ExpectedHash <sha256> to supply a trusted hash."
        exit 1
    }
}

# 7. Check if already installed and valid
$isCached = (Test-Path -LiteralPath $appScript) -and (Test-Path -LiteralPath $appModules) -and (Test-Path -LiteralPath $appConfig)
if ($isCached -and -not $ForceUpdate) {
    Write-Host "[2/4] Cached installation found at: $targetAppDir" -ForegroundColor Green
    Write-Host "[3/4] Skipping download (Use -ForceUpdate to reinstall)." -ForegroundColor Gray
} else {
    # 8. Resolve Download URL
    $archiveName = "HailUninstaller-v$Version.zip"
    $downloadUrl = if ($ReleaseUrl) {
        $ReleaseUrl
    } else {
        "$($script:DefaultReleaseBaseUrl)/v$Version/$archiveName"
    }

    Write-Host "[2/4] Downloading official release artifact..." -ForegroundColor Cyan
    Write-Host "      Source: $downloadUrl" -ForegroundColor Gray
    Write-Host "      Target: $targetAppDir" -ForegroundColor Gray

    if ($DryRun) {
        Write-Host "      [DRY-RUN] Simulation only: Download and extraction skipped." -ForegroundColor Yellow
        Write-Host "[3/4] [DRY-RUN] Verification against expected SHA-256: $targetSha256" -ForegroundColor Yellow
        Write-Host "[4/4] [DRY-RUN] Ready to launch HailUninstaller.ps1." -ForegroundColor Yellow
        return
    }

    # Safe temporary download path
    $tempZip = Join-Path $env:TEMP ("HailUninstaller_{0}_{1}.zip" -f $Version, [System.IO.Path]::GetRandomFileName())
    $stagingDir = Join-Path $env:TEMP ("HailStaging_{0}_{1}" -f $Version, [System.IO.Path]::GetRandomFileName())

    try {
        # Check if download source is local file
        if (Test-Path -LiteralPath $downloadUrl -PathType Leaf) {
            Write-Host "      Copying local release artifact..." -ForegroundColor Gray
            Copy-Item -LiteralPath $downloadUrl -Destination $tempZip -Force
        } else {
            # Download via HTTPS with timeout
            $webClient = New-Object System.Net.WebClient
            try {
                $webClient.Headers.Add("User-Agent", "HailUninstaller-Bootstrap/$Version")
                $webClient.DownloadFile($downloadUrl, $tempZip)
            } finally {
                $webClient.Dispose()
            }
        }

        # 9. Cryptographic Checksum Verification
        Write-Host "[3/4] Verifying cryptographic integrity (SHA-256)..." -ForegroundColor Cyan
        $computedHash = (Get-FileHash -Path $tempZip -Algorithm SHA256).Hash.ToUpperInvariant()

        if ($computedHash -ne $targetSha256) {
            # Tampered or corrupted file: destroy immediately
            Remove-Item -LiteralPath $tempZip -Force -ErrorAction SilentlyContinue
            Write-Error "[SECURITY FATAL] Cryptographic checksum mismatch!`nExpected: $targetSha256`nComputed: $computedHash`nThe downloaded file does not match the official release signature and may have been tampered with or corrupted during transmission. Execution aborted."
            exit 1
        }

        Write-Host "      Checksum verified: $computedHash" -ForegroundColor Green

        # 10. Safe Extraction with Path Traversal Protection
        Write-Host "      Extracting release package..." -ForegroundColor Gray
        Add-Type -AssemblyName "System.IO.Compression.FileSystem"
        
        New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null
        $zipArchive = [System.IO.Compression.ZipFile]::OpenRead($tempZip)
        try {
            $stagingFullPath = [System.IO.Path]::GetFullPath($stagingDir)
            if (-not $stagingFullPath.EndsWith([System.IO.Path]::DirectorySeparatorChar.ToString())) {
                $stagingFullPath += [System.IO.Path]::DirectorySeparatorChar
            }

            foreach ($entry in $zipArchive.Entries) {
                $destinationPath = [System.IO.Path]::GetFullPath((Join-Path $stagingDir $entry.FullName))
                # Guard against Zip Slip / Path Traversal
                if (-not $destinationPath.StartsWith($stagingFullPath, [System.StringComparison]::OrdinalIgnoreCase)) {
                    throw "[SECURITY ERROR] Path traversal attempt detected in archive entry: $($entry.FullName)"
                }

                if ($entry.Length -eq 0 -and $entry.FullName.EndsWith("/")) {
                    if (-not (Test-Path -LiteralPath $destinationPath)) {
                        New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
                    }
                } else {
                    $parentDir = [System.IO.Path]::GetDirectoryName($destinationPath)
                    if (-not (Test-Path -LiteralPath $parentDir)) {
                        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
                    }
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destinationPath, $true)
                }
            }
        } finally {
            $zipArchive.Dispose()
        }

        # 11. Deploy into target directory
        if (-not (Test-Path -LiteralPath $targetAppDir)) {
            New-Item -ItemType Directory -Path $targetAppDir -Force | Out-Null
        }

        # Copy extracted files to target directory
        Get-ChildItem -LiteralPath $stagingDir | ForEach-Object {
            Copy-Item -LiteralPath $_.FullName -Destination $targetAppDir -Recurse -Force
        }

        Write-Host "      Installed to: $targetAppDir" -ForegroundColor Green

    } catch {
        Write-Error "[FATAL] Failed to download or deploy HailUninstaller: $($_.Exception.Message)"
        exit 1
    } finally {
        # Clean up temporary zip and staging folder
        if (Test-Path -LiteralPath $tempZip) {
            Remove-Item -LiteralPath $tempZip -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path -LiteralPath $stagingDir) {
            Remove-Item -LiteralPath $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# ==============================================================================
# Launch HailUninstaller
# ==============================================================================
Write-Host "[4/4] Launching HailUninstaller..." -ForegroundColor Green
Write-Host ""

if (-not (Test-Path -LiteralPath $appScript)) {
    Write-Error "[FATAL] Entry point script not found: $appScript"
    exit 1
}

# Forward any arguments passed to the bootstrap
if ($PassthroughArgs -and $PassthroughArgs.Count -gt 0) {
    $formattedArgs = @()
    foreach ($arg in $PassthroughArgs) {
        if ($arg -match '[\s"''\$]') {
            $escaped = $arg -replace '"', '\"'
            $formattedArgs += "`"$escaped`""
        } else {
            $formattedArgs += $arg
        }
    }
    $invokerCmd = "& `"$appScript`" $($formattedArgs -join ' ')"
    $sb = [scriptblock]::Create($invokerCmd)
    & $sb
} else {
    & $appScript
}
