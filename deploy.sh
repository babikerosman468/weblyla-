#!/data/data/com.termux/files/usr/bin/bash
# deploy_weblyla.sh - push to GitHub, deploy to Vercel, and open page
set -e

REPO_DIR=~/gitlyla
PROD_URL="https://weblyla-nngy4tr7n-babikerosmans-projects.vercel.app"
GITHUB_USER="babikerosman468"
GITHUB_REPO="weblyla-.git"

cd "$REPO_DIR"
echo "==> In repo folder: $REPO_DIR"

# --- Step 1: Security check - ensure PAT is not exposed in config ---
echo "==> Checking for exposed PAT in git config..."
if git remote -v | grep -q "ghp_"; then
    echo "⚠️  WARNING: PAT token found in git remote URL!"
    echo "==> Removing current remote to secure your token..."
    git remote remove origin
    git remote add origin "https://github.com/$GITHUB_USER/${GITHUB_REPO%.git}"
    echo "✅ Remote URL secured"
fi

# --- Step 2: Use PAT from environment variable securely ---
if [[ -n "$GITHUB_PAT" ]]; then
    echo "==> Using PAT from environment variable securely"
    git remote set-url origin "https://$GITHUB_USER:$GITHUB_PAT@github.com/$GITHUB_USER/${GITHUB_REPO%.git}"
else
    echo "❌ GITHUB_PAT environment variable not set!"
    echo "Please set your GitHub PAT first:"
    echo "export GITHUB_PAT=\"your_personal_access_token_here\""
    exit 1
fi

# --- Step 3: Verify remote URL (without exposing PAT) ---
echo "==> Remote URL configured:"
git remote -v | sed 's/ghp_[^@]*/***REDACTED***/g'

# --- Step 4: Stage all changes ---
git add .
echo "==> All changes staged"

# --- Step 5: Commit changes if any ---
if git diff --cached --quiet; then
    echo "==> No changes to commit"
else
    git commit -m "Auto commit: deploy to Vercel $(date '+%Y-%m-%d %H:%M:%S')"
    echo "==> Changes committed"
fi

# --- Step 6: Pull remote changes with rebase ---
echo "==> Pulling latest changes from GitHub..."
if git pull --rebase origin main; then
    echo "✅ Successfully pulled and rebased"
else
    echo "❌ Rebase conflict or error occurred!"
    echo "==> Resolve conflicts manually and run:"
    echo "git rebase --continue"
    echo "Then run this script again."
    exit 1
fi

# --- Step 7: Push to GitHub ---
echo "==> Pushing to GitHub..."
if git push origin main; then
    echo "✅ Successfully pushed to GitHub"
else
    echo "❌ Push failed! Attempting with force push (not recommended)..."
    read -p "Force push? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git push --force-with-lease origin main
        echo "✅ Force push completed"
    else
        echo "❌ Push aborted by user"
        exit 1
    fi
fi

# --- Step 8: Remove PAT from remote URL for security ---
echo "==> Securing remote URL by removing PAT..."
git remote set-url origin "https://github.com/$GITHUB_USER/${GITHUB_REPO%.git}"
echo "✅ Remote URL secured"

# --- Step 9: Deploy to Vercel production ---
echo "==> Deploying to Vercel production..."
if vercel --prod --yes; then
    echo "✅ Successfully deployed to Vercel production"
    echo "🌐 Production URL: $PROD_URL"
else
    echo "❌ Vercel deployment failed!"
    echo "Check your Vercel configuration and try again."
    exit 1
fi

# --- Step 10: Open deployed page automatically ---
echo "==> Opening deployed website..."
if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$PROD_URL"
elif command -v termux-open-url >/dev/null 2>&1; then
    termux-open-url "$PROD_URL"
else
    echo "⚠️  Could not automatically open browser"
    echo "Please open manually: $PROD_URL"
fi

echo "🎉 Deployment completed successfully!"
echo "📊 Check your website at: $PROD_URL"

