class_name Goblin
extends CharacterBody2D

## Goblin actor. Reads stats + gambits from an EnemyDef resource so the
## content stays data-driven per CLAUDE.md.

signal health_changed(new_hp: int)
signal died

@export var enemy_def: EnemyDef = null

var hp: int = 0


func _ready() -> void:
	if enemy_def != null:
		hp = enemy_def.max_hp


func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	health_changed.emit(hp)
	if hp <= 0:
		died.emit()


func get_gambits() -> Array[GambitDef]:
	if enemy_def == null:
		return []
	return enemy_def.default_gambits
