class_name HarvestableResourceNode
extends "res://scripts/interaction/interactable.gd"

const WorldItemDropScene = preload("res://scenes/world/world_item_drop.tscn")
const WorldItemDropScript = preload("res://scripts/world/world_item_drop.gd")
const HealthComponentScript = preload("res://scripts/combat/health_component.gd")
const DEPLETION_PERMANENT := 0
const DEPLETION_RESPAWN := 1
const DEPLETION_REGROW := 2

signal harvest_started(actor: Node2D)
signal harvest_cancelled(actor: Node2D)
signal harvest_completed(actor: Node2D, drops: Array[Node2D], experience_reward: int)
signal depleted()
signal recovered()

@export var definition: Resource

var harvest_progress := 0.0
var recovery_remaining := 0.0
var health: HealthComponentScript
var _harvesting_actor: Node2D
var _active_tool_stack: Resource
var _random := RandomNumberGenerator.new()
var _connection_mask := 0

const CONNECT_NORTH := 1
const CONNECT_EAST := 2
const CONNECT_SOUTH := 4
const CONNECT_WEST := 8
const CARDINAL_CONNECTIONS := {
	CONNECT_NORTH: Vector2i.UP,
	CONNECT_EAST: Vector2i.RIGHT,
	CONNECT_SOUTH: Vector2i.DOWN,
	CONNECT_WEST: Vector2i.LEFT,
}

@onready var name_label := get_node_or_null("NameLabel") as Label
@onready var status_label := get_node_or_null("StatusLabel") as Label


func _ready() -> void:
	super()
	add_to_group("resource_node")
	if definition == null:
		push_error("ResourceNode '%s' has no definition." % name)
		set_available(false)
		return
	display_name = "Stone Block" if definition.visual_kind == "rock" else definition.display_name
	interaction_verb = "Harvest"
	health = HealthComponentScript.new()
	add_child(health)
	health.configure(definition.maximum_health, definition.damage_material_tags)
	add_to_group("damageable")
	_random.seed = hash("%s:%s:%s" % [definition.node_id, global_position.x, global_position.y])
	if definition.visual_kind == "rock":
		call_deferred("refresh_grid_connections")
		_configure_full_cell_collision()
	_update_presentation()


func _process(delta: float) -> void:
	if is_harvesting():
		_validate_harvest_actor()
	elif is_depleted() and recovery_remaining > 0.0:
		advance_simulation(delta)


func can_interact(actor: Node2D) -> bool:
	return (
		super(actor)
		and not is_depleted()
		and not is_harvesting()
		and get_actor_skill_level(actor) >= definition.required_skill_level
		and has_required_tool(actor)
	)


func get_prompt_text() -> String:
	if definition == null:
		return "Invalid resource"
	if is_harvesting():
		return "Harvesting %s (%d%%)" % [display_name, roundi(get_harvest_ratio() * 100.0)]
	if is_depleted():
		return "%s depleted" % display_name
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not definition.required_tool_tags.is_empty() and not has_required_tool(player):
		return "Equip %s" % _get_tool_requirement_name()
	return "%s %s" % [interaction_verb, display_name]


func get_debug_state() -> String:
	if definition == null:
		return "Invalid definition"
	if is_harvesting():
		return "Working %d%% | %.0f/%.0f HP" % [roundi(get_harvest_ratio() * 100.0), health.current_health, health.maximum_health]
	if is_depleted():
		if recovery_remaining > 0.0:
			return "Depleted | recovers in %.1fs" % recovery_remaining
		return "Depleted"
	var tool_text := "Hands" if definition.required_tool_tags.is_empty() else _get_tool_requirement_name()
	return "Ready | %.0f/%.0f HP | %s %d+ | %s" % [
		health.current_health,
		health.maximum_health,
		String(definition.skill_id).capitalize(),
		definition.required_skill_level,
		tool_text,
	]


func is_harvesting() -> bool:
	return is_instance_valid(_harvesting_actor)


func is_depleted() -> bool:
	return health != null and health.is_depleted()


func get_health_ratio() -> float:
	return health.get_ratio() if health != null else 0.0


func take_damage(amount: float, damage_kind: StringName = &"melee", effective_tags: Array = [], source: Node2D = null) -> float:
	if health == null or is_depleted():
		return 0.0
	var applied := health.apply_damage(amount, damage_kind, effective_tags)
	if applied > 0.0 and health.is_depleted():
		_finish_depletion(source)
	else:
		_update_presentation()
	return applied


func get_harvest_ratio() -> float:
	var effective_time := get_effective_harvest_time()
	if definition == null or effective_time <= 0.0:
		return 0.0
	return clampf(harvest_progress / effective_time, 0.0, 1.0)


func uses_hold_interaction() -> bool:
	return false


func prefers_utility_when_armed() -> bool:
	return true


func continue_hold_interaction(actor: Node2D, delta: float) -> bool:
	if actor != _harvesting_actor:
		return false
	advance_simulation(delta)
	return is_harvesting()


func cancel_hold_interaction(actor: Node2D) -> void:
	if actor == _harvesting_actor:
		cancel_harvest()


func is_hold_interaction_active(actor: Node2D) -> bool:
	return actor == _harvesting_actor and is_harvesting()


func get_actor_skill_level(actor: Node2D) -> int:
	if not is_instance_valid(actor) or definition == null or definition.skill_id.is_empty():
		return 0
	var skills := actor.get_node_or_null("Skills")
	return skills.get_skill_level(definition.skill_id) if skills else 0


func has_required_tool(actor: Node2D) -> bool:
	if definition == null or definition.required_tool_tags.is_empty():
		return true
	return find_compatible_tool(actor) != null


func find_compatible_tool(actor: Node2D) -> Resource:
	if not is_instance_valid(actor) or definition == null or definition.required_tool_tags.is_empty():
		return null
	var equipment := actor.get_node_or_null("Equipment")
	if equipment == null:
		return null
	return equipment.get_equipped_tool(definition.required_tool_tags, definition.minimum_tool_tier)


func get_effective_harvest_time(actor: Node2D = null) -> float:
	if definition == null:
		return 0.0
	var tool_stack := _active_tool_stack
	if tool_stack == null and is_instance_valid(actor):
		tool_stack = find_compatible_tool(actor)
	var speed_multiplier := 1.0
	if tool_stack != null and tool_stack.item_definition.tool_profile != null:
		speed_multiplier = tool_stack.item_definition.tool_profile.work_speed_multiplier
	return definition.harvest_time_seconds / maxf(speed_multiplier, 0.01)


func advance_simulation(delta: float) -> void:
	if definition == null:
		return
	if is_harvesting():
		if not _validate_harvest_actor():
			return
		harvest_progress += delta
		if harvest_progress >= get_effective_harvest_time():
			_complete_work_strike()
		else:
			_update_presentation()
	elif is_depleted() and recovery_remaining > 0.0:
		recovery_remaining = maxf(recovery_remaining - delta, 0.0)
		if recovery_remaining <= 0.0:
			_recover()
		else:
			_update_presentation()


func _validate_harvest_actor() -> bool:
	if not is_harvesting():
		return false
	if not definition.required_tool_tags.is_empty() and find_compatible_tool(_harvesting_actor) != _active_tool_stack:
		cancel_harvest()
		return false
	if global_position.distance_to(_harvesting_actor.global_position) > definition.cancel_distance:
		cancel_harvest()
		return false
	return true


func cancel_harvest() -> void:
	if not is_harvesting():
		return
	var previous_actor := _harvesting_actor
	_harvesting_actor = null
	_active_tool_stack = null
	harvest_progress = 0.0
	harvest_cancelled.emit(previous_actor)
	_update_presentation()


func _perform_interaction(actor: Node2D) -> void:
	_harvesting_actor = actor
	_active_tool_stack = find_compatible_tool(actor)
	harvest_progress = 0.0
	harvest_started.emit(actor)
	_complete_work_strike()


func _complete_work_strike() -> void:
	var actor := _harvesting_actor
	var used_tool := _active_tool_stack
	_harvesting_actor = null
	_active_tool_stack = null
	harvest_progress = 0.0
	var damage: float = definition.unarmed_work_damage
	var damage_tags: Array[StringName] = definition.damage_material_tags
	if used_tool != null and used_tool.item_definition != null:
		damage = used_tool.item_definition.tool_damage
		damage_tags = used_tool.item_definition.tool_damage_tags
	var applied := take_damage(damage, &"tool", damage_tags, actor)
	if applied > 0.0:
		_wear_used_tool(actor, used_tool)
	_update_presentation()


func _finish_depletion(actor: Node2D) -> void:
	var drops := _spawn_yields()
	_award_experience(actor)
	harvest_completed.emit(actor, drops, definition.experience_reward)
	_begin_depletion()
	_update_presentation()


func _spawn_yields() -> Array[Node2D]:
	var drops: Array[Node2D] = []
	for index in definition.yields.size():
		var harvest_yield: Resource = definition.yields[index]
		var quantity: int = harvest_yield.roll_quantity(_random)
		var drop := WorldItemDropScene.instantiate() as WorldItemDropScript
		drop.configure(harvest_yield.item_definition, quantity)
		get_parent().add_child(drop)
		drop.global_position = global_position + Vector2(22.0 + index * 10.0, 18.0 + index * 6.0)
		drops.append(drop)
	return drops


func _award_experience(actor: Node2D) -> void:
	if not is_instance_valid(actor) or definition.skill_id.is_empty():
		return
	var skills := actor.get_node_or_null("Skills")
	if skills:
		skills.add_experience(definition.skill_id, definition.experience_reward)


func _wear_used_tool(actor: Node2D, used_tool: Resource) -> void:
	if used_tool == null or not is_instance_valid(actor):
		return
	var equipment := actor.get_node_or_null("Equipment")
	if equipment == null or equipment.get_hand_stack() != used_tool:
		return
	var item_name: String = used_tool.item_definition.display_name
	if equipment.damage_hand_item(1):
		var inventory_ui := get_tree().get_first_node_in_group("inventory_ui")
		if inventory_ui != null:
			inventory_ui.show_notification("%s broke" % item_name)


func _begin_depletion() -> void:
	set_available(false)
	depleted.emit()
	if definition.depletion_behavior != DEPLETION_PERMANENT:
		recovery_remaining = definition.recovery_time_seconds
	if definition.depletion_behavior == DEPLETION_RESPAWN:
		visible = false
		set_grid_occupancy_enabled(false)
		_set_collision_shapes_disabled(true)
	elif definition.visual_kind == "rock":
		visible = false
		set_grid_occupancy_enabled(false)
		_set_collision_shapes_disabled(true)


func _recover() -> void:
	health.restore_full()
	recovery_remaining = 0.0
	visible = true
	set_available(true)
	if definition.depletion_behavior == DEPLETION_RESPAWN:
		set_grid_occupancy_enabled(true)
		_set_collision_shapes_disabled(false)
	recovered.emit()
	_update_presentation()


func _set_collision_shapes_disabled(disabled: bool) -> void:
	for child in find_children("*", "CollisionShape2D", true, false):
		(child as CollisionShape2D).set_deferred("disabled", disabled)


func _update_presentation() -> void:
	if definition == null:
		return
	if is_instance_valid(name_label):
		name_label.text = display_name
	if is_instance_valid(status_label):
		if is_harvesting():
			status_label.text = "%d%%" % roundi(get_harvest_ratio() * 100.0)
		elif is_depleted():
			status_label.text = "DEPLETED"
		else:
			status_label.text = "%.0f / %.0f HP" % [health.current_health, health.maximum_health]
	queue_redraw()


func _draw() -> void:
	if definition == null:
		return
	var depleted_color: Color = definition.depleted_color
	if is_depleted():
		draw_rect(Rect2(-10.0, -5.0, 20.0, 10.0), depleted_color)
	elif definition.visual_kind == "tree":
		draw_rect(Rect2(-5.0, 2.0, 10.0, 24.0), definition.depleted_color)
		draw_circle(Vector2(-7.0, -4.0), 15.0, definition.secondary_color)
		draw_circle(Vector2(8.0, -6.0), 17.0, definition.primary_color)
		draw_circle(Vector2(0.0, -15.0), 16.0, definition.primary_color.lightened(0.08))
	elif definition.visual_kind == "rock":
		_draw_connected_stone_tile()
	else:
		draw_circle(Vector2(-9.0, 2.0), 13.0, definition.primary_color)
		draw_circle(Vector2(9.0, 1.0), 14.0, definition.primary_color.lightened(0.06))
		draw_circle(Vector2(0.0, -9.0), 13.0, definition.primary_color)
		for berry_position in [Vector2(-9.0, -3.0), Vector2(7.0, -7.0), Vector2(10.0, 7.0)]:
			draw_circle(berry_position, 3.0, definition.secondary_color)

	if not is_depleted() and health != null and health.current_health < health.maximum_health:
		draw_rect(Rect2(-20.0, 28.0, 40.0, 5.0), Color("#16201c"))
		draw_rect(Rect2(-19.0, 29.0, 38.0 * get_health_ratio(), 3.0), Color("#d86155"))
	elif is_harvesting():
		draw_rect(Rect2(-20.0, 28.0, 40.0, 5.0), Color("#16201c"))
		draw_rect(Rect2(-19.0, 29.0, 38.0 * get_harvest_ratio(), 3.0), Color("#e6c36a"))


func _get_tool_requirement_name() -> String:
	var names: PackedStringArray = []
	for required_tag in definition.required_tool_tags:
		names.append(String(required_tag).replace("_", " ").capitalize())
	return " + ".join(names)


func get_connection_mask() -> int:
	return _connection_mask


func refresh_grid_connections() -> void:
	if definition == null or definition.visual_kind != "rock" or not _is_grid_occupancy_registered:
		return
	var new_mask := 0
	for direction_flag in CARDINAL_CONNECTIONS:
		var neighbor_cell: Vector2i = get_occupied_cell() + CARDINAL_CONNECTIONS[direction_flag]
		var neighbor: Node2D = _grid_world.get_cell_occupant(neighbor_cell)
		if neighbor is HarvestableResourceNode and neighbor.definition != null and neighbor.definition.node_id == definition.node_id:
			new_mask |= direction_flag
	if new_mask != _connection_mask:
		_connection_mask = new_mask
		queue_redraw()
	_update_connected_tile_labels()


func _configure_full_cell_collision() -> void:
	var body_shape := get_node_or_null("Body/CollisionShape2D") as CollisionShape2D
	if body_shape == null:
		return
	var tile_shape := RectangleShape2D.new()
	tile_shape.size = Vector2(30.0, 30.0)
	body_shape.shape = tile_shape


func _update_connected_tile_labels() -> void:
	if not is_instance_valid(name_label) or not is_instance_valid(status_label):
		return
	var is_cluster_label := (_connection_mask & (CONNECT_NORTH | CONNECT_WEST)) == 0
	name_label.visible = is_cluster_label
	status_label.visible = is_cluster_label


func _draw_connected_stone_tile() -> void:
	var half_size := 16.0
	draw_rect(Rect2(-half_size, -half_size, half_size * 2.0, half_size * 2.0), definition.primary_color)
	draw_rect(Rect2(-half_size + 3.0, -half_size + 3.0, half_size * 2.0 - 6.0, 7.0), definition.primary_color.lightened(0.1))
	var edge_color: Color = definition.secondary_color.darkened(0.12)
	if (_connection_mask & CONNECT_NORTH) == 0:
		draw_line(Vector2(-half_size, -half_size), Vector2(half_size, -half_size), edge_color, 2.0)
	if (_connection_mask & CONNECT_EAST) == 0:
		draw_line(Vector2(half_size, -half_size), Vector2(half_size, half_size), edge_color, 2.0)
	if (_connection_mask & CONNECT_SOUTH) == 0:
		draw_line(Vector2(half_size, half_size), Vector2(-half_size, half_size), edge_color, 2.0)
	if (_connection_mask & CONNECT_WEST) == 0:
		draw_line(Vector2(-half_size, half_size), Vector2(-half_size, -half_size), edge_color, 2.0)
	var crack_offset := float(posmod(hash(get_occupied_cell()), 7) - 3)
	draw_polyline(PackedVector2Array([
		Vector2(-5.0 + crack_offset, -4.0),
		Vector2(1.0 + crack_offset, 1.0),
		Vector2(-2.0 + crack_offset, 7.0),
	]), definition.secondary_color, 1.5)
