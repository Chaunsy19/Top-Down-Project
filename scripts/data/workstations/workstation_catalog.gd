class_name WorkstationCatalog
extends Resource

@export var workstations: Array[Resource] = []


func get_workstation(workstation_id: StringName) -> Resource:
	for workstation in workstations:
		if workstation != null and workstation.workstation_id == workstation_id:
			return workstation
	return null


func provides_tag(tag: StringName) -> bool:
	for workstation in workstations:
		if workstation != null and tag in workstation.workstation_tags:
			return true
	return false


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_ids := {}
	for workstation in workstations:
		if workstation == null:
			errors.append("Workstation catalog contains an empty entry.")
			continue
		errors.append_array(workstation.validate())
		if seen_ids.has(workstation.workstation_id):
			errors.append("Duplicate workstation_id '%s'." % workstation.workstation_id)
		seen_ids[workstation.workstation_id] = true
	return errors
