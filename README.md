# HailUninstaller

> **Deep Application Removal Tool for Windows**  
> Lightweight, zero-installation PowerShell tool to completely identify and remove an application's remaining footprint.

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-blue.svg)](https://microsoft.com/powershell)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Zero Install](https://img.shields.io/badge/Installation-Zero%20Install-brightgreen.svg)]()

---

## ⚡ Quick Start

Launch immediately with one command in Windows PowerShell (Administrator recommended):

```powershell
irm https://hailuninstaller.dev | iex
```

Or clone the repository and run:

```cmd
Run.bat
```

---

## 🎯 The Difference

Unlike system debloaters that alter Windows settings, telemetry, or services, **HailUninstaller has one focused purpose**:

> **Completely identify and remove an application's remaining footprint without touching system integrity.**

1. **Step 1 — Official Uninstaller First**: Uses the application's native uninstaller before scanning for leftovers.
2. **Step 2 — Multi-Factor Evidence Engine**: Evaluates files, registry keys, services, scheduled tasks, and shortcuts using weighted evidence scoring instead of naive wildcard deletion.
3. **Step 3 — Interactive Preview**: Full preview table categorized into `HIGH CONFIDENCE`, `REVIEW`, and `PROTECTED` with total reclaimable size metrics.
4. **Step 4 — Automated Backup & 1-Click Rollback**: Backs up files, directories, and exports `.reg` hives before deletion with restore manifest tracking.

---

## 💻 CLI Usage

HailUninstaller supports both the interactive TUI and command-line automation:

```powershell
# List installed applications
.\HailUninstaller.ps1 -List

# Scan leftovers for an application (Read-only simulation)
.\HailUninstaller.ps1 -Scan "Discord"

# Deep exhaustive subsystem scan
.\HailUninstaller.ps1 -DeepScan "Discord"

# Uninstall app and clean high-confidence leftovers with automated backup
.\HailUninstaller.ps1 -Uninstall "Discord" -DeepClean -CreateBackup

# Restore a previous cleanup snapshot
.\HailUninstaller.ps1 -Restore "2026-10-02_120000_Discord"
```

---

## 📂 Repository Architecture

```
HailUninstaller/
├── HailUninstaller.ps1      # Main entrypoint (Interactive TUI & CLI)
├── Run.bat                  # Double-click launcher with auto-elevation
├── LICENSE                  # MIT License
├── README.md                # Documentation
│
├── Config/                  # Rules & Safety configurations
│   ├── Applications.json    # Curated application profiles
│   ├── ProtectedPaths.json  # Critical system safety blacklist
│   └── Rules.json           # Scoring heuristics and weights
│
├── Modules/                 # Modular architecture
│   ├── UI.ps1               # Terminal UI, ANSI styling, and progress bars
│   ├── Applications.ps1     # Registry & MSI & AppX application detector
│   ├── Scanner.ps1          # Subsystem scan orchestrator
│   ├── FileScanner.ps1      # AppData, ProgramData, and Temp file scanner
│   ├── RegistryScanner.ps1  # HKCU & HKLM software & startup scanner
│   ├── ServiceScanner.ps1   # Windows service footprint scanner
│   ├── TaskScanner.ps1      # Windows scheduled tasks scanner
│   ├── ProcessScanner.ps1   # Active app process manager
│   ├── ShortcutScanner.ps1  # Desktop & Start menu shortcut detector
│   ├── Evidence.ps1         # Multi-factor confidence scoring engine
│   ├── Cleanup.ps1          # Safe surgical deletion engine
│   ├── Backup.ps1           # Snapshot backup & manifest creator
│   └── Restore.ps1          # Reversible snapshot restore engine
│
└── Tests/                   # Automated Pester test suite
    ├── Scanner.Tests.ps1
    ├── Registry.Tests.ps1
    └── Cleanup.Tests.ps1
```

---

## 🛡️ Safety Invariants

- **Zero Naive Deletions**: Wildcard deletions like `if ($path -like "*Name*") { Remove-Item }` are strictly forbidden.
- **Protected Paths Enforcement**: Built-in guardrails protect `C:\Windows`, `System32`, `WinSxS`, user home roots, and critical Windows registry hives.
- **Preview & Confirmation**: All deletions require explicit user confirmation with review toggles.
- **Manifest-Based Rollback**: Backups are structured in `%LOCALAPPDATA%\HailUninstaller\Backups\` with comprehensive manifest files.

---

## 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.
