<#
.SYNOPSIS
    Builds official release packages and SHA-256 checksums for HailUninstaller.
.DESCRIPTION
    Packages core application scripts, modules, configurations, and assets into an
    official distribution ZIP archive, calculates cryptographic SHA-256 checksums,
    updates Config/Releases.json, and produces release verification artifacts.
.PARAMETER Version
    The semantic version string to package (e.g. "0.0.1").
.PARAMETER OutputDir
    The target directory where release archives and checksums will be saved.
.PARAMETER UpdateManifest
    Update Config/Releases.json with the generated SHA-256 hash.
.EXAMPLE
    .\Tools\New-ReleasePackage.ps1 -Version "0.0.1" -UpdateManifest
#>
[CmdletBinding()]
param(
    [string]$Version = "0.0.1",
    [string]$OutputDir = "release",
    [switch]$UpdateManifest = $true
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  HailUninstaller Release Packaging Engine" -ForegroundColor Cyan
Write-Host "  Target Version: v$Version" -ForegroundColor White
Write-Host "=================================================================" -ForegroundColor Cyan

# Resolve output path
$resolvedOutputDir = if ([System.IO.Path]::IsPathRooted($OutputDir)) { $OutputDir } else { Join-Path $RepoRoot $OutputDir }
if (-not (Test-Path -LiteralPath $resolvedOutputDir)) {
    New-Item -ItemType Directory -Path $resolvedOutputDir -Force | Out-Null
}

$archiveName = "HailUninstaller-v$Version.zip"
$archivePath = Join-Path $resolvedOutputDir $archiveName
$checksumPath = Join-Path $resolvedOutputDir "checksums.sha256"

# Create a clean temporary staging directory
$stagingDir = Join-Path $env:TEMP ("HailUninstaller_Build_" + [System.IO.Path]::GetRandomFileName())
if (Test-Path -LiteralPath $stagingDir) {
    Remove-Item -LiteralPath $stagingDir -Recurse -Force
}
New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null

try {
    Write-Host "[1/5] Gathering release payload files..." -ForegroundColor Gray

    # Core root files
    $rootFiles = @(
        "HailUninstaller.ps1",
        "Run.bat",
        "logo.png",
        "LICENSE",
        "README.md"
    )

    foreach ($rf in $rootFiles) {
        $srcPath = Join-Path $RepoRoot $rf
        if (Test-Path -LiteralPath $srcPath) {
            Copy-Item -LiteralPath $srcPath -Destination (Join-Path $stagingDir $rf) -Force
        } else {
            Write-Warning "Optional root file missing: $rf"
        }
    }

    # Modules
    $modulesDest = Join-Path $stagingDir "Modules"
    New-Item -ItemType Directory -Path $modulesDest -Force | Out-Null
    $modulesSrc = Join-Path $RepoRoot "Modules"
    Get-ChildItem -LiteralPath $modulesSrc -Filter "*.ps1" | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $modulesDest $_.Name) -Force
    }

    # Config
    $configDest = Join-Path $stagingDir "Config"
    New-Item -ItemType Directory -Path $configDest -Force | Out-Null
    $configSrc = Join-Path $RepoRoot "Config"
    Get-ChildItem -LiteralPath $configSrc -Filter "*.json" | Where-Object { $_.Name -ne "Releases.json" } | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $configDest $_.Name) -Force
    }

    Write-Host "[2/5] Compressing release archive ($archiveName)..." -ForegroundColor Gray
    if (Test-Path -LiteralPath $archivePath) {
        Remove-Item -LiteralPath $archivePath -Force
    }

    # Use System.IO.Compression with optimal compression
    Add-Type -AssemblyName "System.IO.Compression.FileSystem"
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $stagingDir,
        $archivePath,
        [System.IO.Compression.CompressionLevel]::Optimal,
        $false
    )

    $archiveSize = (Get-Item -LiteralPath $archivePath).Length
    $archiveSizeKB = [math]::Round($archiveSize / 1KB, 2)
    Write-Host "      Archive created successfully: $archiveSizeKB KB" -ForegroundColor Green

    Write-Host "[3/5] Computing cryptographic SHA-256 checksum..." -ForegroundColor Gray
    $hashObj = Get-FileHash -Path $archivePath -Algorithm SHA256
    $sha256 = $hashObj.Hash.ToUpperInvariant()
    Write-Host "      SHA-256: $sha256" -ForegroundColor Yellow

    Write-Host "[4/5] Writing checksums manifest (checksums.sha256)..." -ForegroundColor Gray
    $checksumLine = "$sha256 *$archiveName"
    Set-Content -Path $checksumPath -Value $checksumLine -Encoding ASCII

    if ($UpdateManifest) {
        Write-Host "[5/5] Updating Config/Releases.json..." -ForegroundColor Gray
        $releasesJsonPath = Join-Path $RepoRoot "Config\Releases.json"
        if (Test-Path -LiteralPath $releasesJsonPath) {
            $jsonContent = Get-Content -LiteralPath $releasesJsonPath -Raw | ConvertFrom-Json
            if (-not $jsonContent.releases) {
                $jsonContent | Add-Member -MemberType NoteProperty -Name "releases" -Value ([PSCustomObject]@{})
            }

            $currentDate = (Get-Date).ToString("yyyy-MM-dd")
            $relObj = [PSCustomObject]@{
                version              = $Version
                releaseDate          = $currentDate
                archiveName          = $archiveName
                sha256               = $sha256
                minPowerShellVersion = "5.1"
                minWindowsVersion    = "10.0"
                notes                = "HailUninstaller v$Version official release package."
            }

            $jsonContent.latest = $Version
            $jsonContent.releases | Add-Member -MemberType NoteProperty -Name $Version -Value $relObj -Force

            $jsonContent | ConvertTo-Json -Depth 6 | Set-Content -Path $releasesJsonPath -Encoding UTF8
            Write-Host "      Config/Releases.json updated." -ForegroundColor Green
        }
    }

    Write-Host ""
    Write-Host "=================================================================" -ForegroundColor Green
    Write-Host "  Release Package Ready!" -ForegroundColor Green
    Write-Host "  Archive:  $archivePath" -ForegroundColor White
    Write-Host "  Checksum: $checksumPath" -ForegroundColor White
    Write-Host "  SHA-256:  $sha256" -ForegroundColor Yellow
    Write-Host "=================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "To publish this release to GitHub via CLI:" -ForegroundColor Cyan
    Write-Host "  gh release create v$Version $archivePath $checksumPath --title `"HailUninstaller v$Version`" --notes `"Release v$Version`"" -ForegroundColor White

    return [PSCustomObject]@{
        Version     = $Version
        ArchivePath = $archivePath
        Sha256      = $sha256
        ChecksumPath= $checksumPath
        Size        = $archiveSize
    }
}
finally {
    if (Test-Path -LiteralPath $stagingDir) {
        Remove-Item -LiteralPath $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
