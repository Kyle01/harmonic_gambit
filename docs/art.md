# Art

Design reference for pixel-art generation. The verbose creative
brief lives in `docs/world.md`; this doc captures the universal
visual rules so authors of per-asset `.spec.md` files have one
canonical reference. Specs are self-contained — this doc is not
concatenated into prompts at runtime; instead, anything that needs
to reach the model is inlined into the spec body or the
`SUBJECT_LEADS` block in `tools/generate_art.py`.

The "Universal style" section below and `tools/generate_art.py →
SUBJECT_LEADS` describe the same aesthetic to two different
audiences (designers vs. the model). Keep them in sync — drift
means the model ships against a different brief than humans
authored to.

## Universal style

- **16-bit pixel art.** SNES / Genesis density. Hand-painted
  pixels. Anti-aliased curves. Soft dithering. Limited shading
  bands per surface (2–4), not the many-band gradient density of
  PS1-2D. Not 8-bit / NES flat. Not photorealistic. Not vector
  smooth.
- **Painted, not rendered.** No PBR sheen, raytrace glints, AO.
- **Warm-weighted, impossibly saturated.** Sunset / dream-hour /
  gold-hour. Pastel rainbows, rose-pink, electric green, gold-
  orange, cornflower, coral. If a color could be muted, it
  shouldn't be.
- **Sincere, not parody.** Psychedelic communion. Never wink-at-
  the-camera "60s pastiche."
- **Subtle wrongness underneath.** Intensity per asset; menus &
  most portraits dial near zero.
- **Breathing.** Static frames imply motion.

## Lineage (the visual DNA)

- Late-60s psych poster: Heinz Edelmann (*Yellow Submarine*),
  Peter Max, Wes Wilson, Victor Moscoso.
- Art-nouveau ancestors: Mucha (decorative panels), Klimt (gold
  ornament), Toorop (symbolist line).
- Dreamscape: Moebius (clean line, dream logic), Roger Dean
  (biomorphic — leave the prog-fantasy connotation).
- Synesthetic pop: Keiichi Tanaami (saturated AND unsettling).

## Shape & light

- Organic, flowing, melting. Curves over hard angles.
- Exaggerated scale: flowers bigger than houses; horizons curved
  the wrong way.
- Light always warm. Sunset / glow / gold-hour, never midday.

## DO NOT generate

Photorealism, PBR sheen, gritty grunge, muted/grey-brown, harsh
geometry, hard shadows, cyberpunk neon, medieval-fantasy
silhouettes (knights/castles/dragons/runes), modern UI chrome
(drop shadows, glassmorphism), 8-bit/NES/chiptune/arcade pixel,
32-bit / PS1-2D gradient density, anime moe/chibi/waifu,
pin-up / sexualized / "realistic hot" character design,
baked-in text or game title.

## Format

PNG, RGBA-8. Project filter is Nearest — internal anti-aliasing
fine. Portraits: opaque (interior + border are part of the art).
Scene backgrounds: full-bleed.
