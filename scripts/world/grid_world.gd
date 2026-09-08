class_name GridWorld
extends Node2D

@export var cell_size := Vector2(64.0, 32.0)
@export var grid_dimensions := Vector2i(14, 14)
@export var grid_origin := Vector2(448.0, 24.0)
@export var show_blocked_cells := true

const FLOOR_COLOR := Color("#25352f")
const FLOOR_ALT_COLOR := Color("#293a33")
const GRID_COLOR := Color("#385047")
const WALL_COLOR := Color("#8f7056")
const WALL_ALT_COLOR := Color("#795e49")
const BLOCKED_COLOR := Color(0.78, 0.25, 0.20, 0.12)

var _blocked_cell_counts: Dictionary[Vector2i, int] = {}


func _ready() -> void:
	add_to_group("grid_world")
	_register_boundary_cells()
	_create_boundary_collision()
	queue_redraw()


func world_to_cell(world_position: Vector2) -> Vector2i:
	var grid_position := world_to_grid_position(world_position)
	return Vector2i(floori(grid_position.x + 0.5), floori(grid_position.y + 0.5))


func cell_to_world(cell: Vector2i) -> Vector2:
	return grid_position_to_local(Vector2(cell))


func world_to_grid_position(world_position: Vector2) -> Vector2:
	var local_position := to_local(world_position) - grid_origin
	var half_width := cell_size.x * 0.5
	var half_height := cell_size.y * 0.5
	return Vector2(
		(local_position.x / half_width + local_position.y / half_height) * 0.5,
		(local_position.y / half_height - local_position.x / half_width) * 0.5
	)


func grid_position_to_local(grid_position: Vector2) -> Vector2:
	return grid_origin + Vector2(
		(grid_position.x - grid_position.y) * cell_size.x * 0.5,
		(grid_position.x + grid_position.y) * cell_size.y * 0.5
	)


func grid_delta_to_local(grid_delta: Vector2) -> Vector2:
	return Vector2(
		(grid_delta.x - grid_delta.y) * cell_size.x * 0.5,
		(grid_delta.x + grid_delta.y) * cell_size.y * 0.5
	)


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


func _create_boundary_collision() -> void:
	if grid_dimensions.x < 3 or grid_dimensions.y < 3:
		return
	var collision_body := StaticBody2D.new()
	collision_body.name = "IsometricBoundary"
	add_child(collision_body)
	var minimum_cell := Vector2i(1, 1)
	var maximum_cell := grid_dimensions - Vector2i(2, 2)
	var points := PackedVector2Array([
		cell_to_world(minimum_cell) + Vector2(0.0, -cell_size.y * 0.5),
		cell_to_world(Vector2i(maximum_cell.x, minimum_cell.y)) + Vector2(cell_size.x * 0.5, 0.0),
		cell_to_world(maximum_cell) + Vector2(0.0, cell_size.y * 0.5),
		cell_to_world(Vector2i(minimum_cell.x, maximum_cell.y)) + Vector2(-cell_size.x * 0.5, 0.0),
	])
	for index in points.size():
		var shape := SegmentShape2D.new()
		shape.a = points[index]
		shape.b = points[(index + 1) % points.size()]
		var collision_shape := CollisionShape2D.new()
		collision_shape.shape = shape
		collision_body.add_child(collision_shape)


func _draw() -> void:
	for diagonal in range(grid_dimensions.x + grid_dimensions.y - 1):
		for x in grid_dimensions.x:
			var y := diagonal - x
			if y < 0 or y >= grid_dimensions.y:
				continue
			var cell := Vector2i(x, y)
			var boundary := x == 0 or y == 0 or x == grid_dimensions.x - 1 or y == grid_dimensions.y - 1
			var fill_color := WALL_COLOR if boundary else FLOOR_COLOR
			if (x + y) % 2 == 1:
				fill_color = WALL_ALT_COLOR if boundary else FLOOR_ALT_COLOR
			var polygon := get_cell_polygon(cell)
			draw_colored_polygon(polygon, fill_color)
			draw_polyline(PackedVector2Array([polygon[0], polygon[1], polygon[2], polygon[3], polygon[0]]), GRID_COLOR, 1.0)
	if show_blocked_cells:
		for cell in _blocked_cell_counts:
			if cell.x == 0 or cell.y == 0 or cell.x == grid_dimensions.x - 1 or cell.y == grid_dimensions.y - 1:
				continue
			draw_colored_polygon(get_cell_polygon(cell), BLOCKED_COLOR)


func get_cell_polygon(cell: Vector2i) -> PackedVector2Array:
	var center := cell_to_world(cell)
	var half_width := cell_size.x * 0.5
	var half_height := cell_size.y * 0.5
	return PackedVector2Array([
		center + Vector2(0.0, -half_height),
		center + Vector2(half_width, 0.0),
		center + Vector2(0.0, half_height),
		center + Vector2(-half_width, 0.0),
	])
