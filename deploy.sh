#!/data/data/com.termux/files/usr/bin/bash
# deploy_weblyla.sh - secure deployment script with .env support
set -e

REPO_DIR=~/gitlyla
ENV_FILE="$REPO_DIR/.env"

# --- Function to load environment variables ---
load_env() {
    if [[ -f "$ENV_FILE" ]]; then
        echo "==> Loading environment variables from $ENV_FILE"
        # Safely load environment variables, excluding comments and empty lines
        while IFS='=' read -r key value || [[ -n "$key" ]]; do
            # Skip comments and empty lines
            if [[ $key =~ ^[[:space:]]*# ]] || [[ -z "$key" ]]; then
                continue
            fi
            # Remove quotes and export the variable
            value="${value%%#*}"  # Remove inline comments
            value="${value%"${value##*[![:space:]]}"}"  # Trim trailing whitespace
            value="${value#\"}"   # Remove leading double quote
            value="${value%\"}"   # Remove trailing double quote
            value="${value#\'}"   # Remove leading single quote
            value="${value%\'}"   # Remove trailing single quote
            export "$key=$value"
        done < <(grep -v '^[[:space:]]*$' "$ENV_FILE" | grep -v '^#')
    else
        echo "❌ .env file not found at $ENV_FILE"
        echo "Please create .env file with your configuration"
        exit 1
    fi
}

# --- Function to validate required variables ---
validate_env() {
    local required_vars=("GITHUB_PAT" "GITHUB_USER" "GITHUB_REPO")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        echo "❌ Missing required environment variables:"
        printf ' - %s\n' "${missing_vars[@]}"
        echo "Please check your .env file"
        exit 1
    fi
    
    # Set default VERCEL_PROD_URL if not provided
    if [[ -z "$VERCEL_PROD_URL" ]]; then
        VERCEL_PROD_URL="https://${GITHUB_REPO}-$(echo $GITHUB_USER | tr '[:upper:]' '[:lower:]').vercel.app"
    fi
}

# --- Function to secure remote URL ---
secure_remote_url() {
    local current_url=$(git remote get-url origin 2>/dev/null || echo "")
    if [[ "$current_url" == *"ghp_"* ]]; then
        echo "⚠️  Securing remote URL (removing PAT exposure)..."
        git remote set-url origin "https://github.com/$GITHUB_USER/$GITHUB_REPO.git"
    fi
}

# --- Main execution ---
cd "$REPO_DIR"
echo "==> Starting deployment from: $REPO_DIR"

# Load and validate environment variables
load_env
validate_env

echo "==> Using repository: $GITHUB_USER/$GITHUB_REPO"
echo "==> Production URL: $VERCEL_PROD_URL"

# --- Step 1: Secure current remote configuration ---
secure_remote_url

# --- Step 2: Set temporary remote URL with PAT ---
echo "==> Setting secure temporary remote URL..."
git remote set-url origin "https://$GITHUB_USER:$GITHUB_PAT@github.com/$GITHUB_USER/$GITHUB_REPO.git"

# --- Step 3: Verify remote URL (redacted for security) ---
echo "==> Remote URL configured (PAT redacted):"
git remote -v | sed 's/ghp_[^@]*/***REDACTED***/g'

# --- Step 4: Stage all changes ---
git add .
echo "==> All changes staged"

# --- Step 5: Commit changes if any ---
if git diff --cached --quiet; then
    echo "==> No changes to commit"
else
    git commit -m "Auto deploy: $(date '+%Y-%m-%d %H:%M:%S')"
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
    # Secure remote before exiting
    secure_remote_url
    exit 1
fi

# --- Step 7: Push to GitHub ---
echo "==> Pushing to GitHub..."
if git push origin main; then
    echo "✅ Successfully pushed to GitHub"
else
    echo "❌ Push failed!"
    # Secure remote before exiting
    secure_remote_url
    exit 1
fi

# --- Step 8: Secure remote URL after push ---
secure_remote_url
echo "✅ Remote URL secured"

# --- Step 9: Deploy to Vercel production ---
echo "==> Deploying to Vercel production..."
if vercel --prod --yes; then
    echo "✅ Successfully deployed to Vercel production"
    echo "🌐 Production URL: $VERCEL_PROD_URL"
else
    echo "❌ Vercel deployment failed!"
    echo "Check your Vercel configuration and try again."
    exit 1
fi

# --- Step 10: Open deployed page automatically ---
echo "==> Opening deployed website..."
if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$VERCEL_PROD_URL" 2>/dev/null && echo "✅ Browser opened" || echo "⚠️  Could not open browser"
elif command -v termux-open-url >/dev/null 2>&1; then
    termux-open-url "$VERCEL_PROD_URL" && echo "✅ Browser opened" || echo "⚠️  Could not open browser"
else
    echo "⚠️  Could not automatically open browser"
    echo "Please open manually: $VERCEL_PROD_URL"
fi

echo "🎉 Deployment completed successfully!"
echo "📊 Website: $VERCEL_PROD_URL"
EOF

