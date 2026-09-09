class_name Interactable
extends Area2D

signal interacted(actor: Node2D)
signal availability_changed(is_available: bool)

@export var display_name := "Interactable"
@export var interaction_verb := "Use"
@export var is_available := true
@export var blocks_grid_cell := false
@export var snap_to_grid_when_blocking := true

var _grid_world: Node2D
var _occupied_cell := Vector2i(-1, -1)
var _is_grid_occupancy_registered := false


func _ready() -> void:
	add_to_group("interactable")
	if blocks_grid_cell:
		call_deferred("_register_grid_occupancy")


func _exit_tree() -> void:
	set_grid_occupancy_enabled(false)


func get_interaction_point() -> Vector2:
	var interaction_point := get_node_or_null("InteractionPoint") as Node2D
	return interaction_point.global_position if interaction_point else global_position


func can_interact(actor: Node2D) -> bool:
	return is_available and is_instance_valid(actor)


func interact(actor: Node2D) -> bool:
	if not can_interact(actor):
		return false
	_perform_interaction(actor)
	interacted.emit(actor)
	return true


func set_available(value: bool) -> void:
	if is_available == value:
		return
	is_available = value
	availability_changed.emit(is_available)


func get_prompt_text() -> String:
	return "%s %s" % [interaction_verb, display_name]


func get_debug_state() -> String:
	return "Available" if is_available else "Unavailable"


func set_grid_occupancy_enabled(enabled: bool) -> void:
	if not blocks_grid_cell:
		return
	if enabled and not _is_grid_occupancy_registered:
		_register_grid_occupancy()
	elif not enabled and _is_grid_occupancy_registered:
		if is_instance_valid(_grid_world):
			_grid_world.unregister_cell_occupant(_occupied_cell, self)
		_is_grid_occupancy_registered = false


func _perform_interaction(_actor: Node2D) -> void:
	pass


func _register_grid_occupancy() -> void:
	if _is_grid_occupancy_registered:
		return
	_grid_world = get_tree().get_first_node_in_group("grid_world") as Node2D
	if _grid_world == null:
		push_warning("%s could not find a GridWorld for occupancy registration." % name)
		return
	_occupied_cell = _grid_world.world_to_cell(global_position)
	if snap_to_grid_when_blocking:
		global_position = _grid_world.to_global(_grid_world.cell_to_world(_occupied_cell))
	if not _grid_world.try_register_cell_occupant(_occupied_cell, self):
		push_warning("%s could not occupy grid cell %s because it is already occupied." % [name, _occupied_cell])
		return
	_is_grid_occupancy_registered = true


func get_occupied_cell() -> Vector2i:
	return _occupied_cell
