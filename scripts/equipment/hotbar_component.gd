class_name HotbarComponent
extends Node

signal changed()
signal selected_slot_changed(slot_index: int, item_id: StringName)
signal selection_failed(slot_index: int, item_id: StringName)

const SLOT_ACTIONS: Array[StringName] = [
	&"hotbar_slot_1", &"hotbar_slot_2", &"hotbar_slot_3",
	&"hotbar_slot_4", &"hotbar_slot_5", &"hotbar_slot_6",
	&"hotbar_slot_7", &"hotbar_slot_8", &"hotbar_slot_9",
]

@export var allowed_categories: Array[StringName] = [&"tool", &"weapon"]

var selected_slot := -1
var _assignments: Array[StringName] = []
var _inventory: InventoryComponent
var _equipment: EquipmentComponent


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("player_hotbar")
	_assignments.resize(SLOT_ACTIONS.size())
	_inventory = get_parent().get_node_or_null("Inventory") as InventoryComponent
	_equipment = get_parent().get_node_or_null("Equipment") as EquipmentComponent
	if _inventory != null:
		_inventory.changed.connect(_on_related_state_changed)
	if _equipment != null:
		_equipment.changed.connect(_on_related_state_changed)
		_equipment.equipped_item_broken.connect(_on_equipped_item_broken)
	changed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	for index in SLOT_ACTIONS.size():
		if event.is_action_pressed(SLOT_ACTIONS[index]):
			select_slot(index)
			get_viewport().set_input_as_handled()
			return


func assign_from_inventory(hotbar_slot: int, inventory_slot: int) -> bool:
	if not is_valid_slot(hotbar_slot) or _inventory == null:
		return false
	var stack := _inventory.get_slot(inventory_slot)
	if stack == null or stack.item_definition == null or not is_definition_allowed(stack.item_definition):
		return false
	var item_id: StringName = stack.item_definition.item_id
	for index in _assignments.size():
		if index != hotbar_slot and _assignments[index] == item_id:
			_assignments[index] = &""
	_assignments[hotbar_slot] = item_id
	changed.emit()
	return true


func clear_slot(hotbar_slot: int) -> bool:
	if not is_valid_slot(hotbar_slot) or _assignments[hotbar_slot].is_empty():
		return false
	_assignments[hotbar_slot] = &""
	if hotbar_slot == selected_slot:
		_unequip_hand_item()
	changed.emit()
	return true


func select_slot(hotbar_slot: int) -> bool:
	if not is_valid_slot(hotbar_slot):
		return false
	selected_slot = hotbar_slot
	var item_id := get_assignment(hotbar_slot)
	var succeeded := _equip_assignment(item_id)
	selected_slot_changed.emit(hotbar_slot, item_id)
	if not succeeded:
		selection_failed.emit(hotbar_slot, item_id)
	changed.emit()
	return succeeded


func get_assignment(hotbar_slot: int) -> StringName:
	return _assignments[hotbar_slot] if is_valid_slot(hotbar_slot) else &""


func get_stack_for_slot(hotbar_slot: int) -> Resource:
	var item_id := get_assignment(hotbar_slot)
	if item_id.is_empty():
		return null
	if hotbar_slot == selected_slot and _equipment != null:
		var hand_stack := _equipment.get_hand_stack()
		if hand_stack != null and hand_stack.item_definition.item_id == item_id:
			return hand_stack
	if _inventory == null:
		return null
	return _inventory.get_slot(_inventory.find_first_item(item_id))


func is_definition_allowed(item_definition: Resource) -> bool:
	if item_definition == null:
		return false
	for category in allowed_categories:
		if item_definition.has_category(category):
			return true
	return false


func is_valid_slot(hotbar_slot: int) -> bool:
	return hotbar_slot >= 0 and hotbar_slot < SLOT_ACTIONS.size()


func _equip_assignment(item_id: StringName) -> bool:
	if _equipment == null or _inventory == null:
		return false
	var hand_stack := _equipment.get_hand_stack()
	if item_id.is_empty():
		return _unequip_hand_item()
	if hand_stack != null and hand_stack.item_definition.item_id == item_id:
		return true
	var inventory_slot := _inventory.find_first_item(item_id)
	if inventory_slot < 0:
		_unequip_hand_item()
		return false
	return _equipment.equip_from_inventory(_inventory, inventory_slot)


func _unequip_hand_item() -> bool:
	if _equipment == null or _inventory == null:
		return false
	if _equipment.get_hand_stack() == null:
		return true
	return _equipment.unequip_to_inventory(_inventory)


func _on_related_state_changed() -> void:
	changed.emit()


func _on_equipped_item_broken(_item_definition: Resource) -> void:
	call_deferred("_equip_assignment", get_assignment(selected_slot))
