class_name EventEffectApplier
extends RefCounted

## Runtime applier for the event-effect mini-DSL. Consumes the same
## `EventEffectParser` the admin `EventRunDemo` formatter uses, so the
## two paths cannot drift on syntax. New verbs land in the parser once
## and both paths see them. Mutates `GameState` directly and emits the
## matching `EventBus` signal on every change so subscribers don't have
## to poll.
##
## `heal_party` is an intentional no-op — the per-character HP system is
## out of scope; the verb stays valid so authored content keeps parsing.


static func apply(effect: String, column: int, def: EventDef) -> void:
	var token: Dictionary = EventEffectParser.parse(effect)
	var verb: StringName = token.get("verb", &"")
	var args: Array = token.get("args", [])
	var mult: float = EventResolver.column_multiplier(def, column)
	match verb:
		EventEffectParser.VERB_GAIN_CREDITS:
			_apply_gain_credits(args, mult)
		EventEffectParser.VERB_HEAL_PARTY:
			pass
		EventEffectParser.VERB_RECRUIT:
			_apply_recruit(args)
		EventEffectParser.VERB_GAIN_ITEM:
			_apply_gain_item(args)
		EventEffectParser.VERB_GAIN_GAMBIT_CARD:
			_apply_gain_gambit_card(args)
		EventEffectParser.VERB_GAIN_BAND_CARD:
			_apply_gain_band_card(args)


static func _apply_gain_credits(args: Array, mult: float) -> void:
	if args.is_empty():
		push_error("EventEffectApplier: gain_credits missing amount arg")
		return
	var base: int = String(args[0]).to_int()
	var scaled: int = int(ceil(float(base) * mult))
	GameState.credits += scaled
	EventBus.credits_changed.emit(GameState.credits)


static func _apply_recruit(args: Array) -> void:
	if args.size() < 2:
		push_error("EventEffectApplier: recruit needs <character_id>:<level>")
		return
	var character_id: StringName = StringName(String(args[0]))
	var def: CharacterDef = _find_character(character_id)
	if def == null:
		push_error("EventEffectApplier: unknown character id '%s'" % character_id)
		return
	GameState.owned_characters.append(def)
	EventBus.character_recruited.emit(def)


static func _apply_gain_item(args: Array) -> void:
	if args.is_empty():
		push_error("EventEffectApplier: gain_item missing item id")
		return
	var item_id: StringName = StringName(String(args[0]))
	var item: ItemDef = _find_item(item_id)
	if item == null:
		push_error("EventEffectApplier: unknown item id '%s'" % item_id)
		return
	GameState.inventory.append(item)
	EventBus.item_acquired.emit(item)


static func _apply_gain_gambit_card(args: Array) -> void:
	if args.is_empty():
		push_error("EventEffectApplier: gain_gambit_card missing card id")
		return
	var card_id: StringName = StringName(String(args[0]))
	var card: GambitCard = _find_gambit_card(card_id)
	if card == null:
		push_error("EventEffectApplier: unknown gambit card id '%s'" % card_id)
		return
	GameState.owned_gambit_cards.append(card)
	EventBus.card_acquired.emit(card)


static func _apply_gain_band_card(args: Array) -> void:
	if args.is_empty():
		push_error("EventEffectApplier: gain_band_card missing card id")
		return
	var card_id: StringName = StringName(String(args[0]))
	var card: BandCard = _find_band_card(card_id)
	if card == null:
		push_error("EventEffectApplier: unknown band card id '%s'" % card_id)
		return
	GameState.owned_band_cards.append(card)
	EventBus.card_acquired.emit(card)


static func _find_character(id: StringName) -> CharacterDef:
	for def: CharacterDef in CharacterCatalog.get_all():
		if def.id == id:
			return def
	return null


static func _find_item(id: StringName) -> ItemDef:
	for def: ItemDef in ItemCatalog.get_all():
		if def.id == id:
			return def
	return null


static func _find_gambit_card(id: StringName) -> GambitCard:
	for card: GambitCard in GambitCardCatalog.get_all():
		if card.id == id:
			return card
	return null


static func _find_band_card(id: StringName) -> BandCard:
	for card: BandCard in BandCardCatalog.get_all():
		if card.id == id:
			return card
	return null
