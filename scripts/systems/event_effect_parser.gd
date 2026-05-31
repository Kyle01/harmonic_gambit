class_name EventEffectParser
extends RefCounted

## Shared parser for the event-effect mini-DSL. Both the admin
## `EventRunDemo` (which renders effects without applying them) and the
## runtime `EventEffectApplier` consume the same parser so the two paths
## cannot drift on syntax. New verbs land here once and both paths see them.
##
## Effect format: "verb:arg1:arg2:..." — colon-separated tokens. The first
## token is the verb, the remainder are positional args as raw strings.
## Numeric / id coercion is the caller's responsibility.

const VERB_GAIN_CREDITS: StringName = &"gain_credits"
const VERB_HEAL_PARTY: StringName = &"heal_party"
const VERB_RECRUIT: StringName = &"recruit"
const VERB_GAIN_ITEM: StringName = &"gain_item"
const VERB_GAIN_GAMBIT_CARD: StringName = &"gain_gambit_card"
const VERB_GAIN_BAND_CARD: StringName = &"gain_band_card"

const KNOWN_VERBS: Array[StringName] = [
	VERB_GAIN_CREDITS,
	VERB_HEAL_PARTY,
	VERB_RECRUIT,
	VERB_GAIN_ITEM,
	VERB_GAIN_GAMBIT_CARD,
	VERB_GAIN_BAND_CARD,
]


## Parse an effect string into `{verb: StringName, args: Array[String]}`.
## Unknown verb → push_error + `verb == &""`, so callers fail loud rather
## than silently treating the effect as a no-op.
static func parse(effect: String) -> Dictionary:
	var parts: PackedStringArray = effect.split(":")
	if parts.is_empty() or parts[0] == "":
		push_error("EventEffectParser: empty effect string")
		return {"verb": &"", "args": []}
	var verb: StringName = StringName(parts[0])
	var args: Array[String] = []
	for i: int in range(1, parts.size()):
		args.append(parts[i])
	if not KNOWN_VERBS.has(verb):
		push_error("EventEffectParser: unknown verb '%s' in effect '%s'" % [verb, effect])
		return {"verb": &"", "args": args}
	return {"verb": verb, "args": args}
