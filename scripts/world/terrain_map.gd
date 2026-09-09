@tool
class_name TerrainMap
extends TileMapLayer

const TERRAIN_DATA_LAYER := "terrain_id"
const WALKABLE_DATA_LAYER := "walkable"


func get_terrain_id(cell: Vector2i) -> StringName:
	var tile_data := get_cell_tile_data(cell)
	if tile_data == null:
		return &"void"
	return StringName(tile_data.get_custom_data(TERRAIN_DATA_LAYER))


func is_cell_walkable(cell: Vector2i) -> bool:
	var tile_data := get_cell_tile_data(cell)
	return tile_data != null and bool(tile_data.get_custom_data(WALKABLE_DATA_LAYER))
