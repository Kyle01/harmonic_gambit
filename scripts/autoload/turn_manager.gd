extends Node

## Authoritative combat heartbeat. One shared party action-timer paced by
## party average speed. When an actor's window opens, emits
## EventBus.actor_window_opened(actor) so GambitEngine can resolve their
## next action. No Timer nodes for gameplay — see CLAUDE.md.
##
## SchedulingModel is intentionally abstract: the shared-timer design is
## novel, so swap-in per-actor ATB must remain possible during prototyping.

enum SchedulingModel {
	SHARED_PARTY_TIMER,
	PER_ACTOR_ATB,
}

const TICK_INTERVAL: float = 1.5

var scheduling_model: SchedulingModel = SchedulingModel.SHARED_PARTY_TIMER

var _party: Array[Node] = []
var _enemies: Array[Node] = []
var _running: bool = false
var _cursor: int = 0
var _accumulator: float = 0.0


func start_combat(party: Array[Node], enemies: Array[Node]) -> void:
	_party = party
	_enemies = enemies
	_running = true
	_cursor = 0
	_accumulator = 0.0


func stop_combat() -> void:
	_running = false


func _process(delta: float) -> void:
	if not _running:
		return
	_accumulator += delta
	if _accumulator >= TICK_INTERVAL:
		_accumulator = 0.0
		_fire_next_actor()


func _fire_next_actor() -> void:
	var roster: Array[Node] = []
	for a in _party:
		if _alive(a):
			roster.append(a)
	for e in _enemies:
		if _alive(e):
			roster.append(e)
	if roster.is_empty():
		_running = false
		return
	var actor: Node = roster[_cursor % roster.size()]
	_cursor += 1
	EventBus.actor_window_opened.emit(actor)


func _alive(actor: Node) -> bool:
	if actor == null or not is_instance_valid(actor):
		return false
	if not ("hp" in actor):
		return false
	return actor.hp > 0
