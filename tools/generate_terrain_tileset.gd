extends SceneTree

const TILE_SIZE := 32
const VARIATION_COUNT := 8
const ATLAS_PATH := "res://art/terrain/generated_terrain_atlas.png"
const TILESET_PATH := "res://data/terrain/starter_terrain_tileset.tres"

const TERRAIN_DEFINITIONS := [
	{ "id": &"grassy_dirt", "walkable": true, "blend_priority": 3 },
	{ "id": &"grass", "walkable": true, "blend_priority": 4 },
	{ "id": &"shallow_water", "walkable": true, "blend_priority": 1 },
	{ "id": &"deep_water", "walkable": false, "blend_priority": 0 },
	{ "id": &"sand", "walkable": true, "blend_priority": 2 },
]


func _initialize() -> void:
	var texture := load(ATLAS_PATH) as Texture2D
	if texture == null:
		push_error("Generated atlas has not been imported yet: %s" % ATLAS_PATH)
		quit(1)
		return

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i.ONE * TILE_SIZE
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	_add_custom_data_layer(tile_set, "terrain_id", TYPE_STRING_NAME)
	_add_custom_data_layer(tile_set, "walkable", TYPE_BOOL)
	_add_custom_data_layer(tile_set, "blend_priority", TYPE_INT)

	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i.ONE * TILE_SIZE
	tile_set.add_source(source, 0)
	for terrain_index in TERRAIN_DEFINITIONS.size():
		var definition: Dictionary = TERRAIN_DEFINITIONS[terrain_index]
		for variation in VARIATION_COUNT:
			var coordinates := Vector2i(terrain_index, variation)
			source.create_tile(coordinates)
			var tile_data := source.get_tile_data(coordinates, 0)
			tile_data.set_custom_data("terrain_id", definition.id)
			tile_data.set_custom_data("walkable", definition.walkable)
			tile_data.set_custom_data("blend_priority", definition.blend_priority)
			if not definition.walkable:
				tile_data.add_collision_polygon(0)
				tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
					Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16),
				]))
	var save_error := ResourceSaver.save(tile_set, TILESET_PATH)
	if save_error != OK:
		push_error("Could not save terrain TileSet: %s" % error_string(save_error))
		quit(1)
		return
	print("TERRAIN TILESET GENERATED: 40 paintable tiles with gameplay metadata and deep-water collision.")
	quit(0)


func _add_custom_data_layer(tile_set: TileSet, layer_name: String, layer_type: Variant.Type) -> void:
	var layer_index := tile_set.get_custom_data_layers_count()
	tile_set.add_custom_data_layer(layer_index)
	tile_set.set_custom_data_layer_name(layer_index, layer_name)
	tile_set.set_custom_data_layer_type(layer_index, layer_type)
