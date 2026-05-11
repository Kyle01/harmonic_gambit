class_name ItemCatalog
extends RefCounted

const ITEMS_DIR: String = "res://resources/items"


static func get_all() -> Array[ItemDef]:
	var results: Array[ItemDef] = []
	var dir: DirAccess = DirAccess.open(ITEMS_DIR)
	if dir == null:
		push_warning("ItemCatalog: cannot open %s" % ITEMS_DIR)
		return results
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and _is_resource_file(file_name):
			var path: String = "%s/%s" % [ITEMS_DIR, file_name]
			var res: Resource = load(path)
			if res is ItemDef:
				results.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()
	results.sort_custom(_by_display_name)
	return results


static func _is_resource_file(file_name: String) -> bool:
	return file_name.ends_with(".tres") or file_name.ends_with(".res")


static func _by_display_name(a: ItemDef, b: ItemDef) -> bool:
	var a_key: String = a.display_name if a.display_name != "" else str(a.id)
	var b_key: String = b.display_name if b.display_name != "" else str(b.id)
	return a_key.naturalnocasecmp_to(b_key) < 0
