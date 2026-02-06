# Rclone Cache Quick Reference - 快速参考

## 🚀 Quick Start

### 1. Mount with Permanent Cache
```cmd
mount-hgcc-permanent-cache.bat
```

### 2. Pre-warm Cache (Run Once After Mounting)
**PowerShell:**
```powershell
.\prewarm-cache.ps1
```

**Git Bash:**
```bash
bash prewarm-cache.sh
```

### 3. Open VSCode to Specific Project
```
File → Open Folder → Z:\projects\ydon268\Project1_Centromere
```

---

## 📊 Cache Settings Summary

| Setting | Value | Meaning |
|---------|-------|---------|
| File cache lifetime | 30 days | Files stay cached for 1 month |
| Directory cache | 7 days | Folder structure cached for 1 week |
| Max cache size | 100 GB | Auto-cleanup when exceeded |
| Min free space | 10 GB | Stop caching if disk <10GB free |

---

## 🔍 Check Cache Status

### How much is cached?
**PowerShell:**
```powershell
$size = (Get-ChildItem C:\rclone-cache\hgcc -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1GB
Write-Host "Cache size: $([math]::Round($size, 2)) GB"
```

**Bash:**
```bash
du -sh /c/rclone-cache/hgcc
```

### List cached files
**PowerShell:**
```powershell
Get-ChildItem C:\rclone-cache\hgcc\vfs -Recurse -File | 
    Sort-Object LastAccessTime -Descending | 
    Select-Object -First 20 Name, @{N='Size(MB)';E={[math]::Round($_.Length/1MB,2)}}, LastAccessTime |
    Format-Table -AutoSize
```

---

## 🧹 Manual Cache Cleanup

### Clean files older than 30 days
**PowerShell:**
```powershell
$threshold = (Get-Date).AddDays(-30)
Get-ChildItem C:\rclone-cache\hgcc -Recurse -File | 
    Where-Object { $_.LastAccessTime -lt $threshold } | 
    Remove-Item -Force -Verbose
```

### Clean entire cache (CAUTION: Will re-download everything)
**PowerShell:**
```powershell
Remove-Item C:\rclone-cache\hgcc\* -Recurse -Force
```

**IMPORTANT:** Only do this when mount is STOPPED!

---

## 🐛 Troubleshooting

### Problem: VSCode still lags when opening folders

**Diagnosis:**
```powershell
# Check if mount is using long dir-cache-time
# Should see "dir-cache-time 168h" in the mount window
```

**Fix:**
- Make sure you're using `mount-hgcc-permanent-cache.bat`
- Not the old `mount-hgcc-optimized.bat`

---

### Problem: Cache fills disk (>100GB)

**Check what's using space:**
```powershell
Get-ChildItem C:\rclone-cache\hgcc\vfs -Recurse -File | 
    Sort-Object Length -Descending | 
    Select-Object -First 20 Name, @{N='Size(GB)';E={[math]::Round($_.Length/1GB,3)}} |
    Format-Table -AutoSize
```

**Solutions:**
1. Delete large cached files you don't need:
   ```powershell
   # Delete cached files > 1GB
   Get-ChildItem C:\rclone-cache\hgcc\vfs -Recurse -File | 
       Where-Object { $_.Length -gt 1GB } | 
       Remove-Item -Force
   ```

2. Reduce `--vfs-cache-max-size` in mount script:
   ```batch
   --vfs-cache-max-size 50G ^
   ```

---

### Problem: Files I deleted remotely still show up

**This is normal!** Cache takes up to 1 hour to sync (based on `--poll-interval 1h`)

**Force immediate sync:**
```bash
# In Git Bash, while mount is running
rclone rc vfs/refresh recursive=true dir=/projects/ydon268
```

Or just wait 1 hour - it will auto-sync.

---

### Problem: Cache doesn't survive reboot

**Check cache location:**
```powershell
Test-Path C:\rclone-cache\hgcc
# Should return: True
```

**If False, cache was deleted.** Make sure nothing is cleaning `C:\rclone-cache\`

Check Windows:
- Storage Sense (might auto-delete temp files)
- Disk Cleanup tools
- Antivirus quarantine

---

## ⚡ Performance Expectations

### First Time Opening Folder
- **Before cache:** 20-30 seconds
- **After cache:** 20-30 seconds (must download)

### Second Time Opening Same Folder  
- **Before cache:** 20-30 seconds (re-downloads)
- **After cache:** **1-2 seconds** ✨

### Opening File
- **First access:** 2-5 seconds (downloads)
- **Cached:** <0.5 seconds ⚡

---

## 📝 Cache Persistence Rules

### ✅ Cache SURVIVES (Persists):
- Reboots
- Unmounting and remounting
- Windows updates
- VSCode restarts

### ❌ Cache LOST when:
- You delete `C:\rclone-cache\hgcc\`
- Disk runs out of space completely
- You change `--cache-dir` path
- File age exceeds `--vfs-cache-max-age` (30 days)
- Cache size exceeds `--vfs-cache-max-size` (100GB) - oldest files deleted

---

## 🔧 Advanced: Auto-Start at Login

### Create Windows Task Scheduler Job

1. Open Task Scheduler
2. Create Basic Task:
   - Name: "Rclone HGCC Mount"
   - Trigger: At log on
   - Action: Start a program
   - Program: `C:\path\to\mount-hgcc-permanent-cache.bat`
   - ✅ Check "Run whether user is logged on or not"

3. Then run pre-warm script manually once

---

## 📚 Related Files

- `mount-hgcc-permanent-cache.bat` - Mount script with 30-day cache
- `prewarm-cache.ps1` - PowerShell pre-warming script  
- `prewarm-cache.sh` - Bash pre-warming script
- `rclone-permanent-cache-guide.md` - Full documentation

---

## 💡 Pro Tips

1. **Run pre-warm script right after mounting**
   - Caches everything in background
   - Next folder open will be instant

2. **Only open specific project in VSCode**
   - ✅ `Z:\projects\ydon268\Project1_Centromere`
   - ❌ `Z:\` (tries to index everything!)

3. **Check cache size weekly**
   ```powershell
   du -sh /c/rclone-cache/hgcc
   ```

4. **Increase cache size if you have space**
   - Edit mount script: `--vfs-cache-max-size 200G ^`
   - More cache = more files stay local

---


