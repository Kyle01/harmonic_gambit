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
2. Edit the frontmatter and the body. Required frontmatter keys: `path` (where to write the audio), `loop` (true/false — also written into the `.import` sidecar), `length_sec`, `instrumental` (true = no vocals, false = vocals allowed; default lives in the spec, not the script). Optional: `context` (free-form metadata, e.g. `main_menu`, `rest`). Read `docs/music.md` first — palette and contrastive NOTs apply to every track.
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

## Generating art

Pixel art is data-driven on the same pattern as music. Every PNG asset has a sibling self-contained `*.spec.md` (YAML frontmatter — path, asset_type, dimensions — plus a markdown body describing the figure / instrument / pose / scene). `tools/generate_art.py` reads the spec, prepends a small asset-type lead-in (`SUBJECT_LEADS`) that carries the global tarot/flat-shading/palette rules, calls PixelLab pixflux, and writes the PNG + `.import` sidecar + `.generated.json` provenance. Models will improve; rerunning the script regenerates every asset from the same source-of-truth spec.

A second generator, `tools/generate_palette.py`, derives the UI palette via the Claude API (LLM, not PixelLab — a palette is hex codes, not pixel art) and writes `resources/theme/palette.tres` as a typed `PaletteDef` resource.

### One-time setup

```sh
python -m venv .venv
source .venv/bin/activate
pip install -r tools/requirements.txt
cp .env.example .env                     # then edit .env and paste keys
```

Required keys: `PIXELLAB_SECRET` (from <https://pixellab.ai/account>), `ANTHROPIC_API_KEY` (from <https://console.anthropic.com>).

### Spec design

Each `*.spec.md` is self-contained: pixflux loses the plot when prompts get composed across multiple files (empirically: 5500-char prompts produced vista-only scenes with no figure). The global aesthetic rules live in `SUBJECT_LEADS` inside `tools/generate_art.py` so they reach the API as a tight lead-in; the rest of the prompt is the spec's own body. `docs/art.md` and `docs/world.md` are pure design references for spec authors — they are not concatenated into prompts.

### Add or regenerate an asset

```sh
# Dry-run prints the rendered prompt without spending API credits:
python tools/generate_art.py --spec assets/sprites/characters/guitar.spec.md --dry-run

# Generate for real (writes PNG + .import + .generated.json):
python tools/generate_art.py --spec assets/sprites/characters/guitar.spec.md

# Regenerate every spec under assets/sprites/ (skips _-prefixed non-targets):
python tools/generate_art.py --all
```

### Regenerate the palette

```sh
python tools/generate_palette.py --spec assets/sprites/_palette.spec.md
```

Slot list lives in the spec's frontmatter; adding a slot here also requires adding the matching `@export var` in `scripts/data/palette_def.gd`. Default model is `claude-sonnet-4-6`; override with `--model`.

### Regeneration semantics

The PixelLab and Anthropic endpoints are non-deterministic. `--all` produces a *fresh art set* — not byte-for-byte reproductions. The `.generated.json` sidecar records the rendered prompt, model, dimensions, and PNG SHA256 — useful for diffing two takes. The image itself isn't reproducible from it.

### Pointers

- `docs/art.md` — universal aesthetic reference for spec authors (not concatenated into prompts).
- `docs/typography.md` — font choices, license provenance, Theme wiring.
- `docs/world.md` — fuller creative brief; `docs/art.md` is its visual distillation.

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
  fonts/    # munro.ttf (title), munro_small.ttf (body) — see docs/typography.md

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
