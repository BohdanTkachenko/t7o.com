# AGENTS.md

Guidance for AI coding agents (Claude Code, Cursor, Copilot, Aider, etc.) working in this repository.

## Project

`t7o.com` is the owner's personal blog, built with [Zola](https://www.getzola.org/) (a Rust-based static site generator). Content focus: personal projects, especially open-source work.

Layout (standard Zola 0.22+): `zola.toml` (config), `content/` (Markdown posts with TOML frontmatter), `templates/` (Tera), `static/`, `sass/`, `themes/`.

## Theme

The site uses [austere-theme-zola](https://github.com/tomwrw/austere-theme-zola). It is **not** a git submodule — it is a Nix flake input (`austere-theme` in `flake.nix`, `flake = false`) symlinked to `themes/austere` by the devShell's `shellHook`. The symlink is gitignored; the theme version is pinned in `flake.lock`.

- To update the theme: `nix flake update austere-theme` then re-enter the shell (or `direnv reload`).
- To edit theme files: don't. `themes/austere` points into the read-only Nix store. Override by adding a file at the same path under the project root (e.g. `templates/index.html` to override the theme's `index.html`) — Zola resolves project files before theme files.

### Existing theme overrides

- `templates/base.html` — fork of the theme's base template. Changes vs. upstream: (1) guards `100 / items_per_row` division when `menu_links` is empty (upstream divides by zero → NaN → build error); (2) hides the empty `<nav>` and its preceding `<hr>` when `menu_links` is empty; (3) replaces the two inline `<style>` blocks with `<link rel="stylesheet" href="…/style.css">`, because we moved styling to SCSS; (4) replaces the inline theme-toggle script with `<script src="/js/theme.js">`; (5) replaces the inline site-icon SVG with `<span class="site-icon">` whose shape comes from `/icons/site.svg` via CSS `mask-image`; (6) replaces the inline lightbox script with `<script defer src="/js/lightbox.js">`. When updating the theme, re-diff against the upstream `base.html` and re-apply these patches.

## Styles

All styles live in `sass/style.scss`, which Zola compiles to `/style.css` (`compile_sass = true` in `zola.toml`). Colors are SCSS variables at the top of that file — edit them there, not in `zola.toml`. The theme's original `[extra.colours.*]` config is not used; the theme's internal `<style>` blocks are bypassed by the `base.html` override above.

## Static assets

`static/` passes through to `public/` unchanged:

- `static/icons/site.svg` — site logo, used as a CSS `mask-image` so it still tints with `--accent`.
- `static/js/theme.js` — light/dark toggle. Loaded **synchronously** in `<head>` because it sets the initial `html.className` before paint; making it `defer` would cause a FOUC on first paint.
- `static/js/lightbox.js` — article-image click-to-expand. Loaded with `defer`.

## Development Environment

This project uses a Nix flake with a devShell (`flake.nix`) and direnv (`.envrc`).

To add a new tool, add it to `devPackages` in `flake.nix` and run `refresh`. Do not use `nix run` or `nix shell` for project tooling — keep everything in the devShell. Use `nix run` only for one-off commands that don't belong in the devShell permanently.

## Commands

- `zola serve` — local dev server with live reload (default `http://127.0.0.1:1111`)
- `zola build` — render the static site into `public/`
- `zola check` — validate internal links and the content tree without building
- `nix fmt` — format the tree (treefmt: nixfmt for Nix, taplo for TOML, prettier for Markdown/CSS/SCSS/JS, `xmllint --format` for SVG). Config lives inline in `flake.nix` under `treefmtEval`. HTML templates are **not** formatted automatically — prettier mangles Tera tags and djlint isn't idempotent on them, so `*.html` is excluded. Format them by hand.
