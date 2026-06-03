@tool
class_name PlacementController
extends Node

const _ENTRY_SCRIPT := preload(
	"res://addons/go_placer/palette/go_placer_palette_entry.gd"
)

var _editor_plugin: EditorPlugin
var _mesh_picking_enabled: bool = true
var _normal_align_enabled: bool = false
var _aabb_snap_enabled: bool = false
var _snap_angle_step: float = 15.0
var _position_snap_size: float = 1.0
var _active_entry: GoPlacerPaletteEntry = null
var _target_parent_node: Node = null

func setup(plugin: EditorPlugin) -> void:
	_editor_plugin = plugin

func set_active_entry(entry: GoPlacerPaletteEntry) -> void:
	_active_entry = entry

func set_mesh_picking(enabled: bool) -> void:
	_mesh_picking_enabled = enabled

func set_normal_align(enabled: bool) -> void:
	_normal_align_enabled = enabled

func set_aabb_snap(enabled: bool) -> void:
	_aabb_snap_enabled = enabled

func set_snap_angle_step(step: float) -> void:
	_snap_angle_step = step

func set_position_snap_size(size: float) -> void:
	_position_snap_size = size

func set_target_parent(node: Node) -> void:
	_target_parent_node = node

func snap_angle_step() -> float:
	return _snap_angle_step

func position_snap_size() -> float:
	return _position_snap_size

func normal_align_enabled() -> bool:
	return _normal_align_enabled

func aabb_snap_enabled() -> bool:
	return _aabb_snap_enabled

func mesh_picking_enabled() -> bool:
	return _mesh_picking_enabled

func target_parent_node() -> Node:
	return _target_parent_node

func commit_to_scene(
	instance: Node, parent: Node, scene_root: Node, ghost_transform: Transform3D
) -> void:
	var undo_redo: EditorUndoRedoManager = _editor_plugin.get_undo_redo()
	var asset_name: String = _active_entry.display_name
	if asset_name == "":
		asset_name = _active_entry.asset.resource_name
	if asset_name == "":
		asset_name = "Asset"
	undo_redo.create_action("Place Asset: %s" % asset_name)
	undo_redo.add_do_method(parent, "add_child", instance, true)
	undo_redo.add_do_property(instance, "owner", scene_root)
	if instance is Node3D:
		undo_redo.add_do_property(instance, "global_transform", ghost_transform)
	undo_redo.add_do_reference(instance)
	undo_redo.add_undo_method(parent, "remove_child", instance)
	undo_redo.commit_action()
