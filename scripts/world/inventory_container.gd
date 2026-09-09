class_name InventoryContainer
extends "res://scripts/interaction/interactable.gd"

const InventoryComponentScript = preload("res://scripts/inventory/inventory_component.gd")

@export var container_title := "SUPPLY CRATE"

@onready var inventory: InventoryComponentScript = %Inventory
@onready var title_label := get_node_or_null("TitleLabel") as Label


func _ready() -> void:
	display_name = container_title.capitalize()
	interaction_verb = "Open"
	super()
	add_to_group("inventory_container")
	if is_instance_valid(title_label):
		title_label.text = container_title.capitalize()
	queue_redraw()


func get_debug_state() -> String:
	if not is_instance_valid(inventory):
		return "Inventory unavailable"
	return "%d/%d slots | %.1f/%.1f weight" % [
		inventory.get_used_slot_count(),
		inventory.slot_count,
		inventory.get_total_weight(),
		inventory.maximum_weight,
	]


func _perform_interaction(actor: Node2D) -> void:
	var actor_inventory := actor.get_node_or_null("Inventory") as InventoryComponentScript
	var inventory_ui := get_tree().get_first_node_in_group("inventory_ui")
	if actor_inventory != null and inventory_ui != null:
		inventory_ui.open_container(self, actor, actor_inventory, inventory)


func _draw() -> void:
	draw_rect(Rect2(-21.0, -15.0, 42.0, 30.0), Color("#6e4f34"))
	draw_rect(Rect2(-21.0, -15.0, 42.0, 8.0), Color("#92704b"))
	draw_line(Vector2(-21.0, -6.0), Vector2(21.0, -6.0), Color("#2d2922"), 2.0)
	draw_rect(Rect2(-3.0, -4.0, 6.0, 9.0), Color("#d0aa58"))
