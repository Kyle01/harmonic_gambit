class_name ItemDef
extends Resource

## Run-acquired item template (potions, tonics, keys). Stack rule, on-use
## effect, and rarity are deliberately omitted until a consumption-runtime
## PR lands.

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var art: Texture2D = null
