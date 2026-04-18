# Architecture

Terse reference for the code layout. Updates as systems stabilize. Hard
rules live in `CLAUDE.md`; this doc describes *what* the pieces are and
*how they talk*.

## Three layers

| Layer | Location | Responsibility |
|---|---|---|
| **Data** | `resources/*.tres`, `scripts/data/*.gd` | Typed `Resource` schemas + the `.tres` instances that fill them. No logic. |
| **Systems** | `scripts/autoload/`, `scripts/systems/`, `scripts/components/` | Pure GDScript logic. Authoritative state. Emits signals on `EventBus`. |
| **UI** | `scenes/ui/` | Presentation only. Subscribes to `EventBus`, never mutates state. |

Cross-layer rule: **systems never know UI exists**, and **UI never calls into systems directly**. The bridge is always `EventBus`.

## Autoloads (in dependency order)

The registration order in `project.godot` matches this list — earlier
autoloads must be ready before later ones reference them.

### 1. `EventBus` (`event_bus.gd`)
Signal-only node. No state, no logic. Every cross-system signal is declared
here.

Current signals:
- `actor_window_opened(actor: Node)` — TurnManager → GambitEngine trigger.
- `band_bonus_changed(bonus: Resource)` — BandComposer → UI / combat stats.

Past-tense naming is mandatory (`health_changed`, not `change_health`).

### 2. `RNG` (`rng.gd`)
Seeded per-stream random. **The only sanctioned source of randomness.**
`randi()`, `randf()`, and `randomize()` are forbidden.

- `set_seed(seed: int)` — call once per run (`GameState.run_seed`).
- `get_stream(name: String) -> RandomNumberGenerator` — named streams keep
  independent subsystems reproducible (e.g., `"loot"` vs `"enemy_ai"` won't
  perturb each other).

### 3. `GameState` (`game_state.gd`)
Per-run state only: `current_floor`, `party`, `inventory`, `run_seed`.
Resets between runs. **Nothing here persists across runs** — that's
`CardCatalog`.

### 4. `CardCatalog` (`card_catalog.gd`)
The **only** cross-run persistent state besides achievements. Tracks
discovered cards / enemies / characters. Serializes to
`user://catalog.tres`. No power meta-progression ever lands here.

### 5. `TurnManager` (`turn_manager.gd`)
Authoritative combat heartbeat. One shared party action-timer paced by
party average speed. When an actor's window opens, emits
`EventBus.actor_window_opened(actor)`.

`SchedulingModel` enum (`SHARED_PARTY_TIMER`, `PER_ACTOR_ATB`) stays
abstract — the shared-timer design is novel and must remain swappable
during prototyping.

**No `Timer` nodes for gameplay.** Timers are for animation only.

### 6. `GambitEngine` (`gambit_engine.gd`)
Listens for `actor_window_opened`, walks the actor's gambit list in
priority order, returns a `ResolvedAction` (action + resolved target).
Pure function of actor state + world snapshot — no side effects. The
returned action is executed by the combat system.

`ResolvedAction` is not yet a Resource; return type is `Resource` for now
and will tighten once the schema lands.

### 7. `BandComposer` (`band_composer.gd`)
Evaluates the current party's instrument roles against the equipped
`BandCard.required_roles`. On match transitions, emits
`EventBus.band_bonus_changed(bonus)`.

## Data schemas (`scripts/data/`)

All `class_name`'d. Typed fields only. No logic.

- **`GambitDef`** — `action_id: StringName`, `trigger_expr: String`,
  `target_selector: StringName`, `priority: int (0-100)`.
  `trigger_expr` and `target_selector` are stringly-typed until a
  condition/selector registry lands.
- **`Card`** (base) — `id`, `display_name`, `art`, `flavor`.
- **`GambitCard extends Card`** — wraps `GambitDef`.
- **`BandCard extends Card`** — `required_roles: Array[StringName]`,
  `bonus_payload: Resource` (tightens to `BandBonus` later).
- **`EnemyDef`** — stats, `sprite_frames`, `default_gambits`.
- **`CharacterDef`** — playable character template including
  `instrument_role`, `starting_gambits`.
- **`EventNode`** — a node in the FTL-style run map (`COMBAT`, `ELITE`,
  `LORE`, `SHOP`, `REST`).

## Components (`scripts/components/`)

Small, single-responsibility nodes attached to actors. Composition over
inheritance. Expected families:

- `HealthComponent` — hp, damage, death signal.
- `GambitListComponent` — holds an `Array[GambitDef]`, serves
  `GambitEngine`.
- `InstrumentComponent` — the actor's `instrument_role`; read by
  `BandComposer`.

Components should expose signals for their own state changes; `EventBus`
is for *cross-system* traffic, not *within-actor* traffic.

## Validation

Before commit:

```bash
gdparse scripts/**/*.gd
gdlint scripts/**/*.gd
```

For non-trivial `.tscn` / `.tres` changes: open in Godot via MCP,
screenshot, visually confirm. Type/lint passing is necessary but not
sufficient.
