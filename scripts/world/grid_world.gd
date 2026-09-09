class_name GridWorld
extends Node2D

signal cell_occupant_changed(cell: Vector2i, occupant: Node2D)

@export_range(8, 128, 1) var grid_size := 32
@export var grid_dimensions := Vector2i(28, 16)
@export var show_blocked_cells := true
@export_node_path("TileMapLayer") var terrain_map_path: NodePath

const GRID_COLOR := Color("#385047")
const BLOCKED_COLOR := Color(0.78, 0.25, 0.20, 0.12)

var _blocked_cell_counts: Dictionary[Vector2i, int] = {}
var _cell_occupants: Dictionary[Vector2i, Node2D] = {}


func _ready() -> void:
	add_to_group("grid_world")
	_register_blocked_terrain_cells()
	queue_redraw()


func world_to_cell(world_position: Vector2) -> Vector2i:
	var local_position := to_local(world_position)
	return Vector2i(floori(local_position.x / grid_size), floori(local_position.y / grid_size))


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell * grid_size) + Vector2.ONE * (grid_size * 0.5)


func is_cell_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_dimensions.x and cell.y < grid_dimensions.y


func is_cell_walkable(cell: Vector2i) -> bool:
	return is_cell_in_bounds(cell) and _blocked_cell_counts.get(cell, 0) == 0


func try_register_cell_occupant(cell: Vector2i, occupant: Node2D) -> bool:
	if not is_cell_in_bounds(cell) or not is_instance_valid(occupant):
		return false
	var existing_occupant := get_cell_occupant(cell)
	if existing_occupant != null and existing_occupant != occupant:
		return false
	if existing_occupant == null and _blocked_cell_counts.get(cell, 0) > 0:
		return false
	if existing_occupant == occupant:
		return true
	_cell_occupants[cell] = occupant
	set_cell_blocked(cell, true)
	cell_occupant_changed.emit(cell, occupant)
	_notify_connection_neighbors(cell)
	return true


func unregister_cell_occupant(cell: Vector2i, occupant: Node2D) -> void:
	if get_cell_occupant(cell) != occupant:
		return
	_cell_occupants.erase(cell)
	set_cell_blocked(cell, false)
	cell_occupant_changed.emit(cell, null)
	_notify_connection_neighbors(cell)


func get_cell_occupant(cell: Vector2i) -> Node2D:
	var occupant: Node2D = _cell_occupants.get(cell)
	if occupant != null and not is_instance_valid(occupant):
		_cell_occupants.erase(cell)
		return null
	return occupant


func _notify_connection_neighbors(changed_cell: Vector2i) -> void:
	for offset in [Vector2i.ZERO, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		var occupant: Node2D = get_cell_occupant(changed_cell + offset)
		if occupant != null and occupant.has_method("refresh_grid_connections"):
			occupant.call_deferred("refresh_grid_connections")


func set_cell_blocked(cell: Vector2i, is_blocked: bool) -> void:
	if not is_cell_in_bounds(cell):
		return

	var current_count: int = _blocked_cell_counts.get(cell, 0)
	if is_blocked:
		_blocked_cell_counts[cell] = current_count + 1
	elif current_count <= 1:
		_blocked_cell_counts.erase(cell)
	else:
		_blocked_cell_counts[cell] = current_count - 1
	queue_redraw()


func get_cell_debug_state(cell: Vector2i) -> String:
	if not is_cell_in_bounds(cell):
		return "Out of bounds"
	return "Walkable" if is_cell_walkable(cell) else "Blocked"


func _register_blocked_terrain_cells() -> void:
	if terrain_map_path.is_empty():
		return
	var terrain_map := get_node_or_null(terrain_map_path) as TileMapLayer
	if terrain_map == null or not terrain_map.has_method("is_cell_walkable"):
		push_warning("GridWorld terrain map is missing or does not expose is_cell_walkable().")
		return
	for cell in terrain_map.get_used_cells():
		if not terrain_map.call("is_cell_walkable", cell):
			set_cell_blocked(cell, true)


func _draw() -> void:
	var room_size := Vector2(grid_dimensions * grid_size)

	for x in range(grid_dimensions.x + 1):
		var x_position := float(x * grid_size)
		draw_line(Vector2(x_position, 0.0), Vector2(x_position, room_size.y), GRID_COLOR)

	for y in range(grid_dimensions.y + 1):
		var y_position := float(y * grid_size)
		draw_line(Vector2(0.0, y_position), Vector2(room_size.x, y_position), GRID_COLOR)

	if show_blocked_cells:
		for cell in _blocked_cell_counts:
			draw_rect(Rect2(Vector2(cell * grid_size), Vector2.ONE * grid_size), BLOCKED_COLOR)

