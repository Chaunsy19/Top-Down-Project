class_name GridWorld
extends Node2D

@export_range(8, 128, 1) var grid_size := 32
@export var grid_dimensions := Vector2i(28, 16)
@export var show_blocked_cells := true

const FLOOR_COLOR := Color("#25352f")
const GRID_COLOR := Color("#385047")
const WALL_COLOR := Color("#9b7859")
const BLOCKED_COLOR := Color(0.78, 0.25, 0.20, 0.12)

var _blocked_cell_counts: Dictionary[Vector2i, int] = {}


func _ready() -> void:
	add_to_group("grid_world")
	_register_boundary_cells()
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


func _register_boundary_cells() -> void:
	for x in grid_dimensions.x:
		set_cell_blocked(Vector2i(x, 0), true)
		set_cell_blocked(Vector2i(x, grid_dimensions.y - 1), true)
	for y in range(1, grid_dimensions.y - 1):
		set_cell_blocked(Vector2i(0, y), true)
		set_cell_blocked(Vector2i(grid_dimensions.x - 1, y), true)


func _draw() -> void:
	var room_size := Vector2(grid_dimensions * grid_size)
	var room_rect := Rect2(Vector2.ZERO, room_size)
	draw_rect(room_rect, FLOOR_COLOR)

	for x in range(grid_dimensions.x + 1):
		var x_position := float(x * grid_size)
		draw_line(Vector2(x_position, 0.0), Vector2(x_position, room_size.y), GRID_COLOR)

	for y in range(grid_dimensions.y + 1):
		var y_position := float(y * grid_size)
		draw_line(Vector2(0.0, y_position), Vector2(room_size.x, y_position), GRID_COLOR)

	var wall_thickness := float(grid_size)
	draw_rect(Rect2(0.0, 0.0, room_size.x, wall_thickness), WALL_COLOR)
	draw_rect(Rect2(0.0, room_size.y - wall_thickness, room_size.x, wall_thickness), WALL_COLOR)
	draw_rect(Rect2(0.0, 0.0, wall_thickness, room_size.y), WALL_COLOR)
	draw_rect(Rect2(room_size.x - wall_thickness, 0.0, wall_thickness, room_size.y), WALL_COLOR)

	if show_blocked_cells:
		for cell in _blocked_cell_counts:
			draw_rect(Rect2(Vector2(cell * grid_size), Vector2.ONE * grid_size), BLOCKED_COLOR)

