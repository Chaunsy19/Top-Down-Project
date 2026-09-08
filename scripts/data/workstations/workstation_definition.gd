class_name WorkstationDefinition
extends Resource

@export var workstation_id: StringName
@export var display_name := "Workstation"
@export var workstation_tags: Array[StringName] = []
@export var primary_color := Color("#9a5b32")


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if workstation_id.is_empty():
		errors.append("A workstation is missing workstation_id.")
	if workstation_tags.is_empty():
		errors.append("Workstation '%s' has no capability tags." % workstation_id)
	return errors
