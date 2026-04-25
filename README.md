# harmonic_rogue

> A pixel-art roguelite RPG where combat is a performance: you compose FF12-style gambits, build musical band lineups, and hit rhythm prompts for every action.

> `harmonic_rogue` is a working-directory slug, not the final game title.

**Status:** pre-alpha. Hello-world combat pipeline validated (see commit `5bd0e13`).

## Docs map

| File | What it's for |
|---|---|
| [`docs/getting_started.md`](docs/getting_started.md) | Setup walkthrough — prerequisites, first run, MCPs, dev flow. **Start here if you're new to the repo.** |
| [`docs/gdd.md`](docs/gdd.md) | Game design — vision, pillars, combat timing, run structure. **Start here if you want to understand the game.** |
| [`docs/architecture.md`](docs/architecture.md) | Code architecture — three-layer rules, autoloads, signal contract, Resource schemas. |
| [`CLAUDE.md`](CLAUDE.md) | AI-agent rules — hard constraints, forbidden actions, validation steps. Governs any Claude / AI session working in this repo. |
| [`.github/workflows/`](.github/workflows) | CI — `validate.yml` (blocking lint/parse/headless-import) and `ai-review.yml` (advisory OpenAI review). |

---

## Dev setup

### Required

- **Godot 4.6+ (standard build, not .NET).** Install from <https://godotengine.org/download>.
- **Python 3.9+** with [`gdtoolkit`](https://github.com/Scony/godot-gdscript-toolkit) for GDScript validation:
  ```sh
  pip install gdtoolkit
  ```
  Provides `gdparse`, `gdlint`, `gdformat`.

No other dependencies. No C#, no GDExtension, no native addons — this is a hard rule so the RAWRLAB free-Switch-port fallback stays alive (see [`docs/gdd.md`](docs/gdd.md#platforms)).

### Optional (AI-driven workflow)

- **Godot MCP Pro** — editor-bridge MCP for scene/script manipulation from Claude Code.
- **Aseprite MCP Pro** — pixel-art tool integration; produces Godot-ready `SpriteFrames.tres`.
- **PixelLab MCP** — AI-assisted sprite generation.
- **Claude Code Remote Control** — drive sessions from phone (iOS app).

These are configured in `~/.claude.json` (local scope, auto-approved). The repo works without them; they just make content pipelines hands-free.

→ For a step-by-step walkthrough including MCP setup, see [`docs/getting_started.md`](docs/getting_started.md).

---

## Run the game

```sh
# open in the Godot editor
godot .

# or run the main scene directly
godot --path . res://scenes/ui/main_menu.tscn
```

The main scene is `scenes/ui/main_menu.tscn` — the "Gambits & Grooves" title screen with five buttons (Start, Catalog, Options, Credits, ADMIN). Each routes to a placeholder page via `get_tree().change_scene_to_file()`; every placeholder has a Back button that returns to the menu.

Viewport is **1280×720** (Switch handheld native) with `canvas_items` stretch + `keep` aspect — scales cleanly to docked Switch (1920×1080) and desktop, letterboxes on non-16:9.

`scenes/levels/test_arena.tscn` is still in the tree — a minimal arena with one player, one goblin, and the shared-timer combat loop wired through. Run it via the editor's "Play Scene" (F6) for combat-loop dev work.

---

## Validate before committing

```sh
FILES=$(git ls-files '*.gd' | grep -v '^addons/')
echo "$FILES" | xargs gdparse            # syntax
echo "$FILES" | xargs gdlint             # style
echo "$FILES" | xargs gdformat --check   # formatting (drop --check to auto-fix)
```

CI (`.github/workflows/validate.yml`) runs the same three checks plus a Godot headless import on every PR and blocks merge on failure. `.github/workflows/ai-review.yml` posts an advisory OpenAI review comment on each PR (re-runs on every push); observations only, never blocks merge.

For non-trivial scene or resource changes: open the scene in Godot (via MCP or manually), screenshot, visually verify. Type/lint passing is necessary but not sufficient — **run the game** and confirm the feature works before claiming a task is done.

---

## Project layout

```
assets/
  sprites/{characters,enemies,items,tilesets,ui}/   # art (PixelLab → Aseprite → .tres)
  audio/
  fonts/    # alagard.ttf (title display), silkscreen.ttf (UI body)

scenes/
  actors/   # player.tscn, goblin.tscn, etc. — paired with per-scene .gd
  levels/   # test_arena.tscn and future combat/map scenes
  ui/       # main_menu.tscn, *_placeholder.tscn, rhythm_prompt.tscn, …
  events/ items/

scripts/
  autoload/   # global singletons — EventBus, RNG, GameState, TurnManager, etc.
  components/ # small single-responsibility actor components (planned)
  systems/    # pure logic modules
  data/       # class_name'd Resource schemas (no logic): GambitDef, Card, EnemyDef, …

resources/   # .tres instances filling those schemas: actual gambits, enemies, events, cards

docs/        # design + architecture docs
```

---

## Commit discipline

- Small, frequent commits. One logical change per commit.
- Imperative messages with type prefixes: `feat:` / `fix:` / `chore:` / `refactor:` / `docs:` / `test:`.
- Never `git add -A` or `git add .` — stage explicit paths.
- Never `--no-verify` to bypass hooks. Fix the underlying issue.

See [`CLAUDE.md`](CLAUDE.md) for the complete AI-agent contract and forbidden actions.
