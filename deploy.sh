#!/data/data/com.termux/files/usr/bin/bash
# deploy_weblyla.sh - push to GitHub, deploy to Vercel, and open page
set -e

REPO_DIR=~/gitlyla
PROD_URL="https://weblyla-nngy4tr7n-babikerosmans-projects.vercel.app"

cd "$REPO_DIR"
echo "==> In repo folder: $REPO_DIR"

# --- Step 1: Use PAT from environment variable ---
if [[ -n "$GITHUB_PAT" ]]; then
    git remote set-url origin "https://babikerosman468:$GITHUB_PAT@github.com/babikerosman468/weblyla-.git"
    echo "==> Using PAT from environment variable"
fi

# --- Step 2: Stage all changes ---
git add .
echo "==> All changes staged"

# --- Step 3: Commit changes if any ---
if git diff --cached --quiet; then
    echo "==> No changes to commit"
else
    git commit -m "Auto commit: deploy to Vercel"
    echo "==> Changes committed"
fi

# --- Step 4: Pull remote changes with rebase ---
git pull --rebase origin main || {
    echo "==> Rebase conflict! Resolve manually and run 'git rebase --continue'"
    exit 1
}

# --- Step 5: Push to GitHub ---
git push -u origin main
echo "✅ Pushed to GitHub"

# --- Step 6: Deploy to Vercel production ---
vercel --prod
echo "✅ Deployed to Vercel production: $PROD_URL"

# --- Step 7: Open deployed page automatically ---
xdg-open "$PROD_URL" 2>/dev/null || termux-open-url "$PROD_URL"
echo "🌐 Website opened in browser"

