#!/data/data/com.termux/files/usr/bin/bash
# push_weblyla_https.sh
# Push first commit to weblyla using HTTPS + PAT

set -e

REPO_DIR=~/gitlyla
cd "$REPO_DIR"
echo "In repo folder: $REPO_DIR"

# --- Step 1: Set remote to HTTPS ---
git remote set-url origin https://github.com/babikerosman468/weblyla.git
echo "Remote set to HTTPS: https://github.com/babikerosman468/weblyla.git"

# --- Step 2: Show remote ---
git remote -v

# --- Step 3: Show status ---
git status

# --- Step 4: Stage all files ---
git add .
echo "All files staged."

# --- Step 5: Commit if no commit exists ---
if git rev-parse HEAD >/dev/null 2>&1; then
    echo "HEAD exists, skipping initial commit."
else
    git commit -m "Initial commit: weblyla project"
    echo "Initial commit created."
fi

# --- Step 6: Push to remote ---
echo "You will be prompted for your GitHub username and PAT."
git push -u origin main

echo "✅ Done: First commit pushed to weblyla using HTTPS + PAT"

