class_name CharacterUI
extends CanvasLayer

var _armor_choices: Dictionary = {}
var _armor_status: Label
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
	_create_armor_controls()
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
		_refresh_armor_controls()
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

func _create_armor_controls() -> void:
	var layout := equipment_panel.get_node("Margin/Layout")
	var rows := {&"head": "HeadRow", &"torso": "BodyRow", &"legs": "LegsRow"}
	for slot in EquipmentComponent.ARMOR_SLOTS:
		var row := layout.get_node(rows[slot])
		row.get_node("Slot").text = String(slot).to_upper()
		row.get_node("Value").hide()
		var choice := OptionButton.new()
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.fit_to_longest_item = false
		choice.item_selected.connect(_select_armor.bind(slot))
		row.add_child(choice)
		_armor_choices[slot] = choice
	_armor_status = Label.new()
	_armor_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_armor_status.text = "Craft wood armor, then select it here. Empty unequips."
	layout.add_child(_armor_status)


func _refresh_armor_controls() -> void:
	var inventory := _player.get_node("Inventory") as InventoryComponent
	for slot in EquipmentComponent.ARMOR_SLOTS:
		var choice: OptionButton = _armor_choices[slot]
		# Do not rebuild an open popup underneath the pointer.
		if choice.get_popup().visible:
			continue
		choice.clear()
		choice.add_item("Empty")
		choice.set_item_metadata(0, -1)
		var equipped := _equipment.get_armor_stack(slot)
		if equipped != null:
			choice.add_item("%s · %d%%" % [equipped.item_definition.display_name, roundi(equipped.item_definition.armor_protection * 100.0)])
			choice.set_item_metadata(1, -2)
			choice.select(1)
		for index in inventory.slot_count:
			var stack := inventory.get_slot(index)
			if stack != null and stack.item_definition.armor_slot == String(slot):
				choice.add_item("Equip %s · %d%%" % [stack.item_definition.display_name, roundi(stack.item_definition.armor_protection * 100.0)])
				choice.set_item_metadata(choice.item_count - 1, index)


func _select_armor(index: int, slot: StringName) -> void:
	var choice: OptionButton = _armor_choices[slot]
	var inventory_index: int = choice.get_item_metadata(index)
	if inventory_index == -2:
		return
	var inventory := _player.get_node("Inventory") as InventoryComponent
	var succeeded := _equipment.unequip_armor_to_inventory(inventory, slot) if inventory_index == -1 else _equipment.equip_armor_from_inventory(inventory, inventory_index, slot)
	_armor_status.text = "Equipment updated." if succeeded else "Could not change armor. Check inventory capacity and item availability."
	_refresh()
