@tool
class_name TerrainMap
extends TileMapLayer

const TERRAIN_DATA_LAYER := "terrain_id"
const WALKABLE_DATA_LAYER := "walkable"
const BLEND_PRIORITY_DATA_LAYER := "blend_priority"
const VARIATION_COUNT := 8
const TERRAIN_ATLAS_COLUMNS := {
	&"grassy_dirt": 0,
	&"grass": 1,
	&"shallow_water": 2,
	&"deep_water": 3,
	&"sand": 4,
}

@export var automatic_variations := true
@export var variation_seed := 1979


func _ready() -> void:
	if not Engine.is_editor_hint() and automatic_variations:
		apply_deterministic_variations()
	refresh_blending()


func get_terrain_id(cell: Vector2i) -> StringName:
	var tile_data := get_cell_tile_data(cell)
	if tile_data == null:
		return &"void"
	return StringName(tile_data.get_custom_data(TERRAIN_DATA_LAYER))


func is_cell_walkable(cell: Vector2i) -> bool:
	var tile_data := get_cell_tile_data(cell)
	return tile_data != null and bool(tile_data.get_custom_data(WALKABLE_DATA_LAYER))


func get_blend_priority(cell: Vector2i) -> int:
	var tile_data := get_cell_tile_data(cell)
	return int(tile_data.get_custom_data(BLEND_PRIORITY_DATA_LAYER)) if tile_data != null else -1


func paint_terrain(cell: Vector2i, terrain_id: StringName, variation := -1) -> bool:
	if not TERRAIN_ATLAS_COLUMNS.has(terrain_id):
		push_warning("Unknown terrain ID: %s" % terrain_id)
		return false
	var selected_variation := variation
	if selected_variation < 0:
		selected_variation = get_deterministic_variation(cell)
	selected_variation = posmod(selected_variation, VARIATION_COUNT)
	set_cell(cell, 0, Vector2i(TERRAIN_ATLAS_COLUMNS[terrain_id], selected_variation), 0)
	refresh_blending()
	return true


func apply_deterministic_variations() -> void:
	for cell in get_used_cells():
		var atlas_coordinates := get_cell_atlas_coords(cell)
		if atlas_coordinates.x < 0:
			continue
		var selected_variation := get_deterministic_variation(cell)
		if atlas_coordinates.y != selected_variation:
			set_cell(cell, get_cell_source_id(cell), Vector2i(atlas_coordinates.x, selected_variation), get_cell_alternative_tile(cell))
	refresh_blending()


func get_deterministic_variation(cell: Vector2i) -> int:
	var mixed := (cell.x * 73856093) ^ (cell.y * 19349663) ^ (variation_seed * 83492791)
	return posmod(mixed, VARIATION_COUNT)


func refresh_blending() -> void:
	var overlay := get_node_or_null("TerrainBlendOverlay")
	if overlay != null:
		overlay.queue_redraw()
