class_name GridFootprintObstacle
extends Node2D

@export var occupied_cell_offsets: Array[Vector2i] = [Vector2i.ZERO]

var _grid_world: Node2D
var _occupied_cells: Array[Vector2i] = []


func _ready() -> void:
	_register_grid_footprint()


func _exit_tree() -> void:
	_clear_grid_footprint()


func get_occupied_cells() -> Array[Vector2i]:
	return _occupied_cells.duplicate()


func _register_grid_footprint() -> void:
	_grid_world = get_tree().get_first_node_in_group("grid_world") as Node2D
	if _grid_world == null:
		push_warning("GridFootprintObstacle '%s' could not find a grid world." % name)
		return
	var anchor_cell: Vector2i = _grid_world.world_to_cell(global_position)
	for cell_offset in occupied_cell_offsets:
		var occupied_cell := anchor_cell + cell_offset
		if not _grid_world.is_cell_in_bounds(occupied_cell):
			continue
		_grid_world.set_cell_blocked(occupied_cell, true)
		_occupied_cells.append(occupied_cell)


func _clear_grid_footprint() -> void:
	if not is_instance_valid(_grid_world):
		return
	for occupied_cell in _occupied_cells:
		_grid_world.set_cell_blocked(occupied_cell, false)
	_occupied_cells.clear()
