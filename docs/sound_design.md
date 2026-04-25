# Sound Design

This is the continuity brief for every piece of audio in the game — music,
SFX, ambience. Read before generating any new audio with ElevenLabs (or any
other source) and before tuning volumes, buses, or audio-adjacent UI.

*Tonal direction for the world lives in `world.md`; this doc translates
that direction into sonic rules.*

## North star

Late-1960s psychedelic communion. Warm, saturated, analog-sounding —
tape warmth, tube glow, instruments you can hear people playing.
Expansive: swirling reverbs, reversed sounds, generous space,
instruments panning wide. Sincerely uplifting on the surface — a
hippie anthem at the right depth — with subtle wrongness in the mix:
something slightly off-pitch in the background, a note that sustains
too long, a reverb tail that goes somewhere you didn't send it.

The single most important adjective is **exaggerated**. Everything
the Realm feels, the music feels more of. More color, more warmth,
more ache.

Genre coordinates: psychedelic rock (Jefferson Airplane, Grateful
Dead, early Pink Floyd), orchestral psychedelic pop (*Yellow
Submarine* soundtrack), acid folk (Vashti Bunyan, Tyrannosaurus Rex).
Synesthetic crossover à la Psychonauts 2's PSI King's Sensorium —
genres blur, instruments are expressive of color. Full tonal anchor
in `world.md`.

## Diegesis rule (read this first)

**Combat music is diegetic.** In combat, the *band you've assembled* is what
the player hears — the instrument-role party cards map to the actual
instruments in the mix. Rhythm-prompt hits are them playing.

**Non-combat music is composed.** The main-menu theme, map ambience, rest
nodes, and shops run composed tracks authored against this doc. These
tracks are always on the `Music` bus, can be swapped on scene transitions,
and can be ducked by UI SFX.

This separation is load-bearing for one of the three game pillars (band
composition) — never blur it. If a track could ever play behind combat,
stop and ask.

## Per-context directives

| Context       | Source     | Mood directive                                                                                              |
|---------------|------------|-------------------------------------------------------------------------------------------------------------|
| Main menu     | Composed   | Warm psychedelic communion. 60-80 BPM, loopable 75-90s. Tropeless hippie anthem; slight wrongness under it. |
| Map (FTL-node)| Composed   | Traveling-between-fights. Sparser than main menu; same palette. Dreamy, drifting.                           |
| Rest node     | Composed   | Softer, warmer, almost lullaby. A touch less exaggerated — the Realm lets you breathe here.                 |
| Shop          | Composed   | More rhythmic and curious, jauntier. Still psychedelic, still warm.                                         |
| Combat        | Diegetic   | Driven by party composition; do not author a backing track.                                                 |
| Rhythm prompt | Diegetic   | Within-combat; see combat.                                                                                  |

## ElevenLabs prompt recipes

Keep these stable — rewrites drift the aesthetic. Edit here, not ad-hoc at
call time. The `compose_music` MCP tool is the default entry point.

### Theme / menu / map

> Warm late-1960s psychedelic music. Analog instruments — electric
> guitar with tape-warm amp, Hammond-style organ, flutes, tambourine,
> soft brass. Slow-to-medium tempo (60-80 BPM). Loopable. Rich stereo
> with swirling plate reverb and subtle phasing. Sincere, blissful,
> expansive — a hippie anthem, not a parody. Underneath the bliss, a
> subtle wrongness: an instrument slightly out of tune, a sustained
> note that goes a beat too long, a reverb tail heading somewhere you
> didn't send it. No vocals. Exaggerated warmth. Woodstock soundcheck
> crossed with the *Yellow Submarine* soundtrack.

Length: 75–90s for main menu, 45–60s for map loops.
Output: prefer Ogg Vorbis; convert MP3 if that's all ElevenLabs returns.

### Rest node

> Same palette as main theme, softer. Acoustic guitar fingerpicks,
> flute, gentle tambourine, hand-drum pulse. Warmer mids, less
> swirling reverb. Brief major-key lift once per loop, then back to
> space. 50-70s. The Realm lets you breathe here.

### UI clicks & navigation SFX

Use `text_to_sound_effects`.

> Soft analog-synth blip, like a vintage tape-loop start or a warm
> subtractive pluck. Short, dry, one-shot. ~80-120ms. Friendly but
> understated; matches the warm psychedelic register without fighting
> music for attention.

### Rhythm-prompt hit SFX

> Tight percussive confirm. Hand-drum transient or a warm analog
> pluck with a snappy attack and short tail, ~150ms. Feels like part
> of the band, not a UI click.

## SFX philosophy

- **Dry, short, present.** No long tails; nothing that blurs the next cue.
- All SFX route through the `SFX` bus.
- UI click, rhythm confirm, menu transitions are the only SFX families for
  now. Add new families to this doc before generating them.
- SFX must not drown out combat music in the mix — the band is louder than
  the confirm.

## Volume defaults

- Music: `0.0` linear (muted) — **dev-only default, revert to `0.8` before ship**
- SFX: `0.8` linear (≈ −1.9 dB)

Rationale: music is temporarily muted by default because the developer
is iterating and doesn't want the theme playing on every launch. Flip
`UserSettings.music_volume_linear` back to `0.8` before shipping — the
player should hear the theme the first time they open the menu. SFX
stays at 0.8: 1.0 is full headroom / no attenuation, which on desktop
speakers or headphones can be uncomfortably loud at OS-level 50%, and
0.8 gives room to raise as well as lower.

## Implementation pointers

- Buses defined in `default_bus_layout.tres` (Master / Music / SFX).
- `AudioSettings` autoload is the only thing that should touch
  `AudioServer.set_bus_volume_db`. UI talks to `AudioSettings`.
- `AudioSettings` persists to `user://settings.tres`.
- Music files live in `assets/audio/music/`, SFX in `assets/audio/sfx/`.
  Import `.ogg` with `loop = true` for music beds.
