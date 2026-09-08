class_name InventorySlotUI
extends Button

signal slot_activated(slot_index: int, mouse_button: int, shift_pressed: bool, double_click: bool)

var slot_index := -1
var item_stack: Resource

@onready var item_glyph: ColorRect = %ItemGlyph
@onready var item_name: Label = %ItemName
@onready var quantity_label: Label = %Quantity


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	_update_style(false)


func configure(index: int, stack: Resource) -> void:
	slot_index = index
	item_stack = stack
	if not is_node_ready():
		return
	if item_stack == null:
		item_glyph.visible = false
		item_name.text = ""
		quantity_label.text = ""
		tooltip_text = "Empty slot"
	else:
		var definition: Resource = item_stack.item_definition
		item_glyph.visible = true
		item_glyph.color = definition.world_color
		item_name.text = definition.display_name
		quantity_label.text = str(item_stack.quantity) if definition.stack_limit > 1 else ""
		tooltip_text = "%s\n%s\nWeight: %.2f each" % [definition.display_name, definition.description, definition.weight]
	_update_style(false)


func set_selected_state(selected: bool) -> void:
	_update_style(selected)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			slot_activated.emit(slot_index, event.button_index, event.shift_pressed, event.double_click)
			accept_event()


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

