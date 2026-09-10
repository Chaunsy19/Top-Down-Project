class_name CharacterUI
extends CanvasLayer

var _body_label: Label
var _test_region: OptionButton
var _player: Node2D
var _needs: Node
var _equipment: EquipmentComponent

@onready var health_panel: PanelContainer = %HealthPanel
@onready var equipment_panel: PanelContainer = %EquipmentPanel
@onready var blood_bar: ProgressBar = %BloodBar
@onready var hunger_bar: ProgressBar = %HungerBar
@onready var rest_bar: ProgressBar = %RestBar
@onready var condition_label: Label = %ConditionLabel
@onready var hand_item_label: Label = %HandItemLabel
@onready var hand_detail_label: Label = %HandDetailLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("character_ui")
	health_panel.visible = false
	equipment_panel.visible = false
	%HealthCloseButton.pressed.connect(close_health)
	%EquipmentCloseButton.pressed.connect(close_equipment)
	_body_label = Label.new()
	_body_label.add_theme_font_size_override("font_size", 14)
	health_panel.get_node("Margin/Layout").add_child(_body_label)
	if OS.is_debug_build():
		var row := HBoxContainer.new()
		health_panel.get_node("Margin/Layout").add_child(row)
		_test_region = OptionButton.new()
		for region in BodyHealth.REGIONS:
			_test_region.add_item(String(region).replace("_", " ").capitalize())
		row.add_child(_test_region)
		var test_button := Button.new()
		test_button.text = "Test wound"
		test_button.tooltip_text = "Development: 25 region damage and 8 blood loss per game hour."
		test_button.pressed.connect(_test_wound)
		row.add_child(test_button)
	call_deferred("_find_player")


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		_find_player()
	_refresh()


func open_health() -> void:
	_find_player()
	health_panel.visible = true
	health_panel.move_to_front()
	_register_window(health_panel, Callable(self, "close_health"))
	_refresh()


func close_health() -> void:
	health_panel.visible = false
	_unregister_window(health_panel)


func toggle_health() -> void:
	if health_panel.visible:
		close_health()
	else:
		open_health()


func open_equipment() -> void:
	_find_player()
	equipment_panel.visible = true
	equipment_panel.move_to_front()
	_register_window(equipment_panel, Callable(self, "close_equipment"))
	_refresh()


func close_equipment() -> void:
	equipment_panel.visible = false
	_unregister_window(equipment_panel)


func toggle_equipment() -> void:
	if equipment_panel.visible:
		close_equipment()
	else:
		open_equipment()


func is_health_open() -> bool:
	return health_panel.visible


func is_equipment_open() -> bool:
	return equipment_panel.visible


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node2D
	_needs = _player.get_node_or_null("Needs") if _player != null else null
	_equipment = _player.get_node_or_null("Equipment") as EquipmentComponent if _player != null else null


func _refresh() -> void:
	if is_instance_valid(_needs):
		blood_bar.value = _needs.body_health.blood
		hunger_bar.value = _needs.hunger
		rest_bar.value = _needs.fatigue
		condition_label.text = "%s\nBlood: %.0f / 100\nHunger: %.0f / 100\nRest: %.0f / 100" % [
			_needs.get_condition_text(),
			_needs.body_health.blood,
			_needs.hunger,
			_needs.fatigue,
		]
		var body: BodyHealth = _needs.body_health
		var lines := PackedStringArray()
		lines.append("Blood: %.1f/100 · Bleeding: %.1f/hour" % [body.blood, body.get_bleeding_rate()])
		for region in BodyHealth.REGIONS:
			lines.append(body.get_region_text(region))
		lines.append("Movement: %d%% · Work/attacks: %d%%" % [roundi(_needs.get_movement_multiplier() * 100.0), roundi(_needs.get_action_multiplier() * 100.0)])
		lines.append("Wounds clot over time. Rest well-fed to recover.")
		_body_label.text = "\n".join(lines)
	if is_instance_valid(_equipment):
		var hand_stack := _equipment.get_hand_stack()
		if hand_stack == null or hand_stack.item_definition == null:
			hand_item_label.text = "Empty"
			hand_detail_label.text = "Select a tool or weapon from the hotbar."
		else:
			hand_item_label.text = hand_stack.item_definition.display_name
			var profile: Resource = hand_stack.item_definition.tool_profile
			hand_detail_label.text = "Melee %.0f  •  Tool %.0f" % [hand_stack.item_definition.melee_damage, hand_stack.item_definition.tool_damage]
			if profile != null and profile.maximum_durability > 0:
				hand_detail_label.text += "  •  Durability %d / %d" % [hand_stack.current_durability, profile.maximum_durability]


func _register_window(window: Control, close_callback: Callable) -> void:
	var ui_manager := get_node_or_null("/root/UIManager")
	if ui_manager != null:
		ui_manager.register_modal(window, close_callback)


func _unregister_window(window: Control) -> void:
	var ui_manager := get_node_or_null("/root/UIManager")
	if ui_manager != null:
		ui_manager.unregister_modal(window)

func _test_wound() -> void:
	if is_instance_valid(_player):
		_player.take_region_damage(BodyHealth.REGIONS[_test_region.selected], 25.0, 8.0)
		_refresh()
