#!/data/data/com.termux/files/usr/bin/bash
# autopush.sh
# Automatically stage, commit, pull (rebase), and push to weblyla- using HTTPS + PAT

set -e

REPO_DIR=~/gitlyla
cd "$REPO_DIR"
echo "==> In repo folder: $REPO_DIR"

# --- Step 1: Ask for GitHub PAT ---
read -sp "Enter your GitHub PAT: " NEWPAT
echo

# --- Step 2: Update remote URL with PAT ---
git remote set-url origin https://babikerosman468:${NEWPAT}@github.com/babikerosman468/weblyla-.git
echo "==> Remote updated with HTTPS + PAT"

# --- Step 3: Stage all changes ---
git add .
echo "==> All local changes staged"

# --- Step 4: Commit changes ---
if git diff --cached --quiet; then
    echo "==> No staged changes to commit"
else
    git commit -m "Auto commit: staged changes before pull"
    echo "==> Changes committed"
fi

# --- Step 5: Pull remote changes with rebase ---
echo "==> Pulling remote changes with rebase..."
git pull --rebase origin main || {
    echo "==> Rebase failed due to conflicts. Resolve manually and run 'git rebase --continue'"
    exit 1
}

# --- Step 6: Push to remote ---
git push -u origin main
echo "✅ All local changes pushed to GitHub repo weblyla-"

