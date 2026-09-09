class_name HotbarSlotUI
extends Button

var slot_index := -1
var hotbar: HotbarComponent

@onready var key_label: Label = %KeyLabel
@onready var item_glyph: ColorRect = %ItemGlyph
@onready var item_label: Label = %ItemLabel
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func bind_hotbar(value: HotbarComponent) -> void:
	hotbar = value


func configure(index: int, item_id: StringName, stack: Resource, selected: bool) -> void:
	slot_index = index
	key_label.text = str(index + 1)
	if item_id.is_empty():
		item_glyph.visible = false
		item_label.text = "Empty"
		status_label.text = ""
		tooltip_text = "Hotbar %d — Drop a tool or weapon here" % (index + 1)
	else:
		var registry := get_node_or_null("/root/ContentRegistry")
		var definition: Resource = stack.item_definition if stack != null else (registry.get_item(item_id) if registry != null else null)
		item_glyph.visible = definition != null
		item_glyph.color = definition.world_color if definition != null else Color("#735052")
		item_label.text = definition.display_name if definition != null else String(item_id).capitalize()
		if stack == null:
			status_label.text = "MISSING"
			tooltip_text = "%s is assigned but unavailable" % item_label.text
		elif stack.has_durability():
			stack.initialize_runtime_state()
			status_label.text = "%d/%d" % [stack.current_durability, definition.tool_profile.maximum_durability]
			tooltip_text = "%s — Durability %s" % [definition.display_name, status_label.text]
		else:
			status_label.text = str(stack.quantity) if stack.quantity > 1 else ""
			tooltip_text = definition.display_name
		tooltip_text += "\nRight-click to clear"
	_apply_style(selected, not item_id.is_empty() and stack == null)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and hotbar != null:
		hotbar.clear_slot(slot_index)
		accept_event()


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if hotbar == null or data is not Dictionary or data.get("kind", &"") != &"inventory_stack":
		return false
	var source_inventory := data.get("inventory") as InventoryComponent
	var source_slot := int(data.get("slot_index", -1))
	if source_inventory == null or source_inventory != hotbar.get_inventory():
		return false
	var stack := source_inventory.get_slot(source_slot)
	return stack != null and hotbar.is_definition_allowed(stack.item_definition)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(Vector2.ZERO, data):
		return
	hotbar.assign_from_inventory(slot_index, int(data.get("slot_index", -1)))


func _apply_style(selected: bool, missing: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#202725")
	style.border_color = Color("#d8ad4c") if selected else (Color("#8f4e51") if missing else Color("#59615e"))
	style.set_border_width_all(3 if selected else 2)
	style.set_corner_radius_all(4)
	add_theme_stylebox_override("normal", style)
	var hover_style := style.duplicate()
	hover_style.bg_color = Color("#303a36")
	add_theme_stylebox_override("hover", hover_style)
	add_theme_stylebox_override("pressed", hover_style)
