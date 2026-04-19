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

You are preparing a pull request for the user. Execute the full sequence: prepare the branch, draft the cover page, get the user's approval, push the branch, and hand off the GitHub compare URL with the pre-filled body. Do not skip the approval step.

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
- **On `main` with unpushed commits ahead of origin/main:** follow-up-to-unpushed-PR convention left work on local main. To open the PR, migrate:
  1. Propose a branch name derived from the dominant commit theme (e.g., commits around the main menu → `feature/main-menu`). Confirm with the user before proceeding.
  2. `git checkout -b <branch>` — creates the feature branch at current HEAD.
  3. `git checkout main && git reset --hard origin/main` — rewinds local main to match upstream. Commits are preserved on the feature branch. Confirm this reset with the user before running it.
  4. `git checkout <branch>` — continue on the feature branch.
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

If relevant screenshots exist:

1. Ask which to include (default: all that match the PR's scope).
2. Upload each:
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

## Step 6 — Review with the user

Show the drafted title and body in chat (rendered as it will appear on GitHub). Ask: "Ship with this, or edit?" **Wait for approval.** Make any requested edits before pushing.

## Step 7 — Push the branch

```bash
git push -u origin <branch>
```

If push fails (network, auth, non-fast-forward, etc.), show the error, stop, and don't print the compare URL yet.

## Step 8 — Hand off

Print a final message with these three pieces clearly separated so the user can copy them into GitHub:

1. **Compare URL:** `https://github.com/<owner>/<repo>/compare/main...<branch>?expand=1` (tell them to open it).
2. **Title** (ready to paste).
3. **Body** — inside a fenced code block so it's one copy-paste into the PR description field.

Also remind them: if any ntfy-hosted screenshots are embedded, drag-drop the PNGs from `screenshots/` into the web UI after creating the PR for permanent GitHub-hosted copies (ntfy URLs expire in ~3 hours).

## Arguments

Freeform `$ARGUMENTS` may include hints — use them as overrides rather than asking again:

- A proposed branch name (e.g., "branch=feature/main-menu").
- "--no-screenshots" → skip the screenshot step entirely.
- A title override in quotes → use as-is.

Otherwise: derive everything from the commit history, conversation, and user confirmation.
