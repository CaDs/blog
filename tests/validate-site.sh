#!/bin/bash
# Hugo Site Validation Tests
# Run with: ./tests/validate-site.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

warn() {
    echo -e "${YELLOW}⚠ WARN${NC}: $1"
}

info() {
    echo -e "  INFO: $1"
}

echo "========================================"
echo "Hugo Site Validation Tests"
echo "========================================"
echo ""

# Change to project root
cd "$(dirname "$0")/.."
PROJECT_ROOT=$(pwd)

# ===========================================
# 1. Configuration Tests
# ===========================================
echo "--- Configuration Tests ---"

# Check hugo.toml exists
if [[ -f "hugo.toml" ]]; then
    pass "hugo.toml exists"
else
    fail "hugo.toml not found"
fi

# Validate TOML syntax
if command -v python3 &> /dev/null; then
    if python3 -c "import tomllib; tomllib.load(open('hugo.toml', 'rb'))" 2>/dev/null || \
       python3 -c "import toml; toml.load('hugo.toml')" 2>/dev/null; then
        pass "hugo.toml has valid TOML syntax"
    else
        # Try with tomli for older Python
        if python3 -c "import tomli; tomli.load(open('hugo.toml', 'rb'))" 2>/dev/null; then
            pass "hugo.toml has valid TOML syntax"
        else
            warn "Could not validate TOML syntax (missing toml library)"
        fi
    fi
fi

# Check baseURL is set correctly
if grep -q "baseURL = 'https://cads-tech.dev/'" hugo.toml; then
    pass "baseURL is correctly set to https://cads-tech.dev/"
else
    fail "baseURL is not correctly configured"
fi

# Check theme is configured
if grep -q "theme = 'hugo-bearblog'" hugo.toml; then
    pass "Theme is configured"
else
    fail "Theme is not configured in hugo.toml"
fi

echo ""

# ===========================================
# 2. Directory Structure Tests
# ===========================================
echo "--- Directory Structure Tests ---"

REQUIRED_DIRS=(
    "archetypes"
    "content"
    "content/blog"
    "static"
    "themes/hugo-bearblog"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        pass "Directory exists: $dir"
    else
        fail "Missing directory: $dir"
    fi
done

echo ""

# ===========================================
# 3. Template Tests
# ===========================================
echo "--- Template Tests ---"

# Check theme templates exist
REQUIRED_TEMPLATES=(
    "themes/hugo-bearblog/layouts/_default/baseof.html"
    "themes/hugo-bearblog/layouts/_default/list.html"
    "themes/hugo-bearblog/layouts/_default/single.html"
    "themes/hugo-bearblog/layouts/partials/header.html"
    "themes/hugo-bearblog/layouts/partials/footer.html"
)

for template in "${REQUIRED_TEMPLATES[@]}"; do
    if [[ -f "$template" ]]; then
        pass "Template exists: $template"
    else
        fail "Missing template: $template"
    fi
done

# Check local layout overrides
LOCAL_OVERRIDES=(
    "layouts/partials/custom_head.html"
    "layouts/partials/footer.html"
)

for override in "${LOCAL_OVERRIDES[@]}"; do
    if [[ -f "$override" ]]; then
        pass "Layout override exists: $override"
    else
        warn "Missing layout override: $override"
    fi
done

echo ""

# ===========================================
# 4. Content Tests
# ===========================================
echo "--- Content Tests ---"

# Check for required content files
REQUIRED_CONTENT=(
    "content/_index.md"
    "content/blog/_index.md"
)

for content in "${REQUIRED_CONTENT[@]}"; do
    if [[ -f "$content" ]]; then
        pass "Content file exists: $content"
    else
        fail "Missing content file: $content"
    fi
done

# Check for at least one blog post
POST_COUNT=$(find content/blog -name "*.md" -not -name "_index.md" | wc -l)
if [[ $POST_COUNT -gt 0 ]]; then
    pass "Found $POST_COUNT blog post(s)"
else
    fail "No blog posts found in content/blog/"
fi

# Validate front matter in posts (TOML format with +++ delimiters)
for post in content/blog/*.md; do
    if [[ -f "$post" && "$post" != *"_index.md" ]]; then
        if head -1 "$post" | grep -q "^+++$"; then
            pass "Valid front matter start in $(basename $post)"
        else
            fail "Invalid front matter in $(basename $post)"
        fi
    fi
done

echo ""

# ===========================================
# 5. Static Assets Tests
# ===========================================
echo "--- Static Assets Tests ---"

if [[ -f "static/favicon.svg" ]]; then
    pass "Favicon exists"
else
    warn "Favicon not found"
fi

if [[ -f "static/_headers" ]]; then
    pass "Cloudflare _headers file exists"
else
    warn "_headers file not found"
fi

echo ""

# ===========================================
# 6. Hugo Build Test (if Hugo is available)
# ===========================================
echo "--- Build Tests ---"

if command -v hugo &> /dev/null; then
    info "Hugo version: $(hugo version)"

    # Test build
    if hugo --minify -d /tmp/hugo-test-build 2>/dev/null; then
        pass "Hugo build succeeded"

        # Check output files
        if [[ -f "/tmp/hugo-test-build/index.html" ]]; then
            pass "index.html generated"
        else
            fail "index.html not generated"
        fi

        if [[ -f "/tmp/hugo-test-build/index.xml" ]]; then
            pass "RSS feed generated"
        else
            fail "RSS feed not generated"
        fi

        if [[ -f "/tmp/hugo-test-build/sitemap.xml" ]]; then
            pass "Sitemap generated"
        else
            fail "Sitemap not generated"
        fi

        # Cleanup
        rm -rf /tmp/hugo-test-build
    else
        fail "Hugo build failed"
    fi
else
    warn "Hugo not installed - skipping build tests"
    info "Install Hugo to run build tests: https://gohugo.io/installation/"
fi

echo ""

# ===========================================
# Summary
# ===========================================
echo "========================================"
echo "Test Summary"
echo "========================================"
echo -e "${GREEN}Passed${NC}: $TESTS_PASSED"
echo -e "${RED}Failed${NC}: $TESTS_FAILED"
echo ""

if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
