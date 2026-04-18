class_name Card
extends Resource

## Base card type. GambitCard and BandCard inherit. This layer only holds
## the shared catalog metadata — specific payload lives on subclasses.

@export var id: StringName = &""
@export var display_name: String = ""
@export var art: Texture2D = null
@export var flavor: String = ""
