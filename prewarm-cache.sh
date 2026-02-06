#!/bin/bash
# Pre-warm rclone cache for instant folder access
# Run on your LOCAL COMPUTER after mounting
# Author: Yikai Dong, Weinstock Lab

PROJECT_DIR="/z/projects/your_emory_id"

echo ""
echo "=== Pre-warming rclone cache ==="
echo "Project: $PROJECT_DIR"
echo ""

# Cache directory structure
echo "[1/2] Caching directory structure..."
DIR_COUNT=$(find "$PROJECT_DIR" -type d 2>/dev/null | wc -l)
echo "      Cached $DIR_COUNT directories"

# Cache file metadata
echo "[2/2] Caching file metadata..."
FILE_COUNT=$(find "$PROJECT_DIR" -type f 2>/dev/null | wc -l)
echo "      Cached $FILE_COUNT files"

echo ""
echo "=== Complete ==="
