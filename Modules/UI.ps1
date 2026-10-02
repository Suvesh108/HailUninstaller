# Modules/UI.ps1
# User Interface and Terminal formatting module for HailUninstaller

function Format-Color {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        [Parameter(Mandatory = $true)]
        [string]$ColorName
    )

    $e = [char]27
    $colors = @{
        "Reset"        = "$e[0m"
        "Bold"         = "$e[1m"
        "Dim"          = "$e[2m"
        "Cyan"         = "$e[36m"
        "BrightCyan"   = "$e[96m"
        "Blue"         = "$e[34m"
        "BrightBlue"   = "$e[94m"
        "Green"        = "$e[32m"
        "BrightGreen"  = "$e[92m"
        "Yellow"       = "$e[33m"
        "BrightYellow" = "$e[93m"
        "Red"          = "$e[31m"
        "BrightRed"    = "$e[91m"
        "White"        = "$e[37m"
        "BrightWhite"  = "$e[97m"
        "Gray"         = "$e[90m"
    }

    if ($colors.ContainsKey($ColorName)) {
        return ($colors[$ColorName] + $Text + $colors["Reset"])
    }
    return $Text
}

function Show-Banner {
    $c = Format-Color -Text "+==============================================================+" -ColorName "Cyan"
    $t1 = Format-Color -Text "|                      HAILUNINSTALLER                         |" -ColorName "BrightCyan"
    $t2 = Format-Color -Text "|               Deep Application Removal Tool                  |" -ColorName "BrightWhite"
    $b = Format-Color -Text "+==============================================================+" -ColorName "Cyan"
    Write-Host $c
    Write-Host $t1
    Write-Host $t2
    Write-Host $b
    Write-Host ""
}

function Show-Header {
    param([string]$Title)
    $line = "-" * 62
    $headerText = "[*] " + $Title + " " + $line
    if ($headerText.Length -gt 64) {
        $headerText = $headerText.Substring(0, 64)
    }
    Write-Host (Format-Color -Text $headerText -ColorName "Cyan")
    Write-Host ""
}

function Show-ProgressBar {
    param(
        [int]$Current,
        [int]$Total,
        [string]$TaskName,
        [int]$BarWidth = 30
    )

    $denom = [math]::Max(1, $Total)
    $percent = [math]::Min(100, [int](($Current / $denom) * 100))
    $filledCount = [int](($percent / 100.0) * $BarWidth)
    $emptyCount = $BarWidth - $filledCount

    $barFilled = "=" * $filledCount
    $barEmpty = " " * $emptyCount

    $coloredBar = Format-Color -Text ("[" + $barFilled + $barEmpty + "]") -ColorName "BrightCyan"
    $coloredPercent = Format-Color -Text ("$percent" + "%") -ColorName "BrightGreen"
    Write-Host "`r$coloredBar $coloredPercent  $TaskName" -NoNewline
    if ($percent -ge 100) {
        Write-Host ""
    }
}

function Format-Bytes {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) {
        return "{0:N2} GB" -f ($Bytes / 1GB)
    } elseif ($Bytes -ge 1MB) {
        return "{0:N2} MB" -f ($Bytes / 1MB)
    } elseif ($Bytes -ge 1KB) {
        return "{0:N2} KB" -f ($Bytes / 1KB)
    } else {
        return "$Bytes B"
    }
}

function Show-AppDetails {
    param($App)
    Write-Host (Format-Color -Text "Selected Application:" -ColorName "BrightCyan")
    Write-Host ("  Name:      " + (Format-Color -Text $App.DisplayName -ColorName 'BrightWhite'))
    Write-Host ("  Version:   " + $App.DisplayVersion)
    Write-Host ("  Publisher: " + $App.Publisher)
    Write-Host ("  Location:  " + $App.InstallLocation)
    Write-Host ""
}
