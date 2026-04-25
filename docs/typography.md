# Typography

The project ships two typefaces, both from Ten by Twenty's Munro
family — one designer, three coordinated weights, redistributed under
the SIL Open Font License 1.1.

## Choices

| Role | Font file | Use |
|---|---|---|
| Display / titles | `assets/fonts/munro.ttf` | Headings, screen titles, archetype names. Larger sizes. |
| Body / UI | `assets/fonts/munro_small.ttf` | Buttons, labels, body copy, descriptions. Designed for compact 8 px tall rendering. |
| Reserved | `assets/fonts/munro_narrow.ttf` | Available for tight columns / per-stat numeric readouts. Not currently wired into the Theme. |

Why Munro: clean, minimalist pixel font designed for 10 pt and
multiples; doesn't fight the saturated psychedelic art (the art
carries the visual character; the type is the quiet supporting
voice). Coordinated family avoids the "two-different-pixel-grids"
clash that mixed-author pixel fonts often introduce. Explicit OFL
1.1 license — clean redistribution provenance.

## License

Copyright © 2007 Ten by Twenty (http://tenbytwenty.com). Distributed
under SIL Open Font License 1.1. Full license text in
`assets/fonts/OFL.txt` — required to ship with the binaries per OFL §2.

## Predecessor (replaced)

`assets/fonts/alagard.ttf` and `assets/fonts/silkscreen.ttf` predate
this PR. They remain in the repo for now to keep prior `.tscn`
references resolving — once every scene migrates to the centralized
Theme (see `resources/theme/main_theme.tres`), they can be removed.
Do not introduce new references to either; the Munro family is the
go-forward choice.

## Wiring

Use the project Theme rather than inline `theme_override_fonts/*`
entries:

```
[ext_resource type="Theme" path="res://resources/theme/main_theme.tres"]
[node name="Root" type="Control"]
theme = ExtResource("...")
```

A label inheriting the Theme picks up the body font automatically;
a header label sets `theme_type_variation = "Header"` to inherit the
display font with the title size. See `main_theme.tres` for the
declared type variations.
