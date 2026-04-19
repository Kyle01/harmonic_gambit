---
name: open-pr
description: |
  Push current work to a feature branch and open a GitHub pull request
  end-to-end: branches, drafts a cover page (summary, changes, testing,
  screenshots), pushes, and creates the PR via `gh`. Returns the PR URL
  so the user can jump straight to reviewing on GitHub.
---

# Open PR

$ARGUMENTS

You are opening a pull request for the user, fully. Execute the full sequence end-to-end without stopping for approval: prepare the branch, draft the cover page, push, **create the PR with `gh pr create`**, and return the PR URL. The user reviews on GitHub, not in chat — your job is to put them on the PR page as quickly as possible.

Use best judgment for decisions the skill historically asked the user about (branch name, which screenshots to include, title wording). Only stop if you genuinely can't proceed — working tree dirty, no commits to push, push fails, `gh` missing or unauthenticated.

## Step 0 — Verify `gh`

```bash
gh --version && gh auth status
```

If `gh` is missing or unauthenticated, stop and tell the user exactly this:

> `gh` is required to open the PR. Install and auth: `brew install gh && gh auth login` (pick GitHub.com → HTTPS → "Login with a web browser"). Then rerun `/open-pr`.

Do **not** try to install or authenticate `gh` yourself.

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

`screenshots/` is gitignored (per `feedback_screenshots_ephemeral.md`). To show them in the PR cover page, upload to ntfy.sh and embed the URLs inline. The user will drag-drop the PNGs into the PR web UI later for permanent GitHub-hosted copies.

If relevant screenshots exist, include them without asking — default is all that match the PR's scope; use judgment to drop obvious duplicates or noise. If `screenshots/` is empty but the PR is a UI feature, regenerate 1–3 representative captures via Godot MCP Pro (`play_scene` → `get_game_screenshot save_path="res://screenshots/<name>.png"` → `stop_scene`) before uploading.

Upload each:

```bash
set -a; source ~/.config/harmonic_rogue/ntfy.conf; set +a
curl -sS -T <local-path> \
  -H "Filename: <display-name>.png" \
  "$NTFY_SERVER/$NTFY_TOPIC"
```

Parse the JSON response for `attachment.url` and collect URLs. Embed inline as `![caption](<ntfy-url>)` in the PR body.

ntfy.sh free tier stores files ~3h — fine for the user's immediate review; the drag-drop step gives permanence. If there are no relevant screenshots, omit the section.

## Step 4 — Draft title and body

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

## Step 5 — Push the branch

```bash
git push -u origin <branch>
```

If push fails (network, auth, non-fast-forward, etc.), show the error and stop — do not attempt `gh pr create` on an un-pushed branch.

## Step 6 — Create the PR with `gh`

```bash
gh pr create \
  --base main \
  --head <branch> \
  --title "<title>" \
  --body "$(cat <<'EOF'
<body here>
EOF
)"
```

`gh` returns the PR URL on success. If it fails:

- **Branch already has an open PR:** run `gh pr edit <branch> --title "..." --body "..."` to update the existing one and use `gh pr view <branch> --json url -q .url` to get the URL.
- **Auth error:** tell the user to run `gh auth login` and stop.
- **Other:** show the error output and stop.

## Step 7 — Hand off

Print a terse final message. The user's next action is to review the PR on GitHub — optimize for them clicking through immediately.

Structure the handoff as:

1. **One-line status:** e.g., "Opened PR #<n> on `feature/main-menu`." — under 15 words.
2. **PR URL** (returned by `gh pr create`) on its own line so it renders as tappable in the Claude Code iOS app.
3. **Footnote** (only if ntfy-hosted screenshots were embedded): "Drag-drop the PNGs from `screenshots/` into the PR web UI — ntfy URLs expire in ~3 hours."

Do **not** re-paste the title and body in chat after success (the PR page is the canonical view) and do **not** ask "anything else?".

## Arguments

Freeform `$ARGUMENTS` may include hints — apply silently without asking:

- A proposed branch name (e.g., "branch=feature/main-menu").
- `--no-screenshots` → skip the screenshot step entirely.
- `--draft` → pass `--draft` to `gh pr create`.
- A title override in quotes → use as-is.

Otherwise: derive everything from the commit history and conversation.
