extends CanvasLayer

var _world_clock: Node
var _needs: Node

@onready var time_label: Label = %TimeLabel
@onready var period_label: Label = %PeriodLabel
@onready var hunger_bar: ProgressBar = %HungerBar
@onready var fatigue_bar: ProgressBar = %FatigueBar
@onready var health_bar: ProgressBar = %HealthBar
@onready var condition_label: Label = %ConditionLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_find_sources")


func _process(_delta: float) -> void:
	if not is_instance_valid(_world_clock) or not is_instance_valid(_needs):
		_find_sources()
	_refresh()


func _find_sources() -> void:
	_world_clock = get_tree().get_first_node_in_group("world_clock")
	_needs = get_tree().get_first_node_in_group("survival_needs")


func _refresh() -> void:
	if is_instance_valid(_world_clock):
		time_label.text = _world_clock.get_time_text()
		period_label.text = _world_clock.get_period_name()
	if not is_instance_valid(_needs):
		return
	hunger_bar.value = _needs.hunger
	fatigue_bar.value = _needs.fatigue
	health_bar.value = _needs.health
	condition_label.text = "%s  •  R: %s" % [
		_needs.get_condition_text(),
		"wake" if _needs.is_resting else "rest",
	]
