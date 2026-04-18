class_name TestArena
extends Node2D

## Hello-world combat scene. Loads gambit + enemy resources, starts the
## shared timer, handles EventBus.actor_window_opened by asking
## GambitEngine for a ResolvedAction, then applies it.

const PLAYER_GAMBIT_PATH: String = "res://resources/gambits/attack_nearest.tres"
const GOBLIN_DEF_PATH: String = "res://resources/enemies/goblin.tres"
const PLAYER_DAMAGE: int = 8
const GOBLIN_DAMAGE: int = 4

var party: Array[Node] = []
var enemies: Array[Node] = []

@onready var player: Player = $Player
@onready var goblin: Goblin = $Goblin
@onready var rhythm_prompt: RhythmPrompt = $CanvasLayer/RhythmPrompt
@onready var log_label: Label = $CanvasLayer/Log


func _ready() -> void:
	var attack_nearest: GambitDef = load(PLAYER_GAMBIT_PATH)
	player.gambits = [attack_nearest]

	var goblin_def: EnemyDef = load(GOBLIN_DEF_PATH)
	goblin.enemy_def = goblin_def
	goblin.hp = goblin_def.max_hp

	party = [player]
	enemies = [goblin]

	EventBus.actor_window_opened.connect(_on_actor_window)
	TurnManager.start_combat(party, enemies)
	_log("combat started — player %d hp, goblin %d hp" % [player.hp, goblin.hp])


func get_party() -> Array[Node]:
	return party


func get_enemies() -> Array[Node]:
	return enemies


func _on_actor_window(actor: Node) -> void:
	var action: ResolvedAction = GambitEngine.evaluate(actor, self)
	if action == null:
		_log("%s: no valid gambit" % actor.name)
		return
	_apply_action(action)


func _apply_action(action: ResolvedAction) -> void:
	rhythm_prompt.pulse()
	var damage: int = PLAYER_DAMAGE if action.actor == player else GOBLIN_DAMAGE
	_log("%s → %s on %s (%d dmg)" % [action.actor.name, action.action_id, action.target.name, damage])
	match action.action_id:
		&"attack":
			action.target.take_damage(damage)
			_log("  %s hp: %d" % [action.target.name, action.target.hp])
			if action.target.hp <= 0:
				_log("%s fell — combat ends" % action.target.name)
				TurnManager.stop_combat()


func _log(msg: String) -> void:
	print("[arena] %s" % msg)
	if log_label != null:
		log_label.text = "%s\n%s" % [log_label.text, msg]
