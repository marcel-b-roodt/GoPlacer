@tool
class_name GoPlacerSettingsDrawer
extends GoPlacerDrawer

const _DRAWER_SCRIPT := preload(
	"res://addons/go_placer/core/go_placer_drawer.gd"
)

var _placement_controller: Node = null
var _normal_align_check: CheckBox = null
var _snap_angle_option: OptionButton = null
var _pos_snap_spin: SpinBox = null
var _target_parent_label: Label = null
var _clear_parent_btn: Button = null

var _aabb_snap_check: CheckBox = null
var _mesh_picking_check: CheckBox = null

func setup(placement_controller: Node) -> void:
	_placement_controller = placement_controller

func set_plugin(plugin: EditorPlugin) -> void:
	super.set_plugin(plugin)

func _ready() -> void:
	_setup_drawer("Settings", true)

	_normal_align_check = CheckBox.new()
	_normal_align_check.text = "Align to Normal"
	_normal_align_check.button_pressed = false
	_normal_align_check.tooltip_text = (
		"Orient instance up to match surface normal."
	)
	_normal_align_check.toggled.connect(_on_normal_align_toggled)
	_content.add_child(_normal_align_check)

	_aabb_snap_check = CheckBox.new()
	_aabb_snap_check.text = "AABB Snap"
	_aabb_snap_check.button_pressed = false
	_aabb_snap_check.tooltip_text = (
		"Offset placed instance so its AABB sits flush on the surface."
	)
	_aabb_snap_check.toggled.connect(_on_aabb_snap_toggled)
	_content.add_child(_aabb_snap_check)

	_mesh_picking_check = CheckBox.new()
	_mesh_picking_check.text = "Mesh Picking"
	_mesh_picking_check.button_pressed = true
	_mesh_picking_check.tooltip_text = (
		"Raycast against mesh faces when no physics collider is found."
		+ " Disable for better performance in large scenes."
	)
	_mesh_picking_check.toggled.connect(_on_mesh_picking_toggled)
	_content.add_child(_mesh_picking_check)

	var snap_row := HBoxContainer.new()
	_content.add_child(snap_row)

	var snap_label := Label.new()
	snap_label.text = "Rotation Snap"
	snap_label.add_theme_font_size_override("font_size", 11)
	snap_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	snap_row.add_child(snap_label)

	_snap_angle_option = OptionButton.new()
	_snap_angle_option.add_theme_font_size_override("font_size", 11)
	_populate_snap_angle_options()
	_snap_angle_option.item_selected.connect(_on_snap_angle_selected)
	snap_row.add_child(_snap_angle_option)

	var pos_snap_row := HBoxContainer.new()
	_content.add_child(pos_snap_row)

	var pos_snap_label := Label.new()
	pos_snap_label.text = "Pos Snap (Ctrl)"
	pos_snap_label.add_theme_font_size_override("font_size", 11)
	pos_snap_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pos_snap_row.add_child(pos_snap_label)

	_pos_snap_spin = SpinBox.new()
	_pos_snap_spin.min_value = 0.0
	_pos_snap_spin.max_value = 100.0
	_pos_snap_spin.step = 0.25
	_pos_snap_spin.value = 1.0
	_pos_snap_spin.suffix = "m"
	_pos_snap_spin.tooltip_text = (
		"Position snap grid size when holding Ctrl."
	)
	_pos_snap_spin.value_changed.connect(_on_pos_snap_changed)
	pos_snap_row.add_child(_pos_snap_spin)

	var parent_row := HBoxContainer.new()
	_content.add_child(parent_row)

	var parent_label := Label.new()
	parent_label.text = "Parent"
	parent_label.add_theme_font_size_override("font_size", 11)
	parent_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent_row.add_child(parent_label)

	_target_parent_label = Label.new()
	_target_parent_label.text = "Scene Root"
	_target_parent_label.add_theme_font_size_override("font_size", 11)
	_target_parent_label.add_theme_color_override(
		"font_color", Color(0.6, 0.8, 1.0)
	)
	_target_parent_label.tooltip_text = (
		"Target parent for placed instances. "
		+ "Click a Node3D in the Scene tree to auto-set."
	)
	_target_parent_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_target_parent_label.clip_text = true
	parent_row.add_child(_target_parent_label)

	_clear_parent_btn = Button.new()
	_clear_parent_btn.text = "X"
	_clear_parent_btn.add_theme_font_size_override("font_size", 10)
	_clear_parent_btn.tooltip_text = "Reset to scene root or GoPlacerParent."
	_clear_parent_btn.pressed.connect(_on_clear_parent)
	parent_row.add_child(_clear_parent_btn)

func update_target_parent_display(node: Node) -> void:
	if _target_parent_label == null:
		return
	if node == null:
		_target_parent_label.text = "Scene Root"
		return
	var scene_root: Node = null
	if _plugin != null:
		scene_root = _plugin.get_editor_interface().get_edited_scene_root()
	if node == scene_root:
		_target_parent_label.text = "Scene Root"
	else:
		_target_parent_label.text = str(node.name)

func _populate_snap_angle_options() -> void:
	_snap_angle_option.clear()
	_snap_angle_option.add_item("Free", 0)
	_snap_angle_option.set_item_metadata(0, 0.0)
	_snap_angle_option.add_item("15\u00b0", 1)
	_snap_angle_option.set_item_metadata(1, 15.0)
	_snap_angle_option.add_item("30\u00b0", 2)
	_snap_angle_option.set_item_metadata(2, 30.0)
	_snap_angle_option.add_item("45\u00b0", 3)
	_snap_angle_option.set_item_metadata(3, 45.0)
	_snap_angle_option.add_item("90\u00b0", 4)
	_snap_angle_option.set_item_metadata(4, 90.0)
	_snap_angle_option.select(1)

func _on_normal_align_toggled(enabled: bool) -> void:
	if _placement_controller != null:
		_placement_controller.set_normal_align(enabled)

func _on_aabb_snap_toggled(enabled: bool) -> void:
	if _placement_controller != null:
		_placement_controller.set_aabb_snap(enabled)

func _on_mesh_picking_toggled(enabled: bool) -> void:
	if _placement_controller != null:
		_placement_controller.set_mesh_picking(enabled)

func _on_snap_angle_selected(index: int) -> void:
	var step: float = float(_snap_angle_option.get_item_metadata(index))
	if _placement_controller != null:
		_placement_controller.set_snap_angle_step(step)

func _on_pos_snap_changed(value: float) -> void:
	if _placement_controller != null:
		_placement_controller.set_position_snap_size(value)

func _on_clear_parent() -> void:
	if _placement_controller != null:
		_placement_controller.set_target_parent(null)
	update_target_parent_display(null)
