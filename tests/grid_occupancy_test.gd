extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var packed_main := load("res://scenes/main.tscn") as PackedScene
	var main := packed_main.instantiate()
	root.add_child(main)
	await physics_frame
	await physics_frame

	var world := main.get_node("FoundationTest")
	var rock_scene := load("res://scenes/world/resource_node.tscn") as PackedScene
	var rock_definition: Resource = root.get_node("ContentRegistry").get_resource_node(&"rock")
	var cluster_cells := _find_open_cluster(world)
	_assert(cluster_cells.size() == 3, "The test map needs one open L-shaped cluster for occupancy coverage.")
	if cluster_cells.size() != 3:
		main.queue_free()
		await process_frame
		quit(1)
		return
	var rock := _spawn_rock(world, rock_scene, rock_definition, cluster_cells[0], "TestRock")
	var rock_east := _spawn_rock(world, rock_scene, rock_definition, cluster_cells[1], "TestRockEast")
	var rock_south := _spawn_rock(world, rock_scene, rock_definition, cluster_cells[2], "TestRockSouth")
	await physics_frame
	await physics_frame

	_assert(rock.global_position == world.to_global(world.cell_to_world(rock.get_occupied_cell())), "Blocking objects should snap to cell centers.")
	_assert(world.get_cell_occupant(rock.get_occupied_cell()) == rock, "The grid should identify the object occupying a cell.")
	_assert(rock.get_connection_mask() == 6, "The corner stone should connect east and south; got %d." % rock.get_connection_mask())
	_assert(rock_east.get_connection_mask() == 8, "The east stone should connect west; got %d." % rock_east.get_connection_mask())
	_assert(rock_south.get_connection_mask() == 1, "The south stone should connect north; got %d." % rock_south.get_connection_mask())

	var duplicate := Node2D.new()
	world.add_child(duplicate)
	_assert(not world.try_register_cell_occupant(rock.get_occupied_cell(), duplicate), "A second blocking object must not claim an occupied cell.")
	_assert(not world.try_register_cell_occupant(Vector2i.ZERO, duplicate), "Placed objects must not claim blocked terrain or boundary cells.")
	duplicate.queue_free()

	var mined_cell: Vector2i = rock.get_occupied_cell()
	rock.take_damage(rock.health.current_health, &"melee")
	await process_frame
	_assert(world.get_cell_occupant(mined_cell) == null, "Mining out stone should release its occupied cell.")
	_assert(world.is_cell_walkable(mined_cell), "A mined-out stone cell should become walkable.")
	_assert(rock_east.get_connection_mask() == 0, "Neighbor connections should refresh when stone is removed; got %d." % rock_east.get_connection_mask())

	main.queue_free()
	await process_frame
	if _failures.is_empty():
		print("GRID OCCUPANCY TEST PASSED: snapping, ownership, exclusivity, and stone connections are valid.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _find_open_cluster(world: GridWorld) -> Array[Vector2i]:
	for y in range(1, world.grid_dimensions.y - 1):
		for x in range(1, world.grid_dimensions.x - 1):
			var center := Vector2i(x, y)
			var east := center + Vector2i.RIGHT
			var south := center + Vector2i.DOWN
			if world.is_cell_walkable(center) and world.is_cell_walkable(east) and world.is_cell_walkable(south):
				return [center, east, south]
	return []


func _spawn_rock(world: GridWorld, rock_scene: PackedScene, definition: Resource, cell: Vector2i, node_name: String) -> HarvestableResourceNode:
	var rock := rock_scene.instantiate() as HarvestableResourceNode
	rock.name = node_name
	rock.definition = definition
	rock.position = world.cell_to_world(cell)
	world.add_child(rock)
	return rock
