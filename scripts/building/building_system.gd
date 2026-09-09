class_name BuildingSystem
extends Node2D

signal placement_changed(definition: Resource, is_valid: bool, reason: String)
signal site_placed(site: Node)

const ConstructionSiteScene := preload("res://scenes/building/construction_site.tscn")

var selected_definition: Resource
var current_cell := Vector2i.ZERO
var placement_valid := false
var placement_reason := ""
var _world: GridWorld
var _player: PlayerController
var _inventory: InventoryComponent


func _ready() -> void:
	add_to_group("building_system")
	call_deferred("_bind_world")


func _bind_world() -> void:
	_world = get_tree().get_first_node_in_group("grid_world") as GridWorld
	_player = get_tree().get_first_node_in_group("player") as PlayerController
	_inventory = _player.get_node_or_null("Inventory") as InventoryComponent if _player != null else null
	queue_redraw()


func _process(_delta: float) -> void:
	if selected_definition == null or _world == null:
		return
	current_cell = _world.world_to_cell(get_global_mouse_position())
	global_position = _world.to_global(_world.cell_to_world(current_cell))
	_update_validity()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if selected_definition == null:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
		cancel_placement()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("attack"):
		place_selected_at_cell(current_cell)
		get_viewport().set_input_as_handled()


func begin_placement(definition: Resource) -> void:
	selected_definition = definition
	_update_validity()
	queue_redraw()


func cancel_placement() -> void:
	selected_definition = null
	placement_valid = false
	placement_reason = ""
	placement_changed.emit(null, false, "")
	queue_redraw()


func can_place_at_cell(definition: Resource, cell: Vector2i) -> String:
	if definition == null or _world == null or _inventory == null:
		return "Building system is unavailable."
	if not _world.is_cell_in_bounds(cell):
		return "Outside the buildable map."
	if not _world.is_cell_walkable(cell):
		return "That tile is blocked or not walkable."
	for node in get_tree().get_nodes_in_group("construction_site") + get_tree().get_nodes_in_group("built_structure"):
		if is_instance_valid(node) and _world.world_to_cell(node.global_position) == cell:
			return "That tile already contains a building."
	for cost in definition.costs:
		if _inventory.get_item_quantity(cost.item_definition.item_id) < cost.quantity:
			return "Need %d %s." % [cost.quantity, cost.item_definition.display_name]
	return ""


func place_selected_at_cell(cell: Vector2i) -> Node:
	if selected_definition == null:
		return null
	var reason := can_place_at_cell(selected_definition, cell)
	if not reason.is_empty():
		placement_reason = reason
		placement_changed.emit(selected_definition, false, reason)
		return null
	for cost in selected_definition.costs:
		_inventory.remove_item(cost.item_definition.item_id, cost.quantity)
	var site := ConstructionSiteScene.instantiate()
	site.configure(selected_definition)
	site.position = _world.cell_to_world(cell)
	_world.add_child(site)
	site_placed.emit(site)
	_update_validity()
	return site


func _update_validity() -> void:
	placement_reason = can_place_at_cell(selected_definition, current_cell) if selected_definition != null else ""
	placement_valid = selected_definition != null and placement_reason.is_empty()
	placement_changed.emit(selected_definition, placement_valid, placement_reason)


func _draw() -> void:
	if selected_definition == null:
		return
	var color := Color("#5fca78") if placement_valid else Color("#df655d")
	draw_rect(Rect2(-16, -16, 32, 32), Color(color, 0.32), true)
	draw_rect(Rect2(-16, -16, 32, 32), color, false, 2.5)
