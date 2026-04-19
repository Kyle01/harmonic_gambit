# CLAUDE.md — harmonic_rogue

This file is the **AI-agent contract** for this repo: hard rules, forbidden actions, validation steps. Keep it tight. Design and architecture context live in separate docs.

## Reference docs

Read these when the task calls for it — don't guess from memory.

- **[`docs/gdd.md`](docs/gdd.md)** — game design: pillars, combat timing, run structure, party, aesthetic, platforms, open design questions. **Read before making any design-affecting decision.**
- **[`docs/architecture.md`](docs/architecture.md)** — code architecture: three-layer rules, autoload contract, signal names, Resource schemas. **Read before adding or moving any system.**
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

## Validation Before Commit

```bash
gdparse scripts/**/*.gd scenes/**/*.gd    # syntax check
gdlint  scripts/**/*.gd scenes/**/*.gd    # style check
```

For non-trivial `.tscn` / `.tres` changes: open the scene in Godot via MCP and screenshot it. Type/lint passing is necessary but not sufficient — **run the game** via Godot MCP Pro and visually confirm the feature before claiming it's done.

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

## Branch Workflow

- **Never commit directly to `main`.** Every non-trivial change starts on a `feature/<slug>` or `docs/<slug>` branch.
- Validate on the branch via Godot MCP Pro (`play_scene` + screenshot + interaction test) before merging.
- Fast-forward merge to `main` only after validation passes.
- Trivial single-line fixes can be an exception — use judgment, but when in doubt, branch.

---

## Commit Discipline

- Small, frequent commits. One logical change per commit.
- Imperative messages with type prefixes: `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `test:`.
- If `gdlint` fails, fix-forward in a follow-up commit — do not amend.
- Never `--no-verify` to bypass hooks. Fix the underlying issue.

---

## Testing Workflow

After any non-trivial change:
1. `gdparse` + `gdlint` pass on all staged `.gd` files.
2. Run the game via Godot MCP Pro (`play_scene` tool).
3. Capture a screenshot of the relevant state.
4. Visually verify the feature behaves as expected.
5. Only then commit.
