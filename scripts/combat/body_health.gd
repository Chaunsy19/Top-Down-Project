class_name BodyHealth
extends Node
## Reusable character condition; time is supplied by the actor's needs/clock.

signal changed()

const BLOOD_LOSS_MULTIPLIER := 1.1
const REGIONS: Array[StringName] = [&"head", &"torso", &"left_arm", &"right_arm", &"left_leg", &"right_leg"]
@export var clotting_per_game_hour := 4.0
@export var recovery_per_game_hour := 2.0
var condition: Dictionary = {}
## One cumulative injury record per region, with damage and blood loss/hour.
var injuries: Dictionary = {}
var blood := 100.0


func _init() -> void:
	for region in REGIONS:
		condition[region] = 100.0


func apply_damage(region: StringName, amount: float, bleeding_rate: float = 0.0) -> float:
	if not region in REGIONS or not is_finite(amount) or not is_finite(bleeding_rate) or amount <= 0.0 or is_collapsed():
		return 0.0
	var applied := minf(amount, condition[region])
	if applied <= 0.0:
		return 0.0
	condition[region] -= applied
	var previous: Dictionary = injuries.get(region, {"damage": 0.0, "bleeding": 0.0})
	injuries[region] = {"damage": 100.0 - condition[region], "bleeding": minf(float(previous.bleeding) + maxf(bleeding_rate, 0.0), 30.0)}
	changed.emit()
	return applied


func advance_game_minutes(minutes: float, can_recover: bool = false) -> void:
	if not is_finite(minutes) or minutes <= 0.0 or is_collapsed():
		return
	var hours := minutes / 60.0
	var was_bleeding := get_bleeding_rate() > 0.0
	for region in injuries.keys():
		var injury: Dictionary = injuries[region]
		var rate: float = injury.bleeding
		var clotting := maxf(clotting_per_game_hour, 0.0)
		var duration := minf(hours, rate / clotting) if clotting > 0.0 else hours
		blood = maxf(0.0, blood - (rate * duration - 0.5 * clotting * duration * duration) * BLOOD_LOSS_MULTIPLIER)
		injury.bleeding = maxf(0.0, rate - clotting * hours)
		if can_recover and rate <= 0.0:
			condition[region] = minf(100.0, condition[region] + maxf(recovery_per_game_hour, 0.0) * hours)
			injury.damage = 100.0 - condition[region]
			if injury.damage <= 0.0:
				injuries.erase(region)
	if can_recover and not was_bleeding and blood > 0.0:
		blood = minf(100.0, blood + maxf(recovery_per_game_hour, 0.0) * hours)
	changed.emit()


func get_bleeding_rate() -> float:
	var total := 0.0
	for injury in injuries.values():
		total += float(injury.bleeding)
	return total * BLOOD_LOSS_MULTIPLIER


func is_collapsed() -> bool:
	return blood <= 0.0


func get_movement_multiplier() -> float:
	return _capacity(&"left_leg", &"right_leg")


func get_action_multiplier() -> float:
	return _capacity(&"left_arm", &"right_arm")


func _capacity(left: StringName, right: StringName) -> float:
	if is_collapsed():
		return 0.0
	var limb_ratio := (float(condition[left]) + float(condition[right])) / 200.0
	return lerpf(0.35, 1.0, limb_ratio) * lerpf(0.4, 1.0, blood / 100.0)


func get_region_text(region: StringName) -> String:
	var value: float = condition[region]
	var severity := "Healthy" if value >= 100.0 else ("Minor" if value > 70.0 else ("Moderate" if value > 35.0 else "Severe"))
	var rate: float = injuries.get(region, {}).get("bleeding", 0.0) * BLOOD_LOSS_MULTIPLIER
	return "%s: %.0f/100 · %s%s" % [String(region).replace("_", " ").capitalize(), value, severity, " · bleeding %.1f/h" % rate if rate > 0.0 else ""]
