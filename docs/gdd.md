# Game Design Document

Human-facing design reference. Hard engineering rules live in `CLAUDE.md`; code architecture lives in `architecture.md`. This doc is the "what are we making" anchor.

## Pitch

A pixel-art **roguelite RPG** where combat is a musical performance. You don't directly control your party — you compose the AI that fights for you (FF12-style gambits), build musical band lineups from drops, and play rhythm prompts on every action. Pitched as *Synthwave Pandora*: vaporwave × high fantasy, in the lineage of *Brütal Legend*.

`harmonic_rogue` is a working-directory slug, not the final title.

---

## The three pillars

### 1. Gambits — program your party's AI

Each party member has a priority-ordered list of **gambits** in the form `<action> <trigger> <target>`:

- *"Cast Heal if any party member < 40% HP → that member"*
- *"Cast Sleep if all allies > 80% HP → random enemy"*
- *"Attack if any enemy alive → nearest enemy"*

During combat, when a member's action window opens, their highest-priority gambit whose trigger resolves fires. **Combat input is composing the AI**, not steering it turn-by-turn.

Gambits drop as collectible cards during runs. Your party's combat effectiveness comes from the gambit deck you assemble.

### 2. Band composition — party is a band

Party members have **instrument roles** (lead guitar, bass, drums, keys, vocals, strings, etc.). **Band-type cards** (Jazz Trio, Power Trio, String Quartet, Rhythm Section, …) grant bonuses when the party's instrument lineup matches the card's requirements.

- *Jazz Trio:* piano + bass + drums → combo meter builds faster.
- *Power Trio:* lead guitar + bass + drums → critical hits chain.

Band cards drop alongside gambit cards. Part of the strategic layer is **recruiting and retaining members whose roles unlock your band cards** — not just their raw stats.

### 3. Rhythm mini-game — every action is a beat

Every time a party action fires, a **rhythm prompt** plays: a hit-window the player lands for bonus damage / healing / effect magnitude. Combat feels like performing, not executing commands.

Rhythm is the moment-to-moment skill expression on top of the macro strategy of gambit/band composition.

**Known risk:** party scales to 10 members and combats run ~90 seconds. A rhythm prompt per action per member could hit 2-3 second cadence at the high end. Expect batching / measure-based solutions during prototyping.

---

## Combat timing

One **shared party action-timer** paced by party average speed. UI displays upcoming action windows for each member. When a member's window fires:

1. `TurnManager` emits `actor_window_opened(actor)`.
2. `GambitEngine` walks the actor's gambit list, returns a `ResolvedAction`.
3. The action applies. Rhythm prompt plays during execution.
4. Advance to the next window.

This is **closer to FF12's feel than strict turn-based**, but with a single unified timer instead of per-actor ATB. The shared-timer design is **novel** — `TurnManager.SchedulingModel` is intentionally abstract so per-actor ATB remains swap-in-able if the shared model doesn't feel right in prototyping.

---

## Run structure

- **FTL-style node map** — each run is a graph of random event nodes (combat, elite, lore, shop, rest).
- **~1-hour runs.** Individual combats ~90 seconds.
- **Permadeath.** Lose the party → the run ends.
- **No power meta-progression.** The only persistent state across runs is:
  - **Achievements** (player recognition).
  - **Catalog** — discovered cards, enemies, playable characters.

No stat upgrades, no permanent unlocks that make future runs mechanically easier. Every run starts at the same power floor. Skill and deck construction carry the player; unlocks are cosmetic / completionist.

---

## Party

Starts **solo.** Party recruitment happens during runs via events / shop nodes. Max **10 members.**

Each character has:
- Base stats (HP, speed).
- An **instrument role** (feeds band composition).
- A starting gambit list (editable during the run as gambit cards drop).

---

## Aesthetic

- **Pixel art**, 32-tile base grid (flexible up).
- **Vaporwave × high fantasy** — neon pastels, synthwave palettes, mystic fantasy motifs. Picture *Synthwave Pandora*.
- Combat screen feels like a stage performance, not a battlefield.
- Music is diegetic — the band you've assembled is what plays. The rhythm prompts are *them playing*.

References: *Brütal Legend* (music-as-combat), *Crypt of the NecroDancer* (rhythm-driven action), *Slay the Spire* (deck construction → combat output), *FF12* (gambit-driven party AI), *FTL* (run map structure), *Hades* (narrative roguelite polish).

---

## Platforms

- **Steam first.** PC (Mac / Windows / Linux) via Godot 4.6 Compatibility renderer.
- **Nintendo Switch later.** Two paths:
  - **Primary:** W4 Consoles (paid middleware) — supports GDScript + C#.
  - **Fallback:** RAWRLAB (free, Nintendo-developer-only) — **GDScript-only**, no C#, no GDExtension, no native addons.

Because the fallback path requires pure GDScript, the codebase is **GDScript-only** — no C#, no GDExtension, no native addons, no external binaries. Any non-GDScript dependency kills the free fallback.

### Migrability discipline

In case W4 becomes the only Switch path and we need to port to C# later:

- Typed variables everywhere (`var speed: float = 5.0`, not `var speed = 5.0`).
- `class_name` on every reusable class.
- `Resource` subclasses for records — no duck-typed dicts.
- Minimize `@tool` scripts.
- Three-layer separation strictly enforced (data / systems / UI).

---

## Not in scope (for now)

- Multiplayer / co-op.
- Live-service / seasons / battle passes.
- VR.
- Stat-based meta-progression.
- Mouse-driven combat UI (rhythm + gambits imply controller / keyboard-first).

These may surface later but shouldn't influence current architecture decisions.

---

## Known open questions

1. **Rhythm cadence with 10 party members.** Potentially unplayable at high end. Batching (measure-based prompts, group actions) is the likely fix.
2. **Shared-timer vs. per-actor ATB.** The shared timer is the current bet; keep `SchedulingModel` swappable until prototyping validates.
3. **Band bonus UX.** How does the player see which band card is active and what the composition requirements are? Needs design pass during UI work.
4. **Card rarity / drop economy.** Not yet designed. Will inform how many cards need to exist at ship.
