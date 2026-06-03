@tool
extends EditorPlugin

enum PlacingState { IDLE, PREVIEWING, DRAG_ROTATE }

# Self-preloads — Godot processes scripts alphabetically; references to
# class_names must be preloaded to avoid startup-scan compile errors.
const RAY_LENGTH := 4000.0
const PIXELS_PER_RADIAN := 0.005
const _PANEL_SCRIPT := preload(
	"res://addons/go_placer/core/go_placer_panel.gd"
)
const _CONTROLLER_SCRIPT := preload(
	"res://addons/go_placer/placement/placement_controller.gd"
)
const _GHOST_MANAGER_SCRIPT := preload(
	"res://addons/go_placer/placement/ghost_manager.gd"
)
const _GIZMO_SCRIPT := preload(
	"res://addons/go_placer/placement/placement_gizmo.gd"
)
const _INSTANCE_FACTORY_SCRIPT := preload(
	"res://addons/go_placer/placement/instance_factory.gd"
)
const _SNAP_HELPER_SCRIPT := preload(
	"res://addons/go_placer/placement/snap_helper.gd"
)
const _ENTRY_SCRIPT := preload(
	"res://addons/go_placer/palette/go_placer_palette_entry.gd"
)

var _ghost_manager: GhostManager = _GHOST_MANAGER_SCRIPT.new()
var _gizmo: PlacementGizmo = _GIZMO_SCRIPT.new()
var _placement_controller: PlacementController = null
var _panel: GoPlacerPanel = null
var _state: int = PlacingState.IDLE
var _ghost_hit_position: Vector3 = Vector3.ZERO
var _ghost_hit_normal: Vector3 = Vector3.UP
var _drag_start_x: float = 0.0
var _drag_rotation_y: float = 0.0
var _has_valid_hit: bool = false
var _current_entry: GoPlacerPaletteEntry = null

func _enter_tree() -> void:
	_placement_controller = PlacementController.new()
	add_child(_placement_controller)
	_placement_controller.setup(self)

	_panel = GoPlacerPanel.new()
	_panel.name = "GoPlacer"
	_panel.setup(_placement_controller, self)
	add_control_to_dock(DOCK_SLOT_BOTTOM, _panel)
	_panel.set_plugin(self)

	EditorInterface.get_selection().selection_changed.connect(
		_on_selection_changed
	)

func _exit_tree() -> void:
	_ghost_manager.clear()
	_gizmo.hide()
	if _panel != null:
		remove_control_from_docks(_panel)
		_panel.queue_free()
		_panel = null
	if _placement_controller != null:
		_placement_controller.queue_free()
		_placement_controller = null
	if EditorInterface.get_selection().selection_changed.is_connected(
		_on_selection_changed
	):
		EditorInterface.get_selection().selection_changed.disconnect(
			_on_selection_changed
		)

func _handles(_obj: Object) -> bool:
	return true

func _has_main_screen() -> bool:
	return false

func _on_selection_changed() -> void:
	if _state != PlacingState.IDLE:
		return
	if _panel != null:
		_panel.on_editor_selection_changed()

func _forward_3d_gui_input(
	camera: Camera3D, event: InputEvent
) -> int:
	if _state == PlacingState.IDLE:
		return AFTER_GUI_INPUT_PASS
	if _panel != null and not _panel.visible:
		_cancel_placing()
		return AFTER_GUI_INPUT_PASS

	var handled := _handle_input(camera, event)
	if handled:
		return AFTER_GUI_INPUT_STOP
	return AFTER_GUI_INPUT_PASS

func _handle_input(camera: Camera3D, event: InputEvent) -> bool:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			_cancel_placing()
			return true
		return false

	if event is InputEventMouseButton:
		return _handle_mouse_button(camera, event)

	if event is InputEventMouseMotion:
		return _handle_mouse_motion(camera, event)

	return false

func _handle_mouse_button(
	camera: Camera3D, event: InputEventMouseButton
) -> bool:
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_cancel_placing()
		return true
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _state == PlacingState.PREVIEWING:
			return _on_click_lock(camera, event)
		if not event.pressed and _state == PlacingState.DRAG_ROTATE:
			_commit_place()
			return true
	return false

func _handle_mouse_motion(
	camera: Camera3D, event: InputEventMouseMotion
) -> bool:
	if _state == PlacingState.PREVIEWING:
		_update_ghost_position(camera, event.position)
		return true
	if _state == PlacingState.DRAG_ROTATE:
		_update_drag_rotation(event.position.x)
		_update_ghost_transform()
		_gizmo.update(_drag_rotation_y)
		_gizmo.position_gizmo(
			_ghost_manager.get_ghost().global_position,
			_ghost_hit_normal,
			_placement_controller.normal_align_enabled()
		)
		return true
	return false

func _on_click_lock(camera: Camera3D, event: InputEvent) -> bool:
	var ghost: Node3D = _ghost_manager.get_ghost()
	var hit := SnapHelper.raycast_scene(
		camera, event.position, RAY_LENGTH,
		_ghost_manager.get_exclusion_rids(), ghost,
		_placement_controller.mesh_picking_enabled()
	)
	_ghost_hit_position = hit.position
	_ghost_hit_normal = hit.normal
	_has_valid_hit = true
	_drag_start_x = event.position.x
	_drag_rotation_y = 0.0
	_state = PlacingState.DRAG_ROTATE
	_update_ghost_transform()
	_gizmo.show(
		EditorInterface.get_edited_scene_root(),
		_ghost_manager.get_ghost().global_position,
		_ghost_hit_normal, _drag_rotation_y,
		_placement_controller.normal_align_enabled()
	)
	return true

func _update_ghost_position(
	camera: Camera3D, mouse_pos: Vector2
) -> void:
	var ghost: Node3D = _ghost_manager.get_ghost()
	if ghost == null:
		return
	var hit := SnapHelper.raycast_scene(
		camera, mouse_pos, RAY_LENGTH,
		_ghost_manager.get_exclusion_rids(), ghost,
		_placement_controller.mesh_picking_enabled()
	)
	ghost.visible = true
	_ghost_hit_position = hit.position
	_ghost_hit_normal = hit.normal
	_update_ghost_transform()

func _update_drag_rotation(mouse_x: float) -> void:
	var delta_x: float = mouse_x - _drag_start_x
	var raw_angle: float = delta_x * PIXELS_PER_RADIAN
	if Input.is_key_pressed(KEY_CTRL):
		var step: float = _placement_controller.snap_angle_step()
		if step > 0.0:
			raw_angle = snappedf(raw_angle, deg_to_rad(step))
	_drag_rotation_y = raw_angle

func _update_ghost_transform() -> void:
	var ghost: Node3D = _ghost_manager.get_ghost()
	if ghost == null:
		return
	var pos: Vector3 = _ghost_hit_position
	if Input.is_key_pressed(KEY_CTRL):
		var snap_size: float = _placement_controller.position_snap_size()
		if snap_size > 0.0:
			pos.x = snappedf(pos.x, snap_size)
			pos.y = snappedf(pos.y, snap_size)
			pos.z = snappedf(pos.z, snap_size)
	SnapHelper.apply_placement_transform(
		ghost, pos, _ghost_hit_normal, _drag_rotation_y,
		_placement_controller.normal_align_enabled(),
		_placement_controller.aabb_snap_enabled()
	)

func _commit_place() -> void:
	var ghost: Node3D = _ghost_manager.get_ghost()
	if ghost == null or not _has_valid_hit:
		return
	var entry: GoPlacerPaletteEntry = _current_entry
	if entry == null or entry.asset == null:
		_cancel_placing()
		return

	var scene_root: Node = EditorInterface.get_edited_scene_root()
	if scene_root == null:
		_cancel_placing()
		return

	var parent: Node = _placement_controller.target_parent_node()
	if parent == null or not is_instance_valid(parent):
		parent = SnapHelper.find_target_parent(scene_root)

	var instance: Node = InstanceFactory.create_from_entry(entry)
	if instance == null:
		_cancel_placing()
		return

	_placement_controller.set_active_entry(entry)
	_placement_controller.commit_to_scene(instance, parent, scene_root, ghost.global_transform)

	EditorInterface.get_selection().clear()
	if instance is Node:
		EditorInterface.get_selection().add_node(instance as Node)
	EditorInterface.mark_scene_as_unsaved()

	_gizmo.hide()
	_drag_rotation_y = 0.0
	_ghost_hit_position = Vector3.ZERO
	_ghost_hit_normal = Vector3.UP
	_state = PlacingState.PREVIEWING
	if ghost != null:
		ghost.visible = false

func _cancel_placing() -> void:
	_ghost_manager.clear()
	_gizmo.hide()
	_state = PlacingState.IDLE
	_has_valid_hit = false
	_current_entry = null
	if _panel != null:
		_panel.deselect_entry()

func start_placing() -> void:
	if _panel != null and not _panel.visible:
		return
	var entry: GoPlacerPaletteEntry = _panel.get_active_entry()
	if entry == null or entry.asset == null:
		return
	_current_entry = entry
	_drag_rotation_y = 0.0
	_state = PlacingState.PREVIEWING
	_ghost_manager.spawn(entry, EditorInterface.get_edited_scene_root())

func stop_placing() -> void:
	_cancel_placing()

func is_placing() -> bool:
	return _state != PlacingState.IDLE

func _get_plugin_name() -> String:
	return "GoPlacer"

func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon(
		"Node", "EditorIcons"
	)
