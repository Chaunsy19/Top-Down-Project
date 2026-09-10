class_name BuildingDefinition
extends Resource

@export var building_id: StringName
@export var display_name := "Building"
@export_multiline var description := ""
@export_enum("floor", "wall", "door", "storage", "workstation", "sleeping_spot") var behavior := "wall"
@export var costs: Array[Resource] = []
@export_range(0.1, 30.0, 0.1) var construction_time := 1.0
@export var blocks_movement := true
@export_range(1.0, 100000.0, 1.0) var maximum_health := 200.0
@export var damage_material_tags: Array[StringName] = [&"wood"]
@export var primary_color := Color("#7b5637")
@export var workstation_definition: Resource
@export_range(1, 100, 1) var storage_slots := 16


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if building_id.is_empty():
		errors.append("A building is missing building_id.")
	for cost in costs:
		if cost == null:
			errors.append("Building '%s' has a null cost." % building_id)
		else:
			errors.append_array(cost.validate(building_id))
	if behavior == "workstation" and workstation_definition == null:
		errors.append("Workstation building '%s' has no workstation definition." % building_id)
	if damage_material_tags.is_empty():
		errors.append("Building '%s' has no damage material tags." % building_id)
	return errors


func get_cost_text() -> String:
	var parts := PackedStringArray()
	for cost in costs:
		if cost != null and cost.item_definition != null:
			parts.append("%d %s" % [cost.quantity, cost.item_definition.display_name])
	return ", ".join(parts)
