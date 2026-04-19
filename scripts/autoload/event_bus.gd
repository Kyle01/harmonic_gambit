extends Node

## Cross-system pub/sub bridge. The only cross-module communication path —
## see CLAUDE.md architecture rules. Systems emit; subscribers connect.

signal actor_window_opened(actor: Node)
signal band_bonus_changed(bonus: Resource)
signal music_volume_changed(linear: float)
signal sfx_volume_changed(linear: float)
