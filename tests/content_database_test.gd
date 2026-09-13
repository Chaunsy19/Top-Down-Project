extends SceneTree
const Store = preload("res://addons/content_database/content_store.gd")
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for kind in Store.TYPES.size():
		var entries := Store.records(kind)
		check(not entries.is_empty(), "Content exists for " + Store.TYPES[kind][0])
		var errors := Store.validate_records(kind, entries)
		check(errors.is_empty(), "Valid content: " + str(errors))
		var duplicate := entries.duplicate()
		duplicate.append(entries[0])
		check(not Store.validate_records(kind, duplicate).is_empty(), "Duplicate IDs rejected")
	var wood: Resource = load("res://data/items/wood.tres")
	check(not Store.references_to(0, wood).is_empty(), "Referenced item cannot be removed")
	check(not Store.create_record(0, "wood", wood).is_empty(), "Existing ID cannot be overwritten")
	check(not Store.create_record(0, "../unsafe", wood).is_empty(), "Path traversal rejected")
	var id := "database_test_" + str(Time.get_ticks_usec())
	var result := Store.create_record(0, id, wood)
	check(result.is_empty(), "Duplicate creation succeeds")
	var path := "res://data/items/" + id + ".tres"
	if result.is_empty():
		var copy: Resource = load(path)
		check(String(copy.item_id) == id and copy.weight == wood.weight, "Duplicate preserves values with new identity")
		check(wood.item_id == &"wood", "Original unchanged")
		DirAccess.remove_absolute(path)
	var registry := root.get_node("ContentRegistry")
	check(registry.get_skill(&"mining").display_name == "Mining", "Skill definitions available at runtime")
	if failures.is_empty():
		print("CONTENT DATABASE TEST PASSED")
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)
