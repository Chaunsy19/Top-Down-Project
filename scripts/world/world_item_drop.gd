class_name WorldItemDrop
extends Node2D

const ItemStackScript = preload("res://scripts/data/items/item_stack.gd")

var item_stack: ItemStackScript

@onready var item_label: Label = %ItemLabel


func _ready() -> void:
	add_to_group("world_item_drop")
	_update_presentation()


func configure(item_definition: Resource, quantity: int) -> void:
	item_stack = ItemStackScript.new()
	item_stack.item_definition = item_definition
	item_stack.quantity = quantity
	if is_node_ready():
		_update_presentation()


func _update_presentation() -> void:
	if item_stack == null or not item_stack.is_valid():
		item_label.text = "Invalid drop"
		queue_redraw()
		return
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
