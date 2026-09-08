class_name ResourceNodeCatalog
extends Resource

@export var resource_nodes: Array[Resource] = []


func get_resource_node(node_id: StringName) -> Resource:
	for definition in resource_nodes:
		if definition != null and definition.node_id == node_id:
			return definition
	return null


func get_resource_nodes_with_tag(tag: StringName) -> Array[Resource]:
	var matches: Array[Resource] = []
	for definition in resource_nodes:
		if definition != null and tag in definition.resource_tags:
			matches.append(definition)
	return matches


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_ids := {}
	for definition in resource_nodes:
		if definition == null:
			errors.append("Resource node catalog contains an empty entry.")
			continue
		errors.append_array(definition.validate())
		if seen_ids.has(definition.node_id):
			errors.append("Duplicate resource node id '%s'." % definition.node_id)
		seen_ids[definition.node_id] = true
	return errors

