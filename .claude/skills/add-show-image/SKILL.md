---
name: add-show-image
description: Add or replace price-list screenshots in the unlisted /shows/ photo album. Use when the user gives prijslijst.autoleaf.nl (or other) URLs or image files to add to "de show"/"het album", or asks to redo one with a different aspect ratio.
---

# Add images to the /shows/ album

The album (`src/pages/shows/index.astro`) shows every image in `src/assets/shows/`, sorted by filename and split into **Liggend** (width ≥ height) and **Staand** sets based on pixel size. `src/assets/shows/sources.json` records which URL each screenshot came from.

Helper: `.claude/skills/add-show-image/shot.sh`
- `shot.sh capture <url> <out.png> <portrait|landscape|landscape-1610>`: screenshot at 2× scale (2160×3840, 3840×2160 or 3840×2400). On first run it fetches missing browser libraries and an emoji font into `~/.cache/autoleaf-shot` (no root needed).
- `shot.sh sheet <out.png>`: contact sheet of all current album images with their filenames.

Write temporary screenshots to the session scratchpad, not to the repo.

## Steps

1. **Duplicate check, per URL.**
   - Look up the URL in `sources.json`. Also match on the pricelist UUID plus the trailing screen ID (`/pricelist/<uuid>/landscape/<screen-id>`). Different screen IDs under the same pricelist are different screens. If it matches, tell the user which file it already is and ask whether to replace it. Don't add it twice.
   - Images without an entry in `sources.json` (01–05, 07–10 at the time of writing) have unknown sources. Run `shot.sh sheet`, Read the sheet and compare it with the new screenshot (step 3): same shop header/logo, same categories and products means a duplicate. If unsure, show the user and ask.
   - For an image file the user supplies (not a URL), compare it with the contact sheet the same way.

2. **Pick the orientation.**
   - The URL contains `landscape` → `landscape`. It contains `portrait`/`staand` → `portrait`.
   - Otherwise (for example `/horeca`), capture `landscape` first. Read the result: if the content fills only the top half or is clearly built for a vertical screen, recapture as `portrait`.
   - The user can override this ("staand", "liggend", "16:10").

3. **Capture and inspect.** Run `shot.sh capture`, then Read the PNG and check:
   - **Login wall** (for example "Log in to Vercel"): staging URLs are protected. Ask for the production URL (`prijslijst.autoleaf.nl`) or a bypass link. Never add a login-page screenshot.
   - **Empty boxes instead of emojis** mean the emoji font is missing: re-run, since the bootstrap should fix it.
   - **Overlapping rows** (product names wrapping into the row below) in a landscape shot: recapture with `landscape-1610`. The extra height fixes vertical overlap and often reveals the shop logo at the bottom.
   - **Prices squeezed together horizontally** ("4,7525,65"): font size follows the viewport width, so no aspect ratio fixes it. A narrower ratio (4:3) makes it worse, and a wider one (21:9) cuts off rows. Keep 16:9 or 16:10, and tell the user the fix belongs in the price-list app (smaller font, wider price column).
   - Repeated category headings across columns are how the price list overflows long categories. That's not a capture bug.

4. **Name and place.** The next number is the highest existing prefix + 1, zero-padded: `NN-prijslijst-liggend.png` or `NN-prijslijst-staand.png`. When replacing, keep the existing filename so the album order stays the same. Copy the file into `src/assets/shows/`.

5. **Record the source.** Add or update the entry in `sources.json`: `{ "url", "mode", "captured": "YYYY-MM-DD" }`.

6. **Verify and commit.** Run `npm run build`; the new file should appear in the image optimisation log. Commit the image together with `sources.json` (message in Dutch, like `feat: …prijslijst in shows album`). **Don't push without asking.** Pushing deploys to autoleaf.nl.
   - If `git push` fails with "Permission denied (publickey)", push over HTTPS with the gh login, without changing git config:
     `git -c credential.helper= -c credential.helper='!gh auth git-credential' push https://github.com/virge-creator/autoleaf-site.git main`

7. **Report** which files were added or replaced, their resolution and orientation, and anything you couldn't capture or noticed (login wall, layout problems in the price list itself).
