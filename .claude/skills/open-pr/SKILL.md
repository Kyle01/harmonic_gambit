---
name: open-pr
description: |
  Push current work to a feature branch, draft a PR cover page (summary,
  changes, testing, screenshots), and hand off the GitHub compare URL +
  pre-filled body for the user to paste into the web UI. Classic git only —
  no `gh` CLI.
---

# Open PR

$ARGUMENTS

You are preparing a pull request for the user. Execute the full sequence end-to-end without stopping for approval: prepare the branch, draft the cover page, push the branch, and hand off the GitHub compare URL with the pre-filled body. The user reviews on GitHub, not in chat — your job is to make that review possible as quickly as possible.

Use best judgment for decisions the skill historically asked the user about (branch name, which screenshots to include, title wording). Only stop if you genuinely can't proceed — working tree dirty, no commits to push, push fails, etc.

## Why no `gh` CLI

The user prefers classic git. Do **not** `brew install gh`, do **not** call `gh pr create`. The deliverable is a pushed branch + the compare URL + a PR body the user pastes into GitHub's web form.

## Step 1 — Determine the PR source branch

```bash
git branch --show-current
git status --short
git log --oneline origin/main..HEAD
```

Branch rules (per `feedback_dev_workflow.md`):

- **Working tree dirty:** tell the user to commit or stash first. Stop — do not auto-stash.
- **On a `feature/*` / `fix/*` / `docs/*` / `chore/*` branch with commits ahead of origin/main:** use it as-is.
- **On `main` with unpushed commits ahead of origin/main:** follow-up-to-unpushed-PR convention left work on local main. Migrate without asking:
  1. Pick a branch name derived from the dominant commit theme (e.g., commits around the main menu → `feature/main-menu`). Prefix: `feature/` for new features, `fix/` for bugfixes, `docs/` for docs-only, `chore/` for tooling/cleanup. Use best judgment.
  2. If a branch with that name already exists **and is stale** (its tip is reachable from current HEAD or from origin/main already), delete it with `git branch -D` and recreate at HEAD. If the name is taken by unrelated in-progress work, pick a different name with a `-v2` or date suffix.
  3. `git checkout -b <branch>` — creates the feature branch at current HEAD.
  4. `git checkout main && git reset --hard origin/main` — rewinds local main to match upstream. Safe because the commits are preserved on the feature branch.
  5. `git checkout <branch>` — continue on the feature branch.
- **No commits ahead of origin/main:** nothing to PR. Stop.

## Step 2 — Gather PR scope

```bash
git log origin/main..HEAD --format="%h%n%s%n%b%n---"
git diff --stat origin/main...HEAD
```

Then inspect the **current conversation** for:

- What features this work adds and **why** (summary / motivation).
- **What was actually tested:** `gdparse` / `gdlint` runs, Godot MCP Pro interactions (`play_scene`, `get_game_screenshot`, `click_button_by_text`, `simulate_action`, etc.), any manual verifications.
- Any local screenshots:
  ```bash
  ls screenshots/*.png 2>/dev/null
  ```

Do not invent testing that didn't happen. If something wasn't tested, say so in the PR body.

## Step 3 — Handle screenshots

`screenshots/` is gitignored (per `feedback_screenshots_ephemeral.md`). To show them in the PR cover page, upload to ntfy.sh and embed the URLs inline. The user will later drag-drop the PNGs into the PR web UI for permanent GitHub-hosted copies.

If relevant screenshots exist, include them without asking — default is all that match the PR's scope, use judgment to drop obvious duplicates or noise. If `screenshots/` is empty but the PR is a UI feature, regenerate 1–3 representative screenshots via Godot MCP Pro (`play_scene` → `get_game_screenshot save_path="res://screenshots/<name>.png"` → `stop_scene`) before uploading.

Upload each:
   ```bash
   set -a; source ~/.config/harmonic_rogue/ntfy.conf; set +a
   curl -sS -T <local-path> \
     -H "Filename: <display-name>.png" \
     "$NTFY_SERVER/$NTFY_TOPIC"
   ```
3. Parse the JSON response for `attachment.url` and collect URLs.
4. Embed inline as `![caption](<ntfy-url>)` in the PR body.

ntfy.sh free tier stores files ~3h — fine for the user's immediate review, and the drag-drop step gives permanence. If there are no relevant screenshots, omit the section.

## Step 4 — Resolve owner/repo for the compare URL

```bash
git remote get-url origin
```

Parse to `https://github.com/<owner>/<repo>`. Strip any `.git` suffix. The compare URL the user will paste into their browser is:

```
https://github.com/<owner>/<repo>/compare/main...<branch>?expand=1
```

## Step 5 — Draft title and body

**Title:** short, imperative, **≤70 chars**. Do **not** prefix with `feat:` / `fix:` etc. — that's for commit messages, not PR titles. Derive from the dominant theme (e.g., "Main menu with placeholder pages and Switch-friendly display").

**Body template** (omit sections that don't apply):

```markdown
## Summary

- <1–3 bullets. The **why**, not the what. E.g., "Establishes vaporwave × high fantasy theme and a Switch-native 1280×720 base grid before deeper UI work.">

## Changes

- <grouped bullets. If a single-commit PR, this is the commit body. Otherwise categorize by feature area.>

## Testing

- `gdparse` + `gdlint`: <pass, or specific findings>
- Godot MCP Pro: <what was loaded, what was clicked, what screenshots captured>
- Manual: <anything verified by hand>

## Screenshots

![main menu](<ntfy-url-1>)
![start placeholder](<ntfy-url-2>)

_Screenshots are hosted on ntfy.sh and expire in ~3 hours. Drag-drop the PNGs from `screenshots/` into the PR web UI for permanent GitHub-hosted copies._

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

Do **not** include "Co-Authored-By" lines in the PR body — those belong in commit trailers.

## Step 6 — Push the branch

```bash
git push -u origin <branch>
```

If push fails (network, auth, non-fast-forward, etc.), show the error, stop, and don't print the compare URL yet.

## Step 7 — Hand off

Print a terse final message. The user's next action is to review the PR on GitHub — optimize for them clicking through immediately.

Structure the handoff as:

1. **One-line status:** e.g., "Pushed `feature/main-menu` → open the PR." — keep it under 15 words.
2. **Compare URL** on its own line so it renders as tappable in the Claude Code iOS app: `https://github.com/<owner>/<repo>/compare/main...<branch>?expand=1`
3. **Title** on its own line, ready to paste.
4. **Body** inside a fenced code block so it's one copy-paste into the PR description field.
5. **Footnote** (only if ntfy-hosted screenshots were embedded): "Drag-drop the PNGs from `screenshots/` into the PR web UI after creating the PR — ntfy URLs expire in ~3 hours."

Do **not** ask "anything else?" or re-summarize what was done. The PR page is the user's next context.

## Arguments

Freeform `$ARGUMENTS` may include hints — apply silently without asking:

- A proposed branch name (e.g., "branch=feature/main-menu").
- "--no-screenshots" → skip the screenshot step entirely.
- A title override in quotes → use as-is.

Otherwise: derive everything from the commit history and conversation.
