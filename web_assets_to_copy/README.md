# Web SEO/meta files

`flutter create .` generates a generic `web/index.html` with placeholder
title/meta tags. After running it, copy the files from this folder over
the generated ones in `web/` to get real SEO basics (checklist items:
meta titles/descriptions, social preview image, favicon, sitemap/robots.txt).

- `index_head_snippet.html` — paste this INTO `web/index.html`'s `<head>`,
  replacing the placeholder `<title>` and meta tags Flutter generates.
- `robots.txt` — copy to `web/robots.txt`.
- Favicon / social preview image: Flutter's default `web/favicon.png` and
  `web/icons/*` are placeholder Flutter logos — replace them with Pair's
  actual icon before deploying. A 1200x630px image named `social-preview.png`
  referenced in the head snippet below covers the "social preview image" item.
