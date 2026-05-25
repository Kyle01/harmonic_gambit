class_name ShopOffers
extends RefCounted

## TODO(shop-v2): Replace this naive offer roll with a proper generator.
## Today: uniform-random selection from all character / gambit / band cards,
## flat 5-credit card price, flat 4-credit item price, items are the full
## ItemCatalog with infinite stock. Future PR introduces rarity tiers,
## region-aware pricing, weighted card-kind mixing, and shop-archetype
## variants (alchemist vs. luthier vs. fence).
##
## Offer Dictionary shape:
##   kind  : StringName  — &"character" | &"gambit" | &"band" | &"item"
##   ref   : Resource    — CharacterDef | GambitCard | BandCard | ItemDef
##   price : int         — credits

const CARD_PRICE: int = 5
const ITEM_PRICE: int = 4
const MIN_CARD_OFFERS: int = 3
const MAX_CARD_OFFERS: int = 6


static func roll_card_offers(rng: RandomNumberGenerator) -> Array:
	var pool: Array = []
	for def: CharacterDef in CharacterCatalog.get_all():
		pool.append({"kind": &"character", "ref": def, "price": CARD_PRICE})
	for card: GambitCard in GambitCardCatalog.get_all():
		pool.append({"kind": &"gambit", "ref": card, "price": CARD_PRICE})
	for card: BandCard in BandCardCatalog.get_all():
		pool.append({"kind": &"band", "ref": card, "price": CARD_PRICE})
	_shuffle_in_place(pool, rng)
	var count: int = rng.randi_range(MIN_CARD_OFFERS, MAX_CARD_OFFERS)
	count = mini(count, pool.size())
	return pool.slice(0, count)


static func item_offers() -> Array:
	var offers: Array = []
	for item: ItemDef in ItemCatalog.get_all():
		offers.append({"kind": &"item", "ref": item, "price": ITEM_PRICE})
	return offers


static func _shuffle_in_place(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
