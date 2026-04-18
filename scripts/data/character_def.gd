class_name CharacterDef
extends Resource

## Playable character template. instrument_role is what BandComposer
## matches against a BandCard's required_roles.

@export var id: StringName = &""
@export var display_name: String = ""
@export var sprite_frames: SpriteFrames = null
@export var instrument_role: StringName = &""
@export var max_hp: int = 20
@export var speed: float = 1.0
@export var starting_gambits: Array[GambitDef] = []
