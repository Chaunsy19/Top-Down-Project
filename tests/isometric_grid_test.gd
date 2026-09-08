extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run_tests")


func run_tests() -> void:
	var world := (load("res://scenes/test/foundation_test.tscn") as PackedScene).instantiate()
	root.add_child(world)
	await physics_frame
	await physics_frame

	if world.cell_size != Vector2(64.0, 32.0) or world.grid_dimensions != Vector2i(14, 14):
		_failures.append("Foundation world does not use the expected 2:1 isometric grid.")
	for cell in [Vector2i(0, 0), Vector2i(1, 12), Vector2i(7, 7), Vector2i(12, 1), Vector2i(13, 13)]:
		var world_position: Vector2 = world.to_global(world.cell_to_world(cell))
		if world.world_to_cell(world_position) != cell:
			_failures.append("Isometric cell %s did not round-trip." % cell)
	for grid_position in [Vector2(1.25, 2.75), Vector2(6.5, 7.5), Vector2(11.8, 3.2)]:
		var projected_world_position: Vector2 = world.to_global(world.grid_position_to_local(grid_position))
		if not world.world_to_grid_position(projected_world_position).is_equal_approx(grid_position):
			_failures.append("Continuous isometric position %s did not round-trip." % grid_position)

	var polygon: PackedVector2Array = world.get_cell_polygon(Vector2i(7, 7))
	if polygon.size() != 4 or not (polygon[1] - polygon[3]).is_equal_approx(Vector2(64.0, 0.0)) or not (polygon[2] - polygon[0]).is_equal_approx(Vector2(0.0, 32.0)):
		_failures.append("Grid cells are not rendered as 64×32 diamonds.")
	var boundary := world.get_node_or_null("IsometricBoundary")
	if boundary == null or boundary.get_child_count() != 4:
		_failures.append("Generated isometric room boundary is incomplete.")
	if not world.y_sort_enabled:
		_failures.append("World Y-sorting is not enabled.")

	var expected_cells := {
		"Player": Vector2i(7, 7),
		"TestTerminal": Vector2i(6, 7),
		"Tree": Vector2i(3, 4),
		"Rock": Vector2i(9, 3),
		"BerryBush": Vector2i(8, 9),
		"SupplyCrate": Vector2i(3, 10),
		"LooseSticks": Vector2i(5, 5),
		"LooseStones": Vector2i(11, 9),
		"Campfire": Vector2i(10, 7),
	}
	for node_name in expected_cells:
		var world_node := world.get_node_or_null(node_name) as Node2D
		if world_node == null or world.world_to_cell(world_node.global_position) != expected_cells[node_name]:
			_failures.append("%s is not anchored to its intended logical isometric cell." % node_name)

	world.queue_free()
	await process_frame
	finish()


func finish() -> void:
	if _failures.is_empty():
		print("ISOMETRIC GRID TEST PASSED: projection, diamonds, placement, sorting, and boundaries are valid.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)
