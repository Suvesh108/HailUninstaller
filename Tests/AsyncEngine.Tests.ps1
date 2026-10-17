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

    Context "DispatcherTimer Closure Scope Retention" {
        It "Retains local variables and drains ConcurrentQueue without null reference when using GetNewClosure" {
            Add-Type -AssemblyName WindowsBase
            Add-Type -AssemblyName PresentationCore
            Add-Type -AssemblyName PresentationFramework

            $testClosureFunction = {
                param([ref]$receivedList)
                $queue = [System.Collections.Concurrent.ConcurrentQueue[psobject]]::new()
                $queue.Enqueue([PSCustomObject]@{ Status = "Active" })
                $queue.Enqueue([PSCustomObject]@{ Status = "Complete" })

                $timer = [System.Windows.Threading.DispatcherTimer]::new()
                $timer.Interval = [TimeSpan]::FromMilliseconds(10)

                $tickBlock = {
                    try {
                        if ($queue) {
                            $item = $null
                            while ($queue.TryDequeue([ref]$item)) {
                                $receivedList.Value.Add($item.Status)
                            }
                        }
                    } finally {
                        $timer.Stop()
                    }
                }.GetNewClosure()

                $timer.Add_Tick($tickBlock)
                $timer.Start()
                return $timer
            }

            $results = [System.Collections.Generic.List[string]]::new()
            $activeTimer = & $testClosureFunction ([ref]$results)

            $frame = [System.Windows.Threading.DispatcherFrame]::new()
            $timeoutTimer = [System.Windows.Threading.DispatcherTimer]::new()
            $timeoutTimer.Interval = [TimeSpan]::FromMilliseconds(100)
            $timeoutTimer.Add_Tick({
                $frame.Continue = $false
                $this.Stop()
            })
            $timeoutTimer.Start()
            [System.Windows.Threading.Dispatcher]::PushFrame($frame)

            $results.Count | Should Be 2
            $results[0] | Should Be "Active"
            $results[1] | Should Be "Complete"
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
