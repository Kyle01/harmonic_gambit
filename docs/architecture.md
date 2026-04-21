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
The **only** cross-run persistent state besides achievements and user
audio preferences. Tracks discovered cards / enemies / characters.
Serializes to `user://catalog.tres`. No power meta-progression ever
lands here. (User audio preferences persist separately via
`AudioSettings` to `user://settings.tres`.)

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

### 8. `AudioSettings` (`audio_settings.gd`)
Authoritative volume state for the `Music` and `SFX` buses. Loads a
`UserSettings` resource from `user://settings.tres` on ready, applies it to
`AudioServer`, and re-saves on every change. The only code in the project
that should call `AudioServer.set_bus_volume_db` — UI talks to this
autoload via `set_music_volume` / `set_sfx_volume`, then subscribes to
`EventBus.music_volume_changed` / `sfx_volume_changed` for display sync.

Bus layout lives at `res://default_bus_layout.tres`, registered via
`project.godot [audio] buses/default_bus_layout`.

Sound design philosophy — the continuity brief for music + SFX — is in
[`docs/sound_design.md`](sound_design.md). Read before generating any new
audio.

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
- **`CharacterDef`** — playable character template: `instrument_role`,
  base + linear-growth stats (`HP/ATK/DEF/POW/SPD`), `learn_list:
  Array[LearnEntry]` gating abilities by level.
- **`AbilityDef`** — atomic move referenced by `LearnEntry` and (today
  stringly, later typed) by `GambitDef.action_id`. `category` (`"damage"` |
  `"support"`, editor-enforced via `@export_enum`) drives category-rigid
  stat scaling (damage→ATK, support→POW); `scope` (`"single"` | `"all"` |
  `"chain"`, same constraint) declares targeting pattern; `mp_cost` is the
  caster's MP spend (basics are 0 / always usable). Authored inline as
  SubResources inside a character's `.tres`, not as standalone ability files.
- **`LearnEntry`** — `{level, ability}` pair in a `CharacterDef.learn_list`.
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

## UI

### Target resolution

**1280×720 base viewport** (Switch handheld native, 16:9). Set in
`project.godot [display]` with `stretch/mode=canvas_items` +
`stretch/aspect=keep`. Scales proportionally to any window — 1:1 on
Switch handheld, 1.5× on Switch docked (1920×1080), free scale on
desktop with letterboxing on non-16:9. Design all UI against the
1280×720 logical grid.

### Fonts

- `assets/fonts/alagard.ttf` — display / titles (medieval-fantasy
  pixel).
- `assets/fonts/silkscreen.ttf` — UI body, buttons, labels (clean
  pixel sans).

Applied inline via `theme_override_fonts/font` until enough UI exists
to justify a shared `theme.tres`.

### Navigation

Scene transitions use `get_tree().change_scene_to_file(path)` directly
— no router. The main menu (`scenes/ui/main_menu.tscn`) wires each
button to a placeholder page; each placeholder shares
`placeholder_page.gd`, which handles the Back button and `ui_cancel`.

Promote to a `SceneRouter` autoload when run-flow (map → combat →
rewards) needs cross-cutting transition state (fade animations,
back-stack, carry-over params). Until then, direct transitions are the
pattern.

## Validation

Before commit:

```bash
gdparse scripts/**/*.gd
gdlint scripts/**/*.gd
```

For non-trivial `.tscn` / `.tres` changes: open in Godot via MCP,
screenshot, visually confirm. Type/lint passing is necessary but not
sufficient.
