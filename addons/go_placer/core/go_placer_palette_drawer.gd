@tool
class_name GoPlacerPaletteDrawer
extends GoPlacerDrawer

signal entry_selected(entry: Resource)
signal entry_deselected()

const _DRAWER_SCRIPT := preload(
	"res://addons/go_placer/core/go_placer_drawer.gd"
)
const _PALETTE_SCRIPT := preload(
	"res://addons/go_placer/palette/go_placer_palette.gd"
)
const _ENTRY_SCRIPT := preload(
	"res://addons/go_placer/palette/go_placer_palette_entry.gd"
)
const _ITEM_LIST_SCRIPT := preload(
	"res://addons/go_placer/core/go_placer_item_list.gd"
)
const THUMB_SIZE := 64
const TILE_SIZE := 80
const DISCOVER_COOLDOWN_MS := 1000

var _placement_controller: Node = null
var _palettes: Array[GoPlacerPalette] = []
var _active_palette_index: int = -1
var _active_entry_index: int = -1
var _palette_option: OptionButton = null
var _new_pal_btn: Button = null
var _delete_pal_btn: Button = null
var _edit_pal_btn: Button = null
var _add_entry_btn: Button = null
var _remove_entry_btn: Button = null
var _entry_grid: GoPlacerItemList = null
var _discover_timer: SceneTreeTimer = null

func setup(placement_controller: Node) -> void:
	_placement_controller = placement_controller

func set_plugin(plugin: EditorPlugin) -> void:
	super.set_plugin(plugin)

func _ready() -> void:
	_setup_drawer("Palettes", true)

	var pal_row := HBoxContainer.new()
	_content.add_child(pal_row)

	_palette_option = OptionButton.new()
	_palette_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_palette_option.add_theme_font_size_override("font_size", 11)
	_palette_option.tooltip_text = "Select a palette of assets."
	_palette_option.item_selected.connect(_on_palette_selected)
	pal_row.add_child(_palette_option)

	_new_pal_btn = Button.new()
	_new_pal_btn.text = "+ New"
	_new_pal_btn.add_theme_font_size_override("font_size", 11)
	_new_pal_btn.tooltip_text = "Create a new empty palette."
	_new_pal_btn.pressed.connect(_on_new_palette)
	pal_row.add_child(_new_pal_btn)

	_edit_pal_btn = Button.new()
	_edit_pal_btn.text = "Edit"
	_edit_pal_btn.add_theme_font_size_override("font_size", 11)
	_edit_pal_btn.tooltip_text = "Open the selected palette in the Inspector."
	_edit_pal_btn.pressed.connect(_on_edit_palette)
	pal_row.add_child(_edit_pal_btn)

	_delete_pal_btn = Button.new()
	_delete_pal_btn.text = "Del"
	_delete_pal_btn.add_theme_font_size_override("font_size", 11)
	_delete_pal_btn.tooltip_text = "Delete the selected palette."
	_delete_pal_btn.pressed.connect(_on_delete_palette)
	pal_row.add_child(_delete_pal_btn)

	var entry_row := HBoxContainer.new()
	_content.add_child(entry_row)

	var entry_label := Label.new()
	entry_label.text = "Assets"
	entry_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry_label.add_theme_font_size_override("font_size", 11)
	entry_row.add_child(entry_label)

	_add_entry_btn = Button.new()
	_add_entry_btn.text = "+"
	_add_entry_btn.add_theme_font_size_override("font_size", 11)
	_add_entry_btn.tooltip_text = "Add an asset to the palette."
	_add_entry_btn.pressed.connect(_on_add_entry)
	entry_row.add_child(_add_entry_btn)

	_remove_entry_btn = Button.new()
	_remove_entry_btn.text = "\u2212"
	_remove_entry_btn.add_theme_font_size_override("font_size", 11)
	_remove_entry_btn.tooltip_text = "Remove the selected asset from the palette."
	_remove_entry_btn.pressed.connect(_on_remove_entry)
	entry_row.add_child(_remove_entry_btn)

	_entry_grid = _ITEM_LIST_SCRIPT.new()
	_entry_grid.custom_minimum_size = Vector2(0, 160)
	_entry_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_entry_grid.fixed_icon_size = Vector2i(THUMB_SIZE, THUMB_SIZE)
	_entry_grid.fixed_column_width = TILE_SIZE
	_entry_grid.icon_mode = ItemList.ICON_MODE_TOP
	_entry_grid.max_columns = 0
	_entry_grid.max_text_lines = 1
	_entry_grid.add_theme_stylebox_override(
		"panel", _make_panel_style()
	)
	_entry_grid.item_selected.connect(_on_entry_selected)
	_entry_grid.item_deselected.connect(_on_entry_deselected)
	_entry_grid.drop_received.connect(_on_drop_received)
	_content.add_child(_entry_grid)

	if Engine.is_editor_hint():
		var fs := EditorInterface.get_resource_filesystem()
		if not fs.filesystem_changed.is_connected(_on_filesystem_changed):
			fs.filesystem_changed.connect(_on_filesystem_changed)
	_discover_palettes()
	_rebuild_palette_dropdown()

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		var fs := EditorInterface.get_resource_filesystem()
		if fs.filesystem_changed.is_connected(_on_filesystem_changed):
			fs.filesystem_changed.disconnect(_on_filesystem_changed)

func get_active_entry() -> GoPlacerPaletteEntry:
	if _active_palette_index < 0 or _active_palette_index >= _palettes.size():
		return null
	var palette: GoPlacerPalette = _palettes[_active_palette_index]
	if _active_entry_index < 0 or _active_entry_index >= palette.entries.size():
		return null
	return palette.entries[_active_entry_index]

func _make_panel_style() -> StyleBox:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.4)
	style.border_color = Color(0.25, 0.25, 0.25)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.content_margin_left = 4
	style.content_margin_right = 4
	return style

func _on_filesystem_changed() -> void:
	if _discover_timer != null and _discover_timer.time_left > 0.0:
		return
	_discover_timer = get_tree().create_timer(DISCOVER_COOLDOWN_MS / 1000.0)
	_discover_timer.timeout.connect(_rebuild_palette_dropdown)

func _discover_palettes() -> void:
	_palettes.clear()
	if not Engine.is_editor_hint():
		return
	_discover_palettes_in_dir("res://palettes/")
	_discover_palettes_in_dir("res://")

func _discover_palettes_in_dir(dir_path: String) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	var da := DirAccess.open(dir_path)
	if da == null:
		return
	da.list_dir_begin()
	var file_name := da.get_next()
	while file_name != "":
		var full_path: String = dir_path.path_join(file_name)
		if da.current_is_dir():
			_discover_palettes_in_dir(full_path)
		elif file_name.get_extension() == "tres":
			if not ResourceLoader.exists(full_path, "GoPlacerPalette"):
				file_name = da.get_next()
				continue
			var res: Resource = ResourceLoader.load(
				full_path, "GoPlacerPalette", ResourceLoader.CACHE_MODE_REUSE
			)
			if res is GoPlacerPalette:
				_palettes.append(res as GoPlacerPalette)
		file_name = da.get_next()
	da.list_dir_end()

func _rebuild_palette_dropdown() -> void:
	if _palette_option == null:
		return
	var prev_selected: int = _palette_option.selected
	_palette_option.clear()
	for i: int in _palettes.size():
		var pal: GoPlacerPalette = _palettes[i]
		var display: String = pal.palette_name
		if display == "":
			display = pal.resource_path.get_file()
		_palette_option.add_item(display)
	if prev_selected >= 0 and prev_selected < _palettes.size():
		_palette_option.select(prev_selected)
		_on_palette_selected(prev_selected)
	elif not _palettes.is_empty():
		_palette_option.select(0)
		_on_palette_selected(0)
	else:
		_active_palette_index = -1
		_refresh_entry_grid()

func _refresh_entry_grid() -> void:
	if _entry_grid == null:
		return
	_entry_grid.clear()
	if _active_palette_index < 0 or _active_palette_index >= _palettes.size():
		return
	var palette: GoPlacerPalette = _palettes[_active_palette_index]
	for entry: GoPlacerPaletteEntry in palette.entries:
		var name: String = _get_entry_display_name(entry)
		var icon: Texture2D = _get_entry_icon(entry)
		if icon != null:
			_entry_grid.add_item(name, icon)
		else:
			_entry_grid.add_item(name)
		if entry.asset != null:
			_request_preview(
				entry, _entry_grid.item_count - 1
			)

func _request_preview(entry: GoPlacerPaletteEntry, index: int) -> void:
	if not Engine.is_editor_hint():
		return
	if entry.asset == null:
		return
	var previewer: EditorResourcePreview = (
		EditorInterface.get_resource_previewer()
	)
	if entry.asset.resource_path != "":
		previewer.queue_resource_preview(
			entry.asset.resource_path, self, "_on_preview_ready", index
		)
	else:
		previewer.queue_edited_resource_preview(
			entry.asset, self, "_on_preview_ready", index
		)

func _on_preview_ready(
	_path: String,
	preview: Texture2D,
	thumbnail: Texture2D,
	userdata: Variant,
) -> void:
	if _entry_grid == null:
		return
	var index: int = int(userdata)
	if index < 0 or index >= _entry_grid.item_count:
		return
	var icon: Texture2D = preview if preview != null else thumbnail
	if icon != null:
		_entry_grid.set_item_icon(index, icon)

func _get_entry_display_name(entry: GoPlacerPaletteEntry) -> String:
	if entry.display_name != "":
		return entry.display_name
	if entry.asset == null:
		return "Unnamed"
	var name: String = entry.asset.resource_name
	if name != "":
		return name
	if entry.asset.resource_path != "":
		return entry.asset.resource_path.get_file().get_basename()
	return "Unnamed"

func _get_entry_icon(entry: GoPlacerPaletteEntry) -> Texture2D:
	if not Engine.is_editor_hint():
		return null
	if entry.asset == null:
		return EditorInterface.get_editor_theme().get_icon(
			"FileBroken", "EditorIcons"
		)
	if entry.asset is PackedScene:
		return EditorInterface.get_editor_theme().get_icon(
			"PackedScene", "EditorIcons"
		)
	if entry.asset is Mesh:
		return EditorInterface.get_editor_theme().get_icon(
			"Mesh", "EditorIcons"
		)
	return EditorInterface.get_editor_theme().get_icon(
		"File", "EditorIcons"
	)

func _on_palette_selected(index: int) -> void:
	_active_palette_index = index
	_active_entry_index = -1
	_refresh_entry_grid()

func _on_entry_selected(index: int) -> void:
	_active_entry_index = index
	var entry: GoPlacerPaletteEntry = get_active_entry()
	if entry != null:
		entry_selected.emit(entry)

func _on_entry_deselected() -> void:
	_active_entry_index = -1
	entry_deselected.emit()

func deselect_entry() -> void:
	_active_entry_index = -1
	if _entry_grid != null:
		_entry_grid.deselect_all()

func _on_new_palette() -> void:
	if not Engine.is_editor_hint():
		return
	_show_name_dialog_async("New Palette", "Palette", _create_palette_with_name)

func _create_palette_with_name(name_input: String) -> void:
	var pal: GoPlacerPalette = _PALETTE_SCRIPT.new()
	pal.palette_name = name_input
	var safe_name: String = name_input.to_snake_case()
	if safe_name.is_empty():
		safe_name = "palette"
	DirAccess.make_dir_recursive_absolute("res://palettes/")
	var save_path := "res://palettes/%s.tres" % safe_name
	if ResourceLoader.exists(save_path):
		var idx := 1
		while ResourceLoader.exists(
			"res://palettes/%s_%d.tres" % [safe_name, idx]
		):
			idx += 1
		save_path = "res://palettes/%s_%d.tres" % [safe_name, idx]
	pal.resource_path = save_path
	ResourceSaver.save(pal, save_path)
	EditorInterface.get_resource_filesystem().update_file(save_path)
	_discover_palettes()
	_rebuild_palette_dropdown()
	for i: int in _palettes.size():
		if _palettes[i].resource_path == save_path:
			_palette_option.select(i)
			_on_palette_selected(i)
			break

func _on_edit_palette() -> void:
	if not Engine.is_editor_hint():
		return
	if _active_palette_index < 0 or _active_palette_index >= _palettes.size():
		return
	EditorInterface.edit_resource(_palettes[_active_palette_index])

func _on_delete_palette() -> void:
	if _active_palette_index < 0 or _active_palette_index >= _palettes.size():
		return
	var pal: GoPlacerPalette = _palettes[_active_palette_index]
	var path: String = pal.resource_path
	if path == "":
		_palettes.remove_at(_active_palette_index)
		_active_palette_index = -1
		_rebuild_palette_dropdown()
		return
	var delete_fn := func() -> void:
		DirAccess.remove_absolute(path)
		EditorInterface.get_resource_filesystem().update_file(path)
		_discover_palettes()
		_rebuild_palette_dropdown()
	_show_confirm_dialog_async(
		"Delete palette '%s'?" % pal.palette_name,
		"Removes the .tres file. Placed assets are unaffected.",
		delete_fn,
	)

func _on_add_entry() -> void:
	if _active_palette_index < 0 or _active_palette_index >= _palettes.size():
		return
	if not Engine.is_editor_hint():
		return
	var file_dialog := FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.filters = PackedStringArray([
		"*.tscn ; Scenes", "*.glb ; GLTF", "*.obj ; OBJ",
		"*.mesh ; Mesh",
	])
	file_dialog.file_selected.connect(_on_asset_file_selected)
	EditorInterface.get_base_control().add_child(file_dialog)
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_asset_file_selected(path: String) -> void:
	if _active_palette_index < 0 or _active_palette_index >= _palettes.size():
		return
	var resource: Resource = load(path)
	if resource == null:
		return
	_palettes[_active_palette_index].add_entry(resource)
	var pal: GoPlacerPalette = _palettes[_active_palette_index]
	if pal.resource_path != "":
		ResourceSaver.save(pal, pal.resource_path)
	_refresh_entry_grid()

func _on_remove_entry() -> void:
	if _active_palette_index < 0 or _active_palette_index >= _palettes.size():
		return
	if _active_entry_index < 0:
		return
	_palettes[_active_palette_index].remove_entry(_active_entry_index)
	_active_entry_index = -1
	var pal: GoPlacerPalette = _palettes[_active_palette_index]
	if pal.resource_path != "":
		ResourceSaver.save(pal, pal.resource_path)
	_refresh_entry_grid()

func _on_drop_received(data: Variant) -> void:
	if not data is Dictionary:
		return
	var dict: Dictionary = data
	if _active_palette_index < 0 or _active_palette_index >= _palettes.size():
		return
	if not dict.has("files"):
		return
	var files: PackedStringArray = dict.files
	for path in files:
		var resource: Resource = load(path)
		if resource == null:
			continue
		if resource is PackedScene or resource is Mesh:
			_palettes[_active_palette_index].add_entry(resource)
	var pal: GoPlacerPalette = _palettes[_active_palette_index]
	if pal.resource_path != "":
		ResourceSaver.save(pal, pal.resource_path)
	_refresh_entry_grid()

func _show_name_dialog_async(
	title: String, default_text: String, on_confirmed: Callable
) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = title
	dialog.ok_button_text = "Create"

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size.x = 300
	dialog.add_child(vbox)

	var line_edit := LineEdit.new()
	line_edit.text = default_text
	line_edit.select_all()
	line_edit.placeholder_text = "Palette name"
	vbox.add_child(line_edit)

	var path_lbl := Label.new()
	path_lbl.add_theme_font_size_override("font_size", 10)
	path_lbl.add_theme_color_override(
		"font_color", Color(0.5, 0.5, 0.5)
	)
	vbox.add_child(path_lbl)

	var update_path := func(text: String) -> void:
		var safe := text.to_snake_case()
		if safe.is_empty():
			safe = "palette"
		path_lbl.text = "res://palettes/%s.tres" % safe
	update_path.call(default_text)

	line_edit.text_changed.connect(update_path)

	EditorInterface.popup_dialog_centered(dialog)
	line_edit.grab_focus.call_deferred()
	line_edit.select_all.call_deferred()

	var on_confirm_fn := func() -> void:
		var name: String = line_edit.text.strip_edges()
		dialog.queue_free()
		if not name.is_empty():
			on_confirmed.call(name)
	var on_cancel_fn := func() -> void:
		dialog.queue_free()
	dialog.confirmed.connect(on_confirm_fn)
	dialog.canceled.connect(on_cancel_fn)

func _show_confirm_dialog_async(
	title: String, message: String, on_confirmed: Callable
) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	dialog.ok_button_text = "Delete"
	dialog.cancel_button_text = "Cancel"
	EditorInterface.popup_dialog_centered(dialog)
	var on_confirm_fn := func() -> void:
		dialog.queue_free()
		on_confirmed.call()
	var on_cancel_fn := func() -> void:
		dialog.queue_free()
	dialog.confirmed.connect(on_confirm_fn)
	dialog.canceled.connect(on_cancel_fn)
