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

- `src/layouts/Layout.astro` — the shared shell: `<head>`, sticky nav (desktop + mobile menu toggle via inline `style.display`), footer. Nav items and active-link matching are defined in the `navItems` array here.
- `src/layouts/BlogPost.astro` — wraps markdown posts in `Layout`, renders frontmatter header, tags, and contact CTA; also holds global `.blog-content` table styles.
- `src/pages/*.astro` — top-level pages (home, functies, integraties, contact).
- `src/styles/global.css` — Tailwind import, brand color tokens in `@theme` (`forest`, `leaf`, `leaf-light`, `mint`, `cream`, …, usable as `bg-forest`, `text-leaf`, etc.), and shared component classes (`btn-primary`, `hero`, `section-cream`, `blog-card`, …). Responsive show/hide uses custom `hide-on-desktop` / `show-on-desktop` classes rather than Tailwind's `hidden md:flex`.
- Internal links are built from `import.meta.env.BASE_URL` normalized to a trailing-slash `base` variable; follow that pattern for new links.
- Static assets (logos, carousel screenshots `public/screenshots/slide-N.jpg`, favicons) live in `public/`.

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

### Forms

Contact form (`contact.astro`) and the newsletter signup (`blog/index.astro`) both POST to Formspree (`https://formspree.io/f/mkokrkdl`); there is no backend.
