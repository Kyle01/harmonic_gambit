# Sound Design

This is the continuity brief for every piece of audio in the game — music,
SFX, ambience. Read before generating any new audio with ElevenLabs (or any
other source) and before tuning volumes, buses, or audio-adjacent UI.

## North star

Atmospheric, minimalist synthwave. Synthesizer and electronic-piano forward.
Melancholy — favor minor keys, suspended chords, and unresolved motion. The
single most important adjective is **restful**: the mix breathes, rests are
part of the composition, and nothing fights the player for attention. Quiet
is a choice we make deliberately, not a ceiling we happen to hit. When in
doubt, simpler + quieter + more space.

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

| Context       | Source     | Mood directive                                                                 |
|---------------|------------|---------------------------------------------------------------------------------|
| Main menu     | Composed   | The north star, verbatim. Loopable, 60–90s. Establish the color of the game.   |
| Map (FTL-node)| Composed   | Even quieter than main menu. Sparser. Traveling-between-fights energy.         |
| Rest node     | Composed   | Warm, small, almost lullaby. Permit a slightly major lift but hold it brief.   |
| Shop          | Composed   | Slightly more rhythmic + curious, still restrained. No upbeat pop energy.      |
| Combat        | Diegetic   | Driven by party composition; do not author a backing track.                    |
| Rhythm prompt | Diegetic   | Within-combat; see combat.                                                     |

## ElevenLabs prompt recipes

Keep these stable — rewrites drift the aesthetic. Edit here, not ad-hoc at
call time. The `compose_music` MCP tool is the default entry point.

### Theme / menu / map

> Atmospheric minimalist synthwave. Solo analog synthesizer and soft
> electronic piano. Minor key, slow tempo (60–75 BPM), sparse texture with
> generous rests and breath between phrases. Melancholy but calm — the
> feeling of walking through a quiet city at night. No drums, or a single
> faint heartbeat kick at most. No vocals. Loopable. Restful, understated,
> never dramatic.

Length: 75–90s for main menu, 45–60s for map loops.
Output: prefer Ogg Vorbis; convert MP3 if that's all ElevenLabs returns.

### Rest node

> Same palette as the main theme. A little warmer, softer high end. Brief
> suspended-to-resolved lift once per loop, then back to space. 50–70s.
> Same instruments, same key family, just a touch more hopeful.

### UI clicks & navigation SFX

Use `text_to_sound_effects`.

> Soft pixel-UI blip. Short, dry, one-shot. Synth-sine with a sharp attack
> and a very short decay, no reverb. Around 80–120 ms. Friendly but not
> cheerful — matches a melancholy synthwave menu.

### Rhythm-prompt hit SFX

> Tight percussive confirm. Subtractive-synth pluck with a snappy transient
> and a short tail, ~150 ms. No ambient tail; must sit cleanly on top of
> the band mix during combat.

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
