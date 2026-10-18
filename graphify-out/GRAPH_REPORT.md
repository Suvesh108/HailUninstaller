# Graph Report - HailUninstaller  (2026-10-18)

## Corpus Check
- 34 files · ~84,662 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 5 file(s) not represented in the graph (top: (none) 3, .bat 1, .css 1)

## Summary
- 102 nodes · 158 edges · 12 communities (7 shown, 5 thin omitted)
- Extraction: 51% EXTRACTED · 49% INFERRED · 0% AMBIGUOUS · INFERRED: 77 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `29293e2d`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Show-CleanupPreviewTui
- Invoke-CleanupItems
- Get-BackupRootDirectory
- Start-ForcedUninstall
- 0.0.1
- HailUninstaller.ps1
- README.md

## God Nodes (most connected - your core abstractions)
1. `Show-HailUninstallerGUI()` - 14 edges
2. `Start-ForcedUninstall()` - 13 edges
3. `Start-DeepScan()` - 10 edges
4. `0.0.1` - 8 edges
5. `Show-CleanupPreviewTui()` - 8 edges
6. `Show-RestoreMenuTui()` - 7 edges
7. `Get-InstalledApplications()` - 7 edges
8. `New-CleanupBackup()` - 7 edges
9. `✨ Key Capabilities` - 7 edges
10. `Get-CleanupBackups()` - 6 edges

## Surprising Connections (you probably didn't know these)
- `Show-InteractiveAppPicker()` --calls--> `Get-InstalledApplications()`  [INFERRED]
  HailUninstaller.ps1 → Modules/Applications.ps1
- `Show-CleanupPreviewTui()` --calls--> `New-CleanupBackup()`  [INFERRED]
  HailUninstaller.ps1 → Modules/Backup.ps1
- `Show-CleanupPreviewTui()` --calls--> `Invoke-CleanupItems()`  [INFERRED]
  HailUninstaller.ps1 → Modules/Cleanup.ps1
- `Show-RestoreMenuTui()` --calls--> `Get-CleanupBackups()`  [INFERRED]
  HailUninstaller.ps1 → Modules/Backup.ps1
- `Show-RestoreMenuTui()` --calls--> `Restore-CleanupBackup()`  [INFERRED]
  HailUninstaller.ps1 → Modules/Restore.ps1

## Import Cycles
- None detected.

## Communities (12 total, 5 thin omitted)

### Community 0 - "Show-CleanupPreviewTui"
Cohesion: 0.40
Nodes (9): Show-CleanupPreviewTui(), Show-InteractiveAppPicker(), Show-RestoreMenuTui(), Format-Bytes(), Format-Color(), Show-AppDetails(), Show-Banner(), Show-Header() (+1 more)

### Community 1 - "Invoke-CleanupItems"
Cohesion: 0.40
Nodes (3): Invoke-CleanupItems(), Evaluate-CandidateEvidence(), Load-ConfigSafe()

### Community 2 - "Get-BackupRootDirectory"
Cohesion: 0.46
Nodes (5): Get-BackupRootDirectory(), Get-CleanupBackups(), New-CleanupBackup(), New-SystemRestorePoint(), Restore-CleanupBackup()

### Community 3 - "Start-ForcedUninstall"
Cohesion: 0.15
Nodes (9): Get-FolderSizeSafe(), Scan-FileLeftovers(), Start-ForcedUninstall(), Scan-RunningAppProcesses(), Scan-RegistryLeftovers(), Start-DeepScan(), Scan-ServiceLeftovers(), Scan-ShortcutLeftovers() (+1 more)

### Community 4 - "0.0.1"
Cohesion: 0.14
Nodes (13): archiveName, minPowerShellVersion, minWindowsVersion, notes, releaseDate, sha256, version, latest (+5 more)

### Community 5 - "HailUninstaller.ps1"
Cohesion: 0.19
Nodes (8): Get-InstalledApplications(), Invoke-NativeUninstall(), Show-HailUninstallerGUI(), Get-RunningHunterTargets(), Invoke-HunterTarget(), Scan-OrphanedStorageFolders(), Build-QuietUninstallCommand(), Detect-InstallerType()

### Community 9 - "README.md"
Cohesion: 0.12
Nodes (15): 1. 🧹 Storage Ghost Folder Isolation, 2. 🎯 Multi-Factor Evidence Scoring Engine, 3. ⚡ Hunter Mode (Interactive Process Inspector), 4. 💨 Heuristic Quiet Engine, 5. 🛡️ Automated Snapshot Backup & 1-Click Rollback, 6. 🎨 Windows 11 Fluent WPF GUI & Clean CLI, Advanced Launcher Commands, 🧪 Automated Testing & Verification (+7 more)

## Knowledge Gaps
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Start-ForcedUninstall()` connect `Start-ForcedUninstall` to `Show-CleanupPreviewTui`, `Invoke-CleanupItems`, `Get-BackupRootDirectory`, `HailUninstaller.ps1`?**
  _High betweenness centrality (0.109) - this node is a cross-community bridge._
- **Are the 13 inferred relationships involving `Show-HailUninstallerGUI()` (e.g. with `HailUninstaller.ps1` and `Get-InstalledApplications()`) actually correct?**
  _`Show-HailUninstallerGUI()` has 13 INFERRED edges - model-reasoned connections that need verification._
- **Should `Start-ForcedUninstall` be split into smaller, more focused modules?**
  _Cohesion score 0.14619883040935672 - nodes in this community are weakly interconnected._
- **Why does `Show-HailUninstallerGUI()` connect `HailUninstaller.ps1` to `Show-CleanupPreviewTui`, `Invoke-CleanupItems`, `Get-BackupRootDirectory`, `Start-ForcedUninstall`?**
  _High betweenness centrality (0.080) - this node is a cross-community bridge._
- **Are the 12 inferred relationships involving `Start-ForcedUninstall()` (e.g. with `HailUninstaller.ps1` and `Evaluate-CandidateEvidence()`) actually correct?**
  _`Start-ForcedUninstall()` has 12 INFERRED edges - model-reasoned connections that need verification._
- **Should `0.0.1` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._
- **Why does `Start-DeepScan()` connect `Start-ForcedUninstall` to `Show-CleanupPreviewTui`, `Invoke-CleanupItems`, `HailUninstaller.ps1`?**
  _High betweenness centrality (0.074) - this node is a cross-community bridge._