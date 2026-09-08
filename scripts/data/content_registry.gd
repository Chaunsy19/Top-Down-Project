extends Node

const ITEM_CATALOG_PATH := "res://data/catalogs/item_catalog.tres"
const ITEM_CATEGORY_CATALOG_PATH := "res://data/catalogs/item_category_catalog.tres"
const RESOURCE_NODE_CATALOG_PATH := "res://data/catalogs/resource_node_catalog.tres"

var item_catalog: Resource
var item_category_catalog: Resource
var resource_node_catalog: Resource


func _ready() -> void:
	item_catalog = load(ITEM_CATALOG_PATH)
	item_category_catalog = load(ITEM_CATEGORY_CATALOG_PATH)
	resource_node_catalog = load(RESOURCE_NODE_CATALOG_PATH)
	for error in validate_catalogs():
		push_error("Content catalog: %s" % error)


func get_item(item_id: StringName) -> Resource:
	return item_catalog.get_item(item_id) if item_catalog else null


func get_items_in_category(category_id: StringName) -> Array[Resource]:
	return item_catalog.get_items_in_category(category_id) if item_catalog else []


func get_resource_node(node_id: StringName) -> Resource:
	return resource_node_catalog.get_resource_node(node_id) if resource_node_catalog else null


func validate_catalogs() -> PackedStringArray:
	var errors := PackedStringArray()
	if item_catalog == null:
		errors.append("Item catalog could not be loaded.")
	else:
		errors.append_array(item_catalog.validate())
	if item_category_catalog == null:
		errors.append("Item category catalog could not be loaded.")
	else:
		errors.append_array(item_category_catalog.validate())
	if resource_node_catalog == null:
		errors.append("Resource node catalog could not be loaded.")
	else:
		errors.append_array(resource_node_catalog.validate())

	if item_catalog != null and item_category_catalog != null:
		for item in item_catalog.items:
			if item == null:
				continue
			for category_id in item.categories:
				if item_category_catalog.get_category(category_id) == null:
					errors.append("Item '%s' references undefined category '%s'." % [item.item_id, category_id])
	if item_catalog != null and resource_node_catalog != null:
		for node_definition in resource_node_catalog.resource_nodes:
			if node_definition == null:
				continue
			for harvest_yield in node_definition.yields:
				if harvest_yield != null and harvest_yield.item_definition != null:
					var yielded_item_id: StringName = harvest_yield.item_definition.item_id
					if item_catalog.get_item(yielded_item_id) == null:
						errors.append("Resource node '%s' yields uncatalogued item '%s'." % [node_definition.node_id, yielded_item_id])
	return errors
