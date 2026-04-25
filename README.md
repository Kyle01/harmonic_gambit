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

## Generating music

Composed (non-combat) tracks are data-driven: each track has a sibling `*.spec.md` next to its audio file, and `tools/generate_music.py` renders the world music context (`docs/music.md`) plus the spec into a single ElevenLabs prompt, calls the API, and writes the audio + `.import` sidecar + `.generated.json` provenance.

### One-time setup

```sh
python -m venv .venv
source .venv/bin/activate                # zsh/bash; .venv\Scripts\activate on Windows
pip install -r tools/requirements.txt
cp .env.example .env                     # then edit .env and paste your ElevenLabs key
```

`.env` is gitignored — never committed. Get a key from <https://elevenlabs.io>.

### Add a new track

1. Copy an existing spec as a template:
   ```sh
   cp assets/audio/music/theme.spec.md assets/audio/music/<new>.spec.md
   ```
2. Edit the frontmatter (`path`, `loop`, `length_sec`, `context`) and the body (role, mood, prompt body, anti-patterns). Read `docs/music.md` first — palette and contrastive NOTs apply to every track.
3. Dry-run to see the rendered prompt without spending credits:
   ```sh
   python tools/generate_music.py --spec assets/audio/music/<new>.spec.md --dry-run
   ```
4. Generate for real:
   ```sh
   python tools/generate_music.py --spec assets/audio/music/<new>.spec.md
   ```
5. Wire the track into `scripts/autoload/music_director.gd` if it needs runtime triggering. Commit the spec, `.mp3`, `.mp3.import`, and `.generated.json`.

### Regenerate everything

```sh
python tools/generate_music.py --all
```

**Warning:** ElevenLabs music generation is non-deterministic. `--all` produces a *fresh OST* against the current source-of-truth specs — not byte-for-byte reproductions of the existing tracks. Use it when the world brief shifts or models improve. If you love a current track, save a copy before re-running so you can A/B.

The `.generated.json` sidecar records the rendered prompt, model, timestamp, and audio SHA256 — useful for diffing two takes. The audio itself isn't reproducible from it.

ElevenLabs caps the rendered prompt at 4100 characters. The script fails fast if the combined `music.md` + spec exceeds that.

### Pointers

- `docs/music.md` — what's *in* the world musically (palette, through-line, contrastive NOTs). The world context every spec is rendered against.
- `docs/sound_design.md` — diegesis rule, SFX recipes, bus layout, volume defaults. Operational audio.

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
