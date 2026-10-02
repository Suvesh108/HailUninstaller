# Graph Report - HailUninstaller  (2026-10-02)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 49 nodes · 64 edges · 15 communities (3 shown, 12 thin omitted)
- Extraction: 58% EXTRACTED · 42% INFERRED · 0% AMBIGUOUS · INFERRED: 27 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `2c083d30`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Show-CleanupPreviewTui
- Scan-OrphanedStorageFolders
- Get-BackupRootDirectory
- Start-DeepScan
- Load-ConfigSafe
- Invoke-CleanupItems
- Scan-ServiceLeftovers
- Scan-ShortcutLeftovers
- Scan-TaskLeftovers

## God Nodes (most connected - your core abstractions)
1. `Show-CleanupPreviewTui()` - 8 edges
2. `Start-DeepScan()` - 8 edges
3. `Show-RestoreMenuTui()` - 7 edges
4. `Format-Color()` - 6 edges
5. `Show-Banner()` - 5 edges
6. `Show-Header()` - 5 edges
7. `Show-InteractiveAppPicker()` - 4 edges
8. `Show-ProgressBar()` - 4 edges
9. `Scan-OrphanedStorageFolders()` - 4 edges
10. `Get-BackupRootDirectory()` - 4 edges

## Surprising Connections (you probably didn't know these)
- `Show-CleanupPreviewTui()` --calls--> `Invoke-CleanupItems()`  [INFERRED]
  HailUninstaller.ps1 → Modules/Cleanup.ps1
- `Show-CleanupPreviewTui()` --calls--> `New-CleanupBackup()`  [INFERRED]
  HailUninstaller.ps1 → Modules/Backup.ps1
- `Show-InteractiveAppPicker()` --calls--> `Get-InstalledApplications()`  [INFERRED]
  HailUninstaller.ps1 → Modules/Applications.ps1
- `Show-RestoreMenuTui()` --calls--> `Get-CleanupBackups()`  [INFERRED]
  HailUninstaller.ps1 → Modules/Backup.ps1
- `Show-RestoreMenuTui()` --calls--> `Restore-CleanupBackup()`  [INFERRED]
  HailUninstaller.ps1 → Modules/Restore.ps1

## Import Cycles
- None detected.

## Communities (15 total, 12 thin omitted)

### Community 0 - "Show-CleanupPreviewTui"
Cohesion: 0.44
Nodes (9): Show-CleanupPreviewTui(), Show-InteractiveAppPicker(), Show-RestoreMenuTui(), Format-Bytes(), Format-Color(), Show-AppDetails(), Show-Banner(), Show-Header() (+1 more)

### Community 1 - "Scan-OrphanedStorageFolders"
Cohesion: 0.29
Nodes (4): Get-InstalledApplications(), Get-FolderSizeSafe(), Scan-FileLeftovers(), Scan-OrphanedStorageFolders()

### Community 2 - "Get-BackupRootDirectory"
Cohesion: 0.47
Nodes (4): Get-BackupRootDirectory(), Get-CleanupBackups(), New-CleanupBackup(), Restore-CleanupBackup()

## Knowledge Gaps
- **12 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Get-InstalledApplications()` connect `Scan-OrphanedStorageFolders` to `Show-CleanupPreviewTui`?**
  _High betweenness centrality (0.369) - this node is a cross-community bridge._
- **Why does `Scan-OrphanedStorageFolders()` connect `Scan-OrphanedStorageFolders` to `Load-ConfigSafe`?**
  _High betweenness centrality (0.349) - this node is a cross-community bridge._
- **Why does `Show-InteractiveAppPicker()` connect `Show-CleanupPreviewTui` to `Scan-OrphanedStorageFolders`?**
  _High betweenness centrality (0.336) - this node is a cross-community bridge._
- **Are the 7 inferred relationships involving `Show-CleanupPreviewTui()` (e.g. with `New-CleanupBackup()` and `Invoke-CleanupItems()`) actually correct?**
  _`Show-CleanupPreviewTui()` has 7 INFERRED edges - model-reasoned connections that need verification._
- **Are the 7 inferred relationships involving `Start-DeepScan()` (e.g. with `Evaluate-CandidateEvidence()` and `Load-ConfigSafe()`) actually correct?**
  _`Start-DeepScan()` has 7 INFERRED edges - model-reasoned connections that need verification._
- **Are the 6 inferred relationships involving `Show-RestoreMenuTui()` (e.g. with `Get-CleanupBackups()` and `Restore-CleanupBackup()`) actually correct?**
  _`Show-RestoreMenuTui()` has 6 INFERRED edges - model-reasoned connections that need verification._
- **Are the 3 inferred relationships involving `Show-Banner()` (e.g. with `Show-CleanupPreviewTui()` and `Show-InteractiveAppPicker()`) actually correct?**
  _`Show-Banner()` has 3 INFERRED edges - model-reasoned connections that need verification._