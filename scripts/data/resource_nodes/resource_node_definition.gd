class_name ResourceNodeDefinition
extends Resource

const HarvestYieldScript = preload("res://scripts/data/resource_nodes/harvest_yield_definition.gd")

enum DepletionBehavior {
	PERMANENT,
	RESPAWN,
	REGROW,
}

@export_group("Identity")
@export var node_id: StringName
@export var display_name := "Resource Node"
@export var resource_tags: Array[StringName] = []

@export_group("Harvesting")
@export_range(1.0, 100000.0, 1.0) var maximum_health := 100.0
@export var damage_material_tags: Array[StringName] = []
@export_range(0.0, 10000.0, 0.5) var unarmed_work_damage := 25.0
@export_range(0.05, 120.0, 0.05) var harvest_time_seconds := 1.0
@export var skill_id: StringName
@export_range(0, 100, 1) var required_skill_level := 0
@export var required_tool_tags: Array[StringName] = []
@export_range(1, 100, 1) var minimum_tool_tier := 1
@export_range(0, 10000, 1) var experience_reward := 0
@export var yields: Array[HarvestYieldScript] = []
@export_range(16.0, 512.0, 1.0) var cancel_distance := 96.0

@export_group("Depletion")
@export var depletion_behavior := DepletionBehavior.PERMANENT
@export_range(0.0, 86400.0, 0.1) var recovery_time_seconds := 0.0

@export_group("Placeholder Presentation")
@export_enum("tree", "rock", "bush") var visual_kind := "tree"
@export var primary_color := Color("#679b62")
@export var secondary_color := Color("#3f6847")
@export var depleted_color := Color("#6f5943")


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if node_id.is_empty():
		errors.append("Resource node definition is missing node_id.")
	if display_name.strip_edges().is_empty():
		errors.append("Resource node '%s' is missing display_name." % node_id)
	if yields.is_empty():
		errors.append("Resource node '%s' has no harvest yields." % node_id)
	if required_tool_tags.is_empty() and minimum_tool_tier > 1:
		errors.append("Resource node '%s' sets a tool tier without requiring a tool tag." % node_id)
	if damage_material_tags.is_empty():
		errors.append("Resource node '%s' has no damage material tags." % node_id)
	for harvest_yield in yields:
		if harvest_yield == null:
			errors.append("Resource node '%s' has an empty yield entry." % node_id)
		else:
			errors.append_array(harvest_yield.validate(node_id))
	if depletion_behavior != DepletionBehavior.PERMANENT and recovery_time_seconds <= 0.0:
		errors.append("Recovering resource node '%s' needs a positive recovery time." % node_id)
	return errors
