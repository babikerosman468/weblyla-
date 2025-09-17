#!/bin/bash

# Fixed GitHub Push Protection Resolution Script
# This script helps resolve GitHub push protection violations caused by exposed secrets

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "This is not a git repository"
        exit 1
    fi
}

# Display the issue
display_issue() {
    log_error "GitHub has blocked your push due to exposed secrets!"
    echo ""
    log_warning "GitHub detected:"
    log_warning "- GitHub Personal Access Token"
    log_warning "In files:"
    log_warning "  - .env:8"
    log_warning "  - pat1:1"
    echo ""
    log_warning "Commit with issue: a3d13d443d988ae5aae5c50c6ad07a9f631a2720"
    echo ""
}

# Step 1: Revoke the exposed token
revoke_tokens() {
    log_info "STEP 1: Revoke exposed tokens"
    echo ""
    log_warning "Immediately revoke your exposed GitHub token:"
    log_info "1. Go to https://github.com/settings/tokens"
    log_info "2. Find the token that was exposed"
    log_info "3. Click the 'Revoke' button next to it"
    echo ""
    read -p "Have you revoked the token? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_error "You must revoke the token before proceeding!"
        exit 1
    fi
    echo ""
    log_success "Token revoked successfully"
    echo ""
}

# Step 2: Remove sensitive files from history
clean_git_history() {
    log_info "STEP 2: Clean git history"
    echo ""
    log_warning "This will permanently remove sensitive files from your git history"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_error "Cannot proceed without cleaning git history"
        exit 1
    fi
    
    # Check if git-filter-repo is installed
    if ! command -v git-filter-repo &> /dev/null; then
        log_info "Installing git-filter-repo..."
        pip install git-filter-repo
    fi
    
    # Remove sensitive files from history
    log_info "Removing sensitive files from git history..."
    git filter-repo --force --invert-paths --path pat1 --path .env
    
    if [ $? -eq 0 ]; then
        log_success "Git history cleaned successfully"
    else
        log_error "Failed to clean git history"
        log_info "Trying alternative method with BFG..."
        clean_with_bfg
    fi
    echo ""
}

# Step 3: Force push the cleaned history
force_push() {
    log_info "STEP 3: Force push cleaned history"
    echo ""
    log_warning "This will overwrite remote history and may affect collaborators"
    read -p "Continue with force push? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_error "Cannot proceed without force push"
        exit 1
    fi
    
    # Check if origin remote exists, add it if it doesn't
    if ! git remote get-url origin > /dev/null 2>&1; then
        log_info "Adding origin remote back..."
        git remote add origin https://github.com/babikerosman468/weblyla-.git
    fi
    
    log_info "Force pushing to remote..."
    git push origin --force --all
    
    if [ $? -eq 0 ]; then
        log_success "Force push completed successfully"
    else
        log_error "Force push failed"
        log_info "Trying to set upstream branch..."
        git push --set-upstream origin main --force
        if [ $? -eq 0 ]; then
            log_success "Force push completed successfully with upstream set"
        else
            log_error "Force push still failed. Please check your remote URL and permissions."
            exit 1
        fi
    fi
    echo ""
}

# Step 4: Set up prevention measures
setup_prevention() {
    log_info "STEP 4: Set up prevention measures"
    echo ""
    
    # Create or update .gitignore
    log_info "Updating .gitignore..."
    if [ ! -f .gitignore ]; then
        touch .gitignore
    fi
    
    # Add common patterns to .gitignore
    if ! grep -q "# Environment variables" .gitignore; then
        cat >> .gitignore << 'EOF'

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Secret files
secrets/
*.secret
pat*
credentials*
*.key
*.pem
EOF
        log_success ".gitignore updated"
    else
        log_info ".gitignore already contains security patterns"
    fi
    
    # Set up pre-commit hooks
    log_info "Setting up pre-commit hooks..."
    if command -v pre-commit &> /dev/null; then
        pre-commit install
        log_success "Pre-commit hooks installed"
    else
        log_warning "pre-commit not installed. Install with: pip install pre-commit"
    fi
    
    # Install detect-secrets
    log_info "Installing detect-secrets..."
    if command -v detect-secrets &> /dev/null; then
        detect-secrets init > .pre-commit-config.yaml
        pre-commit install
        log_success "detect-secrets configured"
    else
        log_warning "detect-secrets not installed. Install with: pip install detect-secrets"
    fi
    echo ""
}

# Step 5: Update deploy script
update_deploy_script() {
    log_info "STEP 5: Update deployment script"
    echo ""
    
    if [ -f "deploy.sh" ]; then
        log_info "Adding security checks to deploy.sh..."
        
        # Add secret check to deploy.sh
        if ! grep -q "secret\|token\|key\|password" deploy.sh; then
            cat >> deploy.sh << 'EOF'

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
EOF
            log_success "Security checks added to deploy.sh"
        else
            log_info "deploy.sh already contains security checks"
        fi
    else
        log_warning "deploy.sh not found. Creating a new secure deploy script..."
        create_secure_deploy_script
    fi
    echo ""
}

# Create a secure deploy script if one doesn't exist
create_secure_deploy_script() {
    cat > deploy.sh << 'EOF'
#!/bin/bash

# Secure Deployment Script
# Includes security checks to prevent committing secrets

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Security check - prevent committing secrets
check_secrets() {
    log_warning "Running security checks..."
    
    # Check .env file for secrets
    if [ -f ".env" ]; then
        echo "Checking .env file for potential secrets..."
        if grep -q -E "(token|key|secret|password)" .env; then
            log_error "Potential secrets found in .env file. Aborting commit."
            exit 1
        fi
    fi

    # Check for other secret files
    SECRET_FILES=( "pat*" "*.secret" "credentials*" )
    for pattern in "${SECRET_FILES[@]}"; do
        if ls $pattern > /dev/null 2>&1; then
            log_error "Secret files found matching pattern: $pattern"
            exit 1
        fi
    done
    
    log_success "Security checks passed"
}

# Main deployment process
echo "🚀 Starting deployment..."

# Run security checks first
check_secrets

echo "📦 Adding files to git..."
git add .

echo "💾 Committing changes..."
git commit -m "Update: $(date +'%Y-%m-%d %H:%M')"

echo "📡 Pushing to GitHub..."
git push origin main

echo "🌐 Deploying to Vercel..."
# Add your Vercel deployment command here

echo "✅ Deployment complete!"
EOF
    
    chmod +x deploy.sh
    log_success "Secure deploy.sh created"
}

# Final verification
final_verification() {
    log_info "FINAL VERIFICATION"
    echo ""
    
    log_info "Checking if secrets are still present in history..."
    if git log --oneline -n 10 | grep -q "a3d13d4"; then
        log_warning "The problematic commit might still be in history"
    else
        log_success "Problematic commit not found in recent history"
    fi
    
    log_info "Verifying .gitignore contains security patterns..."
    if grep -q -E "(\.env|pat\*|secret)" .gitignore; then
        log_success ".gitignore properly configured"
    else
        log_warning ".gitignore might need additional security patterns"
    fi
    
    log_info "Testing if sensitive files are excluded..."
    if [ -f ".env" ]; then
        log_warning ".env file exists - make sure it's in .gitignore"
    fi
    
    echo ""
    log_success "Verification complete!"
    echo ""
}

# Setup SSH agent for authentication
setup_ssh_agent() {
    log_info "Setting up SSH authentication..."
    
    # Start SSH agent if not running
    if [ -z "$SSH_AUTH_SOCK" ]; then
        eval "$(ssh-agent -s)" > /dev/null 2>&1
    fi
    
    # Try to add SSH key
    if [ -f "$HOME/.ssh/id_rsa" ]; then
        ssh-add "$HOME/.ssh/id_rsa" 2>/dev/null
    elif [ -f "$HOME/.ssh/id_ed25519" ]; then
        ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null
    else
        log_warning "No SSH key found. You may need to set up SSH authentication for GitHub."
        log_info "See: https://docs.github.com/en/authentication/connecting-to-github-with-ssh"
    fi
}

# Main execution
main() {
    echo ""
    log_info "GitHub Push Protection Resolution Script"
    log_info "========================================"
    echo ""
    
    check_git_repo
    display_issue
    revoke_tokens
    clean_git_history
    force_push
    setup_ssh_agent
    setup_prevention
    update_deploy_script
    final_verification
    
    echo ""
    log_success "All steps completed successfully!"
    log_info "Next steps:"
    log_info "1. Store secrets as environment variables or use GitHub Secrets"
    log_info "2. Consider using a password manager for development secrets"
    log_info "3. Regularly audit your code for accidental secret exposure"
    echo ""
    
    # Test deployment
    log_info "Testing deployment..."
    if [ -f "deploy.sh" ]; then
        chmod +x deploy.sh
        ./deploy.sh
    fi
}

# Run main function
main "$@"

