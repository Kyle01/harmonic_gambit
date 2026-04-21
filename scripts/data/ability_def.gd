class_name AbilityDef
extends Resource

## An atomic move a character can learn. `LearnEntry` references this to
## level-gate a character's known abilities, and `GambitDef.action_id` will
## resolve here once the stringly-typed ref is tightened (follow-up PR).
##
## Abilities are authored as inline SubResources inside a character's `.tres`,
## not as standalone files — keeps the learn set colocated with the character.
##
## `category` ("damage" | "support") drives category-rigid stat scaling:
## damage scales the caster's ATK, support scales the caster's POW. `scope`
## ("single" | "all" | "chain") declares targeting pattern; the combat
## engine (follow-up PR) reads it to resolve hits. Both are `@export_enum`
## String fields — `.tres` files stay self-documenting (readable string
## values, not integer indices) AND the editor constrains author choices to
## the declared set.
##
## Ability success is driven by the player's rhythm prompt, not by stats —
## stats only modulate magnitudes.

@export var id: StringName = &""
@export var display_name: String = ""
@export var flavor: String = ""
@export_enum("damage", "support") var category: String = "damage"
@export_enum("single", "splash", "chain", "all") var scope: String = "single"
@export var base_power: int = 0
@export var mp_cost: int = 0
