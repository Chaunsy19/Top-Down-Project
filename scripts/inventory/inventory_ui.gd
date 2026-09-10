extends CanvasLayer

const InventoryComponentScript = preload("res://scripts/inventory/inventory_component.gd")
const WorldItemDropScene = preload("res://scenes/world/world_item_drop.tscn")
const InventoryPanelScript = preload("res://scripts/inventory/inventory_panel.gd")

var _player: Node2D
var _player_inventory: InventoryComponentScript
var _container_inventory: InventoryComponentScript

@onready var overlay: Control = %Overlay
@onready var player_panel: InventoryPanelScript = %PlayerPanel
@onready var container_panel: InventoryPanelScript = %ContainerPanel
@onready var notification_label: Label = %NotificationLabel
@onready var notification_timer: Timer = %NotificationTimer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("inventory_ui")
	overlay.visible = false
	notification_label.visible = false
	player_panel.close_requested.connect(close_player_panel)
	container_panel.close_requested.connect(close_container_panel)
	player_panel.drop_requested.connect(drop_player_stack)
	player_panel.consume_requested.connect(consume_player_stack)
	notification_timer.timeout.connect(func() -> void: notification_label.visible = false)
	call_deferred("_find_player")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if overlay.visible:
			close_inventory()
		elif get_node_or_null("/root/UIManager") != null and get_node("/root/UIManager").has_open_modal():
			return
		else:
			open_player_inventory()
		get_viewport().set_input_as_handled()
		return


func open_player_inventory() -> void:
	_find_player()
	if _player_inventory == null:
		return
	container_panel.visible = false
	player_panel.visible = true
	player_panel.set_panel_title("INVENTORY")
	player_panel.bind_inventory(_player_inventory)
	overlay.visible = true
	_register_modal()


func open_container(
	_container: Node2D,
	actor: Node2D,
	actor_inventory: InventoryComponentScript,
	container_inventory: InventoryComponentScript
) -> void:
	_player = actor
	_player_inventory = actor_inventory
	_container_inventory = container_inventory
	var title := String(_container.get("container_title"))
	if title.is_empty():
		title = "CONTAINER"
	container_panel.set_panel_title(String(title).to_upper())
	container_panel.bind_inventory(container_inventory, actor_inventory)
	container_panel.visible = true
	player_panel.visible = true
	player_panel.set_panel_title("INVENTORY")
	player_panel.bind_inventory(actor_inventory, container_inventory)
	overlay.visible = true
	_register_modal()


func close_inventory() -> void:
	overlay.visible = false
	player_panel.visible = false
	container_panel.visible = false
	var ui_manager := get_node_or_null("/root/UIManager")
	if ui_manager:
		ui_manager.unregister_modal(self)


func close_player_panel() -> void:
	player_panel.visible = false
	if container_panel.visible:
		container_panel.bind_inventory(_container_inventory)
	else:
		close_inventory()


func close_container_panel() -> void:
	container_panel.visible = false
	if player_panel.visible:
		player_panel.bind_inventory(_player_inventory)
	else:
		close_inventory()


func is_open() -> bool:
	return overlay.visible


func drop_player_stack(slot_index: int) -> bool:
	if _player_inventory == null or not is_instance_valid(_player):
		return false
	var stack := _player_inventory.get_slot(slot_index)
	if stack == null:
		return false
	var removed: Resource = _player_inventory.remove_from_slot(slot_index, stack.quantity)
	var drop = WorldItemDropScene.instantiate()
	drop.configure_stack(removed)
	_player.get_parent().add_child(drop)
	drop.global_position = _player.global_position + Vector2(0.0, 34.0)
	show_notification("Dropped %d× %s" % [removed.quantity, removed.item_definition.display_name])
	return true


func show_notification(message: String) -> void:
	notification_label.text = message
	notification_label.visible = true
	notification_timer.start()


func consume_player_stack(slot_index: int) -> bool:
	if _player_inventory == null or not is_instance_valid(_player):
		return false
	var stack: Resource = _player_inventory.get_slot(slot_index)
	if stack == null:
		return false
	var item_name: String = stack.item_definition.display_name
	var needs := _player.get_node_or_null("Needs")
	var succeeded: bool = needs != null and needs.consume_item(_player_inventory, slot_index)
	show_notification("Ate %s" % item_name if succeeded else "That item cannot be eaten")
	return succeeded


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node2D
	_player_inventory = _player.get_node_or_null("Inventory") as InventoryComponentScript if _player else null


func _register_modal() -> void:
	var ui_manager := get_node_or_null("/root/UIManager")
	if ui_manager:
		ui_manager.register_modal(self, Callable(self, "close_inventory"))
