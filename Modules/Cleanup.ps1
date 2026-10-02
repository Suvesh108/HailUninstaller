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

    $itemsToDelete = @($SelectedItems | Where-Object { $_.Selected -and -not $_.IsProtected })
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
                "Service" {
                    if ($item.Name) {
                        Stop-Service -Name $item.Name -Force -ErrorAction SilentlyContinue
                        $p = Start-Process -FilePath "sc.exe" -ArgumentList "delete `"$($item.Name)`"" -Wait -PassThru -WindowStyle Hidden
                        if ($p.ExitCode -eq 0) { $removedCount++ } else { $failedCount++ }
                    }
                }
                "Task" {
                    if ($item.Name) {
                        Unregister-ScheduledTask -TaskName $item.Name -Confirm:$false -ErrorAction SilentlyContinue
                        $removedCount++
                    }
                }
                "Registry" {
                    if ($item.Type -eq "Value" -and $item.ValueName) {
                        Remove-ItemProperty -LiteralPath $item.Path -Name $item.ValueName -Force -ErrorAction SilentlyContinue
                        $removedCount++
                    } elseif (Test-Path -LiteralPath $item.Path) {
                        Remove-Item -LiteralPath $item.Path -Recurse -Force -ErrorAction SilentlyContinue
                        $removedCount++
                    }
                }
                "File" {
                    if (Test-Path -LiteralPath $item.Path) {
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
                        $removedCount++
                    }
                }
                Default {
                    # General file/directory removal
                    if ($item.Path -and (Test-Path -LiteralPath $item.Path)) {
                        Remove-Item -LiteralPath $item.Path -Recurse -Force -ErrorAction SilentlyContinue
                        $removedCount++
                        $removedBytes += [long]$item.Size
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
