class_name PaletteDef
extends Resource

## Single source-of-truth UI palette. Generated from
## `assets/sprites/_palette.spec.md` via `tools/generate_palette.py`,
## consumed by the project Theme and any UI code that needs a Color
## by name. Matches the slot list in the spec frontmatter — adding a
## slot here also requires adding it there (and re-running the generator).

@export var bg: Color = Color(0.08, 0.04, 0.18, 1)
@export var surface: Color = Color(0.16, 0.08, 0.32, 1)
@export var text_primary: Color = Color(0.78, 0.94, 1, 1)
@export var text_secondary: Color = Color(0.98, 0.42, 0.82, 1)
@export var accent_warm: Color = Color(1, 0.6, 0.4, 1)
@export var accent_cool: Color = Color(0.5, 0.8, 1, 1)
@export var danger: Color = Color(1, 0.3, 0.45, 1)
@export var success: Color = Color(0.4, 1, 0.6, 1)
@export var outline: Color = Color(0.12, 0.04, 0.22, 1)
