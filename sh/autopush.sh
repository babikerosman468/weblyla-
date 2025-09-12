
#!/data/data/com.termux/files/usr/bin/bash
# autopush.sh - automatically stage, commit, pull, and push using stored PAT

set -e

REPO_DIR=~/gitlyla
cd "$REPO_DIR"
echo "==> In repo folder: $REPO_DIR"

# --- Step 1: Use PAT from environment variable if available ---
if [[ -n "$GITHUB_PAT" ]]; then
    REMOTE_URL="https://babikerosman468:$GITHUB_PAT@github.com/babikerosman468/weblyla-.git"
    git remote set-url origin "$REMOTE_URL"
    echo "==> Using PAT from environment variable"
else
    echo "==> No environment variable GITHUB_PAT found, using existing remote"
fi

# --- Step 2: Stage all changes ---
git add .
echo "==> All local changes staged"

# --- Step 3: Commit changes ---
if git diff --cached --quiet; then
    echo "==> No staged changes to commit"
else
    git commit -m "Auto commit: staged changes before pull"
    echo "==> Changes committed"
fi

# --- Step 4: Pull remote changes with rebase ---
echo "==> Pulling remote changes with rebase..."
git pull --rebase origin main || {
    echo "==> Rebase failed due to conflicts. Resolve manually and run 'git rebase --continue'"
    exit 1
}

# --- Step 5: Push to remote ---
git push -u origin main
echo "✅ All local changes pushed to GitHub repo weblyla-"

