class_name EventCatalog
extends RefCounted

## Static catalog of authored EventDef resources. Mirrors RegionCatalog and
## GambitCardCatalog. Scans res://resources/events/ at call-time; sorted by
## display_name.

const EVENTS_DIR: String = "res://resources/events"


static func get_all() -> Array[EventDef]:
	var results: Array[EventDef] = []
	var dir: DirAccess = DirAccess.open(EVENTS_DIR)
	if dir == null:
		push_warning("EventCatalog: cannot open %s" % EVENTS_DIR)
		return results
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and _is_resource_file(file_name):
			var path: String = "%s/%s" % [EVENTS_DIR, file_name]
			var res: Resource = load(path)
			if res is EventDef:
				results.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()
	results.sort_custom(_by_display_name)
	return results


static func _is_resource_file(file_name: String) -> bool:
	return file_name.ends_with(".tres") or file_name.ends_with(".res")


static func _by_display_name(a: EventDef, b: EventDef) -> bool:
	var a_key: String = a.display_name if a.display_name != "" else str(a.id)
	var b_key: String = b.display_name if b.display_name != "" else str(b.id)
	return a_key.naturalnocasecmp_to(b_key) < 0
