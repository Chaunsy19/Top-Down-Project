class_name CraftingWorkstation
extends "res://scripts/interaction/interactable.gd"

@export var definition: Resource

@onready var name_label: Label = %NameLabel
@onready var soft_light: SoftWorldLight = %SoftLight


func _ready() -> void:
	if definition != null:
		display_name = definition.display_name
	interaction_verb = "Craft at"
	super()
	add_to_group("crafting_workstation")
	name_label.text = display_name
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
	var color: Color = definition.primary_color if definition != null else Color("#9a5b32")
	draw_circle(Vector2.ZERO, 19.0, Color("#31231d"))
	for angle in 8:
		var point := Vector2.from_angle(float(angle) * TAU / 8.0) * 16.0
		draw_circle(point, 5.0, Color("#7d817c"))
	draw_colored_polygon(PackedVector2Array([Vector2(-8, 7), Vector2(0, -18), Vector2(8, 7)]), color)
	draw_circle(Vector2(0, 2), 6.0, Color("#e6c36a"))
