@echo off
REM ========================================
REM Mounting HGCC with Permanent Cache + rclone RC
REM Author: Yikai Dong, Weinstock Lab
REM ========================================

echo.
echo [%TIME%] Starting rclone mount (with --rc)...
echo.

REM Create cache directory
mkdir C:\rclone-cache\hgcc 2>nul

REM Mount weinstocklab with 30-day cache and RC enabled
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
  --poll-interval 1m ^
  --transfers 4 ^
  --no-checksum ^
  --vfs-fast-fingerprint ^
  --vfs-refresh ^
  --links ^
  --rc ^
  --rc-addr=localhost:5572 ^
  --log-level INFO

echo.
echo Mount stopped at %TIME%
pause
