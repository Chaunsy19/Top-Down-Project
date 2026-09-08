class_name InventoryPanel
extends PanelContainer

const InventorySlotScene = preload("res://ui/inventory/inventory_slot.tscn")
const InventoryComponentScript = preload("res://scripts/inventory/inventory_component.gd")
const InventorySlotScript = preload("res://scripts/inventory/inventory_slot_ui.gd")

signal close_requested()
signal drop_requested(slot_index: int)

@export var panel_title := "INVENTORY"
@export_range(1, 10, 1) var columns := 6
@export_range(100.0, 600.0, 5.0) var slots_minimum_height := 300.0
@export var show_currency_footer := true
@export var show_drop_button := true

var _inventory: InventoryComponentScript
var _transfer_inventory: InventoryComponentScript
var _slot_controls: Array[Control] = []
var _selected_slot := -1

@onready var title_label: Label = %Title
@onready var slot_grid: GridContainer = %SlotGrid
@onready var slots_scroll: ScrollContainer = %SlotsScroll
@onready var selection_label: Label = %SelectionLabel
@onready var weight_label: Label = %WeightLabel
@onready var currency_footer: Control = %CurrencyFooter
@onready var drop_button: Button = %DropButton


func _ready() -> void:
	_apply_panel_style()
	title_label.text = panel_title
	slot_grid.columns = columns
	slots_scroll.custom_minimum_size.y = slots_minimum_height
	currency_footer.visible = show_currency_footer
	drop_button.visible = show_drop_button
	%CloseButton.pressed.connect(func() -> void: close_requested.emit())
	drop_button.pressed.connect(_on_drop_pressed)


func bind_inventory(inventory: InventoryComponentScript, transfer_inventory: InventoryComponentScript = null) -> void:
	if _inventory != null and _inventory.changed.is_connected(_refresh):
		_inventory.changed.disconnect(_refresh)
	_inventory = inventory
	_transfer_inventory = transfer_inventory
	_selected_slot = -1
	if _inventory != null:
		_inventory.changed.connect(_refresh)
	_rebuild_slots()
	_refresh()


func set_panel_title(value: String) -> void:
	panel_title = value
	if is_instance_valid(title_label):
		title_label.text = panel_title


func get_inventory() -> InventoryComponentScript:
	return _inventory


func get_selected_slot() -> int:
	return _selected_slot


func _rebuild_slots() -> void:
	for child in slot_grid.get_children():
		child.queue_free()
	_slot_controls.clear()
	if _inventory == null:
		return
	for index in _inventory.slot_count:
		var slot := InventorySlotScene.instantiate() as InventorySlotScript
		slot_grid.add_child(slot)
		slot.configure(index, _inventory.get_slot(index))
		slot.slot_activated.connect(_on_slot_activated)
		_slot_controls.append(slot)


func _refresh() -> void:
	if _inventory == null:
		selection_label.text = "No inventory"
		weight_label.text = ""
		return
	if _slot_controls.size() != _inventory.slot_count:
		_rebuild_slots()
	for index in _slot_controls.size():
		var slot := _slot_controls[index] as InventorySlotScript
		slot.configure(index, _inventory.get_slot(index))
		slot.set_selected_state(index == _selected_slot)
	weight_label.text = "Weight  %.1f / %.1f" % [_inventory.get_total_weight(), _inventory.maximum_weight]
	var selected_stack := _inventory.get_slot(_selected_slot)
	selection_label.text = selected_stack.item_definition.display_name if selected_stack else "Select a slot"
	drop_button.disabled = selected_stack == null


func _on_slot_activated(index: int, mouse_button: int, shift_pressed: bool, double_click: bool) -> void:
	if _inventory == null:
		return
	if mouse_button == MOUSE_BUTTON_RIGHT:
		_inventory.split_stack(index)
		_selected_slot = -1
	elif (shift_pressed or double_click) and _transfer_inventory != null:
		_inventory.transfer_to(_transfer_inventory, index)
		_selected_slot = -1
	elif _selected_slot < 0:
		if _inventory.get_slot(index) != null:
			_selected_slot = index
	elif _selected_slot == index:
		_selected_slot = -1
	else:
		_inventory.move_or_merge(_selected_slot, index)
		_selected_slot = -1
	_refresh()


func _on_drop_pressed() -> void:
	if _selected_slot >= 0:
		drop_requested.emit(_selected_slot)
		_selected_slot = -1
		_refresh()


func _apply_panel_style() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#202725")
	panel_style.border_color = Color("#6b756f")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(5)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	panel_style.shadow_size = 10
	add_theme_stylebox_override("panel", panel_style)
