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

## Realm (run-level meta-map) navigation. Same intent/result split as
## the region signals: realm_node_chosen is UI player intent;
## RealmRunController validates and emits realm_advanced. Fired with
## the chosen RealmNode's region_id so subscribers know what region
## the player is heading into. realm_region_completed is fired by the
## in-region "Go to next region" UI when the run is realm-driven.
signal realm_built(realm: Realm)
signal realm_node_chosen(node_id: int)
signal realm_advanced(prev_node_id: int, new_node_id: int, region_id: StringName)
signal realm_region_completed

## Run-state mutations. Fired by every system that writes to GameState's
## per-run fields so UI/telemetry subscribers don't have to poll. `Card`
## covers both `GambitCard` and `BandCard` — subscribers can is-check.
signal credits_changed(new_total: int)
signal item_acquired(item: ItemDef)
signal card_acquired(card: Card)
signal character_recruited(def: CharacterDef)
