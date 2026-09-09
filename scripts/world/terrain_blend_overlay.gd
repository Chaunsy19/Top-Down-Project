@tool
class_name TerrainBlendOverlay
extends Node2D

const TILE_SIZE := 32
const BLEND_DIRECTION_COUNT := 4
const BLEND_TEXTURE := preload("res://art/terrain/generated_terrain_blends.png")
const NEIGHBORS := [
	{ "offset": Vector2i.UP, "direction": 0 },
	{ "offset": Vector2i.RIGHT, "direction": 1 },
	{ "offset": Vector2i.DOWN, "direction": 2 },
	{ "offset": Vector2i.LEFT, "direction": 3 },
]

var _terrain_map: TerrainMap


func _ready() -> void:
	_terrain_map = get_parent() as TerrainMap
	queue_redraw()


func _draw() -> void:
	if _terrain_map == null or _terrain_map.tile_set == null:
		return
	var half_tile := Vector2.ONE * TILE_SIZE * 0.5
	for cell in _terrain_map.get_used_cells():
		var current_priority := _terrain_map.get_blend_priority(cell)
		var current_terrain := _terrain_map.get_terrain_id(cell)
		for neighbor_definition in NEIGHBORS:
			var neighbor_cell: Vector2i = cell + neighbor_definition.offset
			var neighbor_priority := _terrain_map.get_blend_priority(neighbor_cell)
			if neighbor_priority < 0:
				continue
			var is_same_terrain := _terrain_map.get_terrain_id(neighbor_cell) == current_terrain
			if not is_same_terrain and neighbor_priority <= current_priority:
				continue
			var neighbor_atlas := _terrain_map.get_cell_atlas_coords(neighbor_cell)
			if neighbor_atlas.x < 0 or neighbor_atlas.y < 0:
				continue
			var direction: int = neighbor_definition.direction
			var source_position := Vector2(neighbor_atlas.x * TILE_SIZE, (neighbor_atlas.y * BLEND_DIRECTION_COUNT + direction) * TILE_SIZE)
			var destination := Rect2(_terrain_map.map_to_local(cell) - half_tile, Vector2.ONE * TILE_SIZE)
			var modulation := Color(1.0, 1.0, 1.0, 0.5) if is_same_terrain else Color.WHITE
			draw_texture_rect_region(BLEND_TEXTURE, destination, Rect2(source_position, Vector2.ONE * TILE_SIZE), modulation)
