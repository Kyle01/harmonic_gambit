class_name LearnEntry
extends Resource

## One entry in `CharacterDef.learn_list`: the character knows `ability` once
## they reach `level`. Level-1 entries are the starting abilities. Known
## abilities strictly accumulate — no Pokemon-style replacement.

@export var level: int = 1
@export var ability: AbilityDef = null
