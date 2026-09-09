class_name CraftingWorkstation
extends "res://scripts/interaction/interactable.gd"

@export var definition: Resource

@onready var name_label := get_node_or_null("NameLabel") as Label
@onready var soft_light := get_node_or_null("SoftLight") as SoftWorldLight


func _ready() -> void:
	if definition != null:
		display_name = definition.display_name
	interaction_verb = "Craft at"
	super()
	add_to_group("crafting_workstation")
	if is_instance_valid(name_label):
		name_label.text = display_name
	if is_instance_valid(soft_light):
		soft_light.configure_from_definition(definition)
	queue_redraw()


func get_debug_state() -> String:
	if definition == null:
		return "Invalid workstation"
	return "Tags: %s" % ", ".join(definition.workstation_tags)


func _perform_interaction(actor: Node2D) -> void:
	var crafting_ui := get_tree().get_first_node_in_group("crafting_ui")
	if crafting_ui != null:
		crafting_ui.open_crafting(actor, definition.workstation_tags, display_name)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 19.0, Color("#31231d"))
	for angle in 8:
		var point := Vector2.from_angle(float(angle) * TAU / 8.0) * 16.0
		draw_circle(point, 5.0, Color("#7d817c"))
	draw_line(Vector2(-11, 8), Vector2(11, -5), Color("#6d4128"), 5.0, true)
	draw_line(Vector2(-11, -5), Vector2(11, 8), Color("#835034"), 5.0, true)
