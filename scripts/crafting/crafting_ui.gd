class_name CraftingUI
extends CanvasLayer

var _actor: Node2D
var _inventory: Node
var _crafting: Node
var _workstation_tags: Array[StringName] = []
var _selected_recipe: Resource
var _recipe_buttons: Array[Button] = []
var _paused_by_ui := false

@onready var overlay: Control = %Overlay
@onready var context_label: Label = %ContextLabel
@onready var recipe_list: VBoxContainer = %RecipeList
@onready var recipe_name: Label = %RecipeName
@onready var description_label: Label = %Description
@onready var ingredients_label: Label = %Ingredients
@onready var requirement_label: Label = %Requirement
@onready var result_label: Label = %Result
@onready var time_label: Label = %CraftTime
@onready var status_label: Label = %Status
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var craft_button: Button = %CraftButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("crafting_ui")
	_apply_panel_style()
	overlay.visible = false
	%CloseButton.pressed.connect(close_crafting)
	craft_button.pressed.connect(_on_craft_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("crafting"):
		return
	if overlay.visible:
		close_crafting()
	elif get_node_or_null("/root/UIManager") == null or not get_node("/root/UIManager").has_open_modal():
		var player := get_tree().get_first_node_in_group("player") as Node2D
		open_crafting(player, [], "HAND CRAFTING")
	get_viewport().set_input_as_handled()


func open_crafting(actor: Node2D, workstation_tags: Array[StringName] = [], context := "HAND CRAFTING") -> void:
	if not is_instance_valid(actor):
		return
	_bind_actor(actor)
	_workstation_tags = workstation_tags.duplicate()
	context_label.text = context.to_upper()
	overlay.visible = true
	_rebuild_recipe_list()
	_pause_for_ui()
	var ui_manager := get_node_or_null("/root/UIManager")
	if ui_manager != null:
		ui_manager.register_modal(self, Callable(self, "close_crafting"))


func close_crafting() -> void:
	overlay.visible = false
	var ui_manager := get_node_or_null("/root/UIManager")
	if ui_manager != null:
		ui_manager.unregister_modal(self)
	if _paused_by_ui:
		get_tree().paused = false
		var game_state := get_node_or_null("/root/GameState")
		if game_state != null:
			game_state.set_paused(false)
		_paused_by_ui = false


func is_open() -> bool:
	return overlay.visible


func get_selected_recipe() -> Resource:
	return _selected_recipe


func _bind_actor(actor: Node2D) -> void:
	if _crafting != null:
		_disconnect_crafting_signals()
	if _inventory != null and _inventory.changed.is_connected(_refresh_recipe_states):
		_inventory.changed.disconnect(_refresh_recipe_states)
	_actor = actor
	_inventory = actor.get_node_or_null("Inventory")
	_crafting = actor.get_node_or_null("Crafting")
	if _crafting != null:
		_crafting.crafting_started.connect(_on_crafting_started)
		_crafting.crafting_progressed.connect(_on_crafting_progressed)
		_crafting.crafting_completed.connect(_on_crafting_completed)
		_crafting.crafting_failed.connect(_on_crafting_failed)
	if _inventory != null and not _inventory.changed.is_connected(_refresh_recipe_states):
		_inventory.changed.connect(_refresh_recipe_states)


func _disconnect_crafting_signals() -> void:
	var bindings := [
		[&"crafting_started", Callable(self, "_on_crafting_started")],
		[&"crafting_progressed", Callable(self, "_on_crafting_progressed")],
		[&"crafting_completed", Callable(self, "_on_crafting_completed")],
		[&"crafting_failed", Callable(self, "_on_crafting_failed")],
	]
	for binding in bindings:
		if _crafting.is_connected(binding[0], binding[1]):
			_crafting.disconnect(binding[0], binding[1])


func _rebuild_recipe_list() -> void:
	for child in recipe_list.get_children():
		child.queue_free()
	_recipe_buttons.clear()
	_selected_recipe = null
	var registry := get_node_or_null("/root/ContentRegistry")
	if registry == null:
		status_label.text = "Recipe catalog is unavailable."
		return
	var recipes: Array[Resource] = registry.get_recipes()
	for recipe in recipes:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 48)
		button.focus_mode = Control.FOCUS_NONE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.set_meta("recipe", recipe)
		button.pressed.connect(func() -> void: _select_recipe(recipe))
		recipe_list.add_child(button)
		_recipe_buttons.append(button)
	_refresh_recipe_states()
	if not recipes.is_empty():
		_select_recipe(recipes[0])


func _refresh_recipe_states() -> void:
	if _crafting == null:
		return
	for button in _recipe_buttons:
		var recipe: Resource = button.get_meta("recipe")
		var reason: String = _crafting.get_failure_reason(recipe, _workstation_tags)
		button.text = "%s   %s" % [recipe.display_name, "READY" if reason.is_empty() else "LOCKED"]
		button.modulate = Color.WHITE if reason.is_empty() else Color("#8b918e")
	_update_details()


func _select_recipe(recipe: Resource) -> void:
	_selected_recipe = recipe
	_update_details()


func _update_details() -> void:
	if _selected_recipe == null or _crafting == null:
		return
	recipe_name.text = _selected_recipe.display_name
	description_label.text = _selected_recipe.description
	var ingredient_lines := PackedStringArray()
	for ingredient in _selected_recipe.ingredients:
		var owned: int = _inventory.get_item_quantity(ingredient.item_definition.item_id) if _inventory != null else 0
		ingredient_lines.append("%d× %s   (%d owned)" % [ingredient.quantity, ingredient.item_definition.display_name, owned])
	ingredients_label.text = "INGREDIENTS\n%s" % "\n".join(ingredient_lines)
	var workstation_text := "None — hand craft" if _selected_recipe.required_workstation_tags.is_empty() else _format_tags(_selected_recipe.required_workstation_tags)
	requirement_label.text = "WORKSTATION  %s" % workstation_text
	result_label.text = "RESULT  %d× %s" % [_selected_recipe.output_quantity, _selected_recipe.output_item.display_name]
	time_label.text = "CRAFT TIME  %.2fs" % _selected_recipe.crafting_time_seconds
	var reason: String = _crafting.get_failure_reason(_selected_recipe, _workstation_tags)
	craft_button.disabled = not reason.is_empty()
	status_label.text = "Ready to craft." if reason.is_empty() else reason
	progress_bar.value = _crafting.get_progress_ratio() * 100.0


func _on_craft_pressed() -> void:
	if _selected_recipe != null:
		_crafting.start_crafting(_selected_recipe, _workstation_tags)


func _on_crafting_started(recipe: Resource) -> void:
	_refresh_recipe_states()
	status_label.text = "Crafting %s…" % recipe.display_name
	progress_bar.value = 0.0


func _on_crafting_progressed(_recipe: Resource, ratio: float) -> void:
	progress_bar.value = ratio * 100.0


func _on_crafting_completed(recipe: Resource) -> void:
	_refresh_recipe_states()
	status_label.text = "Crafted %d× %s." % [recipe.output_quantity, recipe.output_item.display_name]
	progress_bar.value = 100.0
	_show_notification("Crafted %s" % recipe.output_item.display_name)


func _on_crafting_failed(_recipe: Resource, reason: String) -> void:
	_refresh_recipe_states()
	status_label.text = reason


func _pause_for_ui() -> void:
	if not get_tree().paused:
		get_tree().paused = true
		var game_state := get_node_or_null("/root/GameState")
		if game_state != null:
			game_state.set_paused(true)
		_paused_by_ui = true


func _show_notification(message: String) -> void:
	var inventory_ui := get_tree().get_first_node_in_group("inventory_ui")
	if inventory_ui != null:
		inventory_ui.show_notification(message)


func _format_tags(tags: Array[StringName]) -> String:
	var names := PackedStringArray()
	for tag in tags:
		names.append(String(tag).replace("_", " ").capitalize())
	return ", ".join(names)


func _apply_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#202725")
	style.border_color = Color("#6b756f")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 10
	$Overlay/Panel.add_theme_stylebox_override("panel", style)
