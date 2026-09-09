class_name BuildingCatalog
extends Resource

@export var buildings: Array[Resource] = []


func get_building(building_id: StringName) -> Resource:
	for definition in buildings:
		if definition != null and definition.building_id == building_id:
			return definition
	return null


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids: Dictionary[StringName, bool] = {}
	for definition in buildings:
		if definition == null:
			errors.append("Building catalog contains a null entry.")
			continue
		errors.append_array(definition.validate())
		if ids.has(definition.building_id):
			errors.append("Duplicate building id '%s'." % definition.building_id)
		ids[definition.building_id] = true
	return errors
