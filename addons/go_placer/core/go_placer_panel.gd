@tool
class_name GoPlacerPanel
extends VBoxContainer

signal entry_activated(entry: Resource)

const _PALETTE_DRAWER_SCRIPT := preload(
	"res://addons/go_placer/core/go_placer_palette_drawer.gd"
)
const _SETTINGS_DRAWER_SCRIPT := preload(
	"res://addons/go_placer/core/go_placer_settings_drawer.gd"
)
const _ENTRY_SCRIPT := preload(
	"res://addons/go_placer/palette/go_placer_palette_entry.gd"
)

var _placement_controller: Node = null
var _palette_drawer: GoPlacerPaletteDrawer = null
var _settings_drawer: GoPlacerSettingsDrawer = null
var _plugin: EditorPlugin = null
var _built: bool = false

func setup(placement_controller: Node, plugin: EditorPlugin) -> void:
	_placement_controller = placement_controller
	_plugin = plugin
	_build_ui()

func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin
	_build_ui()
	if _palette_drawer != null:
		_palette_drawer.set_plugin(plugin)
	if _settings_drawer != null:
		_settings_drawer.set_plugin(plugin)

func _build_ui() -> void:
	if _built:
		return
	_built = true
	custom_minimum_size = Vector2(220, 0)

	_palette_drawer = _PALETTE_DRAWER_SCRIPT.new()
	_palette_drawer.setup(_placement_controller)
	_palette_drawer.set_open(true)
	if _plugin != null:
		_palette_drawer.set_plugin(_plugin)
	_palette_drawer.entry_selected.connect(_on_entry_selected)
	_palette_drawer.entry_deselected.connect(_on_entry_deselected)
	add_child(_palette_drawer)

	_settings_drawer = _SETTINGS_DRAWER_SCRIPT.new()
	_settings_drawer.setup(_placement_controller)
	_settings_drawer.set_open(true)
	if _plugin != null:
		_settings_drawer.set_plugin(_plugin)
	add_child(_settings_drawer)

func get_active_entry() -> GoPlacerPaletteEntry:
	if _palette_drawer == null:
		return null
	return _palette_drawer.get_active_entry()

func _on_entry_selected(entry: GoPlacerPaletteEntry) -> void:
	if entry == null or entry.asset == null:
		return
	if _plugin != null:
		_plugin.start_placing()
	entry_activated.emit(entry)

func _on_entry_deselected() -> void:
	if _plugin != null:
		_plugin.stop_placing()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if _plugin != null and not visible:
			_plugin.stop_placing()

func on_editor_selection_changed() -> void:
	if _plugin == null:
		return
	var selected: Array[Node] = (
		_plugin.get_editor_interface().get_selection().get_selected_nodes()
	)
	if selected.size() > 0:
		var node: Node = selected[0]
		if node is Node3D:
			if _placement_controller != null:
				_placement_controller.set_target_parent(node)
			if _settings_drawer != null:
				_settings_drawer.update_target_parent_display(node)

func deselect_entry() -> void:
	if _palette_drawer != null:
		_palette_drawer.deselect_entry()
