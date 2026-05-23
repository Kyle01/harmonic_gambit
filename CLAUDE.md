# CLAUDE.md — harmonic_rogue

This file is the **AI-agent contract** for this repo: hard rules, forbidden actions, validation steps. Keep it tight. Design and architecture context live in separate docs.

## Reference docs

Read these when the task calls for it — don't guess from memory.

- **[`docs/gdd.md`](docs/gdd.md)** — game design: pillars, combat timing, run structure, party, aesthetic, platforms, open design questions. **Read before making any design-affecting decision.**
- **[`docs/architecture.md`](docs/architecture.md)** — code architecture: three-layer rules, autoload contract, signal names, Resource schemas. **Read before adding or moving any system.**
- **[`docs/music.md`](docs/music.md)** — world music context: through-line, palette, contrastive NOTs, how regeneration works. **Read before authoring a music spec or running `tools/generate_music.py`.**
- **[`docs/sound_design.md`](docs/sound_design.md)** — operational audio rules: diegesis, SFX recipes, bus layout, volumes. **Read before tuning any audio system or generating SFX.**
- **[`docs/world.md`](docs/world.md)** — world brief: the Realm, archetypes, what the world is and is NOT. **Read before writing any copy or generating any art.**
- **[`docs/screens.md`](docs/screens.md)** — per-screen design intent and current state for every admin-hub-routed screen. **Read before building out any screen tile.**
- **[`README.md`](README.md)** — dev setup, how to run, project layout.

If a design question isn't answered in `docs/gdd.md`, surface it to the user rather than inventing an answer. The GDD's "Known open questions" section is the active design backlog.

---

## Game summary (one paragraph)

Pixel-art **roguelite RPG** built on three pillars: **FF12-style gambits** (priority-ordered per-member AI programs), **musical band composition** (instrument-role party cards that unlock bonuses), and a **rhythm mini-game on every action**. Combat uses **one shared party action-timer** (not per-actor ATB — novel, keep `TurnManager.SchedulingModel` swappable). Runs are FTL-style node maps, ~1-hour long, permadeath, **no power meta-progression** (only achievements + a catalog of discovered content persist).

Full design in [`docs/gdd.md`](docs/gdd.md).

---

## Platform rule (hard)

**GDScript only.** No C#, no GDExtension, no native addons, no external binaries. The rationale is the RAWRLAB (free Switch port) fallback — see `docs/gdd.md#platforms`. Violating this kills the free path and forces paid W4 Consoles middleware.

### Migrability discipline

In case C# becomes unavoidable later:

- Typed variables everywhere (`var speed: float = 5.0`, not `var speed = 5.0`).
- `class_name` on every reusable class.
- `Resource` subclasses for records — no duck-typed dicts.
- Minimize `@tool` scripts.

---

## Architecture Rules (hard)

Do not violate without explicit approval.

1. **EventBus is the only cross-system bridge.** Cross-system communication only through the `EventBus` autoload. Never cache another system's node reference across module boundaries.
2. **Three-layer separation:**
   - **Data:** `.tres` Resources in `resources/` and Resource scripts in `scripts/data/`.
   - **Systems:** pure GDScript logic in `scripts/systems/` and autoloads in `scripts/autoload/`.
   - **UI:** presentation only in `scenes/ui/`. UI subscribes to EventBus, never mutates state directly.
3. **Components on actors are small and single-responsibility.** `HealthComponent`, `GambitListComponent`, `InstrumentComponent`, etc. Composition over inheritance.
4. **All randomness goes through `RNG.get_stream(name)`.** Never `randi()` / `randf()` / `randomize()` directly. Roguelite runs must be reproducible from a seed.
5. **`TurnManager` is the authoritative combat heartbeat.** No `Timer` nodes for gameplay logic. Timers are for animation only.
6. **Content is data-driven.** Gambits, cards, band definitions, enemies, events, characters — all `.tres` files. Never hardcoded in scripts.
7. **Typed variables everywhere. Past-tense signal names** (`health_changed`, not `change_health`).

Autoload registry + signal contract in [`docs/architecture.md`](docs/architecture.md).

---

## Validation Before PR

**Hard gate before every PR — CI will reject the branch otherwise.** Run all three on the staged `.gd` files and fix any failures before pushing:

```bash
FILES=$(git ls-files '*.gd' | grep -v '^addons/')
echo "$FILES" | xargs gdparse            # syntax
echo "$FILES" | xargs gdlint             # style
echo "$FILES" | xargs gdformat --check   # formatting
```

`gdformat` (without `--check`) auto-fixes formatting in place. `gdlint` failures must be hand-fixed — do not disable rules without approval.

For non-trivial `.tscn` / `.tres` changes: open the scene in Godot via MCP and screenshot it. Type/lint passing is necessary but not sufficient — **run the game** via Godot MCP Pro and visually confirm the feature before claiming it's done.

## CI (GitHub Actions)

Two workflows run on every PR into `main`:

- **`validate.yml`** — blocking. Runs `gdparse`, `gdlint`, `gdformat --check`, and a Godot headless import (`godot --headless --import --quit`) to catch broken scene/resource links. Merge is blocked until it passes.
- **`ai-review.yml`** — advisory only. Runs an OpenAI reasoning-model review scoped to the diff across four focus areas: Godot architecture, video-game design fundamentals, extensibility, and security. Posts a comment on the PR. Re-runs automatically when you push follow-ups. Observations only — no verdict, never blocks merge.

Branch protection on `main`: PR required, `validate.yml` must pass, no force-push, no approval required (solo dev), admin bypass enabled.

---

## Forbidden Without Explicit Approval

- Deleting scenes.
- Modifying `project.godot` beyond scripted autoload registration.
- Installing Godot asset-library addons.
- Changing the autoload list (order or membership).
- Editing export templates.
- Introducing C# / GDExtension / native dependencies.
- Using `git add -A` or `git add .` — always stage explicit paths.

---

## Paths to skip when exploring

These paths are large, third-party, generated, or empty-of-meaning. Do not `find`, `ls`, `grep`, or `Read` them unless directly necessary for the task:

- `.venv/` — Python tooling deps (1.7k files)
- `.godot/` — engine cache; regenerated on import
- `.claude/skills/godot-api/doc_source/` and `doc_api/` — cloned Godot engine repo (~21MB)
- `screenshots/` — ephemeral QA captures (gitignored)
- `addons/` — third-party plugins (invoked via MCP, not read directly)
- `*.uid` — Godot 4.4 sidecars: one line, opaque hash, zero LLM value
- `.env`, `.env.local` — secrets

---

## Branch Workflow

- **Never commit directly to `main`.** Every non-trivial change starts on a `feature/<slug>` or `docs/<slug>` branch.
- Validate on the branch via Godot MCP Pro (`play_scene` + screenshot + interaction test) before merging.
- Fast-forward merge to `main` only after validation passes.
- Trivial single-line fixes can be an exception — use judgment, but when in doubt, branch.

---

## PR Hygiene

Commit shape is not policed. PR shape is. A PR is the unit of review and the unit of value.

- **One PR, one digestible unit of value.** Each PR should land something a reviewer can hold in their head — a feature, a fix, a refactor with a clear motivation.
- **Don't stack PRs without being asked.** Default to folding new work into the active PR via a new commit. Only split into a separate PR when the user explicitly asks for it. If follow-up work emerges mid-review, fold it in and update the cover page.
- **The PR must be complete.** Code, data, assets, and any doc updates needed to make the change coherent all land together. No "I'll fix the docs in a follow-up." If it's worth doing, it's worth doing in the same PR.
- **Fill out the cover page.** Every PR needs a Summary (what changed and why, including design motivation for non-trivial work) and a Test plan (how it was verified — lint, headless import, MCP screenshot, manual play). Blank or one-line PR bodies are not acceptable. Update the cover page when scope grows.
- **Only humans merge.** Never enable auto-merge, never merge an AI-authored PR automatically. Agents open PRs and wait for a human.

## Testing Workflow

Before opening a PR, after any non-trivial change:
1. `gdparse` + `gdlint` + `gdformat --check` pass on all staged `.gd` files.
2. Run the game via Godot MCP Pro (`play_scene` tool).
3. Capture a screenshot of the relevant state.
4. Visually verify the feature behaves as expected.
5. Only then open the PR.
