---
path: assets/sprites/ui/main_menu_bg.png
asset_type: background
---

# Main menu background

The first image the player sees. The **start of a journey** —
the Realm unfurling ahead. A winding path leads from the
viewer's foreground into a vast warm-toned psychedelic vista.
Inviting, sincere, no tension; the wrongness dialed nearly to
zero (save those cues for the map / rest / combat surfaces).

## Scene

A winding dirt / stone path that begins in the foreground
(lower-center, near the viewer) and curves back into the
landscape, receding over rolling hills toward a glowing
horizon. The path is the composition's spine — the eye
follows it *into* the picture.

Along the path: a tree or two, tall swaying flowers, a small
standing-stone or signpost at the first bend — threshold
markers that say "a journey starts here." Past the hills: a
sky filled with pastel-rainbow gradient (gold-yellow →
chartreuse → cornflower → rose), a sun sitting a beat too low
and too large, maybe a second sun or a moon overlapping.

Dream-logic welcome: flowers bigger than houses, the horizon
curved gently upward at the edges, hills that breathe.

## Composition

- 16:9 aspect (matches the 1280×720 logical viewport at
  category defaults: 400×225 source, scaled up at runtime via
  Nearest filter).
- **Path as leading line.** Foreground bottom-center →
  midground curve → distant horizon. Classic threshold /
  vanishing-point composition.
- **Open vertical sweep.** Sky holds the top 60% of the
  canvas. Title text and menu buttons will sit on top, so
  leave the upper-center relatively uncluttered (glowing
  sky, no hard silhouettes through the text zone).
- **No baked-in title.** Do not generate the game's name into
  the art. Text is a Godot Label rendered on top.

## Style anchors

- **Heinz Edelmann, Yellow Submarine** — psychedelic journey
  vistas, saturated flat-color-field landscapes, winding
  roads through rolling hills.
- **Moebius (Jean Giraud)** — cosmic threshold composition,
  figure-at-edge-of-vast-vista energy, clean line + dream-
  logic horizons.
- **Peter Max** — warm-saturated rainbow sky, sun-low-on-
  horizon cosmic-pop register.
- 16-bit pixel art register per `docs/art.md` — soft
  dithering in the gradients, limited shading bands per
  surface, anti-aliased silhouettes.

## What to avoid

- Hard horizon line. The horizon should glow and bleed, not
  snap.
- Architecture, structures, signage with text. A small
  standing-stone or wordless signpost is fine; a building
  or a lettered sign is not.
- A road with lane markings, tarmac, or modern infrastructure.
  The path is a dirt track or a worn trail through the land.
- Cool-neutral palettes, grey-brown, dusk-leaning toward
  night. The light is sunset, not twilight.
- Centered focal subject blocking the menu area. Leave the
  upper-center visually quiet for title and buttons.
- Modern sky-photo realism. Painted, not photographic.
- Figures / characters in the scene — this is a landscape, not
  a portrait. The player supplies the traveler.
