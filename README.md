<div align="center">

  <img src="logo.png" alt="HailUninstaller Logo" width="128" height="128">

  # HailUninstaller

  ### Deep Application Removal & Ghost Storage Footprint Purge for Windows

  [![GitHub Release](https://img.shields.io/badge/Release-v0.0.1-0078D6?style=for-the-badge&logo=github)](https://github.com/Suvesh108/HailUninstaller/releases)
  [![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207%2B-5391FE?style=for-the-badge&logo=powershell&logoColor=white)](https://microsoft.com/powershell)
  [![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011%20%7C%20Server-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://microsoft.com/windows)
  [![Integrity](https://img.shields.io/badge/Integrity-SHA--256%20Verified-brightgreen?style=for-the-badge&logo=shield&logoColor=white)]()
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)

  <p align="center">
    <strong>Zero-installation, high-precision removal tool that launches official uninstallers first, deeply isolates leftover remnants across file systems, registry hives, background services, and scheduled tasks, scores evidence with heuristic safety guardrails, and provides automated restorable backups before surgical deletion.</strong>
  </p>

</div>

---

## ⚡ Instant Quick Start (Zero-Install One-Liner)

Launch HailUninstaller immediately in Windows PowerShell without manually downloading or managing files:

```powershell
irm "https://raw.githubusercontent.com/Suvesh108/HailUninstaller/main/bootstrap.ps1" | iex
```

> **Note**: HailUninstaller operates cleanly in user space for diagnostics and scanning. When purging system-wide software or protected Program Files directories, launch PowerShell as Administrator or provide the `-Elevate` switch.

### Advanced Launcher Commands

```powershell
# Run system compatibility, TLS 1.2+, and cryptographic security diagnostics
& { $(irm "https://raw.githubusercontent.com/Suvesh108/HailUninstaller/main/bootstrap.ps1") } -Diagnostic

# Dry-run simulation (verifies environment and artifact signatures without writing to disk)
& { $(irm "https://raw.githubusercontent.com/Suvesh108/HailUninstaller/main/bootstrap.ps1") } -DryRun

# Display launcher options and help
& { $(irm "https://raw.githubusercontent.com/Suvesh108/HailUninstaller/main/bootstrap.ps1") } -Help

# Force re-download and cryptographic re-verification of the cached release
& { $(irm "https://raw.githubusercontent.com/Suvesh108/HailUninstaller/main/bootstrap.ps1") } -ForceUpdate

# Forward CLI commands directly through the launcher
& { $(irm "https://raw.githubusercontent.com/Suvesh108/HailUninstaller/main/bootstrap.ps1") } -List
& { $(irm "https://raw.githubusercontent.com/Suvesh108/HailUninstaller/main/bootstrap.ps1") } -Scan "Discord"
& { $(irm "https://raw.githubusercontent.com/Suvesh108/HailUninstaller/main/bootstrap.ps1") } -Orphans
```

---

## 🎯 Why HailUninstaller?

When software is uninstalled through standard Windows Control Panel or Settings, native uninstallers routinely leave behind **gigabytes of abandoned AppData folders, orphaned caches, stale registry keys, active telemetry tasks, and lingering background services**.

Unlike indiscriminate system debloaters that break core Windows settings or naive cleaners that execute dangerous wildcard deletions (`Remove-Item -Recurse "*AppName*"`), **HailUninstaller is built on strict engineering invariants**:

| Feature | Standard Uninstaller | Generic Cleaners / Debloaters | HailUninstaller |
| :--- | :--- | :--- | :--- |
| **Native Uninstallation** | Standard uninstaller only | Skips native uninstaller | **Runs native uninstaller first**, then hunts remnants |
| **Storage Ghost Folders** | Ignored | Naive wildcard deletion | **Cross-checks registry & AppX database** to safely isolate orphan directories |
| **Evidence Validation** | None | Simple string matching | **Multi-factor confidence scoring engine** (Publisher, Rules, Path, Name) |
| **Protected System Paths** | None | Frequently damages OS files | **Hardcoded cryptographic guardrails** protecting Windows, System32 & WinSxS |
| **Safety Rollback** | None | System Restore point only | **Automated file archive & `.reg` hive snapshot** before every purge |
| **Heuristic Quiet Engine** | Manual prompts required | Inconsistent | **Synthesizes silent flags** for Inno, NSIS, MSI, InstallShield, Squirrel |
| **Zero Installation** | Requires installer | Requires installer or setup | **Pure PowerShell**, portable zero-install |

---

## ✨ Key Capabilities

### 1. 🧹 Storage Ghost Folder Isolation
Scans `AppData\Local`, `AppData\Roaming`, `AppData\LocalLow`, `ProgramData`, and secondary fixed storage drive roots. By cross-referencing folders against the Windows Uninstall Registry (HKLM/HKCU 32-bit & 64-bit) and AppX / MSIX package database, HailUninstaller pinpoints directories belonging to software that has **already been uninstalled**, reclaiming tens of gigabytes of disk space safely.

### 2. 🎯 Multi-Factor Evidence Scoring Engine
Residual files, keys, and tasks are analyzed using weighted heuristics:
- **Exact Application Matching**: 100% confidence token equality.
- **Verified Publisher Anchors**: Validates parent publisher folders (e.g., `Adobe`, `Autodesk`, `Mozilla`).
- **Curated Rule Heuristics**: Pre-configured profiles in `Config/Applications.json` and `Config/Rules.json`.
- **Classification Categories**: Every item is grouped into `HIGH CONFIDENCE`, `MEDIUM / REVIEW`, or `PROTECTED`.

### 3. ⚡ Hunter Mode (Interactive Process Inspector)
Running an unwanted background app or mystery tray utility? Hunter Mode tracks active user processes, resolves their parent executable paths, calculates working set memory, and lets you target and purge the software directly.

### 4. 💨 Heuristic Quiet Engine
Automatically identifies installer engines and synthesizes unattended quiet uninstall parameters:
- **Inno Setup**: `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART`
- **NSIS**: `/S _?=<InstallLocation>`
- **Microsoft MSI**: `/qn /norestart` (extracts genuine GUIDs)
- **InstallShield**: `/s /v/qn`
- **Squirrel / Electron**: `--uninstall -s`

### 5. 🛡️ Automated Snapshot Backup & 1-Click Rollback
Before touching a single file or registry value:
- Files and folders are archived into compressed snapshots in `%LOCALAPPDATA%\HailUninstaller\Backups\`.
- Registry hives are exported using native `reg.exe export`.
- A cryptographic `manifest.json` tracks original paths, permissions, and item counts.
- Any operation can be reverted in one click from the GUI or via `HailUninstaller.ps1 -Restore <BackupId>`.

### 6. 🎨 Windows 11 Fluent WPF GUI & Clean CLI
- **Fluent GUI**: Built with responsive WPF XAML, featuring lattice progress indicators, tab switching, and real-time console logging.
- **Headless CLI**: Full command-line automation with machine-readable `-Json` output for system administrators and deployment scripts.

---

## 💻 Local Execution & CLI Reference

Clone the repository locally:

```cmd
:: Launch interactive GUI / TUI with auto-elevation
Run.bat
```

Or execute directly via PowerShell:

```powershell
# Launch Windows 11 Fluent GUI
.\HailUninstaller.ps1

# List all installed desktop applications, AppX packages, and MSI installations
.\HailUninstaller.ps1 -List

# Output installed applications formatted as JSON
.\HailUninstaller.ps1 -List -Json

# Scan leftovers for an application (Read-only non-destructive simulation)
.\HailUninstaller.ps1 -Scan "Discord"

# Deep exhaustive subsystem scan (Files, Registry, Services, Tasks, Shortcuts)
.\HailUninstaller.ps1 -DeepScan "Discord"

# Deep-scan storage drives for orphan uninstalled application folders
.\HailUninstaller.ps1 -Orphans

# Purge a stubborn directory or unlisted executable
.\HailUninstaller.ps1 -Forced "C:\Program Files\OldApp"

# Uninstall application, clean high-confidence leftovers, and generate backup snapshot
.\HailUninstaller.ps1 -Uninstall "Discord" -DeepClean -CreateBackup

# Rollback and restore a previous cleanup snapshot
.\HailUninstaller.ps1 -Restore "2026-10-18_020822_Discord"
```

### CLI Command Reference

| Parameter | Type | Description |
| :--- | :--- | :--- |
| `-List` | Switch | Lists all installed system applications, MSI packages, and AppX store apps. |
| `-Scan <name>` | String | Performs read-only leftover analysis for the specified application name. |
| `-DeepScan <name>` | String | Performs exhaustive deep subsystem scan across all fixed storage roots. |
| `-Orphans` | Switch | Scans storage roots for ghost folders of uninstalled applications. |
| `-Uninstall <name>`| String | Executes official uninstaller followed optionally by leftover purge. |
| `-Forced <path>` | String | Targeted purge scan for a specific executable or directory remnant. |
| `-Hunter` | Switch | Launches process hunter target tracer. |
| `-DeepClean` | Switch | Automatically cleans detected high-confidence leftovers. |
| `-CreateBackup` | Switch | Creates restorable file and registry snapshot before deletion. |
| `-Restore <id>` | String | Restores a previously created backup snapshot by Backup ID. |
| `-Cli` | Switch | Forces terminal console mode instead of the Fluent WPF GUI. |
| `-Json` | Switch | Emits machine-readable JSON output for scriptable pipelines. |
| `-Silent` / `-Quiet`| Switch | Suppresses non-essential console output. |

---

## 🔒 Security Architecture & Trust Model

HailUninstaller adheres to rigorous defensive security guardrails:

```
[Web Launcher] irm bootstrap.ps1 | iex
       │
       ▼
[TLS 1.2+ Enforced] ───────────────► Reject insecure SSLv3 / TLS 1.0
       │
       ▼
[Pre-Flight Verification] ─────────► Validate Windows 10/11 & PowerShell 5.1+
       │
       ▼
[Download Official Release] ───────► Staged in user temporary directory
       │
       ▼
[SHA-256 Digest Verification] ─────► Compare against hardcoded pinned trust table
       │                             └── MISMATCH: Immediate deletion & fatal abort
       ▼
[Zip Slip Canonical Check] ────────► Prevent directory traversal (../ escapes)
       │
       ▼
[Atomic Extract to %LOCALAPPDATA%] ─► User-space execution (No machine tampering)
       │
       ▼
[Launch HailUninstaller] ──────────► Zero changes to AV / Windows Defender
```

1. **Independent Cryptographic Verification**:
   The bootstrap launcher contains pinned SHA-256 digests in an embedded trust table, verified independently from download endpoints. **Unverified content will never execute**.
2. **Zip Slip / Path Traversal Guardrails**:
   Archive extraction verifies that every entry's canonical destination strictly resides within `%LOCALAPPDATA%\HailUninstaller\app`. Any relative path traversal (`../`) triggers an immediate security abort.
3. **Zero Security Tampering**:
   HailUninstaller **never** disables Windows Defender, antivirus realtime scanning, UAC, or PowerShell execution policies system-wide.
4. **Least Privilege Operation**:
   Downloads, verification, and UI browsing operate cleanly in standard user context. Elevation is requested strictly when performing deletions in protected system roots.
5. **System Path Blacklist Guardrails**:
   Critical Windows operating system paths are hardcoded as protected:
   - `C:\Windows`, `C:\Windows\System32`, `C:\Windows\WinSxS`
   - User profile roots (`C:\Users\<User>`), desktop roots, system volume info
   - Root registry keys (`HKLM\SAM`, `HKLM\SECURITY`, `HKLM\SYSTEM`)

---

## 📂 Repository Architecture

```
HailUninstaller/
├── bootstrap.ps1              # Zero-install bootstrap launcher with SHA-256 verification
├── HailUninstaller.ps1        # Main application entrypoint (Fluent GUI, TUI & CLI)
├── Run.bat                    # Double-click launcher with auto-elevation
├── LICENSE                    # MIT License
├── README.md                  # Comprehensive project documentation
├── logo.png                   # Brand icon asset
│
├── .github/
│   └── workflows/
│       ├── ci.yml             # Automated Pester test pipeline on Windows runners
│       └── release.yml        # Automated release packaging & checksum publishing
│
├── Config/                    # Heuristic rules & safety configurations
│   ├── Applications.json      # Curated application profiles
│   ├── ProtectedPaths.json    # Critical system safety blacklist
│   ├── Releases.json          # Official release catalog and verified SHA-256 hashes
│   └── Rules.json             # Confidence scoring heuristics and weights
│
├── Modules/                   # Modular architecture
│   ├── UI.ps1                 # Terminal UI, ANSI styling, and progress bars
│   ├── Applications.ps1       # Registry, MSI, AppX, and WinGet application detector
│   ├── Scanner.ps1            # Subsystem scan orchestrator
│   ├── FileScanner.ps1        # AppData, ProgramData, and Temp file scanner
│   ├── RegistryScanner.ps1    # HKCU & HKLM software & startup scanner
│   ├── ServiceScanner.ps1     # Windows service footprint scanner
│   ├── TaskScanner.ps1        # Windows scheduled tasks scanner
│   ├── ProcessScanner.ps1     # Active app process manager
│   ├── ShortcutScanner.ps1    # Desktop & Start menu shortcut detector
│   ├── Evidence.ps1           # Multi-factor confidence scoring engine
│   ├── Cleanup.ps1            # Safe surgical deletion engine
│   ├── Backup.ps1             # Snapshot backup & manifest creator
│   ├── Restore.ps1            # Reversible snapshot restore engine
│   ├── GUI.ps1                # Windows 11 Fluent WPF graphical user interface
│   ├── QuietEngine.ps1        # Silent uninstaller synthesis engine
│   ├── OrphanScanner.ps1      # Ghost storage folder scanner
│   ├── ForcedUninstall.ps1    # Target purge & remnants scanner
│   └── HunterMode.ps1         # Process inspector & desktop crosshair
│
├── Tools/                     # Build and release tooling
│   └── New-ReleasePackage.ps1 # Packages ZIP archives and computes SHA-256 checksums
│
└── Tests/                     # Automated Pester test suite (38+ tests)
    ├── AsyncEngine.Tests.ps1  # GUI async runspace & queue safety tests
    ├── Bootstrap.Tests.ps1    # Launcher, checksum, and security verification tests
    ├── Cleanup.Tests.ps1      # Deletion safety & human confirmation tests
    ├── ForcedUninstall.Tests.ps1 # Target purge & remnant analysis tests
    ├── QuietEngine.Tests.ps1  # Heuristic quiet flag synthesis tests
    ├── Registry.Tests.ps1     # Registry scanner & path normalization tests
    └── Scanner.Tests.ps1      # Application discovery & folder size calculation tests
```

---

## 🧪 Automated Testing & Verification

HailUninstaller includes a comprehensive Pester test suite covering scanning logic, heuristic detection, safety blacklists, and bootstrap security:

```powershell
# Run the complete test suite
Invoke-Pester -Path ./Tests/
```

```
Describing Async Background Engine and Queue Streaming Tests
   Context ConcurrentQueue Thread Safety
    [+] Successfully enqueues and dequeues progress events across threads
   Context DispatcherTimer Closure Scope Retention
    [+] Retains local variables and drains ConcurrentQueue without null reference
   Context Real-Time Console Logging
    [+] Executes Log-GuiConsole without throwing exceptions
   Context Shared Reference Async Task Isolation
    [+] Disposes runspace and removes task record without null-reference exceptions

Describing HailUninstaller Bootstrap & Security Launcher
   Context Pre-flight Compatibility Validation
    [+] Approves Windows 10/11 and Windows Server 2016+ NT version
    [+] Rejects unsupported older Windows versions
    [+] Rejects non-Windows platforms
    [+] Requires PowerShell 5.1 or newer
   Context Cryptographic Checksum Verification
    [+] Correctly validates authentic file hash
    [+] Detects tampered file and fails verification
   Context CLI Command Modes
    [+] Executes -Help flag successfully and outputs usage information
    [+] Executes -Diagnostic flag successfully and reports system status
    [+] Executes -DryRun mode without modifying target directory
   Context End-to-End Local Bootstrap Deployment
    [+] Successfully extracts and deploys from verified archive when hash matches
    [+] Aborts immediately with security error when archive has mismatched hash
    [+] Handles network 404 download errors gracefully with clear fatal message

Describing Evidence and Cleanup Tests
   Context Evidence Scoring and Protection Guardrails
    [+] Strictly protects Windows system paths from deletion
    [+] Scores exact application name and known rules with High Confidence
   Context Human Approval Guardrails
    [+] Refuses deletion if called without human approval
    [+] Allows cleanup execution only when human approval is explicitly confirmed
    [+] Successfully deletes directories containing ReadOnly child files
    [+] Filters out evidence with score below 20 to eliminate noise

Describing Forced Uninstall and Backup/Restore Tests
   Context Start-ForcedUninstall
    [+] Generates scored candidates for a mock target path
    [+] Preserves generic parent directory and targets only the file for standalone executables
   Context Directory Backup and Restore
    [+] Successfully creates and restores a directory backup

Describing Heuristic Quiet Engine Tests
   Context Detect-InstallerType
    [+] Detects Inno Setup, NSIS, MSI, and Squirrel installers
   Context Build-QuietUninstallCommand
    [+] Synthesizes quiet command when official quiet string is missing
    [+] Extracts MSI GUID correctly into RecommendedArgs
    [+] Correctly separates unquoted executable path containing spaces
    [+] Appends _?=InstallLocation for NSIS uninstaller

Describing Registry Scanner Tests
   Context Scan-RegistryLeftovers
    [+] Successfully queries registry without crashing
    [+] Emits normalized PSDrive paths without provider prefixes

Describing Scanner Tests
   Context Get-FolderSizeSafe
    [+] Returns size and count for an existing directory
    [+] Returns zero for non-existent path without error
   Context Applications Enumeration
    [+] Discovers installed system applications

Passed: 38 Failed: 0 Skipped: 0 Pending: 0 (100% Success)
```

---

## 📦 Publishing Releases (Maintainer Guide)

To build and publish an official release with verified cryptographic SHA-256 signatures:

```powershell
# 1. Package the distribution archive and compute SHA-256
.\Tools\New-ReleasePackage.ps1 -Version "0.0.1" -UpdateManifest

# 2. Run the full automated test suite
Invoke-Pester -Path ./Tests/

# 3. Commit changes and push tag to GitHub
git add .
git commit -m "chore: release v0.0.1"
git tag v0.0.1
git push origin main --tags

# 4. Publish release with binary and checksum artifacts via GitHub CLI:
gh release create v0.0.1 release\HailUninstaller-v0.0.1.zip release\checksums.sha256 --title "HailUninstaller v0.0.1" --notes "Official First Release v0.0.1"
```

The GitHub Actions workflow (`.github/workflows/release.yml`) will automatically trigger on tag push to verify tests and publish release assets.

---

## 📄 License

Distributed under the **MIT License**. See [LICENSE](LICENSE) for complete details.

---

<div align="center">
  <sub>Built with precision for clean Windows environments. Zero bloat. Zero naive deletions.</sub>
</div>
