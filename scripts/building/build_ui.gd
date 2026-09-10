class_name BuildUI
extends CanvasLayer

var _system: Node
var _buttons: Array[Button] = []

@onready var panel: PanelContainer = %CatalogPanel
@onready var list: VBoxContainer = %BuildingList
@onready var active_label: Label = %ActiveLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	active_label.visible = false
	%CloseButton.pressed.connect(close_build_palette)
	call_deferred("_bind_system")


func _bind_system() -> void:
	_system = get_tree().get_first_node_in_group("building_system")
	if _system == null:
		return
	_system.placement_changed.connect(_on_placement_changed)
	_rebuild_catalog()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and panel.visible:
		close_build_palette()
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed("building") or get_tree().paused:
		return
	var ui_manager := get_node_or_null("/root/UIManager")
	if ui_manager != null and ui_manager.has_open_modal():
		return
	if _system != null:
		_system.cancel_placement()
	panel.visible = not panel.visible
	get_viewport().set_input_as_handled()


func close_build_palette() -> void:
	panel.visible = false
	if _system != null:
		_system.cancel_placement()


func _rebuild_catalog() -> void:
	for child in list.get_children():
		child.queue_free()
	_buttons.clear()
	var registry := get_node_or_null("/root/ContentRegistry")
	if registry == null:
		return
	for definition in registry.get_buildings():
		var button := Button.new()
		button.custom_minimum_size = Vector2(250, 48)
		button.text = "%s\n%s" % [definition.display_name, definition.get_cost_text()]
		button.tooltip_text = definition.description
		button.pressed.connect(_select_building.bind(definition))
		list.add_child(button)
		_buttons.append(button)


func _select_building(definition: Resource) -> void:
	panel.visible = false
	_system.begin_placement(definition)


func _on_placement_changed(definition: Resource, is_valid: bool, reason: String) -> void:
	active_label.visible = definition != null
	if definition == null:
		return
	active_label.text = "%s  •  %s  •  LMB place  •  RMB/Esc cancel" % [definition.display_name, "Valid" if is_valid else reason]
	active_label.add_theme_color_override("font_color", Color("#79d68b") if is_valid else Color("#ee766c"))
