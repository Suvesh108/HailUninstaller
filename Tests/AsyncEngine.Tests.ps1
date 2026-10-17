# Tests/AsyncEngine.Tests.ps1
# Unit tests for asynchronous background execution and concurrent progress queue streaming

Describe "Async Background Engine and Queue Streaming Tests" {
    Context "ConcurrentQueue Thread Safety" {
        It "Successfully enqueues and dequeues progress events across threads" {
            $queue = [System.Collections.Concurrent.ConcurrentQueue[psobject]]::new()
            $ps = [powershell]::Create()
            $worker = {
                param($q)
                for ($i = 1; $i -le 5; $i++) {
                    $q.Enqueue([PSCustomObject]@{ Step = $i; Message = "Task $i" })
                    Start-Sleep -Milliseconds 20
                }
                return 42
            }
            $ps.AddScript($worker).AddArgument($queue) | Out-Null
            $handle = $ps.BeginInvoke()

            $dequeuedItems = [System.Collections.Generic.List[psobject]]::new()
            while (-not $handle.IsCompleted -or -not $queue.IsEmpty) {
                $item = $null
                while ($queue.TryDequeue([ref]$item)) {
                    $dequeuedItems.Add($item)
                }
                Start-Sleep -Milliseconds 15
            }

            $res = $ps.EndInvoke($handle)
            $ps.Dispose()

            $res | Should Be 42
            $dequeuedItems.Count | Should Be 5
            $dequeuedItems[0].Step | Should Be 1
            $dequeuedItems[4].Step | Should Be 5
        }
    }

    Context "Real-Time Console Logging" {
        It "Executes Log-GuiConsole without throwing exceptions" {
            $baseDir = Split-Path $PSScriptRoot -Parent
            . (Join-Path $baseDir "Modules\GUI.ps1")

            { Log-GuiConsole -Tag "TEST" -Message "Unit test message" -Color Yellow } | Should Not Throw
        }
    }
}
