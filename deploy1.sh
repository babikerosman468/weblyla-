#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# 🚀 UNIVERSAL DEPLOY SCRIPT (Termux + Laptop)
# Author: Dr. Babs
# Purpose: Push local repo → GitHub → Deploy to Vercel → Open site
# Works on: Termux (Android), Linux, macOS, Windows (Git Bash)
# ============================================================

set -e
trap 'echo "❌ Error on line $LINENO. Aborting."; exit 1' ERR

echo "🚀 Starting deployment..."

# --- Detect Environment ---
if [ -d "/data/data/com.termux" ]; then
    PLATFORM="Termux"
else
    PLATFORM=$(uname)
fi
echo "🖥️  Running on: $PLATFORM"

# --- SSH Key Check ---
if [ ! -f ~/.ssh/id_ed25519 ] && [ ! -f ~/.ssh/id_rsa ]; then
    echo "❌ ERROR: No SSH key found!"
    echo "Run:"
    echo "  ssh-keygen -t ed25519 -C \"your_email@example.com\""
    echo "Then add your public key to GitHub:"
    echo "  cat ~/.ssh/id_ed25519.pub"
    exit 1
fi

# --- Test SSH Connection to GitHub ---
echo "🔑 Testing SSH connection to GitHub..."
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "✅ SSH connection successful!"
else
    echo "❌ SSH authentication failed!"
    echo "Make sure your SSH key is added to GitHub and ssh-agent is running:"
    echo "  eval \$(ssh-agent) && ssh-add ~/.ssh/id_ed25519"
    exit 1
fi

# --- Move to repo directory ---
cd ~/gitlyla || { echo "❌ Repo not found at ~/gitlyla"; exit 1; }

# --- Git Operations ---
echo "📦 Adding files..."
git add .

echo "💾 Committing changes..."
git commit -m "Update: $(date '+%Y-%m-%d %H:%M')" || echo "No changes to commit."

# --- Detect Current Branch ---
BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "🌿 Current branch: $BRANCH"

# --- Push to GitHub ---
echo "📡 Pushing changes to GitHub..."
git push git@github.com:babikerosman468/weblyla-.git "$BRANCH"

# --- Deploy to Vercel ---
echo "🌐 Deploying to Vercel..."
if [ -z "$VERCEL_TOKEN" ]; then
    echo "⚠️  No VERCEL_TOKEN found. Deployment may fail if authentication is needed."
fi

DEPLOY_URL=$(vercel --prod --yes --confirm 2>/dev/null | grep -Eo 'https://[^ ]+\.vercel\.app' | tail -n1)
if [ -z "$DEPLOY_URL" ]; then
    DEPLOY_URL="https://weblyla-nngy4tr7n-babikerosmans-projects.vercel.app"
fi
echo "✅ Deployment complete!"
echo "🌍 Your site is live at: $DEPLOY_URL"

# --- Open Website in Chrome ---
echo "🌐 Opening website in Chrome..."
if [ "$PLATFORM" = "Termux" ]; then
    termux-open --view --app "com.android.chrome" "$DEPLOY_URL" 2>/dev/null || termux-open "$DEPLOY_URL"
elif command -v google-chrome >/dev/null 2>&1; then
    google-chrome "$DEPLOY_URL" >/dev/null 2>&1 &
elif command -v chromium-browser >/dev/null 2>&1; then
    chromium-browser "$DEPLOY_URL" >/dev/null 2>&1 &
elif command -v open >/dev/null 2>&1; then
    open -a "Google Chrome" "$DEPLOY_URL" >/dev/null 2>&1 || open "$DEPLOY_URL"
elif command -v start >/dev/null 2>&1; then
    start chrome "$DEPLOY_URL" 2>/dev/null || start "$DEPLOY_URL"
else
    echo "⚠️  Could not automatically open browser."
    echo "Please visit: $DEPLOY_URL"
fi

# --- Secret Check ---
echo "🧩 Checking for secrets..."
if [ -f ".env" ]; then
    if grep -q -E "(token|key|secret|password)" .env; then
        echo "⚠️  WARNING: Sensitive data detected in .env!"
    fi
fi

for pattern in "pat*" "*.secret" "credentials*"; do
    if ls $pattern >/dev/null 2>&1; then
        echo "⚠️  WARNING: Secret files detected ($pattern)"
    fi
done

# --- Deployment Summary ---
echo "---------------------------------------------------"
echo "✅ Deployment Summary"
echo "Repository: $(basename "$(git rev-parse --show-toplevel)")"
echo "Branch: $BRANCH"
echo "Last commit: $(git log -1 --pretty=%B)"
echo "Live URL: $DEPLOY_URL"
echo "---------------------------------------------------"
echo "🎉 All done! Your site should now be live."

