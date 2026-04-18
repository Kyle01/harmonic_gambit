# CLAUDE.md — harmonic_rogue

## Game Vision

A pixel-art **roguelite** RPG built on three intertwined pillars:

1. **FF12-inspired Gambits.** The player does not directly control their party. Each member has a priority-ordered list of gambits in the form `<action> <trigger> <target>` — e.g., *"Cast Heal if any party member < 40% HP → that member"*; *"Cast Sleep if all allies > 80% HP → random enemy"*. Combat input is composing the AI that fights for you.

2. **Musical band composition.** Party members have instrument roles. Equipping a **band-type card** (Jazz Trio, Power Trio, String Quartet, etc.) grants bonuses when the party composition matches. Gambits and band cards drop as collectible cards during runs.

3. **Rhythm mini-game during combat.** Every party action triggers a rhythm prompt for bonus damage. Combat feels like a musical performance.

**Combat timing:** one shared party action-timer (paced by party average speed). UI shows upcoming action windows; when a member's window fires → top-priority valid gambit resolves → rhythm prompt plays. Closer to FF12's feel than strict turn-based, but one unified timer, not per-actor ATB. *Novel design — keep `TurnManager.SchedulingModel` abstract enough to swap for per-actor ATB during prototyping.*

**Run structure:** FTL-style node map of random events (combat / lore / shop / etc.), ~1-hour runs, individual combats ~90 seconds, permadeath.

**Meta-progression:** **none for power**. The only persistent state is achievements + catalog (discovered cards / enemies / playable characters).

**Party:** starts solo, recruits up to 10. *Flagged risk: rhythm-on-every-action × 10 members in 90s combat is aggressive — expect batching / measure-based solutions during prototyping.*

**Aesthetic:** pixel art, vaporwave × high fantasy ("Synthwave Pandora"). Combat-as-music in the lineage of *Brütal Legend*.

`harmonic_rogue` is the working-directory slug, not the final title.

---

## Platform Constraints

- **Steam first, Nintendo Switch later.**
- **Switch port plan:** W4 Consoles (paid middleware) primary; RAWRLAB (free, Nintendo-developer-only) as fallback.
- RAWRLAB is **GDScript-only** — no C#, no GDExtension. Any non-GDScript dependency kills the free fallback.
- **Therefore: GDScript only.** No C#, no GDExtension, no native addons, no external binaries.

### Migrability discipline

Designing for potential future migration to C# (if W4 becomes the only Switch path):

- Avoid duck-typed dicts-as-records; use typed `Resource` classes.
- Minimize `@tool` scripts.
- Typed variables everywhere: `var speed: float = 5.0`, not `var speed = 5.0`.
- `class_name` on every reusable class.
- Three-layer separation (data / systems / UI) strictly enforced (see below).

---

## Architecture Rules

Hard rules — do not violate without explicit approval.

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

---

## Autoload Registry (dependency order)

1. `EventBus` — pub/sub, no state.
2. `RNG` — seeded random streams via `get_stream(name: String) -> RandomNumberGenerator`.
3. `GameState` — current run state (current floor, party, inventory).
4. `CardCatalog` — persistent meta-state (`user://catalog.tres`). Only cross-run state besides achievements.
5. `TurnManager` — shared party action-timer. Emits `actor_window_opened(actor)`.
6. `GambitEngine` — evaluates an actor's gambit list, returns `ResolvedAction`.
7. `BandComposer` — evaluates party vs. equipped band card; emits `band_bonus_changed`.

---

## Validation Before Commit

```bash
gdparse scripts/**/*.gd        # syntax check
gdlint scripts/**/*.gd         # style check
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

## Commit Discipline

- Small, frequent commits. One logical change per commit.
- Imperative messages with type prefixes: `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `test:`.
- If `gdlint` fails, fix-forward in a follow-up commit — do not amend.
- Never `--no-verify` to bypass hooks. Fix the underlying issue.

---

## Testing Workflow

After any non-trivial change:
1. `gdparse` + `gdlint` pass on all staged `.gd` files.
2. Run the game via Godot MCP Pro (`run_project` tool).
3. Capture a screenshot of the relevant state.
4. Visually verify the feature behaves as expected.
5. Only then commit.
