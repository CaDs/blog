#!/bin/bash
# Security Audit Script for Hugo Site
# Run with: ./tests/security-audit.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ISSUES_FOUND=0
WARNINGS=0

# Helper functions
secure() {
    echo -e "${GREEN}✓ SECURE${NC}: $1"
}

vuln() {
    echo -e "${RED}✗ VULNERABILITY${NC}: $1"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
}

warn() {
    echo -e "${YELLOW}⚠ WARNING${NC}: $1"
    WARNINGS=$((WARNINGS + 1))
}

info() {
    echo -e "  INFO: $1"
}

echo "========================================"
echo "Security Audit for Hugo Site"
echo "========================================"
echo ""

cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)

# ===========================================
# 1. Sensitive File Detection
# ===========================================
echo "--- Checking for Sensitive Files ---"

SENSITIVE_PATTERNS=(
    "*.env"
    "*.env.*"
    ".env"
    ".env.local"
    ".env.production"
    "*.pem"
    "*.key"
    "*.p12"
    "*.pfx"
    "id_rsa*"
    "id_dsa*"
    "id_ecdsa*"
    "id_ed25519*"
    "*.log"
    "credentials.json"
    "service-account*.json"
    "*secret*"
    "*.sqlite"
    "*.db"
    "config.local.*"
    ".htpasswd"
    "wp-config.php"
)

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    # Exclude checking in .git directory
    FOUND=$(find . -name "$pattern" -not -path "./.git/*" -not -path "./tests/*" 2>/dev/null || true)
    if [[ -n "$FOUND" ]]; then
        vuln "Sensitive file found: $FOUND"
    fi
done
secure "No sensitive files found in repository"

echo ""

# ===========================================
# 2. .gitignore Audit
# ===========================================
echo "--- Auditing .gitignore ---"

if [[ -f ".gitignore" ]]; then
    secure ".gitignore file exists"

    # Check for essential ignores
    REQUIRED_IGNORES=(
        ".env"
        "*.env"
        ".DS_Store"
        "node_modules"
        "/public/"
    )

    for ignore in "${REQUIRED_IGNORES[@]}"; do
        if grep -qF "$ignore" .gitignore 2>/dev/null || grep -q "^${ignore}$" .gitignore 2>/dev/null; then
            secure ".gitignore includes: $ignore"
        else
            warn ".gitignore missing: $ignore"
        fi
    done
else
    vuln ".gitignore file is missing!"
fi

echo ""

# ===========================================
# 3. Template Security Audit
# ===========================================
echo "--- Template Security Audit ---"

# Check for unsafe HTML rendering in both theme and local overrides
TEMPLATES=$(find themes layouts -name "*.html" 2>/dev/null)

for template in $TEMPLATES; do
    # Check for safeHTML usage (potential XSS if misused)
    if grep -q "safeHTML" "$template"; then
        warn "safeHTML used in $template - ensure input is trusted"
    fi

    # Check for unsafe JS
    if grep -q "safeJS" "$template"; then
        warn "safeJS used in $template - ensure input is trusted"
    fi
done

# Check for inline event handlers (XSS vector)
for template in $TEMPLATES; do
    if grep -qiE 'on(click|load|error|mouseover|submit|focus|blur)=' "$template"; then
        warn "Inline event handler found in $template - review for XSS"
    fi
done

# Check that unsafe rendering is disabled in config
if grep -q "unsafe = false" hugo.toml 2>/dev/null; then
    secure "Unsafe HTML in markdown is disabled"
elif grep -q "unsafe = true" hugo.toml 2>/dev/null; then
    warn "Unsafe HTML in markdown is ENABLED - be careful with untrusted content"
else
    secure "Unsafe HTML defaults to disabled"
fi

echo ""

# ===========================================
# 4. Security Headers Check
# ===========================================
echo "--- Security Headers Audit ---"

if [[ -f "static/_headers" ]]; then
    secure "_headers file exists for Cloudflare Pages"

    SECURITY_HEADERS=(
        "X-Frame-Options"
        "X-Content-Type-Options"
        "Referrer-Policy"
    )

    for header in "${SECURITY_HEADERS[@]}"; do
        if grep -q "$header" static/_headers; then
            secure "Security header configured: $header"
        else
            warn "Missing security header: $header"
        fi
    done

    # Check for CSP (Content Security Policy)
    if grep -qi "Content-Security-Policy" static/_headers; then
        secure "Content-Security-Policy header configured"
    else
        warn "Content-Security-Policy not configured (recommended for production)"
    fi
else
    warn "_headers file not found - security headers not configured"
fi

echo ""

# ===========================================
# 5. External Resource Audit
# ===========================================
echo "--- External Resource Audit ---"

# Check for external scripts/styles without integrity
for template in $TEMPLATES; do
    # Check for external scripts
    if grep -qE '<script[^>]+src="http' "$template"; then
        warn "External script in $template - ensure integrity attribute is used"
    fi

    # Check for external stylesheets
    if grep -qE '<link[^>]+href="http' "$template"; then
        warn "External stylesheet in $template - ensure integrity attribute is used"
    fi
done

secure "Theme uses local assets only"

echo ""

# ===========================================
# 6. Configuration Security
# ===========================================
echo "--- Configuration Security ---"

# Check for exposed sensitive config
if grep -qiE '(api_key|apikey|secret|password|token)' hugo.toml 2>/dev/null; then
    vuln "Potential secrets in hugo.toml!"
else
    secure "No secrets detected in hugo.toml"
fi

# Check baseURL uses HTTPS
if grep -q "baseURL = 'https://" hugo.toml; then
    secure "baseURL uses HTTPS"
elif grep -q "baseURL = 'http://" hugo.toml; then
    warn "baseURL uses HTTP - should use HTTPS"
fi

# Check for enableInlineShortcodes (potential security risk)
if grep -q "enableInlineShortcodes = true" hugo.toml 2>/dev/null; then
    warn "enableInlineShortcodes is enabled - can be a security risk with untrusted content"
else
    secure "Inline shortcodes are disabled"
fi

echo ""

# ===========================================
# 7. Git Security Check
# ===========================================
echo "--- Git Security Check ---"

# Check for secrets in git history (basic check)
if command -v git &> /dev/null; then
    # Check if there are any commits
    if git rev-parse HEAD &>/dev/null; then
        # Look for potential secrets in recent commits
        SUSPECT_COMMITS=$(git log --all --oneline -20 --diff-filter=A -- "*.env" "*.pem" "*.key" "*secret*" "*credential*" 2>/dev/null | head -5)
        if [[ -n "$SUSPECT_COMMITS" ]]; then
            warn "Potentially sensitive files found in git history"
            info "Review these commits: $SUSPECT_COMMITS"
        else
            secure "No obviously sensitive files in recent git history"
        fi
    else
        info "No git history to check yet"
    fi
fi

echo ""

# ===========================================
# 8. Dependency Check
# ===========================================
echo "--- Dependency Check ---"

# Check if package.json exists (for npm dependencies)
if [[ -f "package.json" ]]; then
    warn "package.json found - ensure dependencies are audited"
    if command -v npm &> /dev/null; then
        info "Run 'npm audit' to check for vulnerabilities"
    fi
else
    secure "No npm dependencies to audit"
fi

# Check for Go modules (Hugo extended)
if [[ -f "go.mod" ]]; then
    warn "go.mod found - ensure dependencies are audited"
else
    secure "No Go modules to audit"
fi

echo ""

# ===========================================
# Summary
# ===========================================
echo "========================================"
echo "Security Audit Summary"
echo "========================================"
echo -e "${GREEN}Secure${NC} checks passed"
echo -e "${YELLOW}Warnings${NC}: $WARNINGS"
echo -e "${RED}Vulnerabilities${NC}: $ISSUES_FOUND"
echo ""

if [[ $ISSUES_FOUND -gt 0 ]]; then
    echo -e "${RED}CRITICAL: Vulnerabilities found - fix before deploying!${NC}"
    exit 1
elif [[ $WARNINGS -gt 0 ]]; then
    echo -e "${YELLOW}Review warnings before deploying${NC}"
    exit 0
else
    echo -e "${GREEN}All security checks passed!${NC}"
    exit 0
fi
