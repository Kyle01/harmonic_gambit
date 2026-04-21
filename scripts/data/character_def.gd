class_name CharacterDef
extends Resource

## Playable character template. instrument_role is what BandComposer matches
## against a BandCard's required_roles. learn_list declares which AbilityDefs
## unlock at which level during a run; level-1 entries are the starters.
##
## Stats use linear growth: stat_at_level(L) = base + growth * (L - 1).
## Growth-shape variants (late-bloomer, front-loaded) are deferred — see
## docs/gdd.md "Known open questions".

@export var id: StringName = &""
@export var display_name: String = ""
@export var sprite_frames: SpriteFrames = null
@export var instrument_role: StringName = &""

@export_group("Stats")
@export var base_hp: int = 20
@export var hp_growth: int = 2
@export var base_mp: int = 10
@export var mp_growth: int = 1
@export var base_atk: int = 5
@export var atk_growth: int = 1
@export var base_def: int = 3
@export var def_growth: int = 1
@export var base_pow: int = 5
@export var pow_growth: int = 1
@export var base_spd: int = 5
@export var spd_growth: int = 1

@export_group("Progression")
@export var learn_list: Array[LearnEntry] = []

@export_group("Presentation")
@export var portrait: Texture2D = null
@export var flavor: String = ""


static func stat_at_level(base: int, growth: int, level: int) -> int:
	return base + growth * (level - 1)
