#!/data/data/com.termux/files/usr/bin/bash
# Simple deployment script

echo "🚀 Starting deployment..."

# Check if PAT is set
if [ -z "$GITHUB_PAT" ]; then
    echo "❌ ERROR: GITHUB_PAT not set!"
    echo "Run: export GITHUB_PAT='your_pat_here'"
    exit 1
fi

# Check PAT length
if [ ${#GITHUB_PAT} -ne 40 ]; then
    echo "❌ ERROR: PAT should be 40 characters, got ${#GITHUB_PAT}"
    exit 1
fi

cd ~/gitlyla

echo "📦 Adding files to git..."
git add .

echo "💾 Committing changes..."
git commit -m "Update: $(date '+%Y-%m-%d %H:%M')" || echo "No changes to commit"

echo "📡 Pushing to GitHub..."
git push https://babikerosman468:$GITHUB_PAT@github.com/babikerosman468/weblyla-.git main

echo "🌐 Deploying to Vercel..."
vercel --prod --yes

echo "✅ Deployment complete!"
echo "🌍 Your site is live at: https://weblyla-nngy4tr7n-babikerosmans-projects.vercel.app"
