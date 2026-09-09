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

	var world := main.get_node("FoundationTest") as GridWorld
	var terrain := world.get_node("StarterIsland") as TerrainMap
	_assert(terrain.get_terrain_id(Vector2i(14, 8)) == &"grassy_dirt", "The starter clearing should use grassy dirt.")
	_assert(terrain.get_terrain_id(Vector2i(8, 5)) == &"grass", "The inner island should use grass.")
	_assert(terrain.get_terrain_id(Vector2i(2, 7)) == &"shallow_water", "The island edge should use shallow water.")
	_assert(terrain.get_terrain_id(Vector2i.ZERO) == &"deep_water", "The outer map should use deep water.")
	_assert(terrain.is_cell_walkable(Vector2i(14, 8)), "Dirt should be walkable.")
	_assert(terrain.is_cell_walkable(Vector2i(8, 5)), "Grass should be walkable.")
	_assert(terrain.is_cell_walkable(Vector2i(2, 7)), "Shallow water should be walkable.")
	_assert(not terrain.is_cell_walkable(Vector2i.ZERO), "Deep water should not be walkable.")
	var sand_cells := 0
	var used_variations: Dictionary[int, bool] = {}
	for cell in terrain.get_used_cells():
		if terrain.get_terrain_id(cell) == &"sand":
			sand_cells += 1
		used_variations[terrain.get_cell_atlas_coords(cell).y] = true
	_assert(sand_cells > 0, "The starter island should demonstrate a sand shoreline.")
	_assert(used_variations.size() > 1, "Runtime terrain painting should apply multiple deterministic texture variations.")
	_assert(terrain.get_node_or_null("TerrainBlendOverlay") is TerrainBlendOverlay, "The starter island should include its soft terrain-blend overlay.")
	var atlas_source := terrain.tile_set.get_source(0) as TileSetAtlasSource
	_assert(atlas_source != null and atlas_source.get_tiles_count() == 40, "Five terrains should each expose eight paintable tile variations.")
	var temporary_cell := Vector2i(40, 40)
	var revision_before_paint := terrain.visual_revision
	terrain.set_cell(temporary_cell, 0, Vector2i(4, 0), 0)
	terrain._process(terrain.automatic_refresh_interval)
	await process_frame
	_assert(terrain.get_terrain_id(temporary_cell) == &"sand", "Directly placed tiles should retain their terrain metadata.")
	_assert(terrain.get_cell_atlas_coords(temporary_cell).y == terrain.get_deterministic_variation(temporary_cell), "Direct editor or generator placement should automatically receive a stable variation.")
	_assert(terrain.visual_revision > revision_before_paint, "Any TileMap change should automatically refresh variations and blends.")
	terrain.erase_cell(temporary_cell)
	_assert(_blend_edges_sample_neighbor_boundaries(), "Blend tiles should sample the matching opposite neighbor edge at full boundary opacity.")
	_assert(world.is_cell_walkable(Vector2i(14, 8)), "GridWorld should expose walkable land.")
	_assert(not world.is_cell_walkable(Vector2i.ZERO), "GridWorld should register deep water as blocked.")

	var deep_tile_data := terrain.get_cell_tile_data(Vector2i.ZERO)
	var shallow_tile_data := terrain.get_cell_tile_data(Vector2i(2, 7))
	_assert(deep_tile_data.get_collision_polygons_count(0) == 1, "Deep water should carry a collision polygon.")
	_assert(shallow_tile_data.get_collision_polygons_count(0) == 0, "Shallow water should not carry collision.")

	var player := world.get_node("Player") as PlayerController
	player.position = terrain.map_to_local(Vector2i(2, 7))
	await physics_frame
	_assert(player.test_move(player.global_transform, Vector2.LEFT * 16.0), "The player should physically collide when moving from shallow into deep water.")

	main.queue_free()
	await process_frame
	if _failures.is_empty():
		print("TERRAIN MAP TEST PASSED: five terrains, automatic variations, seamless neighbor blending, painting, walking rules, and deep-water collision are valid.")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _blend_edges_sample_neighbor_boundaries() -> bool:
	var base_texture := load("res://art/terrain/generated_terrain_atlas.png") as Texture2D
	var blend_texture := load("res://art/terrain/generated_terrain_blends.png") as Texture2D
	if base_texture == null or blend_texture == null:
		return false
	var base_image := base_texture.get_image()
	var blend_image := blend_texture.get_image()
	var neighbor_left_edge := base_image.get_pixel(0, 16)
	var east_overlay_boundary := blend_image.get_pixel(31, 32 + 16)
	return (
		is_equal_approx(neighbor_left_edge.r, east_overlay_boundary.r)
		and is_equal_approx(neighbor_left_edge.g, east_overlay_boundary.g)
		and is_equal_approx(neighbor_left_edge.b, east_overlay_boundary.b)
		and east_overlay_boundary.a > 0.99
	)
