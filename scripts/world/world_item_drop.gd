class_name WorldItemDrop
extends "res://scripts/interaction/interactable.gd"

const ItemStackScript = preload("res://scripts/data/items/item_stack.gd")

@export var starting_item_definition: Resource
@export_range(1, 9999, 1) var starting_quantity := 1

var item_stack: ItemStackScript

@onready var item_label: Label = %ItemLabel


func _ready() -> void:
	display_name = "item"
	interaction_verb = "Pick up"
	super()
	if item_stack == null and starting_item_definition != null:
		configure(starting_item_definition, starting_quantity)
	add_to_group("world_item_drop")
	_update_presentation()


func configure(item_definition: Resource, quantity: int) -> void:
	item_stack = ItemStackScript.new()
	item_stack.item_definition = item_definition
	item_stack.quantity = quantity
	item_stack.initialize_runtime_state()
	if is_node_ready():
		_update_presentation()


func configure_stack(stack: Resource) -> void:
	item_stack = stack.duplicate_stack() if stack != null else null
	if is_node_ready():
		_update_presentation()


func can_interact(actor: Node2D) -> bool:
	if not super(actor) or item_stack == null or not item_stack.is_valid():
		return false
	var inventory := actor.get_node_or_null("Inventory")
	return inventory != null and inventory.get_addable_quantity(item_stack.item_definition) > 0


func get_prompt_text() -> String:
	if item_stack == null or not item_stack.is_valid():
		return "Invalid item"
	return "Pick up %d× %s" % [item_stack.quantity, item_stack.item_definition.display_name]


func get_debug_state() -> String:
	if item_stack == null or not item_stack.is_valid():
		return "Invalid drop"
	return "%d× %s" % [item_stack.quantity, item_stack.item_definition.display_name]


func _perform_interaction(actor: Node2D) -> void:
	var inventory := actor.get_node_or_null("Inventory")
	var remainder: int = inventory.add_stack(item_stack)
	var collected := item_stack.quantity - remainder
	item_stack.quantity = remainder
	_show_notification("Picked up %d× %s" % [collected, item_stack.item_definition.display_name])
	if item_stack.quantity <= 0:
		queue_free()
	else:
		_update_presentation()


func _show_notification(message: String) -> void:
	var inventory_ui := get_tree().get_first_node_in_group("inventory_ui")
	if inventory_ui:
		inventory_ui.show_notification(message)


func _update_presentation() -> void:
	if item_stack == null or not item_stack.is_valid():
		item_label.text = "Invalid drop"
		queue_redraw()
		return
	display_name = item_stack.item_definition.display_name
	item_label.text = "%d× %s" % [item_stack.quantity, item_stack.item_definition.display_name]
	queue_redraw()


func _draw() -> void:
	var color := Color.WHITE
	if item_stack != null and item_stack.item_definition != null:
		color = item_stack.item_definition.world_color
	var points := PackedVector2Array([
		Vector2(0.0, -7.0),
		Vector2(8.0, 0.0),
		Vector2(0.0, 7.0),
		Vector2(-8.0, 0.0),
	])
	draw_colored_polygon(points, Color("#171d1b"))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), color, 2.0)
