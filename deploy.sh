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

# Get the deployment URL (you might need to adjust this based on vercel output)
DEPLOY_URL="https://weblyla-nngy4tr7n-babikerosmans-projects.vercel.app"

echo "✅ Deployment complete!"
echo "🌍 Your site is live at: $DEPLOY_URL"

# Open the website in default browser
echo "🌐 Opening website..."
if command -v termux-open-url > /dev/null 2>&1; then
    # Termux environment
    termux-open-url "$DEPLOY_URL"
elif command -v xdg-open > /dev/null 2>&1; then
    # Linux environments
    xdg-open "$DEPLOY_URL"
elif command -v open > /dev/null 2>&1; then
    # macOS
    open "$DEPLOY_URL"
elif command -v start > /dev/null 2>&1; then
    # Windows (if running in Windows subsystem)
    start "$DEPLOY_URL"
else
    echo "⚠️  Could not automatically open browser. Please visit: $DEPLOY_URL"
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
