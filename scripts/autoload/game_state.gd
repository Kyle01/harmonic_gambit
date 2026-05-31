extends Node

## Per-run state: current floor, party roster, inventory, owned cards/characters,
## active realm, credits/chips, run seed. Reset between runs via
## `reset_for_new_run(seed)`. Persistent meta-state lives in CardCatalog, not here.

var current_floor: int = 0
var party: Array[Node] = []
var inventory: Array[ItemDef] = []
var run_seed: int = 0

var credits: int = 0
var chips: int = 0
var owned_characters: Array[CharacterDef] = []
var owned_gambit_cards: Array[GambitCard] = []
var owned_band_cards: Array[BandCard] = []
var active_realm: Realm = null
var intro_fired: bool = false


func reset_for_new_run(seed: int) -> void:
	current_floor = 0
	party = []
	inventory = []
	run_seed = seed
	credits = 0
	chips = 0
	owned_characters = []
	owned_gambit_cards = []
	owned_band_cards = []
	active_realm = null
	intro_fired = false
