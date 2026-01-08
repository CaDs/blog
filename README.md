# CaDs Tech Blog

A tech blog built with [Hugo](https://gohugo.io/) and deployed on [Cloudflare Pages](https://pages.cloudflare.com/).

## Local Development

### Prerequisites

- [Hugo Extended](https://gohugo.io/installation/) (v0.112.0 or later)

### Running Locally

```bash
# Clone the repository
git clone <your-repo-url>
cd blog

# Start the development server
hugo server -D

# The site will be available at http://localhost:1313
```

### Creating New Content

```bash
# Create a new blog post
hugo new posts/my-new-post.md
```

### Building for Production

```bash
hugo --minify
```

The built site will be in the `public/` directory.

## Deployment to Cloudflare Pages

### Initial Setup

1. **Connect Repository**: Go to [Cloudflare Pages](https://dash.cloudflare.com/?to=/:account/pages) and click "Create a project"

2. **Select Repository**: Connect your GitHub/GitLab account and select this repository

3. **Configure Build Settings**:
   - **Framework preset**: Hugo
   - **Build command**: `hugo --minify`
   - **Build output directory**: `public`
   - **Environment variable**: `HUGO_VERSION` = `0.140.2`

4. **Deploy**: Click "Save and Deploy"

### Custom Domain Setup

1. Go to your Pages project in Cloudflare dashboard
2. Navigate to "Custom domains"
3. Add `cads-tech.dev`
4. Since your domain is already on Cloudflare, DNS will be configured automatically

### Environment Variables

| Variable | Value | Description |
|----------|-------|-------------|
| `HUGO_VERSION` | `0.140.2` | Hugo version to use for builds |

## Project Structure

```
blog/
├── archetypes/         # Content templates
├── content/            # Markdown content
│   ├── posts/          # Blog posts
│   └── about.md        # About page
├── static/             # Static files (images, etc.)
├── themes/
│   └── cads-theme/     # Custom theme
└── hugo.toml           # Hugo configuration
```

## Theme Features

- Responsive design
- Dark/Light mode toggle
- Syntax highlighting
- Reading time estimates
- Table of contents
- SEO optimized
- RSS feed

## License

MIT License
