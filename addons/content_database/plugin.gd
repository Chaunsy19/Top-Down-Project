@tool
extends EditorPlugin
const Store = preload("res://addons/content_database/content_store.gd")
var dock: VBoxContainer
var kind: OptionButton
var search: LineEdit
var list: ItemList
var status: RichTextLabel
var selected: Resource
var create_dialog: ConfirmationDialog
var id_input: LineEdit
var remove_dialog: ConfirmationDialog
var copying := false
var selected_id := ""

func _enter_tree() -> void:
	dock = VBoxContainer.new()
	dock.name = "Content Database"
	dock.custom_minimum_size = Vector2(280, 300)
	kind = OptionButton.new()
	for type in Store.TYPES:
		kind.add_item(type[0])
	dock.add_child(kind)
	kind.item_selected.connect(func(_i): selected = null; refresh())
	search = LineEdit.new()
	search.placeholder_text = "Search ID, name, category or tags"
	dock.add_child(search)
	search.text_changed.connect(func(_text): refresh())
	var row := HBoxContainer.new()
	dock.add_child(row)
	button(row, "New", func(): show_create(false))
	button(row, "Duplicate", func(): show_create(true))
	button(row, "Remove", request_remove)
	list = ItemList.new()
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.custom_minimum_size.y = 200
	dock.add_child(list)
	list.item_selected.connect(select_record)
	var actions := HBoxContainer.new()
	dock.add_child(actions)
	button(actions, "Save", save_record)
	button(actions, "Refresh", refresh)
	button(actions, "Rebuild catalog", rebuild)
	status = RichTextLabel.new()
	status.custom_minimum_size.y = 110
	status.selection_enabled = true
	dock.add_child(status)
	create_dialog = ConfirmationDialog.new()
	create_dialog.title = "Create content record"
	id_input = LineEdit.new()
	id_input.placeholder_text = "Unique ID, e.g. iron_axe"
	id_input.custom_minimum_size = Vector2(330, 40)
	create_dialog.add_child(id_input)
	dock.add_child(create_dialog)
	create_dialog.confirmed.connect(create_record)
	remove_dialog = ConfirmationDialog.new()
	dock.add_child(remove_dialog)
	remove_dialog.confirmed.connect(remove_record)
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)
	refresh()

func _exit_tree() -> void:
	remove_control_from_docks(dock)
	dock.queue_free()

func button(parent: Control, text: String, callback: Callable) -> void:
	var control := Button.new()
	control.text = text
	control.pressed.connect(callback)
	parent.add_child(control)

func refresh() -> void:
	list.clear()
	for entry in Store.records(kind.selected):
		var id := String(entry.get(Store.TYPES[kind.selected][5]))
		var label := "%s  ·  %s" % [entry.get("display_name"), id]
		var haystack := label
		for property in ["categories", "resource_tags", "workstation_tags"]:
			var value: Variant = entry.get(property)
			if value != null:
				haystack += " " + str(value)
		if not search.text.is_empty() and not search.text.to_lower() in haystack.to_lower():
			continue
		list.add_item(label)
		list.set_item_metadata(list.item_count - 1, entry)
		if entry == selected:
			list.select(list.item_count - 1)
	status.text = "%d records. Select a record to edit in the Inspector. Save validates and rebuilds this catalog. IDs are permanent reference keys; duplicate to create a new identity." % list.item_count

func select_record(index: int) -> void:
	selected = list.get_item_metadata(index)
	selected_id = String(selected.get(Store.TYPES[kind.selected][5]))
	get_editor_interface().edit_resource(selected)
	status.text = selected.resource_path + "\nEdit properties in the Inspector, then Save here. External resource links remain shared when duplicated."

func show_create(duplicate_selected: bool) -> void:
	if duplicate_selected and selected == null:
		status.text = "Select a record to duplicate."
		return
	copying = duplicate_selected
	id_input.text = String(selected.get(Store.TYPES[kind.selected][5])) + "_copy" if copying else ""
	create_dialog.popup_centered(Vector2i(380, 120))
	id_input.grab_focus()

func create_record() -> void:
	var error := Store.create_record(kind.selected, id_input.text.strip_edges(), selected if copying else null)
	if not error.is_empty():
		status.text = error
		return
	var path := "res://data/%s/%s.tres" % [Store.TYPES[kind.selected][1], id_input.text.strip_edges()]
	selected = load(path)
	selected_id = id_input.text.strip_edges()
	get_editor_interface().get_resource_filesystem().scan()
	refresh()
	get_editor_interface().edit_resource(selected)
	var catalog_error := Store.rebuild(kind.selected)
	status.text = "Created " + path + ("\nFill required fields, then Save:\n" + catalog_error if not catalog_error.is_empty() else "\nCatalog updated.")

func save_record() -> void:
	if selected == null:
		status.text = "Select a record first."
		return
	if String(selected.get(Store.TYPES[kind.selected][5])) != selected_id:
		status.text = "IDs are reference keys. Restore '%s'; use Duplicate for a new ID." % selected_id
		return
	var errors := Store.validate_records(kind.selected, [selected])
	if not errors.is_empty():
		status.text = "\n".join(errors)
		return
	var error := ResourceSaver.save(selected, selected.resource_path)
	if error != OK:
		status.text = error_string(error)
		return
	rebuild()

func rebuild() -> void:
	var error := Store.rebuild(kind.selected)
	refresh()
	status.text = "Catalog updated." if error.is_empty() else error
	get_editor_interface().get_resource_filesystem().scan()

func request_remove() -> void:
	if selected == null:
		return
	var refs := Store.references_to(kind.selected, selected)
	if not refs.is_empty():
		status.text = "Cannot remove; referenced by:\n" + "\n".join(refs)
		return
	remove_dialog.dialog_text = "Move %s to the Recycle Bin and remove it from the catalog?" % selected.resource_path
	remove_dialog.popup_centered(Vector2i(420, 150))

func remove_record() -> void:
	if selected == null or not Store.references_to(kind.selected, selected).is_empty():
		status.text = "References changed. Check removal again."
		return
	var path := selected.resource_path
	var remaining := Store.records(kind.selected)
	remaining.erase(selected)
	var errors := Store.validate_records(kind.selected, remaining)
	if not errors.is_empty():
		status.text = "Fix catalog errors before removal:\n" + "\n".join(errors)
		return
	var error := OS.move_to_trash(ProjectSettings.globalize_path(path))
	if error != OK:
		status.text = "Could not move file to Recycle Bin: " + error_string(error)
		return
	selected = null
	get_editor_interface().edit_resource(null)
	rebuild()
