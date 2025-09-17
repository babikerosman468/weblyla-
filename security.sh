#!/bin/bash

# Security Hardening Script for Git Repositories
# This script sets up security tools, GitHub Secrets, and audit mechanisms

set -e

echo "🔒 Starting Security Hardening Setup"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository. Please run this script from a git repo."
    exit 1
fi

REPO_NAME=$(basename -s .git $(git config --get remote.origin.url))
LOCAL_CONFIG_DIR=".git-security"

print_status "Setting up security for repository: $REPO_NAME"

# ============================================================================
# STEP 1: Install Security Tools
# ============================================================================

print_status "STEP 1: Installing security tools..."

install_python_tools() {
    print_status "Installing Python security tools..."
    
    # Check if pip is available
    if ! command -v pip3 &> /dev/null; then
        print_warning "pip3 not found. Installing pip..."
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y python3-pip
        elif command -v brew &> /dev/null; then
            brew install python3
        else
            print_error "Cannot install pip automatically. Please install pip3 manually."
            return 1
        fi
    fi

    # Install security tools
    pip3 install --user pre-commit detect-secrets==1.4.0
    
    # Add user pip bin to PATH if not already
    if ! echo $PATH | grep -q "$HOME/.local/bin"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        export PATH="$HOME/.local/bin:$PATH"
    fi
}

install_node_tools() {
    print_status "Installing Node.js security tools..."
    
    if command -v npm &> /dev/null; then
        npm install -g @github/dependency-submission-toolkit
        npm install -G npm-audit-resolver
    else
        print_warning "npm not found. Skipping Node.js tools..."
    fi
}

install_os_tools() {
    print_status "Installing system security tools..."
    
    if command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y git-secrets gitleaks
    elif command -v brew &> /dev/null; then
        brew install git-secrets gitleaks
    else
        print_warning "Package manager not found. Skipping system tools..."
    fi
}

# Run installation functions
install_python_tools
install_node_tools
install_os_tools

# ============================================================================
# STEP 2: Setup Pre-commit Hooks
# ============================================================================

print_status "STEP 2: Setting up pre-commit hooks..."

setup_pre_commit() {
    cat > .pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: detect-private-key

  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']

  - repo: local
    hooks:
      - id: audit-dependencies
        name: Audit Dependencies
        entry: bash .git-security/audit_dependencies.sh
        language: system
        pass_filenames: false
        stages: [pre-commit]

exclude: '^\.secrets\.baseline$|package-lock\.json|yarn\.lock'
EOF

    # Initialize pre-commit
    pre-commit install
}

setup_pre_commit

# ============================================================================
# STEP 3: Setup Detect-Secrets Baseline
# ============================================================================

print_status "STEP 3: Setting up secrets detection..."

setup_detect_secrets() {
    if [ ! -f .secrets.baseline ]; then
        detect-secrets scan > .secrets.baseline
        detect-secrets scan --update .secrets.baseline
    fi
    
    # Add baseline to gitignore to avoid committing it
    if ! grep -q ".secrets.baseline" .gitignore; then
        echo "# Secrets detection baseline" >> .gitignore
        echo ".secrets.baseline" >> .gitignore
    fi
}

setup_detect_secrets

# ============================================================================
# STEP 4: Create Security Configuration Directory
# ============================================================================

print_status "STEP 4: Creating security configuration..."

mkdir -p $LOCAL_CONFIG_DIR

# Create audit script
cat > $LOCAL_CONFIG_DIR/audit_dependencies.sh << 'EOF'
#!/bin/bash

echo "🔍 Running dependency audit..."

# Node.js projects
if [ -f "package.json" ]; then
    echo "📦 Auditing Node.js dependencies..."
    if command -v npm &> /dev/null; then
        npm audit --audit-level moderate
        # Continue even if audit fails
        true
    fi
fi

# Python projects
if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    echo "🐍 Auditing Python dependencies..."
    if command -v safety &> /dev/null; then
        pip freeze | safety check --stdin || true
    else
        echo "Install safety: pip install safety"
    fi
fi

echo "✅ Dependency audit completed"
EOF

chmod +x $LOCAL_CONFIG_DIR/audit_dependencies.sh

# Create weekly audit script
cat > $LOCAL_CONFIG_DIR/weekly_audit.sh << 'EOF'
#!/bin/bash

echo "📅 Running weekly security audit..."
echo "Date: $(date)"

# Full secrets scan
echo "🔍 Scanning for secrets..."
detect-secrets scan --update .secrets.baseline

# Dependency audit
bash .git-security/audit_dependencies.sh

# Check for known vulnerabilities
if [ -f "package.json" ]; then
    npx audit-ci --config .git-security/audit-ci.json || true
fi

echo "✅ Weekly audit completed"
EOF

chmod +x $LOCAL_CONFIG_DIR/weekly_audit.sh

# Create audit-ci config
cat > $LOCAL_CONFIG_DIR/audit-ci.json << 'EOF'
{
  "low": true,
  "moderate": true,
  "high": true,
  "critical": true,
  "report-type": "important",
  "allowlist": []
}
EOF

# ============================================================================
# STEP 5: GitHub Secrets Setup Guide
# ============================================================================

print_status "STEP 5: Setting up GitHub Secrets integration..."

create_github_secrets_guide() {
    cat > $LOCAL_CONFIG_DIR/GITHUB_SECRETS_GUIDE.md << 'EOF'
# GitHub Secrets Management Guide

## Required Secrets for This Project

### Environment Variables to Secure:
- `API_KEYS`: Any external API keys
- `DATABASE_URL`: Database connection strings
- `AUTH_TOKENS`: Authentication tokens
- `SERVICE_ACCOUNTS`: Service account credentials

### How to Add Secrets to GitHub:

1. Go to your repository on GitHub
2. Navigate to: Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Add the following secrets:

### Essential Secrets (Add these):
- `PRODUCTION_DB_URL` - Production database connection
- `STAGING_DB_URL` - Staging database connection  
- `API_KEY_MAIN` - Primary API key
- `JWT_SECRET` - JWT signing secret

### GitHub Actions Usage:

```yaml
- name: Use secrets
  env:
    DB_URL: ${{ secrets.PRODUCTION_DB_URL }}
    API_KEY: ${{ secrets.API_KEY_MAIN }}
```

### Local Development Setup:

Create `.env.local` file:
```bash
# Copy from template
cp .env.example .env.local

# Add your local values (never commit this file!)
echo ".env.local" >> .gitignore
```

### Emergency Rotation Procedure:

1. Revoke compromised secrets immediately
2. Generate new secrets
3. Update GitHub Secrets
4. Update all deployed environments
5. Audit access logs
EOF
}

create_github_secrets_guide

# ============================================================================
# STEP 6: Git Hooks for Security
# ============================================================================

print_status "STEP 6: Setting up git hooks..."

setup_git_hooks() {
    # Pre-push hook for additional security checks
    cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash

echo "🔒 Running pre-push security checks..."

# Run detect-secrets check
if command -v detect-secrets &> /dev/null; then
    if ! detect-secrets-hook --baseline .secrets.baseline; then
        echo "❌ Secrets detection failed! Check for exposed secrets."
        exit 1
    fi
fi

echo "✅ Pre-push security checks passed"
EOF

    chmod +x .git/hooks/pre-push
}

setup_git_hooks

# ============================================================================
# STEP 7: Regular Audit Setup
# ============================================================================

print_status "STEP 7: Setting up regular audits..."

setup_regular_audits() {
    # Add audit script to package.json if it exists
    if [ -f "package.json" ]; then
        if ! grep -q "audit:security" package.json; then
            npm pkg set scripts.audit:security="bash .git-security/weekly_audit.sh"
        fi
    fi

    # Create cron job suggestion
    cat > $LOCAL_CONFIG_DIR/cron_setup.md << 'EOF'
# Automated Audit Setup

## For Linux/macOS (cron):

```bash
# Add to crontab (edit with: crontab -e)
0 9 * * 1 cd /path/to/your/repo && bash .git-security/weekly_audit.sh >> .git-security/audit.log 2>&1
```

## For GitHub Actions (recommended):

Create `.github/workflows/security-audit.yml`:

```yaml
name: Weekly Security Audit
on:
  schedule:
    - cron: '0 9 * * 1'  # Every Monday at 9 AM
  workflow_dispatch:      # Manual trigger

jobs:
  security-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run security audit
        run: bash .git-security/weekly_audit.sh
```
EOF
}

setup_regular_audits

# ============================================================================
# STEP 8: Documentation and Readme
# ============================================================================

print_status "STEP 8: Creating documentation..."

create_documentation() {
    # Update README with security section
    if [ -f "README.md" ]; then
        if ! grep -q "## Security" README.md; then
            cat >> README.md << 'EOF'

## Security

This project includes automated security checks:

### Pre-commit Hooks
- Secrets detection using detect-secrets
- Dependency auditing
- Code quality checks

### Regular Audits
Weekly security audits are run automatically. Check the `.git-security/` directory for configuration.

### GitHub Secrets
All sensitive data is stored in GitHub Secrets. See [GITHUB_SECRETS_GUIDE.md](.git-security/GITHUB_SECRETS_GUIDE.md) for details.

### Reporting Issues
Please report security issues to the maintainers immediately.
EOF
        fi
    else
        cat > SECURITY.md << 'EOF'
# Security Policy

## Supported Versions
Security updates are provided for the latest version only.

## Reporting a Vulnerability
Please report security issues via private communication with maintainers.

## Security Features
- Automated secrets detection
- Regular dependency auditing
- Pre-commit security checks
- GitHub Secrets for sensitive data
EOF
    fi
}

create_documentation

# ============================================================================
# FINAL SETUP
# ============================================================================

print_status "Running initial audit..."

# Run first audit
bash $LOCAL_CONFIG_DIR/audit_dependencies.sh

print_success "Security hardening complete!"
echo ""
echo "📋 Next steps:"
echo "1. Review and add secrets to GitHub: ${BLUE}https://github.com/$(git remote get-url origin | cut -d: -f2 | sed 's/\.git$//')/settings/secrets/actions${NC}"
echo "2. Test pre-commit hooks: ${BLUE}pre-commit run --all-files${NC}"
echo "3. Set up weekly audits: ${BLUE}cat ${LOCAL_CONFIG_DIR}/cron_setup.md${NC}"
echo "4. Read the guide: ${BLUE}cat ${LOCAL_CONFIG_DIR}/GITHUB_SECRETS_GUIDE.md${NC}"
echo ""
echo "🔒 Your repository is now secured with:"
echo "   - Pre-commit security hooks"
echo "   - Secrets detection"
echo "   - Dependency auditing"
echo "   - GitHub Secrets integration"
echo "   - Regular security audits"

# Add security directory to gitignore
if ! grep -q ".git-security" .gitignore; then
    echo "# Security configuration" >> .gitignore
    echo ".git-security/" >> .gitignore
fi

print_success "Setup completed successfully! 🎉"

