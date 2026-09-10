extends CanvasLayer

const CharacterUIScript = preload("res://scripts/ui/character_ui.gd")
const ALERT_ICON_COLOR := Color(1.0, 0.55, 0.34, 1.0)
const RESTING_ICON_COLOR := Color(0.45, 0.72, 1.0, 1.0)

var _pulse_time := 0.0
var _world_clock: Node
var _needs: Node
var _player: PlayerController

@onready var time_label: Label = %TimeLabel
@onready var period_label: Label = %PeriodLabel
@onready var health_button: Button = %HealthButton
@onready var equipment_button: Button = %EquipmentButton
@onready var inventory_button: Button = %InventoryButton
@onready var hunger_button: Button = %HungerButton
@onready var rest_button: Button = %RestButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	health_button.pressed.connect(_open_health)
	equipment_button.pressed.connect(_open_equipment)
	inventory_button.pressed.connect(_open_inventory)
	hunger_button.pressed.connect(_open_inventory)
	rest_button.pressed.connect(_toggle_rest)
	call_deferred("_find_sources")


func _process(delta: float) -> void:
	_pulse_time += delta
	if not is_instance_valid(_world_clock) or not is_instance_valid(_needs) or not is_instance_valid(_player):
		_find_sources()
	_refresh()


func _find_sources() -> void:
	_world_clock = get_tree().get_first_node_in_group("world_clock")
	_needs = get_tree().get_first_node_in_group("survival_needs")
	_player = get_tree().get_first_node_in_group("player") as PlayerController


func _refresh() -> void:
	if is_instance_valid(_world_clock):
		time_label.text = _world_clock.get_time_text()
		period_label.text = _world_clock.get_period_name()
	if not is_instance_valid(_needs):
		return
	health_button.tooltip_text = "Blood: %.1f / 100 · Bleeding: %.1f/hour — open injuries" % [_needs.body_health.blood, _needs.body_health.get_bleeding_rate()]
	equipment_button.tooltip_text = "Open equipment"
	inventory_button.tooltip_text = "Open inventory"
	hunger_button.tooltip_text = "Hunger low: %.0f / 100 — open inventory" % _needs.hunger
	rest_button.tooltip_text = "%s: %.0f / 100" % ["Resting" if _needs.is_resting else "Rest low", _needs.fatigue]
	var bleeding: bool = _needs.body_health.get_bleeding_rate() > 0.0 and not _needs.body_health.is_collapsed()
	health_button.modulate = Color(1.0, 0.35, 0.35, 0.65 + 0.35 * sin(_pulse_time * TAU * 1.5)) if bleeding else (ALERT_ICON_COLOR if _needs.body_health.blood <= _needs.critical_threshold else Color.WHITE)
	if not bleeding:
		_pulse_time = 0.0
	hunger_button.visible = _needs.hunger <= _needs.critical_threshold
	hunger_button.modulate = ALERT_ICON_COLOR
	rest_button.visible = _needs.fatigue <= _needs.critical_threshold or _needs.is_resting
	rest_button.modulate = RESTING_ICON_COLOR if _needs.is_resting else ALERT_ICON_COLOR


func _open_health() -> void:
	var character_ui := get_tree().get_first_node_in_group("character_ui") as CharacterUIScript
	if character_ui != null:
		character_ui.toggle_health()


func _open_equipment() -> void:
	var character_ui := get_tree().get_first_node_in_group("character_ui") as CharacterUIScript
	if character_ui != null:
		character_ui.toggle_equipment()


func _open_inventory() -> void:
	var inventory_ui := get_tree().get_first_node_in_group("inventory_ui")
	if inventory_ui == null:
		return
	if inventory_ui.is_open():
		inventory_ui.close_inventory()
	else:
		inventory_ui.open_player_inventory()


func _toggle_rest() -> void:
	if not is_instance_valid(_needs) or not is_instance_valid(_player):
		return
	if _player.is_combat_ready:
		rest_button.tooltip_text = "Put away the held item before resting"
		return
	_needs.toggle_resting()
