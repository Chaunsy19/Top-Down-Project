class_name WorkstationDefinition
extends Resource

@export var workstation_id: StringName
@export var display_name := "Workstation"
@export var workstation_tags: Array[StringName] = []
@export var primary_color := Color("#9a5b32")

@export_group("Lighting")
@export var emits_light := false
@export var light_color := Color(1.0, 0.57, 0.25, 1.0)
@export_range(0.0, 8.0, 0.05) var light_energy := 1.15
@export_range(16.0, 1024.0, 1.0) var light_radius := 180.0
@export_range(0.0, 0.5, 0.01) var light_flicker := 0.08


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if workstation_id.is_empty():
		errors.append("A workstation is missing workstation_id.")
	if workstation_tags.is_empty():
		errors.append("Workstation '%s' has no capability tags." % workstation_id)
	return errors
