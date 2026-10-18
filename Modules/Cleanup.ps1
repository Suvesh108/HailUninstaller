# Modules/Cleanup.ps1
# Safe cleanup and deletion execution engine

function Invoke-CleanupItems {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [array]$SelectedItems,
        [switch]$HumanApproved,
        [scriptblock]$ProgressCallback = $null
    )

    # Invariant: Human intervention and explicit approval are strictly mandatory
    if (-not $HumanApproved) {
        throw "HUMAN_APPROVAL_REQUIRED: HailUninstaller is hard-coded to require explicit human confirmation before deleting any items."
    }

    $itemsToDelete = @($SelectedItems | Where-Object { 
        $isSelected = if ($null -ne $_.PSObject.Properties['Selected']) { [bool]$_.Selected } else { $true }
        $isSelected -and -not $_.IsProtected 
    })
    $total = $itemsToDelete.Count

    $removedBytes = 0L
    $removedCount = 0
    $failedCount = 0

    for ($i = 0; $i -lt $total; $i++) {
        $item = $itemsToDelete[$i]
        $actionDesc = "$($item.Category): $(if ($item.Path) { $item.Path } else { $item.Name })"
        if ($ProgressCallback) {
            & $ProgressCallback ($i + 1) $total $actionDesc
        }

        try {
            switch ($item.Category) {
                "Process" {
                    if ($item.Id) {
                        try {
                            Stop-Process -Id $item.Id -Force -ErrorAction Stop
                            $removedCount++
                        } catch {
                            $failedCount++
                        }
                    }
                }
                "Service" {
                    if ($item.Name) {
                        Stop-Service -Name $item.Name -Force -ErrorAction SilentlyContinue
                        $p = Start-Process -FilePath "sc.exe" -ArgumentList "delete `"$($item.Name)`"" -Wait -PassThru -WindowStyle Hidden
                        if ($p.ExitCode -eq 0) { $removedCount++ } else { $failedCount++ }
                    }
                }
                "Task" {
                    if ($item.Name) {
                        $tPath = if ($item.Path) { $item.Path } else { "\" }
                        try {
                            Unregister-ScheduledTask -TaskPath $tPath -TaskName $item.Name -Confirm:$false -ErrorAction Stop
                            $removedCount++
                        } catch {
                            $failedCount++
                        }
                    }
                }
                "Registry" {
                    if ($item.Type -eq "Value" -and $item.ValueName) {
                        Remove-ItemProperty -LiteralPath $item.Path -Name $item.ValueName -Force -ErrorAction SilentlyContinue
                        $prop = (Get-ItemProperty -LiteralPath $item.Path -Name $item.ValueName -ErrorAction SilentlyContinue).$($item.ValueName)
                        if ($null -eq $prop) { $removedCount++ } else { $failedCount++ }
                    } elseif (Test-Path -LiteralPath $item.Path) {
                        Remove-Item -LiteralPath $item.Path -Recurse -Force -ErrorAction SilentlyContinue
                        if (-not (Test-Path -LiteralPath $item.Path)) { $removedCount++ } else { $failedCount++ }
                    }
                }
                "File" {
                    if (Test-Path -LiteralPath $item.Path) {
                        if (Test-Path -LiteralPath $item.Path -PathType Container) {
                            Get-ChildItem -LiteralPath $item.Path -Recurse -Force -ErrorAction SilentlyContinue |
                                Where-Object { $_.Attributes -band [System.IO.FileAttributes]::ReadOnly } |
                                ForEach-Object { $_.Attributes = $_.Attributes -bxor [System.IO.FileAttributes]::ReadOnly }
                        }
                        Remove-Item -LiteralPath $item.Path -Recurse -Force -ErrorAction SilentlyContinue
                        if (-not (Test-Path -LiteralPath $item.Path)) {
                            $removedCount++
                            $removedBytes += [long]$item.Size
                        } else {
                            $failedCount++
                        }
                    }
                }
                "Shortcut" {
                    if (Test-Path -LiteralPath $item.Path) {
                        Remove-Item -LiteralPath $item.Path -Force -ErrorAction SilentlyContinue
                        if (-not (Test-Path -LiteralPath $item.Path)) {
                            $removedCount++
                            $removedBytes += [long]$item.Size
                        } else {
                            $failedCount++
                        }
                    }
                }
                Default {
                    # General file/directory removal
                    if ($item.Path -and (Test-Path -LiteralPath $item.Path)) {
                        if (Test-Path -LiteralPath $item.Path -PathType Container) {
                            Get-ChildItem -LiteralPath $item.Path -Recurse -Force -ErrorAction SilentlyContinue |
                                Where-Object { $_.Attributes -band [System.IO.FileAttributes]::ReadOnly } |
                                ForEach-Object { $_.Attributes = $_.Attributes -bxor [System.IO.FileAttributes]::ReadOnly }
                        }
                        Remove-Item -LiteralPath $item.Path -Recurse -Force -ErrorAction SilentlyContinue
                        if (-not (Test-Path -LiteralPath $item.Path)) {
                            $removedCount++
                            $removedBytes += [long]$item.Size
                        } else {
                            $failedCount++
                        }
                    }
                }
            }
        } catch {
            $failedCount++
        }
    }

    return [PSCustomObject]@{
        RemovedBytes = $removedBytes
        RemovedCount = $removedCount
        FailedCount  = $failedCount
    }
}
