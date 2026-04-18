class_name EnemyDef
extends Resource

## Enemy template: base stats, sprite, and the default gambit list that
## drives its combat AI. Instances read from this at spawn time.

@export var id: StringName = &""
@export var display_name: String = ""
@export var sprite_frames: SpriteFrames = null
@export var max_hp: int = 10
@export var speed: float = 1.0
@export var default_gambits: Array[GambitDef] = []
