# Claude Code Skills — harmonic_rogue

Mix of third-party (pinned from `htdt/godogen`) and first-party (written for this repo — see `open-pr`).

The third-party skills are pinned to the **last GDScript commit before the 2026-04-06 C# migration**.

- **Pinned commit:** `71364d6`
- **Commit message:** "Update Tripo3D: add P1-20260311 + v3.1, simplify to two quality presets"
- **Source:** https://github.com/htdt/godogen

## Why pinned

`godogen` migrated from GDScript to C# / .NET 9 on 2026-04-06. This project is GDScript-only (to preserve the RAWRLAB free Switch port fallback — see `/CLAUDE.md`). We need the pre-migration skills, and master cannot be trusted to give us that.

## Skills installed

| Skill | Activates when | Source | Notes |
|---|---|---|---|
| `godogen` | User asks to "make a game" / "build a game" (whole-game generation). | godogen (pinned) | Orchestrator. Rarely triggers — our architecture is hand-directed. Harmless to keep. |
| `godot-api` | Looking up Godot class APIs (methods, properties, signals). | godogen (pinned) | **Critical** — lazy-loaded docs for 754 classes. Prevents Python-idiom hallucinations in GDScript. |
| `visual-qa` | Analyzing game screenshots for defects against a reference. | godogen (pinned) | Complements the Godot MCP Pro screenshot workflow. Uses Gemini Flash by default. |
| `open-pr` | User wants to open a PR for current work. | first-party | End-to-end: branches work, drafts cover page (summary / changes / testing / ntfy-hosted screenshots), pushes, opens PR via `gh pr create`. Returns the PR URL. Requires `gh` (`brew install gh && gh auth login`). |

## Reinstall / refresh procedure

```bash
# 1. Clone godogen at pinned commit
mkdir -p /tmp/godogen-inspect
git clone https://github.com/htdt/godogen.git /tmp/godogen-inspect
cd /tmp/godogen-inspect
git checkout 71364d6

# 2. Replace skills
rm -rf <project>/.claude/skills/{godogen,godot-api,visual-qa}
cp -R /tmp/godogen-inspect/skills/{godogen,godot-api,visual-qa} <project>/.claude/skills/

# 3. Bootstrap godot-api docs (downloads Godot source, regenerates 754 class markdowns)
bash <project>/.claude/skills/godot-api/tools/ensure_doc_api.sh
```

## Fresh-clone bootstrap

`godot-api/doc_source/` and `godot-api/doc_api/` are gitignored (15M + 5.6M, regeneratable). After a fresh clone of this repo, run the bootstrap script:

```bash
bash .claude/skills/godot-api/tools/ensure_doc_api.sh
```

The `godot-api` skill's `SKILL.md` also instructs Claude to run this if `doc_api/` is empty, so it will self-bootstrap on first use.
