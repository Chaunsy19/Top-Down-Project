class_name BuiltStructure
extends "res://scripts/interaction/interactable.gd"

var definition: Resource
var is_open := false
var container_title := "STORAGE"

@onready var blocker_shape: CollisionShape2D = %BlockerShape
@onready var interaction_shape: CollisionShape2D = %InteractionShape
@onready var inventory: InventoryComponent = %Inventory
@onready var soft_light: SoftWorldLight = %SoftLight


func configure(value: Resource) -> void:
	definition = value
	if definition != null:
		display_name = definition.display_name
		blocks_grid_cell = definition.blocks_movement


func _ready() -> void:
	if definition == null:
		push_error("BuiltStructure requires a BuildingDefinition.")
		return
	interaction_verb = _get_interaction_verb()
	container_title = definition.display_name.to_upper()
	pointer_selection_radius = 23.0
	interaction_shape.disabled = definition.behavior not in ["door", "storage", "workstation", "sleeping_spot"]
	inventory.slot_count = definition.storage_slots
	inventory.initialize_slots()
	blocker_shape.disabled = not definition.blocks_movement
	if definition.behavior == "workstation" and definition.workstation_definition != null:
		soft_light.configure_from_definition(definition.workstation_definition)
	else:
		soft_light.enabled = false
	super()
	add_to_group("built_structure")
	add_to_group("built_%s" % definition.behavior)
	queue_redraw()


func register_grid_occupancy() -> void:
	set_grid_occupancy_enabled(definition != null and definition.blocks_movement and not is_open)


func can_interact(actor: Node2D) -> bool:
	return definition != null and definition.behavior in ["door", "storage", "workstation", "sleeping_spot"] and super(actor)


func _perform_interaction(actor: Node2D) -> void:
	match definition.behavior:
		"door":
			_set_door_open(not is_open)
		"storage":
			var actor_inventory := actor.get_node_or_null("Inventory") as InventoryComponent
			var inventory_ui := get_tree().get_first_node_in_group("inventory_ui")
			if actor_inventory != null and inventory_ui != null:
				inventory_ui.open_container(self, actor, actor_inventory, inventory)
		"workstation":
			var crafting_ui := get_tree().get_first_node_in_group("crafting_ui")
			if crafting_ui != null:
				crafting_ui.open_crafting(actor, definition.workstation_definition.workstation_tags, display_name)
		"sleeping_spot":
			var needs := actor.get_node_or_null("Needs") as SurvivalNeeds
			if needs != null:
				needs.set_resting(not needs.is_resting)


func _set_door_open(value: bool) -> void:
	if value == is_open:
		return
	if value:
		set_grid_occupancy_enabled(false)
		is_open = true
		blocker_shape.set_deferred("disabled", true)
	else:
		is_open = false
		blocker_shape.set_deferred("disabled", false)
		register_grid_occupancy()
	queue_redraw()


func _get_interaction_verb() -> String:
	match definition.behavior:
		"door": return "Open"
		"storage": return "Open"
		"workstation": return "Craft at"
		"sleeping_spot": return "Rest at"
	return "Inspect"


func _draw() -> void:
	var color: Color = definition.primary_color if definition != null else Color.GRAY
	match definition.behavior if definition != null else "wall":
		"floor":
			draw_rect(Rect2(-16, -16, 32, 32), color)
			for x in [-10.0, 0.0, 10.0]: draw_line(Vector2(x, -16), Vector2(x, 16), color.darkened(0.12), 1.0)
		"wall":
			draw_rect(Rect2(-16, -16, 32, 32), color)
			draw_rect(Rect2(-13, -13, 26, 26), color.lightened(0.12), false, 3.0)
		"door":
			draw_rect(Rect2(-4 if is_open else -13, -13, 8 if is_open else 26, 26), color)
		"storage":
			draw_rect(Rect2(-14, -11, 28, 22), color)
			draw_line(Vector2(-14, -3), Vector2(14, -3), color.lightened(0.25), 2.0)
		"workstation":
			draw_circle(Vector2.ZERO, 13, color.darkened(0.35))
			for angle in 8: draw_circle(Vector2.from_angle(angle * TAU / 8.0) * 12, 4, color)
		"sleeping_spot":
			draw_rect(Rect2(-13, -15, 26, 30), color)
			draw_rect(Rect2(-10, -12, 20, 8), color.lightened(0.25))
