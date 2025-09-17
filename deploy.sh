#!/data/data/com.termux/files/usr/bin/bash
# Simple deployment script using SSH authentication

echo "🚀 Starting deployment..."

# Check if SSH key is set up
if [ ! -f ~/.ssh/id_rsa ] && [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "❌ ERROR: No SSH key found!"
    echo "Run: ssh-keygen -t ed25519 -C \"your_email@example.com\""
    echo "Then add the public key to your GitHub account:"
    echo "cat ~/.ssh/id_ed25519.pub"
    exit 1
fi

# Test SSH connection to GitHub
echo "🔑 Testing SSH connection to GitHub..."
ssh -T git@github.com > /dev/null 2>&1
if [ $? -ne 1 ]; then
    echo "❌ ERROR: SSH connection to GitHub failed!"
    echo "Make sure:"
    echo "1. Your SSH key is added to GitHub"
    echo "2. SSH agent is running: eval \$(ssh-agent) && ssh-add ~/.ssh/id_ed25519"
    exit 1
fi

cd ~/gitlyla

echo "📦 Adding files to git..."
git add .

echo "💾 Committing changes..."
git commit -m "Update: $(date '+%Y-%m-%d %H:%M')" || echo "No changes to commit"

echo "📡 Pushing to GitHub using SSH..."
git push git@github.com:babikerosman468/weblyla-.git main

echo "🌐 Deploying to Vercel..."
vercel --prod --yes

# Get the deployment URL
DEPLOY_URL="https://weblyla-nngy4tr7n-babikerosmans-projects.vercel.app"

echo "✅ Deployment complete!"
echo "🌍 Your site is live at: $DEPLOY_URL"

# Open the website in Chrome specifically
echo "🌐 Opening website in Chrome..."
if command -v termux-open > /dev/null 2>&1; then
    # Termux environment - try to open in Chrome if available
    termux-open --view --app "com.android.chrome" "$DEPLOY_URL" 2>/dev/null || termux-open "$DEPLOY_URL"
elif command -v google-chrome > /dev/null 2>&1; then
    # Linux with Google Chrome installed
    google-chrome "$DEPLOY_URL" >/dev/null 2>&1 &
elif command -v chromium-browser > /dev/null 2>&1; then
    # Linux with Chromium
    chromium-browser "$DEPLOY_URL" >/dev/null 2>&1 &
elif command -v open > /dev/null 2>&1; then
    # macOS - open with Chrome if available, else default browser
    if open -a "Google Chrome" "$DEPLOY_URL" >/dev/null 2>&1; then
        echo "Opened in Google Chrome"
    else
        open "$DEPLOY_URL"
    fi
elif command -v start > /dev/null 2>&1; then
    # Windows
    start chrome "$DEPLOY_URL" 2>/dev/null || start "$DEPLOY_URL"
else
    echo "⚠️  Could not automatically open Chrome. Please visit: $DEPLOY_URL"
    echo "📱 Or open Chrome manually and go to: $DEPLOY_URL"
fi

# Security check - prevent committing secrets
if [ -f ".env" ]; then
    echo "Checking for potential secrets in .env file..."
    if grep -q -E "(token|key|secret|password)" .env; then
        echo "ERROR: Potential secrets found in .env file. Aborting commit."
        exit 1
    fi
fi

# Check for other secret files
SECRET_FILES=( "pat*" "*.secret" "credentials*" )
for pattern in "${SECRET_FILES[@]}"; do
    if ls $pattern > /dev/null 2>&1; then
        echo "ERROR: Secret files found matching pattern: $pattern"
        exit 1
    fi
done

echo "🎉 All done! Your Lula Support website should now be open in Chrome."

