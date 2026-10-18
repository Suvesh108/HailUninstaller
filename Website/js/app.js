// Website/app.js - Interactive terminal simulation & copy interaction

document.addEventListener('DOMContentLoaded', () => {
  // 1. Copy Command Interaction
  const copyBtn = document.getElementById('copy-btn');
  const installCmd = document.getElementById('install-command');

  if (copyBtn && installCmd) {
    copyBtn.addEventListener('click', async () => {
      try {
        await navigator.clipboard.writeText(installCmd.innerText.trim());
        const copyText = copyBtn.querySelector('.copy-text');
        const origText = copyText.innerText;
        copyText.innerText = 'Copied!';
        copyBtn.style.borderColor = 'var(--status-green)';
        copyBtn.style.color = 'var(--status-green)';

        setTimeout(() => {
          copyText.innerText = origText;
          copyBtn.style.borderColor = '';
          copyBtn.style.color = '';
        }, 2000);
      } catch (err) {
        console.error('Clipboard copy failed:', err);
      }
    });
  }

  // 2. Interactive Terminal Screens
  const terminalContent = document.getElementById('term-content');
  const tabs = document.querySelectorAll('.term-tab');

  const screens = {
    menu: `<span style="color:#00d2ff">╔══════════════════════════════════════════════════════════════╗</span>
<span style="color:#00d2ff">║                      HAILUNINSTALLER                         ║</span>
<span style="color:#ffffff">║               Deep Application Removal Tool                  ║</span>
<span style="color:#00d2ff">╚══════════════════════════════════════════════════════════════╝</span>

  <span style="color:#ffffff">1. Installed Applications</span>
  <span style="color:#ffffff">2. Scan for Leftovers</span>
  <span style="color:#ffffff">3. Deep Scan</span>
  <span style="color:#ffffff">4. Cleanup History</span>
  <span style="color:#ffffff">5. Restore</span>
  <span style="color:#f59e0b">Q. Exit</span>

<span style="color:#00d2ff">Select an option:</span> 1

<span style="color:#00d2ff">┌─ Installed Applications Browser ─────────────────────────────</span>
<span style="color:#f59e0b">Type a filter term (or press Enter to list all):</span> discord

[ 1] <span style="color:#ffffff">Discord</span>                                         <span style="color:#94a3b8">(1.0.9168)</span>
Select application number (1-1): 1

<span style="color:#00d2ff">Selected Application:</span>
  Name:      <span style="color:#ffffff">Discord</span>
  Version:   1.0.9168
  Publisher: Discord Inc.
  Location:  C:\\Users\\User\\AppData\\Local\\Discord

<span style="color:#ffffff">[1] Normal Uninstall</span>
<span style="color:#10b981">[2] Uninstall + Deep Scan</span>
<span style="color:#00d2ff">[3] Scan Only</span>
<span style="color:#94a3b8">[4] Cancel</span>

<span style="color:#f59e0b">Select action:</span> 2`,

    scan: `<span style="color:#00d2ff">[HailUninstaller] Invoking native uninstaller for Discord...</span>
<span style="color:#94a3b8">Command: "C:\\Users\\User\\AppData\\Local\\Discord\\Update.exe" --uninstall -s</span>
<span style="color:#10b981">✓ Native uninstaller completed.</span>

<span style="color:#00d2ff">Initiating multi-subsystem deep scan...</span>

<span style="color:#00d2ff">[████████████████████████]</span> <span style="color:#10b981">100%</span>  File System (AppData / ProgramData)
<span style="color:#10b981">✓ AppData\\Local\\Discord</span>
<span style="color:#10b981">✓ AppData\\Roaming\\discord</span>
<span style="color:#10b981">✓ ProgramData\\Discord</span>

<span style="color:#00d2ff">[████████████████████████]</span> <span style="color:#10b981">100%</span>  Windows Registry (HKCU / HKLM)
<span style="color:#10b981">✓ HKCU:\\Software\\Discord</span>
<span style="color:#10b981">✓ HKCU:\\Software\\Classes\\discord</span>

<span style="color:#00d2ff">[████████████████████████]</span> <span style="color:#10b981">100%</span>  Windows Services & Tasks
<span style="color:#10b981">✓ DiscordUpdater (Service)</span>
<span style="color:#10b981">✓ Discord Update (Scheduled Task)</span>

<span style="color:#00d2ff">[████████████████████████]</span> <span style="color:#10b981">100%</span>  Desktop & Start Menu Shortcuts
<span style="color:#10b981">✓ Discord.lnk</span>

<span style="color:#00d2ff">Deep scan complete. Running evidence scoring engine...</span>`,

    preview: `<span style="color:#00d2ff">╔══════════════════════════════════════════════════════════════╗</span>
<span style="color:#00d2ff">║                      CLEANUP PREVIEW                         ║</span>
<span style="color:#00d2ff">╚══════════════════════════════════════════════════════════════╝</span>

<span style="color:#10b981;font-weight:bold">HIGH CONFIDENCE</span>
  <span style="color:#10b981">[x]</span> C:\\Users\\User\\AppData\\Local\\Discord               <span style="color:#00d2ff">742.10 MB</span>
  <span style="color:#10b981">[x]</span> C:\\Users\\User\\AppData\\Roaming\\discord             <span style="color:#00d2ff"> 83.45 MB</span>
  <span style="color:#10b981">[x]</span> C:\\ProgramData\\Discord                                <span style="color:#00d2ff"> 20.80 MB</span>
  <span style="color:#10b981">[x]</span> DiscordUpdater                                        <span style="color:#00d2ff">   Service</span>

<span style="color:#f59e0b;font-weight:bold">REVIEW</span>
  [R1] <span style="color:#64748b">[ ]</span> HKCU:\\Software\\Discord                              <span style="color:#f59e0b">  Registry</span>
  [R2] <span style="color:#64748b">[ ]</span> HKCU:\\Software\\Classes\\discord                      <span style="color:#f59e0b">  Registry</span>

<span style="color:#ef4444;font-weight:bold">PROTECTED</span>
  [-] C:\\Windows\\System32\\...                                 <span style="color:#ef4444">System Safe</span>
────────────────────────────────────────────────────────────────
Selected: <span style="color:#ffffff">4 items</span> | Reclaimable Size: <span style="color:#10b981;font-weight:bold">846.35 MB</span>

<span style="color:#f59e0b">[A] Select All High | [N] None | [R&lt;n&gt;] Toggle Review | [D] Delete | [B] Back:</span> D

<span style="color:#00d2ff">Create cleanup backup? [Y/N] (Default: Y):</span> Y
<span style="color:#10b981">Backup complete (2026-10-02_120000_Discord).</span>
<span style="color:#ef4444">846.35 MB ready for removal. Continue deletion? [Y/N]:</span> Y`,

    cleanup: `<span style="color:#00d2ff">┌─ Executing Cleanup ──────────────────────────────────────────</span>

<span style="color:#00d2ff">[████████████████████████]</span> <span style="color:#10b981">100%</span>  File: C:\\Users\\User\\AppData\\Local\\Discord
<span style="color:#00d2ff">[████████████████████████]</span> <span style="color:#10b981">100%</span>  File: C:\\Users\\User\\AppData\\Roaming\\discord
<span style="color:#00d2ff">[████████████████████████]</span> <span style="color:#10b981">100%</span>  File: C:\\ProgramData\\Discord
<span style="color:#00d2ff">[████████████████████████]</span> <span style="color:#10b981">100%</span>  Service: DiscordUpdater

<span style="color:#10b981">╔══════════════════════════════════════════════════════════════╗</span>
<span style="color:#10b981">║                      CLEANUP COMPLETE                        ║</span>
<span style="color:#10b981">╚══════════════════════════════════════════════════════════════╝</span>

Removed Space: <span style="color:#ffffff;font-weight:bold">846.35 MB</span>
Removed Items: <span style="color:#ffffff;font-weight:bold">37</span>
Failed Items:  <span style="color:#10b981">0</span>

<span style="color:#00d2ff">Snapshot stored in:</span> %LOCALAPPDATA%\\HailUninstaller\\Backups\\
<span style="color:#94a3b8">To restore anytime: .\\HailUninstaller.ps1 -Restore 2026-10-02_120000_Discord</span>

<span style="color:#00d2ff">Press Enter to continue...</span> <span style="animation: blink 1s infinite">_</span>`
  };

  function renderScreen(key) {
    if (screens[key]) {
      terminalContent.innerHTML = screens[key];
    }
  }

  tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      tabs.forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      renderScreen(tab.dataset.step);
    });
  });

  // Initial render
  renderScreen('preview');
});
