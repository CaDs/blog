# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Hugo static site blog ("CaDs Tech") deployed to Cloudflare Pages at `cads-tech.dev`. Uses the `hugo-bearblog` theme (Git submodule). Requires Hugo Extended v0.140.2+.

## Commands

```bash
# Local development (includes draft posts)
hugo server -D

# Build for production
hugo --minify

# Create a new blog post
hugo new content/blog/my-post-title.md

# Run site validation tests
bash tests/validate-site.sh

# Run security audit
bash tests/security-audit.sh

# Deploy (handled by GitHub Actions on push to main, or manual)
# Requires CLOUDFLARE_API_TOKEN and CLOUDFLARE_ACCOUNT_ID secrets
```

## Architecture

- **Hugo static site** with `hugo-bearblog` theme (submodule in `themes/hugo-bearblog/`)
- **Deployment**: Cloudflare Pages via GitHub Actions (`.github/workflows/deploy.yml`), configured in `wrangler.jsonc`
- **CI pipeline** (`.github/workflows/ci.yml`): validates structure, runs security audit, builds site, checks HTML and internal links
- **Content** lives in `content/` — blog posts go in `content/blog/`. Permalink pattern: `/:slug/`
- **Static assets** in `static/` — includes Cloudflare `_headers` (security headers, caching) and `_redirects`
- **Archetypes** in `archetypes/default.md` — template for `hugo new` with frontmatter: title, date, draft, description, tags, categories
- **Hugo config** in `hugo.toml` — taxonomies disabled (bearblog style), Monokai syntax highlighting
- **Layout overrides** in `layouts/partials/` — custom `header.html`, `footer.html` (social links), and `custom_head.html` (Google Fonts, CSS overrides) that override the theme's defaults
- **Design**: forced dark-mode only (black `#000` background, white text, `#82acdf` link color). All styling lives in `custom_head.html` via CSS custom properties

## Content Conventions

Blog post frontmatter uses TOML (`+++` delimiters) with fields: `title`, `date`, `draft`, `description`, `tags`, `categories`. New posts are created as drafts by default.

## Git Conventions

- **Never** add a `Co-Authored-By` trailer to commit messages.
