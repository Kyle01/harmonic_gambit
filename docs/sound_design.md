# Sound Design

Operational rules for audio in the build — diegesis, SFX, bus layout,
volumes. For *music* mood and palette, see `music.md`. For per-track
music prompts, see the `*.spec.md` next to each file under
`assets/audio/music/`.

## Diegesis rule (read this first)

**Combat music is diegetic.** In combat, the *band you've assembled*
is what the player hears — the instrument-role party cards map to the
actual instruments in the mix. Rhythm-prompt hits are them playing.

**Non-combat music is composed.** The main-menu theme, map ambience,
rest nodes, and shops run composed tracks authored against `music.md`
and per-track `*.spec.md` files. These tracks are always on the
`Music` bus, can be swapped on scene transitions, and can be ducked by
UI SFX.

This separation is load-bearing for one of the three game pillars
(band composition) — never blur it. If a track could ever play behind
combat, stop and ask.

## SFX philosophy

- **Dry, short, present.** No long tails; nothing that blurs the next
  cue.
- All SFX route through the `SFX` bus.
- UI click, rhythm confirm, menu transitions are the only SFX
  families for now. Add new families to this doc before generating
  them.
- SFX must not drown out combat music in the mix — the band is louder
  than the confirm.

### UI clicks & navigation SFX

Use ElevenLabs `text_to_sound_effects`.

> Soft analog-synth blip, like a vintage tape-loop start or a warm
> subtractive pluck. Short, dry, one-shot. ~80-120ms. Friendly but
> understated; matches the warm psychedelic register without fighting
> music for attention.

### Rhythm-prompt hit SFX

> Tight percussive confirm. Hand-drum transient or a warm analog
> pluck with a snappy attack and short tail, ~150ms. Feels like part
> of the band, not a UI click.

SFX recipes stay inline here for now — the SFX library is small
enough that per-SFX specs would be overhead. Migrate to a spec system
modeled on music if the library grows.

## Volume defaults

- Music: `0.8` linear (≈ −1.9 dB)
- SFX: `0.8` linear (≈ −1.9 dB)

Rationale: 1.0 is full headroom / no attenuation, which on desktop
speakers or headphones can be uncomfortably loud at OS-level 50%.
0.8 leaves room to raise as well as lower from defaults.

## Implementation pointers

- Buses defined in `default_bus_layout.tres` (Master / Music / SFX).
- `AudioSettings` autoload is the only thing that should touch
  `AudioServer.set_bus_volume_db`. UI talks to `AudioSettings`.
- `AudioSettings` persists to `user://settings.tres`.
- Music files live in `assets/audio/music/`. Each has a sibling
  `<name>.spec.md` (consumed by `tools/generate_music.py`) and a
  `<name>.generated.json` provenance file. SFX live in
  `assets/audio/sfx/`.
- Music files import with `loop = true` if the spec has `loop: true`
  (the generation tool writes the `.import` sidecar).
