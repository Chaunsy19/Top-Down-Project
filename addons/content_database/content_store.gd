@tool
extends RefCounted

const TYPES := [
	["Items", "items", "items/item_definition", "item_catalog", "items", "item_id"],
	["Buildings", "buildings", "building/building_definition", "building_catalog", "buildings", "building_id"],
	["Resource nodes", "resource_nodes", "resource_nodes/resource_node_definition", "resource_node_catalog", "resource_nodes", "node_id"],
	["Recipes", "recipes", "recipes/recipe_definition", "recipe_catalog", "recipes", "recipe_id"],
	["Workstations", "workstations", "workstations/workstation_definition", "workstation_catalog", "workstations", "workstation_id"],
	["Skills", "skills", "skills/skill_definition", "skill_catalog", "skills", "skill_id"],
]

static func files_under(directory: String, extensions: Array = ["tres"]) -> PackedStringArray:
	var result := PackedStringArray()
	var dir := DirAccess.open(directory)
	if dir == null:
		return result
	for file in dir.get_files():
		if file.get_extension() in extensions:
			result.append(directory.path_join(file))
	for folder in dir.get_directories():
		if not folder.begins_with("."):
			result.append_array(files_under(directory.path_join(folder), extensions))
	result.sort()
	return result

static func records(kind: int) -> Array[Resource]:
	var result: Array[Resource] = []
	var script_path := "res://scripts/data/%s.gd" % TYPES[kind][2]
	for path in files_under("res://data/" + TYPES[kind][1]):
		var resource := load(path)
		if resource != null and resource.get_script() == load(script_path):
			result.append(resource)
	return result

static func validate_records(kind: int, entries: Array[Resource]) -> PackedStringArray:
	var errors := PackedStringArray()
	var ids := {}
	for entry in entries:
		var id := String(entry.get(TYPES[kind][5]))
		if id.is_empty() or ids.has(id):
			errors.append("Missing or duplicate ID: %s (%s)" % [id, entry.resource_path])
		ids[id] = true
		if entry.has_method("validate"):
			for error in entry.validate():
				errors.append("%s: %s" % [id, error])
	return errors

static func rebuild(kind: int) -> String:
	var entries := records(kind)
	var errors := validate_records(kind, entries)
	if not errors.is_empty():
		return "\n".join(errors)
	var path := "res://data/catalogs/%s.tres" % TYPES[kind][3]
	var catalog := load(path)
	var old_value: Variant = catalog.get(TYPES[kind][4])
	catalog.set(TYPES[kind][4], entries)
	var error := ResourceSaver.save(catalog, path)
	if error != OK:
		catalog.set(TYPES[kind][4], old_value)
		return "Could not save catalog: %s" % error_string(error)
	return ""

static func create_record(kind: int, id: String, source: Resource = null) -> String:
	if id.is_empty() or id != id.to_snake_case() or not id.is_valid_identifier():
		return "Use a lowercase identifier such as iron_axe."
	for entry in records(kind):
		if String(entry.get(TYPES[kind][5])) == id:
			return "That ID already exists."
	var folder: String = "res://data/" + TYPES[kind][1]
	var path: String = folder.path_join(id + ".tres")
	if FileAccess.file_exists(path):
		return "That file already exists."
	DirAccess.make_dir_recursive_absolute(folder)
	var entry: Resource = source.duplicate() if source != null else load("res://scripts/data/%s.gd" % TYPES[kind][2]).new()
	entry.set(TYPES[kind][5], StringName(id))
	entry.set("display_name", id.replace("_", " ").capitalize())
	var error := ResourceSaver.save(entry, path)
	return "" if error == OK else error_string(error)

static func references_to(kind: int, entry: Resource) -> PackedStringArray:
	var refs := PackedStringArray()
	var catalog_path := "res://data/catalogs/%s.tres" % TYPES[kind][3]
	for path in files_under("res://", ["tres", "tscn", "gd"]):
		if path == entry.resource_path or path == catalog_path or path.begins_with("res://addons/content_database/"):
			continue
		var contents := FileAccess.get_file_as_string(path)
		var uid := ResourceUID.id_to_text(ResourceLoader.get_resource_uid(entry.resource_path))
		var referenced := contents.contains(entry.resource_path) or (uid != "uid://<invalid>" and contents.contains(uid))
		referenced = referenced or contents.contains('"' + String(entry.get(TYPES[kind][5])) + '"')
		if referenced:
			refs.append(path)
	return refs
