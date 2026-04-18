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

var scheduling_model: SchedulingModel = SchedulingModel.SHARED_PARTY_TIMER


func start_combat(_party: Array[Node], _enemies: Array[Node]) -> void:
	pass


func stop_combat() -> void:
	pass
