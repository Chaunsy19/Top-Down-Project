class_name InventorySlotUI
extends Button

signal slot_activated(slot_index: int, mouse_button: int, shift_pressed: bool, double_click: bool)
signal stack_dropped(source_inventory: InventoryComponent, source_slot: int, target_inventory: InventoryComponent, target_slot: int, moved_quantity: int)

var _item_icon: TextureRect
var slot_index := -1
var item_stack: Resource
var inventory: InventoryComponent

@onready var item_glyph: ColorRect = %ItemGlyph
@onready var item_name: Label = %ItemName
@onready var quantity_label: Label = %Quantity


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	_item_icon = TextureRect.new()
	_item_icon.position = item_glyph.position
	_item_icon.size = item_glyph.size
	_item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_item_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_item_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_item_icon)
	_update_style(false)


func configure(index: int, stack: Resource, owner_inventory: InventoryComponent = null) -> void:
	slot_index = index
	item_stack = stack
	inventory = owner_inventory
	if not is_node_ready():
		return
	if item_stack == null:
		item_glyph.visible = false
		_item_icon.texture = null
		item_name.text = ""
		quantity_label.text = ""
		tooltip_text = "Empty slot"
	else:
		var definition: Resource = item_stack.item_definition
		item_glyph.visible = definition.icon == null
		_item_icon.texture = definition.icon
		item_glyph.color = definition.world_color
		item_name.text = definition.display_name
		quantity_label.text = str(item_stack.quantity) if definition.stack_limit > 1 else ""
		tooltip_text = "%s\n%s\nWeight: %.2f each\nDrag to move or assign" % [definition.display_name, definition.description, definition.weight]
		if item_stack.has_durability():
			item_stack.initialize_runtime_state()
			tooltip_text += "\nDurability: %d/%d" % [item_stack.current_durability, definition.tool_profile.maximum_durability]
	_update_style(false)


func set_selected_state(selected: bool) -> void:
	_update_style(selected)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			slot_activated.emit(slot_index, event.button_index, event.shift_pressed, event.double_click)
			accept_event()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if inventory == null or item_stack == null:
		return null
	var preview := _create_drag_preview()
	set_drag_preview(preview)
	return {
		"kind": &"inventory_stack",
		"inventory": inventory,
		"slot_index": slot_index,
		"item_id": item_stack.item_definition.item_id,
	}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if inventory == null or data is not Dictionary or data.get("kind", &"") != &"inventory_stack":
		return false
	var source_inventory := data.get("inventory") as InventoryComponent
	var source_slot := int(data.get("slot_index", -1))
	return source_inventory != null and source_inventory.is_valid_slot(source_slot) and source_inventory.get_slot(source_slot) != null and (source_inventory != inventory or source_slot != slot_index)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(Vector2.ZERO, data):
		return
	var source_inventory := data.get("inventory") as InventoryComponent
	var source_slot := int(data.get("slot_index", -1))
	var moved_quantity := source_inventory.transfer_to_slot(inventory, source_slot, slot_index)
	stack_dropped.emit(source_inventory, source_slot, inventory, slot_index, moved_quantity)


func _create_drag_preview() -> Control:
	var preview := PanelContainer.new()
	preview.custom_minimum_size = Vector2(132.0, 46.0)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.14, 0.13, 0.96)
	style.border_color = _get_category_color(item_stack.item_definition.categories)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	preview.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = "%s%s" % [item_stack.item_definition.display_name, "  ×%d" % item_stack.quantity if item_stack.quantity > 1 else ""]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(label)
	return preview


func _update_style(selected: bool) -> void:
	var border_color := Color("#59615e")
	if item_stack != null:
		border_color = _get_category_color(item_stack.item_definition.categories)
	if selected:
		border_color = Color("#e6c36a")

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color("#303634")
	normal_style.border_color = border_color
	normal_style.set_border_width_all(2 if item_stack != null or selected else 1)
	normal_style.set_corner_radius_all(3)
	add_theme_stylebox_override("normal", normal_style)

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = Color("#3b4541")
	hover_style.border_color = border_color.lightened(0.18)
	add_theme_stylebox_override("hover", hover_style)
	add_theme_stylebox_override("pressed", hover_style)


func _get_category_color(categories: Array[StringName]) -> Color:
	if &"medical" in categories:
		return Color("#d85b62")
	if &"food" in categories or &"consumable" in categories:
		return Color("#4ba6b8")
	if &"tool" in categories or &"weapon" in categories:
		return Color("#7dad45")
	if &"material" in categories:
		return Color("#b38a50")
	return Color("#77817d")
