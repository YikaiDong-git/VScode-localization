# VSCode locolization for Emory HGCC Cluster Access - Windows

> **A guide for using VSCode with Emory HGCC HPC cluster via rclone SFTP mount**  
> Bypasses Remote-SSH restrictions with **near-zero server resource usage**

**Author:** Yikai Dong (yikai.dong@emory.edu)  
**Status:** ✅ Tested on Windows 10/11  
**Performance:** Cached operations are instant (<100ms), matching or exceeding native server VSCode

---

### Real-World Performance (After Cache Warming)
> **Note:** All performance tests below were run on my computer with a 2070 Super (an older CPU).

| Operation           | Real Time   | Notes |
|---------------------|------------|-------|
| Open cached folder  | 0.046s     | Faster than server VSCode |
| Create file         | 0.123s     | Cached locally, uploads async |
| Save file           | 0.002s     | |
| Git status          | 0.200s     | Clean repo, typical timing |
---

---

## Why This Approach?

**Zero Server Overhead:**  
Unlike VSCode Remote-SSH (which runs vscode-server processes on the cluster), this solution uses **only standard SFTP** - the same protocol you'd use with FileZilla or WinSCP. The cluster sees you as a simple file transfer client with no additional CPU, memory, or process overhead that troubles the server.

**Performance:**  
After initial cache warming, folder navigation and file access are **instant** - often faster than native server VSCode due to local caching.

**Compliance:**  
Works within HPC cluster restrictions that prohibit Remote-SSH installations in IDE platform like vscode.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [SSH Key Setup](#ssh-key-setup)
4. [rclone Configuration](#rclone-configuration)
5. [Mount Script Setup](#mount-script-setup)
6. [VSCode Settings](#vscode-settings)
7. [Cache System Setup](#cache-system-setup)
8. [Daily Workflow](#daily-workflow)
9. [Performance Notes](#performance-notes)

---

## Prerequisites

- **Windows 10/11** (64-bit)
- **SSH access** to Emory HGCC cluster
- **5~100GB free disk space** for cache (adjustable)
> **Reminder:** Be sure to change all example paths to your own folders. For instance, update the mount-hgcc-permanent-cache.bat file to point to your project directory.

---

## Installation
### Step 1: Install WinFsp

WinFsp provides the FUSE-like filesystem layer needed for rclone mount on Windows.

1. For simplicity, open a **Administrator PowerShell** in your computer and then enter: 
   ```
   winget install WinFsp.WinFsp
   ```
   Or, download **WinFsp 2.0.23075** through https:
   ```
   https://github.com/winfsp/winfsp/releases/download/v2.0/winfsp-2.0.23075.msi
   ```
2. Run the installer:
   - Accept all defaults
   - **Important:** Install both Core and Developer components
   - Reboot if prompted

3. Verify installation (PowerShell):
   ```powershell
   sc query winfsp
   ```
   Should show `STATE: 4 RUNNING`

### Step 2: Install rclone

> You may first run this command in your 'powershell' to get the exact version.
   ```
   Write-Host "OS: $((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').ProductName) | Arch: $env:PROCESSOR_ARCHITECTURE"
   ```

1. For simplicty, we recommend installing rclone via **Administrator PowerShell** too:
   ```
   winget install Rclone.Rclone
   ```
   > **Note:**: You may need to restart your PowerShell window after Installation for the rclone command to be recognized globally.

   Or, Download the latest Windows release:
   ```
   https://downloads.rclone.org/rclone-current-windows-amd64.zip
   ```
   > **Note:** If your computer uses a different architecture or OS, check https://rclone.org/downloads/ for other versions.
   




4. Extract to a permanent location:
   ```powershell
   # Example: Extract to C:\rclone
   Expand-Archive rclone-current-windows-amd64.zip -DestinationPath C:\
   Rename-Item C:\rclone-v* C:\rclone
   ```

5. Add to PATH (PowerShell as Admin):
   ```powershell
   $env:Path += ";C:\rclone"
   [Environment]::SetEnvironmentVariable("Path", $env:Path, "Machine")
   ```

6. Verify installation:
   ```powershell
   rclone version
   ```

---

## Installation

### Step 1: Install WinFsp

WinFsp provides the FUSE-like filesystem layer needed for rclone mount on Windows.

1. Download **WinFsp 2.0.23075**:
1. For simplicity, open a **Administrator PowerShell** in your computer and then enter: 
   ```
   winget install WinFsp.WinFsp
   ```
   Or, download **WinFsp 2.0.23075** through https:
   ```
   https://github.com/winfsp/winfsp/releases/download/v2.0/winfsp-2.0.23075.msi
   ```

2. Run the installer:
   - Accept all defaults
   - **Important:** Install both Core and Developer components
   - Reboot if prompted

3. Verify installation (PowerShell):
   ```powershell
   sc query winfsp
   ```
   Should show `STATE: 4 RUNNING`

### Step 2: Install rclone

1. Download the latest Windows release:
> You may first run this command in your 'powershell' to get the exact version.
   ```
   Write-Host "OS: $((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').ProductName) | Arch: $env:PROCESSOR_ARCHITECTURE"
   ```

1. For simplicty, we recommend installing rclone via **Administrator PowerShell** too:
   ```
   winget install Rclone.Rclone
   ```
   > **Note:**: You may need to restart your PowerShell window after Installation for the rclone command to be recognized globally.

   Or, Download the latest Windows release:
   ```
   https://downloads.rclone.org/rclone-current-windows-amd64.zip
   ```
   > **Note:** If your computer uses a different architecture or OS, check https://rclone.org/downloads/ for other versions.
   




2. Extract to a permanent location:
4. Extract to a permanent location:
   ```powershell
   # Example: Extract to C:\rclone
   Expand-Archive rclone-current-windows-amd64.zip -DestinationPath C:\
   Rename-Item C:\rclone-v* C:\rclone
   ```

3. Add to PATH (PowerShell as Admin):
5. Add to PATH (PowerShell as Admin):
   ```powershell
   $env:Path += ";C:\rclone"
   [Environment]::SetEnvironmentVariable("Path", $env:Path, "Machine")
   ```

4. Verify installation:
6. Verify installation:
   ```powershell
   rclone version
   ```

---

## Mount Script Setup

### Create Mount Script

**On your local computer**, create file: `mount-hgcc-permanent-cache.bat`
**On your local computer's desktop (or anywhere else)**, create file: `mount-hgcc-permanent-cache.bat`

```batch
@echo off
REM ========================================
REM Mounting HGCC with Permanent Cache
REM Author: Yikai Dong, Weinstock Lab
REM ========================================

echo.
echo [%TIME%] Starting rclone mount...
echo.

REM Create cache directory
mkdir C:\rclone-cache\hgcc 2>nul

REM Mount weinstocklab with 30-day cache
rclone mount hgcc:/beegfs/labs/weinstocklab Z: ^
  --network-mode ^
  --vfs-cache-mode full ^
  --cache-dir C:\rclone-cache\hgcc ^
  --vfs-cache-max-size 100G ^
  --vfs-cache-max-age 720h ^
  --vfs-cache-min-free-space 10G ^
  --vfs-write-back 2s ^
  --buffer-size 32M ^
  --vfs-read-ahead 128M ^
  --dir-cache-time 168h ^
  --attr-timeout 1h ^
  --poll-interval 1h ^
  --transfers 4 ^
  --no-checksum ^
  --vfs-fast-fingerprint ^
  --vfs-refresh ^
  --links ^
  --log-level INFO

echo.
echo Mount stopped at %TIME%
pause
```

---

## VSCode Settings

### ⚠️ CRITICAL: Open ONLY Your Working Directory

**On your local computer:**
```
File → Open Folder → Z:\projects\your_emory_id\YourProject
File → Open Folder → Z:\projects\your_emory_id (NOT RECOMMENDED if your folder contain many projects)
```

**DON'T DO THIS:**
```
❌ File → Open Folder → Z:\
```

**Why:** Opening the entire drive or multiple projects will cache hundreds of gigabytes of data from other users' directories. Open only your active working project.

### Create `.vscode/settings.json`

**In your project folder** (`Z:\projects\your_emory_id\YourProject\.vscode\settings.json`):
**In your project folder, or click vscode search bar overhead, push "F1", search and click "open user setting" in the search bar. This will open a json file. Please put these rules to the file** (`Z:\projects\your_emory_id\YourProject\.vscode\settings.json`):

```json
{
   "files.watcherExclude": {
      "**/.git/objects/**": true,
      "**/__pycache__/**": true,
      "**/data/**": true,
      "**/results/**": true
   },
   "search.followSymlinks": false,
   "git.autorefresh": false,
   "python.analysis.indexing": false,
   "files.autoSave": "off",
   "github.copilot.enable": {
      "*": true
   }
}
```

### Reload VSCode

```
Ctrl+Shift+P → "Developer: Reload Window"
```
Or just close and reopen.

---

## Small Tip: Path Separator in VSCode

Some users may notice that when you right-click a folder or file, the menu for "Copy Path" will show backslashes (\\) instead of forward slashes (/). To change this:

1. Open local user settings (Ctrl+,)
2. Search for "Explorer: Copy Path Separator" and "Explorer: Copy Relative Path Separator"
3. Adjust them to be "/" for consistency with Unix-style paths.

---

## Cache System Setup

### Understanding the Cache

**On your local computer**, rclone stores a persistent cache at `C:\rclone-cache\hgcc\`:

- Survives reboots ✅
- Automatic cleanup after 30 days
- Typical size: 5-50GB (depends on your working directory)

### Pre-Warm Cache (Recommended)

**This step is optional but highly recommended** for instant folder navigation.

**On your local computer**, create file: `prewarm-cache.sh`

```bash
#!/bin/bash
# Pre-warm cache for your working directory
# Run this on your LOCAL COMPUTER after mounting

PROJECT_DIR="/z/projects/your_emory_id"

echo "=== Caching directory structure ==="
find "$PROJECT_DIR" -type d 2>/dev/null | wc -l

echo "=== Caching file metadata ==="
find "$PROJECT_DIR" -type f 2>/dev/null | wc -l

echo "=== Done. Next folder open will be instant. ==="
```

### Run Pre-Warming

**On your local computer (Git Bash):**

```bash
# After mounting Z:, run once:
bash prewarm-cache.sh
```

**Time required:** 5-30 minutes (one-time setup)  
**Result:** All subsequent folder operations are instant (<0.1s)

---

## Daily Workflow

### Morning: Start Work

**On your local computer:**
```
File → Open Folder → Z:\projects\your_emory_id\YourProject
File → Open Folder → Z:\projects\your_emory_id (NOT RECOMMENDED if your folder contain many projects)
```

**DON'T DO THIS:**
```
❌ File → Open Folder → Z:\
```

**Why:** Opening the entire drive or multiple projects will cache hundreds of gigabytes of data from other users' directories. Open only your active working project.

### During Day: Run Jobs

**Keep a separate SSH terminal open** for running compute jobs:

```bash
# SSH to HGCC (separate terminal)
ssh your_emory_id@hgcc.emory.edu
cd /beegfs/labs/weinstocklab/projects/your_emory_id/YourProject
sbatch my_job.sh
```

### Evening: End Work

**On your local computer:**
```
File → Open Folder → Z:\projects\your_emory_id\YourProject
File → Open Folder → Z:\projects\your_emory_id (NOT RECOMMENDED if your folder contain many projects)
```

**DON'T DO THIS:**
```
❌ File → Open Folder → Z:\
```

**Why:** Opening the entire drive or multiple projects will cache hundreds of gigabytes of data from other users' directories. Open only your active working project.

---

## Performance Notes

### After Cache Warming
> **Note:** All performance tests below were run on my computer with a 2070 Super (an older CPU).

| Operation           | Real Time   | Notes |
|---------------------|------------|-------|
| Open cached folder  | 0.046s     | Faster than server VSCode |
| Create file         | 0.123s     | Cached locally, uploads async |
| Save file           | 0.002s     | |
| Navigate file tree  | 31.5s      | ls -R used; large directory, slower than other ops |
| Git status          | 0.200s     | Clean repo, typical timing |

### Cache Statistics

- **First-time setup:** 5-30 minutes (run prewarm-cache.sh once)
- **Typical cache size:** 2-100GB
- **Cache hit rate:** >99% after warming
- **Server resource usage:** Near-zero (standard SFTP only)

### Why It's Fast

1. **All metadata cached locally** (directory structure, file sizes, dates)
2. **Small files cached entirely** (most code files)
3. **No network round-trips** for cached operations
4. **Background uploads** (don't block your work)

**Result:** After initial cache warming, working with remote files feels completely local - often faster than native server VSCode due to eliminated network latency.

---

## Important Notes

### Symbolic Links

The `--links` flag in the mount script handles symbolic links properly. Common symlinks on HGCC:
- `weinstocklab` → `/beegfs/labs/weinstocklab`
- `yangfss2` → shared directories

These are cluster shortcuts and will appear in your file explorer - this is normal.

### Cache Management

**The cache is self-managing:**
- Files not accessed in 30 days are auto-deleted
- When cache exceeds 100GB, oldest files are removed (LRU)
- You can adjust `--vfs-cache-max-size` in the mount script

**Check cache size:**
```powershell
# On your local computer
(Get-ChildItem C:\rclone-cache\hgcc -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB
```

### Server Resource Impact

**This solution uses ZERO additional server resources** because:
- rclone runs **on your local computer**, not the server
- Uses only standard SFTP protocol (same as FileZilla/WinSCP)
- No server-side processes, no vscode-server, no extra CPU/memory
- Cluster admins see you as a normal SFTP file transfer client

---

## Files in This Repository

| File | Purpose |
|------|---------|
| `README.md` | This guide |
| `mount-hgcc-permanent-cache.bat` | Mount script (double-click to run) |
| `prewarm-cache.sh` | Cache warming script |
| `CACHE-QUICK-REFERENCE.md` | Quick command reference |

---

## Author

**Yikai Dong**  
PhD Student, Genetics and Molecular Biology  
Dr. Joshua Weinstock Lab  
Emory University  
Email: yikai.dong@emory.edu

---

## Credits

- **rclone**: https://rclone.org/
- **WinFsp**: https://winfsp.dev/
- **Emory HGCC**: https://hgcc.emory.edu/

---

## License

This guide is shared freely for use by Emory University researchers and the broader academic community under MIT License.
