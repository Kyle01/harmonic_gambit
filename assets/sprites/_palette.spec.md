---
output: resources/theme/palette.tres
asset_type: palette
slots:
  - bg
  - surface
  - text_primary
  - text_secondary
  - accent_warm
  - accent_cool
  - danger
  - success
  - outline
---

# UI palette

Derive a coherent UI palette for a 16-bit pixel-art game set in a
psychedelic dreamscape — late-60s hippie-utopia aesthetic, technicolor
saturation, sunset / dream-hour / gold-hour light. The palette drives
every UI surface (menu backgrounds, panel fills, button labels, accent
flourishes), so the choices must hold together across the whole app —
not just look pretty in isolation.

## Slot semantics

| Slot | Role |
|---|---|
| `bg` | The deepest background layer behind every UI surface. Establishes the room. May be deep, but **must remain warm-toned** (no grey-brown, no cold-neutral). |
| `surface` | Mid-depth panel fills above `bg`. Slightly lighter / warmer than `bg` so panels read as raised. |
| `text_primary` | Headings, primary copy. Maximally readable on `surface`. |
| `text_secondary` | Body copy, secondary labels. Readable on `surface`, with hue distinct from `text_primary` — this contrast is part of the Realm's Technicolor signature. |
| `accent_warm` | Primary interactive accent — hover states, key emphasis. Warm side of the palette (gold-orange / coral / rose). |
| `accent_cool` | Secondary accent — informational highlights, link-equivalents. Cool side of the warm palette (cornflower / electric green / sea-glass) — never neon, never cyber. |
| `danger` | HP loss, error states, irreversible-action confirmations. The "wrongness" channel; saturated, slightly off-pitch. |
| `success` | HP gain, confirmations, positive feedback. Warm-saturated green. |
| `outline` | Hairline outlines and dividers. Slightly darker than `bg` so it reads as edge, not as a separate color. |

## Discipline

- **Yellow-green center of gravity.** The palette's dominant
  register is gold-yellow + chartreuse + moss-green + sun-gold.
  Rose / coral / cornflower appear as accents and warm anchors,
  but yellow and green are the two hues that define the Realm.
  Think: late-60s poster art printed on sun-bleached paper, a
  meadow at golden hour, chartreuse silk.
- **No grey-brown. No desaturation.** If a candidate hex looks
  muted, push the saturation up.
- **Warm-weighted.** The whole palette should sit on the warm side
  of the wheel even where individual slots reach toward cool. The
  Realm's "always warm light" rule applies to UI too.
- **Sunset, not midday.** Lean toward gold-hour temperatures over
  high-noon brightness.
- **Distinct hues per slot.** Two slots must not be near-duplicates
  — Technicolor saturation requires hue separation, not just
  lightness shift.
- **Readable.** `text_primary` on `surface` and `text_secondary` on
  `surface` must both pass casual contrast — Realm-bright but not
  illegible.
- **Slot hue steering.** Recommended hue families:
  - `bg`: deep warm green-teal (moss / forest-after-dusk).
  - `surface`: warmer / lighter green or olive, lifted from `bg`.
  - `text_primary`: gold-yellow (hero color).
  - `text_secondary`: chartreuse or citron (lime-adjacent).
  - `accent_warm`: gold-orange / sun-amber.
  - `accent_cool`: sea-glass or jade (green-leaning, never
    cornflower-dominant).
  - `danger`: saturated coral / rose-red.
  - `success`: electric grass-green.
  - `outline`: darkest member of the green family.

## Output format

Reply with a single fenced ```json code block, mapping each slot
name above to a `#RRGGBB` hex string. No alpha, no prose, no
comments inside the JSON.
