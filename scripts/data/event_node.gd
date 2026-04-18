class_name EventNode
extends Resource

## A node in the FTL-style run map: combat / lore / shop / etc. The map
## is a graph of these; run state tracks which one is current.

enum Kind {
	COMBAT,
	ELITE,
	LORE,
	SHOP,
	REST,
}

@export var id: StringName = &""
@export var kind: Kind = Kind.COMBAT
@export var title: String = ""
@export var description: String = ""
