class_name HotbarUI
extends CanvasLayer

const HotbarSlotScene := preload("res://ui/hotbar/hotbar_slot.tscn")

var _hotbar: HotbarComponent
var _player: PlayerController
var _slots: Array[HotbarSlotUI] = []

@onready var slot_row: HBoxContainer = %SlotRow
@onready var mode_label: Label = %ModeLabel


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
		_player = _hotbar.get_parent() as PlayerController
		if _player != null:
			_player.combat_mode_changed.connect(_on_combat_mode_changed)
	_refresh()
	_refresh_mode()


func _refresh() -> void:
	for index in _slots.size():
		var item_id := _hotbar.get_assignment(index) if _hotbar != null else &""
		var stack := _hotbar.get_stack_for_slot(index) if _hotbar != null else null
		_slots[index].configure(index, item_id, stack, _hotbar != null and index == _hotbar.selected_slot)
	_refresh_mode()


func _on_slot_pressed(index: int) -> void:
	if _hotbar != null and not get_tree().paused:
		_hotbar.select_slot(index)


func _on_combat_mode_changed(_is_combat_ready: bool) -> void:
	_refresh_mode()


func _refresh_mode() -> void:
	if _player != null and _player.is_combat_ready:
		mode_label.text = "WEAPON READY  •  LMB use / attack  •  Select again to holster"
		mode_label.add_theme_color_override("font_color", Color("#e27b62"))
	elif _hotbar != null and _hotbar.selected_slot >= 0 and _hotbar.get_stack_for_slot(_hotbar.selected_slot) != null:
		mode_label.text = "TOOL READY  •  Hold LMB use  •  Select again to put away"
		mode_label.add_theme_color_override("font_color", Color("#d6b86a"))
	else:
		mode_label.text = "HANDS FREE  •  LMB interact  •  Select a hotbar item"
		mode_label.add_theme_color_override("font_color", Color("#a9c7b3"))
