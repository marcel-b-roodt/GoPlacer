@tool
class_name GhostManager
extends RefCounted

const _ENTRY_SCRIPT := preload(
	"res://addons/go_placer/palette/go_placer_palette_entry.gd"
)
const _INSTANCE_FACTORY_SCRIPT := preload(
	"res://addons/go_placer/placement/instance_factory.gd"
)

const GHOST_MATERIAL_ALPHA := 0.5

var _ghost: Node3D = null
var _ghost_rids: Array[RID] = []
var _ghost_material: StandardMaterial3D = null

func get_ghost() -> Node3D:
	return _ghost

func get_exclusion_rids() -> Array[RID]:
	return _ghost_rids

func spawn(
	entry: GoPlacerPaletteEntry, scene_root: Node
) -> bool:
	clear()
	if entry == null or entry.asset == null:
		return false
	var instance: Node = _INSTANCE_FACTORY_SCRIPT.create_from_entry(entry)
	if instance == null:
		return false
	var node_3d: Node3D = instance as Node3D
	if node_3d == null:
		instance.queue_free()
		return false
	_ghost = node_3d
	_ghost.visible = false
	_collect_rids(_ghost)
	_disable_collision(_ghost)
	_apply_material(_ghost)
	scene_root.add_child(_ghost)
	_ghost.owner = scene_root
	return true

func clear() -> void:
	_ghost_rids.clear()
	if _ghost != null and is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null

func is_active() -> bool:
	return _ghost != null and is_instance_valid(_ghost)

func _collect_rids(node: Node) -> void:
	if node is CollisionShape3D:
		if node.shape != null:
			_ghost_rids.append(node.shape.get_rid())
	if node is CollisionObject3D:
		_ghost_rids.append(node.get_rid())
	for child: Node in node.get_children():
		_collect_rids(child)

func _disable_collision(node: Node) -> void:
	if node is CollisionObject3D:
		var co: CollisionObject3D = node as CollisionObject3D
		co.collision_mask = 0
		co.collision_layer = 0
	for child: Node in node.get_children():
		_disable_collision(child)

func _apply_material(node: Node) -> void:
	if _ghost_material == null:
		_ghost_material = StandardMaterial3D.new()
		_ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_ghost_material.albedo_color = Color(0.5, 0.8, 1.0, GHOST_MATERIAL_ALPHA)
		_ghost_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		var surface_count: int = mi.get_surface_override_material_count()
		for i: int in surface_count:
			mi.set_surface_override_material(i, _ghost_material)
	for child: Node in node.get_children():
		_apply_material(child)