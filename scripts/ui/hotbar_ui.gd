class_name HotbarUI
extends CanvasLayer

const HotbarSlotScene := preload("res://ui/hotbar/hotbar_slot.tscn")

var _hotbar: HotbarComponent
var _slots: Array[HotbarSlotUI] = []

@onready var slot_row: HBoxContainer = %SlotRow


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index in HotbarComponent.SLOT_ACTIONS.size():
		var slot := HotbarSlotScene.instantiate() as HotbarSlotUI
		slot_row.add_child(slot)
		slot.pressed.connect(_on_slot_pressed.bind(index))
		_slots.append(slot)
	call_deferred("_bind_player_hotbar")


func _bind_player_hotbar() -> void:
	_hotbar = get_tree().get_first_node_in_group("player_hotbar") as HotbarComponent
	if _hotbar != null:
		_hotbar.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for index in _slots.size():
		var item_id := _hotbar.get_assignment(index) if _hotbar != null else &""
		var stack := _hotbar.get_stack_for_slot(index) if _hotbar != null else null
		_slots[index].configure(index, item_id, stack, _hotbar != null and index == _hotbar.selected_slot)


func _on_slot_pressed(index: int) -> void:
	if _hotbar != null and not get_tree().paused:
		_hotbar.select_slot(index)
