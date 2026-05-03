---
path: assets/sprites/realm/the_realm_bg.png
asset_type: abstract_background
seed: 42
---

# The Realm — meta-map background

A pure abstract color-field painting in chartreuse green-gold.

The painting is a vertical stack of soft horizontal color-fields,
all in the chartreuse / yellow-green / green-gold register. The
whole canvas is one continuous chord of green-gold light. Color
sits in bands; bands drift in luminance; bands dissolve into
each other through heavy ordered dithering. Color and atmosphere
only — purely abstract.

The painting will sit behind small colored discs at runtime, so
it must stay quiet and recede. Meditative, suspended, glowing.

## Palette: chartreuse / green-gold

Every pixel of the painting is in the chartreuse range:

- Pale chartreuse (a luminous pale yellow-green like backlit
  parchment).
- Warm chartreuse (a glowing yellow-green — the dominant tone).
- Deep chartreuse (a saturated green-gold — rich and luminous).

The painting is monochromatic in the sense that every band and
every dither pixel falls inside this single yellow-green chord.

## Composition

A vertical stack of three soft horizontal chartreuse fields:

- Top: pale chartreuse, the brightest tone, glowing slightly.
- Middle: warm chartreuse holding steady — the dominant tone,
  filling roughly the center half of the canvas.
- Bottom: deep chartreuse along the lower edge.

Each field is solid color with gentle luminance drift inside
it; transitions between fields happen across a 30–60 pixel
zone of heavy ordered Bayer-style dithering, where one
chartreuse interleaves with the next via small checkered
pixel patterns that read as a soft gradient from a distance.

## Texture

A tactile pixel grain across the whole canvas — gentle
luminance variation within each chartreuse field. A few
slightly brighter pockets in the warm-chartreuse mid-field
act as soft inner glows, as if the canvas is lit from behind
in places.

## Lineage

In the lineage of Rothko's color-field abstractions and
Helen Frankenthaler's stained color compositions: pure color,
purely abstract, contemplative.

## Frame and aspect

- 16:9 source aspect (400×225 at the pixflux ceiling; runtime
  upscales to 1280×720 with Nearest filter).
- Bands run *horizontally* — along the long axis of the image.
- Full-bleed canvas, edge-to-edge chartreuse.
