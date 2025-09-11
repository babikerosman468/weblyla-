#!/data/data/com.termux/files/usr/bin/bash
# first_commit_weblyla.sh

set -e

echo "=== Step 1: Go into ~/gitlyla ==="
cd ~/gitlyla
pwd

echo "=== Step 2: Stage all files ==="
git add .

echo "=== Step 3: Commit files ==="
git commit -m "Initial commit: weblyla project"

echo "=== Step 4: Push to remote main branch ==="
git push -u origin main

echo "=== Done: Your weblyla repo is live on remote ==="

