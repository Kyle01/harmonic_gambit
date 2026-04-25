# Getting started

A walkthrough from a fresh clone to a working dev loop, plus pointers to the optional AI-driven content pipelines this project uses.

## Prerequisites

- **Godot 4.6+** (standard build, not .NET) — <https://godotengine.org/download>. The .NET build is unsupported here: this project is GDScript-only so the RAWRLAB free-Switch-port path stays available (see [`docs/gdd.md`](gdd.md#platforms)).
- **Python 3.9+** with [`gdtoolkit`](https://github.com/Scony/godot-gdscript-toolkit):
  ```sh
  pip install gdtoolkit
  ```
  Provides `gdparse`, `gdlint`, `gdformat`. CI gates merges on these passing.
- **Git** — branch-per-feature workflow, no direct commits to `main`.

No other dependencies. No C#, no GDExtension, no native addons — this is a hard rule.

## First run

```sh
git clone <repo-url>
cd harmonic_rogue
godot .                                              # open in the editor
godot --path . res://scenes/ui/main_menu.tscn        # or run the menu directly
```

The main scene is `scenes/ui/main_menu.tscn` — a "Gambits & Grooves" title screen with five buttons (Start, Catalog, Options, Credits, ADMIN). Each routes to a placeholder; every placeholder has a Back button.

For combat-loop work, open `scenes/levels/test_arena.tscn` in the editor and press F6 ("Play Scene"). It's a minimal arena with one player, one goblin, and the shared-timer combat wired through.

Viewport is **1280×720** (Switch handheld native) with `canvas_items` stretch + `keep` aspect — scales cleanly to docked Switch (1920×1080) and desktop, letterboxes on non-16:9.

## Validate before committing

Run all three on every staged `.gd` file. CI rejects the branch otherwise.

```sh
FILES=$(git ls-files '*.gd' | grep -v '^addons/')
echo "$FILES" | xargs gdparse            # syntax
echo "$FILES" | xargs gdlint             # style — must hand-fix failures
echo "$FILES" | xargs gdformat --check   # formatting — drop --check to auto-fix
```

CI (`.github/workflows/validate.yml`) runs the same trio plus a Godot headless import (`godot --headless --import --quit`) to catch broken scene/resource links. Merge is blocked on failure.

`.github/workflows/ai-review.yml` posts an advisory OpenAI review comment on every PR (re-runs on every push). Observations only — never blocks merge.

## Working with Claude Code

[Claude Code](https://claude.com/claude-code) is the **preferred coding agent** for this project. Two things to know up front:

- The repo ships with [`CLAUDE.md`](../CLAUDE.md) at the root — the AI-agent contract: hard rules, forbidden actions, the validation gate, branch workflow, PR hygiene. Claude Code auto-loads it. If you use a different agent, point it at that file. Skim it once yourself either way — the rules apply to humans too.
- The optional MCP servers below extend Claude Code with editor / pixel-art / sprite-gen / audio-gen tools. They aren't required — you can do everything by hand — but they're how the project's content pipelines are designed to flow.

## Optional: AI-driven content pipelines (MCPs)

These MCPs make the content loop hands-free under Claude Code. None are required to play, build, or contribute. Each links out to its vendor — install instructions drift, so vendor docs are the source of truth.

### Godot MCP Pro

- **What it does:** editor bridge — `play_scene`, screenshots, scene / script ops directly from the agent.
- **Why we use it:** the visual-verify gate. Lint and parse passing is necessary but not sufficient; the project policy is to run the game and confirm a feature looks right before claiming done. See [`CLAUDE.md`](../CLAUDE.md) § Testing Workflow.

### Aseprite MCP Pro

- **What it does:** Aseprite scripting + Godot export — produces ready-to-import `SpriteFrames.tres`, palette tooling, batch export.
- **Why we use it:** sprite assets land in `assets/sprites/` already shaped for Godot. See [`docs/architecture.md`](architecture.md) for where sprite resources live in the data layer.

### PixelLab

- **What it does:** AI sprite + tileset generation (characters, animations, top-down / side-scroller / isometric tilesets).
- **Why we use it:** first-pass character art and tilesets, especially for the 12 instrument-archetypes. Read [`docs/world.md`](world.md) for the visual canon — what the Realm is and isn't — before generating.

### ElevenLabs

- **What it does:** music + SFX generation (`compose_music`, `text_to_sound_effects`).
- **Why we use it:** the soundtrack is the game's third pillar. Prompt structure, the diegesis rule, and the instrument-archetype mapping live in [`docs/sound_design.md`](sound_design.md). Read it before generating any audio.

## Dev flow

1. **Branch.** Off `main` as `feature/<slug>` or `docs/<slug>`. Never commit directly to `main`.
2. **Code.** Edit; stage explicit paths (`git add path/to/file.gd`) — never `git add -A` or `git add .`.
3. **Validate locally.** Run the `gdparse` / `gdlint` / `gdformat --check` trio. Fix what they flag — don't `--no-verify`.
4. **Visual-verify.** For non-trivial scene or resource changes, open the scene in Godot (or via Godot MCP Pro) and confirm the feature behaves as expected.
5. **Push and open a PR.** Fill out the cover page — Summary (what + why) and Test plan (how it was verified). One PR, one digestible unit of value.
6. **Wait for CI.** `validate.yml` blocks merge; `ai-review.yml` is advisory only. A human merges — never auto-merge.

Full contract — branch rules, forbidden actions, PR hygiene — is in [`CLAUDE.md`](../CLAUDE.md).

## Where to go next

| Doc | What it's for |
|---|---|
| [`docs/gdd.md`](gdd.md) | Game design — pillars, combat timing, run structure, open questions |
| [`docs/architecture.md`](architecture.md) | Code architecture — three-layer rules, autoloads, signal contract, Resource schemas |
| [`docs/sound_design.md`](sound_design.md) | Music + SFX — philosophy, diegesis rule, ElevenLabs recipes |
| [`docs/world.md`](world.md) | World brief — the Realm, archetypes, visual canon |
| [`CLAUDE.md`](../CLAUDE.md) | AI-agent contract — hard constraints, forbidden actions, validation gate |
