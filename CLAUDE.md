# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Marketing site for **AutoLeaf Displays** (digital menu boards for Dutch coffeeshops), served at https://autoleaf.nl. Static Astro 6 site styled with Tailwind CSS v4. All site copy is in **Dutch** (`lang="nl"`, dates formatted with `nl-NL`).

## Commands

```sh
npm install
npm run dev       # dev server at localhost:4321
npm run build     # static build to ./dist/
npm run preview   # serve the built site
```

There are no tests or linters configured. `npm run build` is the only check; run it to verify changes compile.

## Deployment

Pushing to `main` triggers `.github/workflows/deploy.yml`, which runs `npm ci && npm run build` and publishes `dist/` to GitHub Pages (custom domain from `public/CNAME`). Build output is never committed.

## Architecture

- `src/layouts/Layout.astro` — the shared shell: `<head>` (canonical, Open Graph, optional JSON-LD via `jsonLd`/`organization` props; the `| AutoLeaf Displays` title suffix is dropped when the title would exceed 60 chars), sticky nav (desktop + mobile menu toggle via inline `style.display`), footer. Nav items and active-link matching are defined in the `navItems` array here.
- `src/layouts/BlogPost.astro` — wraps markdown posts in `Layout`, renders frontmatter header (the only H1 — don't start post bodies with `# Title`), BlogPosting/BreadcrumbList JSON-LD, tags, a "Lees ook" list of recent posts, and contact CTA; also holds global `.blog-content` table styles.
- `src/pages/*.astro` — top-level pages (home, functies, integraties, contact, privacy).
- `src/styles/global.css` — Tailwind import, brand color tokens in `@theme` (`forest`, `leaf`, `leaf-light`, `mint`, `cream`, …, usable as `bg-forest`, `text-leaf`, etc.), and shared component classes (`btn-primary`, `hero`, `section-cream`, `blog-card`, …). Responsive show/hide uses custom `hide-on-desktop` / `show-on-desktop` classes rather than Tailwind's `hidden md:flex`.
- Internal links are built from `import.meta.env.BASE_URL` normalized to a trailing-slash `base` variable; follow that pattern for new links.
- Static assets (logos, favicons, `menu-preview.jpg` which doubles as the og:image) live in `public/`. Homepage carousel screenshots live in `src/assets/screenshots/` and are served as WebP srcsets via `<Image>`.
- Inter is self-hosted via `@fontsource-variable/inter` (no Google Fonts).
- `@astrojs/sitemap` generates `sitemap-index.xml` (excluding `/shows/`); `public/robots.txt` points to it.

### Blog

- Posts are `.md` files in `src/pages/blog/` with frontmatter:
  ```yaml
  layout: ../../layouts/BlogPost.astro
  title: "..."
  description: "..."
  date: YYYY-MM-DD
  tags: ["...", "..."]
  ```
- `src/pages/blog/index.astro` discovers posts via `import.meta.glob('./*.md')` and sorts by `date`. Posts **must be `.md`** (not `.astro`/`.mdx`) to appear in the index.
- Posts may embed raw HTML/`<script>` — e.g. the Germany post loads Chart.js from jsDelivr for an inline chart.

### Shows album (`/shows/`)

Unlisted fullscreen photo carousel shared directly with customers. It's not in the nav, has a `noindex` meta tag and is blocked in `public/robots.txt`. Photos are dropped in `src/assets/shows/` and optimized to WebP srcsets at build time via `getImage()`. They are sorted by filename (numeric-aware, so use `01-…` prefixes) and split into Liggend/Staand sets by their pixel dimensions. `src/pages/shows/index.astro` is standalone (it doesn't use `Layout.astro`) to maximize screen space. Swiping is native CSS scroll-snap. Its "Demo" button links to `/contact/?demo=1`, which prefills the contact message. `src/assets/shows/sources.json` records which price-list URL each screenshot came from; use the `add-show-image` skill (`.claude/skills/add-show-image/`) to add or replace screenshots.

### Forms

Contact form (`contact.astro`) and the newsletter signup (`blog/index.astro`) both POST to Formspree (`https://formspree.io/f/mkokrkdl`); there is no backend.
