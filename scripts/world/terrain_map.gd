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
@export_range(0.02, 1.0, 0.01) var automatic_refresh_interval := 0.1

var _refresh_queued := false
var _is_applying_variations := false
var _refresh_elapsed := 0.0
var _last_tile_data_hash := 0
var visual_revision := 0


func _ready() -> void:
	_last_tile_data_hash = hash(tile_map_data)
	if not changed.is_connected(_on_terrain_changed):
		changed.connect(_on_terrain_changed)
	_schedule_terrain_refresh()


func _process(delta: float) -> void:
	_refresh_elapsed += delta
	if _refresh_elapsed < automatic_refresh_interval:
		return
	_refresh_elapsed = 0.0
	var current_hash := hash(tile_map_data)
	if current_hash != _last_tile_data_hash:
		_last_tile_data_hash = current_hash
		_schedule_terrain_refresh()


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
	if automatic_variations or selected_variation < 0:
		selected_variation = get_deterministic_variation(cell)
	selected_variation = posmod(selected_variation, VARIATION_COUNT)
	set_cell(cell, 0, Vector2i(TERRAIN_ATLAS_COLUMNS[terrain_id], selected_variation), 0)
	_last_tile_data_hash = hash(tile_map_data)
	_schedule_terrain_refresh()
	return true


func apply_deterministic_variations() -> void:
	if _is_applying_variations:
		return
	_is_applying_variations = true
	for cell in get_used_cells():
		var atlas_coordinates := get_cell_atlas_coords(cell)
		if atlas_coordinates.x < 0:
			continue
		var selected_variation := get_deterministic_variation(cell)
		if atlas_coordinates.y != selected_variation:
			set_cell(cell, get_cell_source_id(cell), Vector2i(atlas_coordinates.x, selected_variation), get_cell_alternative_tile(cell))
	_is_applying_variations = false
	_last_tile_data_hash = hash(tile_map_data)


func get_deterministic_variation(cell: Vector2i) -> int:
	var mixed := (cell.x * 73856093) ^ (cell.y * 19349663) ^ (variation_seed * 83492791)
	return posmod(mixed, VARIATION_COUNT)


func refresh_blending() -> void:
	var overlay := get_node_or_null("TerrainBlendOverlay")
	if overlay != null:
		overlay.queue_redraw()


func _on_terrain_changed() -> void:
	if not _is_applying_variations:
		_schedule_terrain_refresh()


func _schedule_terrain_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	call_deferred("_refresh_terrain")


func _refresh_terrain() -> void:
	_refresh_queued = false
	if automatic_variations:
		apply_deterministic_variations()
	refresh_blending()
	visual_revision += 1
