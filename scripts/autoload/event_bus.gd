extends Node

## Cross-system pub/sub bridge. The only cross-module communication path —
## see CLAUDE.md architecture rules. Systems emit; subscribers connect.

signal actor_window_opened(actor: Node)
signal music_volume_changed(linear: float)
signal sfx_volume_changed(linear: float)

## Region-run navigation. UI emits region_node_chosen as player intent;
## a system listens, validates, mutates the active Region, and emits
## region_advanced so any number of UI/system subscribers can react.
signal region_node_chosen(node_id: int)
signal region_advanced(prev_node_id: int, new_node_id: int, kind: int)
