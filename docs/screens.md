# Screens

Per-screen design intent and current implementation status for every screen reachable from the developer admin portal (`scenes/ui/admin_hub.tscn`). This doc is the next implementer's brief — read the relevant section before building out a screen.

Scope is **admin-hub-routed screens only**. Screens not currently wired into the admin hub (main menu, settings, pause, post-run summary, the runtime event-play screen, etc.) live elsewhere or don't exist yet and are deliberately out of scope here.

## Conventions

Each section follows the same shape:

- **What it is** — the screen's role in player experience.
- **When it's reached** — entry points (admin hub today, real game flow eventually).
- **What it shows** — content + interactions in the eventual full implementation.
- **Schema / system additions required** — Resource types, autoloads, or `GameState` fields that must exist before the screen can be built out.
- **Current state** — what ships in the repo right now.
- **Open questions** — explicit unknowns the implementer needs to resolve.
- **Status** — `placeholder` (title + back only), `partial` (some real content), or `real` (production-ready).

The two run-economy resources are referenced throughout. A reminder:

- **Credits** — soft currency. Spent at shops; earned from combat / events.
- **Gambit Chips** — slot-unlock items. Each chip equipped to a character grants +1 programmable gambit slot on that character. Reassignable between battles. NOT currency. Sourced from shop (priced in Credits) and combat / event drops.

---

## Combat

**What it is.** The actual in-run battle screen. The moment-to-moment player experience: a shared party action-timer pacing actor windows; on each window, the actor's gambit list resolves to a chosen action; rhythm prompts overlay during execution.

**When it's reached.** Currently from the admin hub (Combat tile), which loads `scenes/ui/admin_combat.tscn` — a thin wrapper that instances `scenes/levels/test_arena.tscn`. Eventually entered when a player lands on a COMBAT-kind node inside a region.

**What it shows.** Party members on one side, enemies on the other, shared timer along the top with upcoming actor windows. HUD: HP bars, MP pools, equipped Gambit Chips per character (visual reminder of programmable capacity), active band-card activations. On every action: rhythm hit-window prompt drives bonus magnitude. Battle end → rewards screen (Credits, possibly chips, possibly cards).

**Schema / system additions required.** Most foundations exist: `TurnManager` (the heartbeat), `GambitEngine` (action resolution), `CharacterDef`, `EnemyDef`, the EventBus signal contract. Gaps: rhythm UI, band-card runtime activation, reward roll, post-battle return-to-realm flow.

**Current state.** Functional debug arena via `test_arena.tscn`. Gambit resolution and turn pacing work. No rhythm UI, no band-card runtime, no rewards.

**Open questions.**
- How is the rhythm hit-window rendered without overwhelming a 10-member party at peak action density? (See GDD known-risk.)
- Are rewards rolled per-encounter or per-region?
- Should chips occasionally drop from combat (yes per the chip-acquisition design) — at what rate / which combat tier?

**Status:** `partial`.

---

## Playable Characters

**What it is.** The roster browser — a grid of all 12 instrument-archetype characters with click-through to a detail page (stats, learn list, ability tooltips). Eventually the in-game collection / lore screen players visit between runs to see who they've discovered.

**When it's reached.** Admin hub (Playable Characters tile) → `scenes/ui/admin_playable_characters.tscn` → click any tile → `scenes/ui/admin_character_detail.tscn`. Long-term, reached from a meta-progression / collection menu (not yet specced) and gated by `CardCatalog` cross-run state — only discovered characters appear.

**What it shows.** Grid of character tiles (portrait, name, instrument). Detail page: portrait, instrument role, base + level-scaled stats (HP/MP/ATK/DEF/POW/SPD), level slider for previewing growth, learn list (level → ability), ability tooltips.

**Schema / system additions required.** All foundational schemas exist: `CharacterDef`, `AbilityDef`, `LearnEntry`, `CharacterCatalog`. Missing for "real" version: discovery-gating that filters the grid by `CardCatalog` cross-run state, and lore copy on each character (currently absent).

**Current state.** Grid works, drilling into detail page works, level slider works. Shows all authored characters in dev (no discovery gate). 10 of 12 archetype `.tres` files exist (singer, guitar, drummer, keyboard, sax, bass, cello, accordion, upright_bass, harp, dj — see `resources/characters/`).

**Open questions.**
- Should the screen split into "discovered" and "undiscovered" (silhouette) sections, or hide undiscovered entirely?
- Does the detail page get a play / dialogue audio sample for the character's instrument?

**Status:** `partial`.

---

## Band Cards

**What it is.** The catalog of all authored band cards — composition bonuses keyed to instrument-role lineups. Eventually the in-game collection screen for band cards (filter by activation requirements, sort by discovered state).

**When it's reached.** Admin hub (Band Cards tile) → `scenes/ui/admin_band_cards.tscn`. Long-term, reached from the same meta-progression menu as Playable Characters; discovery-gated by `CardCatalog`.

**What it shows.** Grid of band-card tiles. Each tile: card name, art, the activation requirement (e.g. *"keyboard + standing bass + drummer"*), and the applied effects (combo meter speed, damage multiplier, defense, etc.). Click → detail page with full requirement breakdown and band-flavor text.

**Schema / system additions required.** `BandCard` schema exists; `BandCardCatalog` exists. Detail page (`band_card_detail.tscn`) doesn't exist yet. Discovery-gating not wired. Real activation runtime (the `BandComposer` system that detects which cards apply to a live party) is deferred per GDD — V1 ships display-only.

**Current state.** Grid populates from `BandCardCatalog`. 8 templates exist (`resources/band_cards/`): soloist, jazz_trio, rock_band, bluegrass, chamber_ensemble, mariachi, dueling_djs, angelic_choir. Display-only — no detail click-through, no discovery gate.

**Open questions.**
- Are activation requirements strict instrument-role match, fuzzy (any keyboard counts), or scoped (must be lead-keyboard)?
- How does the grid order — by discovery, by lineup size, by family?

**Status:** `placeholder`.

---

## The Realm

**What it is.** The FTL-style meta-map a player navigates between regions during a run. 12 nodes total in a fixed-shape layout, edges color-coded by availability state, click-to-advance. The closest-to-real screen of the entire admin hub.

**When it's reached.** Admin hub (The Realm tile) → `scenes/ui/admin_the_realm.tscn`. Long-term, this **is** the run's between-regions screen — reached after each region completes, persisting until the run ends.

**What it shows.** 12-node fixed-shape graph. Each node renders an icon colored to hint at the underlying region archetype (per the role-discovery rule: no name tooltips — players learn via icon color and play). Edges: gold (available next move), gray (visited), unrendered (locked / not yet reachable). Background: Rothko-inspired dithered yellow/green color-field bands (per project memory `realm_aesthetic`). Click an available node → enter that region.

**Schema / system additions required.** Schemas fully exist: `RealmDef`, `Realm` runtime, `RealmNode`, `EventBus.realm_built / realm_advanced / realm_node_chosen` signals. The remaining gap is **run-state hookup** — currently the admin tile builds a fresh seeded realm each visit; the real version reads the active run's realm from `GameState` and shows actual progress.

**Current state.** Graph renders, edges color correctly, clicking advances. Independent of run state — admin tile reseeds on entry. Visual polish in progress (background was overhauled in PR #18).

**Open questions.**
- What's the post-region transition look like — do you return to the realm with the just-completed node fading to gray, or does the camera animate?
- Does the Realm screen offer any meta-actions (rest, view inventory) or is it pure navigation?

**Status:** `partial → near-real`.

---

## Regions

**What it is.** A region-template browser. Grid of `RegionDef` cards; clicking one launches a synthetic region run for that template (`scenes/levels/region_run_test.tscn`). Useful for dev iteration on individual region designs in isolation.

**When it's reached.** Admin hub (Regions tile) → `scenes/ui/admin_regions.tscn`. **In actual gameplay, regions are entered via realm-node click — not a browser.** This admin tile is therefore arguably dev-only and may be removed once the realm → region launch flow is solid.

**What it shows.** Grid of region tiles (icon color, name, encounter count, distribution preview). Click tile's play button → run that region against a seeded RNG.

**Schema / system additions required.** None — `RegionDef` and `RegionCatalog` are fully wired. 6 region `.tres` files exist (`the_introduction`, `the_city`, `the_expanse`, `the_depths`, `the_warp`, `the_finale`).

**Current state.** Functional dev launcher.

**Open questions.**
- Keep, or retire when realm → region runtime is finalized?
- If keeping, should it be moved out of the admin hub into a separate "dev tools" submenu so the hub stays focused on player-facing screens?

**Status:** `dev-only browser`.

---

## Inventory

**What it is.** The run-state dashboard the player opens at any time during a run to see what they currently own. Six sections — each is a category of run-acquired resource — laid out as a single screen.

**When it's reached.** Admin hub (Inventory tile) → `scenes/ui/inventory.tscn`. Long-term, reachable mid-run via a top-level UI button or a hotkey, from the realm screen and probably from inside other sub-screens (Shop, Band Tuning) so the player can audit while planning.

**What it shows.** Six sections, each its own panel:

1. **Characters** — the owned roster. Tiles with portrait, name, instrument, level. Click → character detail. This is the source pool Band Tuning draws from.
2. **Gambit Cards** — owned trigger cards available to equip in Band Tuning. Tiles show the trigger expression (e.g. *self HP < 50%*), target selector, flavor.
3. **Band Cards** — owned composition cards. Tiles show activation requirement and effects. Activation is automatic against the chosen lineup; this section is read-only.
4. **Items** — consumables (potions, tonics, keys, etc.). Generic item bag.
5. **Credits** — current balance. Plain numeric readout.
6. **Gambit Chips** — unequipped chip count plus a per-character summary of equipped chips (e.g. *Singer: 3 chips, Drummer: 2*). Equip/unequip happens in Band Tuning, not here — this section is informational.

Gambit Cards and Band Cards are deliberately separate sections — they're conceptually distinct (trigger rules vs. lineup bonuses) and players will reason about them separately. Do not collapse them into a single "Cards" tab.

**Schema / system additions required.**
- `ItemDef` Resource (id, display_name, description, art, stack rule, on-use effect or marker for runtime to handle). New under `scripts/data/`.
- `GambitChip` Resource (id, display_name, art, optional rarity). Even if all chips are functionally identical for V1, a Resource type makes them addressable.
- `GameState` extensions: `credits: int`, `chips: Array[GambitChip]`, `items: Array[ItemInstance]`, `owned_gambit_cards: Array[GambitCard]`, `owned_band_cards: Array[BandCard]`. Today's `CardCatalog` is **cross-run discovered** state, not the per-run owned set — keep these separate.
- A read-side helper or event for "chips equipped to character X" so the Inventory chip section can render the per-character summary without the Inventory screen reaching into character internals.

**Current state.** Placeholder — title + back button.

**Open questions.**
- Do items stack (3× Potion) or are they discrete instances (Potion #1, Potion #2)?
- Slot / weight cap on the inventory, or unbounded?
- Do chips have rarity tiers (Common / Rare / etc.) that matter, or are all chips functionally interchangeable?
- Does opening Inventory pause an active battle, or is it only available outside combat?

**Status:** `placeholder`.

---

## Events

**What it is.** A catalog grid of every authored event that can fire on an EVENT-kind node during a run, plus a read-only **demo runner** that walks any event's scene tree end-to-end. One event fires per node at runtime, chosen from a region-weighted distribution against the node's column. The runtime "play this event on a real node" hookup is deferred — the admin demo runner stands in for it during content authoring.

**When it's reached.** Admin hub (Events tile) → `scenes/ui/events.tscn` (grid). Click an event tile's Play button → `scenes/ui/event_run_demo.tscn` (runner). Long-term, the catalog grid is also reachable from a meta-progression / collection menu like Playable Characters and Band Cards (discovery-gateable by `CardCatalog`); the runtime hookup will route EVENT-kind realm-node clicks into a live event-runner scene rather than the demo.

**What it shows.**
- *Grid:* tile per event. Title, hook description, scope summary (regions × columns), column-scaling coefficient, Play button.
- *Demo runner:* current scene's body text + per-choice buttons; a "Preview column" spinbox (0–5) that re-renders numeric effects against `1 + col * coeff`; an effect log panel showing what each entered scene's effects *would* do (`+5 credits → +13 (×2.5)`, `heal party (full)`, `recruit Singer at level 1 → 3`); on terminal scenes a Continue/Restart pair. The demo never mutates `GameState`.

**Schema (landed).**
- `EventDef` (`scripts/data/event_def.gd`) — id, display_name, description, art, `findable_columns: Array[int]`, `findable_regions: Array[StringName]` (both inclusion sets, no sentinel; defaults enumerate the full set), `column_effect_multiplier: float` (effective multiplier at column C = `1 + C * coeff`), `entry_scene_id`, `scenes: Array[EventScene]`.
- `EventScene` — id, body, `choices: Array[EventChoice]` (empty = terminal), `effects: Array[String]` applied on entry. Stringly-typed effect mini-DSL: `gain_credits:N`, `heal_party:full|N`, `recruit:<id>:N`. Refactor to typed `EventEffect` Resource subclasses once the Inventory system lands.
- `EventChoice` — label, `requirement: String` (stringly-typed prerequisite, evaluated at runtime; admin demo never blocks), `outcomes: Array[EventOutcome]`. Same typed-Resource refactor planned.
- `EventOutcome` — `weight: float`, `next_scene_id`. Single-element arrays for deterministic forks; the schema already supports FTL-style 50/50 the moment an event author wants it.
- `EventCatalog` (`scripts/data/event_catalog.gd`) — RefCounted, `get_all()` mirrors `RegionCatalog` / `GambitCardCatalog`.

**Current state.** Two starter events authored: *Abandoned Campsite* (1-fork → gold) and *A Wandering Singer* (nested choice → heal-party or recruit-singer). Catalog grid renders both; demo runner walks any event end-to-end with column-scaling preview.

**Deferred follow-ups.**
- Runtime hookup: EVENT-kind realm nodes route to a live event-runner scene that mutates `GameState` (credits, party, etc.) and uses `RNG.get_stream("event")` per run.
- Typed `EventEffect` / `EventChoiceRequirement` Resource subclasses, once Inventory + run-state plumbing land and effect/requirement vocabulary stabilizes.
- Event detail page (drill-through from the grid). The demo runner currently stands in.
- Per-scene art (only `EventDef.art` exists today).
- Discovery-gating against `CardCatalog`.
- Runtime evaluator for `EventChoice.requirement` and runtime applier for `EventScene.effects`.

**Status:** `built — grid + demo runner; runtime hookup deferred`.

---

## Enemies

**What it is.** A catalog grid of `EnemyDef` templates — the bestiary. Mirrors the Band Cards / Regions screens.

**When it's reached.** Admin hub (Enemies tile) → `scenes/ui/enemies.tscn`. Long-term, reachable from the meta-progression / collection menu; discovery-gated by combat encounters.

**What it shows.** Grid of enemy tiles. Each tile: portrait, name, HP, speed, default gambits as small chips. Click → detail page with full stat block, gambit list, region appearances, lore.

**Schema / system additions required.**
- `EnemyCatalog` autoload — scans `resources/enemies/` for `EnemyDef.tres`. Currently no scanner exists.
- A `enemy_detail.tscn` for drill-down (deferred).
- Region → enemy mapping for "appears in" tags (probably a runtime calculation against `RegionDef.encounter_distribution`, not a stored field).

**Current state.** Placeholder — title + back button. One `goblin.tres` exists in `resources/enemies/`.

**Open questions.**
- Discovery-gated (Pokédex-style, only-defeated visible) or full dev visibility?
- Per-enemy encounter count tracker (run stat or cross-run stat)?
- Do bosses / mini-bosses get their own grid section, or interleave with regulars?

**Status:** `placeholder`.

---

## Gambit Cards

**What it is.** A catalog grid of every authored gambit card. A gambit card is a **(trigger + target_selector) bundle** — *"when self HP < 40% → target self"*, *"always → target the enemy with the least HP"*. The action is supplied at equip-time from the owning character's known abilities (their `learn_list`); priority comes from slot order on the equipped character. Cards do not carry an action_id or priority.

**When it's reached.** Admin hub (Gambit Cards tile) → `scenes/ui/gambit_cards.tscn`. Long-term, reachable from the meta-progression / collection menu.

**What it shows.** Grid of `GambitCardTile`s — a Monopoly-action-card aesthetic: yellow body, dark border, no art, just card name + description. Cards load from `resources/gambits/cards/` via `GambitCardCatalog.get_all()`.

**Schema.**
- `GambitCard` (`scripts/data/gambit_card.gd`) extends `Card`; carries `trigger_expr: String` and `target_selector: StringName`. Inherits `id`, `display_name`, `art`, `flavor` from `Card`.
- `GambitCardCatalog` (`scripts/data/gambit_card_catalog.gd`) — static `RefCounted` mirror of `BandCardCatalog`. Scans `resources/gambits/cards/`.
- `GambitEngine` keeps its narrow trigger/selector vocabulary today; the broader vocabulary declared by the v1 cards (HP/MP thresholds, status, count, target selectors) is content-only until the engine evaluator catches up.

**Current state.** 36 starter cards authored across HP triggers (Self/Ally × 4 thresholds), MP triggers (Self/Ally × 4 thresholds), Ally Dead, enemy-targeting selectors, status triggers (Self/Ally debuffed, Ally asleep/silenced/stunned), and aggregate triggers (2+/3+ enemies, party HP avg). Catalog viewer screen built out.

**Deferred follow-ups.**
- Engine evaluator support for the new trigger expressions and target selectors.
- Equip UX in Band Tuning — player picks a card and one of the character's known abilities to compose a slotted gambit.
- `gambit_card_detail.tscn` (per-card detail page).
- Filter chips / grouping by trigger family.
- Rarity / tier for drop weighting and shop pricing.

**Status:** `built — viewer only` (engine integration pending).

---

## Band Tuning

**What it is.** The interactive party builder. Player picks characters from their owned roster into party slots, equips Gambit Chips to expand programmable slot count per character, then orders Gambit Cards into those slots — the order is the gambit priority that `GambitEngine` evaluates lowest-priority-first (FF12 convention).

**When it's reached.** Admin hub (Band Tuning tile) → `scenes/ui/band_tuning.tscn`. Long-term, reachable from a hub UI button when not in active combat — typically used between battles to retune the lineup or rewire gambit priorities.

**What it shows.** Three interactive widgets stacked or side-by-side:

1. **Roster picker** — drag characters from owned-roster pool into N party slots. Empty slots are visible.
2. **Per-character chip equip panel** — for each slotted character, show their equipped Gambit Chips and an empty-slot count = (equipped chips). Drag chips from the unequipped pool to add slots; drag chips back to remove.
3. **Per-character priority-ordered gambit list** — for each slotted character, a vertical reorderable list of gambit cards. Length is capped by chip-driven slot count. Drag cards in from the owned-gambit-cards pool; reorder by drag to set priority.

Live preview region (always visible): which Band Cards activate against the chosen lineup's instrument roles. As the player swaps characters, activations update in real time.

**Schema / system additions required.** Builds on Inventory's schemas:
- Read access to `GameState.party` (write the result of party selection back).
- Read access to owned characters / chips / gambit cards.
- A "chip-equip" mutation API (e.g. `Character.equip_chip(chip)` + `unequip_chip(chip)`) that updates the character's programmable slot count.
- A "compute active band cards from lineup" pure function — used both here (live preview) and in Combat (runtime activation). Single source of truth.

**Current state.** Placeholder — title + back button.

**Open questions.**
- Is party-size cap fixed (4 per FF-style convention) or scaled by something (band-card requirements? a "maximum band" stat that grows during a run?). The GDD mentions party scaling to 10; the immediate screen needs to know its slot count.
- Can a chip be equipped without a card slotted into it? (Legal but inert — probably yes, supports preparing for a future card drop.)
- Same gambit card equippable to multiple characters, or single-instance possession (one card = one slot anywhere)? Likely single-instance, but confirm with design.
- How is the rhythm-prompt UX surfaced when previewing? Probably not at all — this is composition, not performance.

**Status:** `placeholder`.

---

## Shop

**What it is.** The purchase UI shown on shop nodes during a run. Offers a small randomized inventory of wares the player can buy with Credits.

**When it's reached.** Admin hub (Shop tile) → `scenes/ui/shop.tscn`. Long-term, entered when a player lands on a SHOP-kind node within a region.

**What it shows.** Header: shopkeeper name + flavor + the player's current Credits balance. Body: a grid of 4–8 offers — a mix of Gambit Cards, Band Cards, Items (consumables), Gambit Chips, and occasionally a character recruit. Each offer shows price in Credits and a buy button. Footer: a "Leave shop" button that returns to the region map. On purchase: confirm dialog → Credits deducts → item moves to Inventory.

**Schema / system additions required.**
- Same currency / chip / item / cards-owned schemas that Inventory needs.
- A `ShopOfferDef` or runtime-generated `ShopOffer` struct (probably runtime — offers are rolled, not authored) with item type, item ref, price.
- An offer-roll function using `RNG.get_stream("shop")` for run-reproducibility.
- A region-aware pricing model (deeper regions = higher prices, or fixed across the run?).

**Current state.** Placeholder — title + back button.

**Open questions.**
- Re-stock on revisit, or one-shot (each shop node has its own static stock)?
- Re-roll cost — can the player pay Credits to re-roll the offers?
- Sell-back option — can the player offload owned items for Credits?
- Pricing model — fixed per item (defined alongside its `Def`), or scaled by run depth / region tier?
- Does the shop sell Gambit Chips at all, or are chips only drops-from-combat? (The chip-acquisition design says yes, shop sells them — keep that.)

**Status:** `placeholder`.
