extends SceneTree

const TEST_SCENE := preload("res://scenes/test/foundation_test.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := TEST_SCENE.instantiate()
	root.add_child(world)
	await process_frame

	var building := world.get_node_or_null("BrickStorehouse")
	_assert(building != null, "The test scene should contain the brick storehouse.")
	_assert(building.is_in_group("building"), "The storehouse should be discoverable as a building.")
	_assert(building.get_node_or_null("Body/CollisionShape2D") != null, "The storehouse needs physical collision.")

	var expected_cells: Array[Vector2i] = [
		Vector2i(8, 3), Vector2i(9, 3), Vector2i(8, 4), Vector2i(9, 4),
	]
	var occupied_cells: Array[Vector2i] = building.get_occupied_cells()
	for expected_cell in expected_cells:
		_assert(expected_cell in occupied_cells, "Storehouse footprint should include %s." % expected_cell)
		_assert(not world.is_cell_walkable(expected_cell), "Storehouse cell %s should be blocked." % expected_cell)

	_assert(world.get_node_or_null("HayBales") != null, "The storehouse should have matching hay-bale dressing.")
	_assert(world.get_node_or_null("SackCrate") != null, "The storehouse should have matching sack-crate dressing.")

	world.queue_free()
	await process_frame
	print("ISOMETRIC BUILDING TEST PASSED: art, props, collision, and grid footprint are valid.")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
