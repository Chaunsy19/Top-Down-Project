class_name ConstructionSite
extends "res://scripts/interaction/interactable.gd"

const BuiltStructureScene := preload("res://scenes/building/built_structure.tscn")

var definition: Resource
var progress := 0.0
var _builder: Node2D


func configure(value: Resource) -> void:
	definition = value
	if definition != null:
		display_name = definition.display_name
		blocks_grid_cell = definition.blocks_movement
	interaction_verb = "Build"
	pointer_selection_radius = 23.0


func _ready() -> void:
	super()
	add_to_group("construction_site")
	queue_redraw()


func uses_hold_interaction() -> bool:
	return true


func prefers_utility_when_armed() -> bool:
	return true


func _perform_interaction(actor: Node2D) -> void:
	_builder = actor


func continue_hold_interaction(actor: Node2D, delta: float) -> bool:
	if definition == null or actor != _builder:
		return false
	progress += maxf(delta, 0.0)
	queue_redraw()
	if progress < definition.construction_time:
		return true
	_complete_construction()
	return false


func cancel_hold_interaction(actor: Node2D) -> void:
	if actor == _builder:
		_builder = null


func is_hold_interaction_active(actor: Node2D) -> bool:
	return actor == _builder and progress < definition.construction_time


func get_debug_state() -> String:
	return "Construction %d%%" % roundi(clampf(progress / definition.construction_time, 0.0, 1.0) * 100.0) if definition != null else "Invalid site"


func _complete_construction() -> void:
	set_grid_occupancy_enabled(false)
	var structure := BuiltStructureScene.instantiate()
	structure.configure(definition)
	structure.position = position
	get_parent().add_child(structure)
	queue_free()


func _draw() -> void:
	var color: Color = definition.primary_color if definition != null else Color.GRAY
	draw_rect(Rect2(-14, -14, 28, 28), Color(color, 0.35), true)
	draw_rect(Rect2(-14, -14, 28, 28), color.lightened(0.25), false, 2.0)
	draw_line(Vector2(-11, 11), Vector2(11, -11), color.lightened(0.4), 2.0)
	if definition != null and progress > 0.0:
		draw_rect(Rect2(-14, 17, 28 * clampf(progress / definition.construction_time, 0.0, 1.0), 3), Color("#e6c36a"))
