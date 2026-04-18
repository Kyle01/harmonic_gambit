extends Node

## Per-run state: current floor, party roster, inventory, seed. Reset between
## runs. Persistent meta-state lives in CardCatalog, not here.

var current_floor: int = 0
var party: Array[Node] = []
var inventory: Array[Resource] = []
var run_seed: int = 0
