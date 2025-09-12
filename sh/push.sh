
#!/bin/bash
# Simple script to push weblyla project with a new PAT

# === Step 1: Go into repo ===
cd ~/gitlyla || exit
echo "==> In $(pwd)"

# === Step 2: Ask for new PAT ===
read -sp "Enter your NEW GitHub PAT: " NEWPAT
echo

# === Step 3: Update remote with PAT ===
git remote set-url origin https://babikerosman468:${NEWPAT}@github.com/babikerosman468/weblyla-.git
echo "==> Remote updated"

# === Step 4: Push ===
git push -u origin main

