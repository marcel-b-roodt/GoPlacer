@tool
class_name SnapHelper
extends RefCounted

const AABB_FLUSH_BIAS: float = 0.001

static func snap_angle(angle_deg: float, snap_step: float) -> float:
	if snap_step <= 0.0:
		return angle_deg
	return snappedf(angle_deg, snap_step)

static func raycast_scene(
	camera: Camera3D,
	mouse_pos: Vector2,
	ray_length: float = 4000.0,
	exclude_rids: Array[RID] = [],
	exclude_node: Node = null,
	mesh_picking: bool = true,
) -> Dictionary:
	var result := {"position": Vector3.ZERO, "normal": Vector3.UP}
	var world_3d: World3D = camera.get_world_3d()
	if world_3d == null:
		result.position = floor_plane_intersect(camera, mouse_pos)
		return result
	var state: PhysicsDirectSpaceState3D = world_3d.direct_space_state
	if state == null:
		result.position = floor_plane_intersect(camera, mouse_pos)
		return result

	var origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var direction: Vector3 = camera.project_ray_normal(mouse_pos)
	var to: Vector3 = origin + direction * ray_length

	var query := PhysicsRayQueryParameters3D.create(origin, to)
	query.collision_mask = 0xFFFFFFFF
	query.collide_with_areas = true
	if not exclude_rids.is_empty():
		query.exclude = exclude_rids
	var hit: Dictionary = state.intersect_ray(query)

	if not hit.is_empty():
		result.position = hit.position
		result.normal = Vector3.UP
		if hit.has("normal"):
			result.normal = hit.normal
		return result

	if mesh_picking:
		var mesh_result := _raycast_mesh_faces(
			origin, direction, ray_length, exclude_node
		)
		if not mesh_result.is_empty():
			return mesh_result
	result.position = floor_plane_intersect(camera, mouse_pos)
	result.normal = Vector3.UP
	return result

static func _raycast_mesh_faces(
	origin: Vector3,
	direction: Vector3,
	ray_length: float,
	exclude_node: Node = null,
) -> Dictionary:
	var scene_root: Node = EditorInterface.get_edited_scene_root()
	if scene_root == null:
		return {}
	var closest_dist: Array = [ray_length]
	var closest_pos: Array = [Vector3.ZERO]
	var closest_norm: Array = [Vector3.UP]
	var found_ref: Array = [false]
	_find_mesh_hit_ref(
		scene_root, origin, direction,
		closest_dist, closest_pos, closest_norm, found_ref,
		exclude_node
	)
	if not found_ref[0]:
		return {}
	var result := {"position": Vector3.ZERO, "normal": Vector3.UP}
	result.position = closest_pos[0]
	result.normal = closest_norm[0]
	return result

static func _find_mesh_hit_ref(
	node: Node,
	origin: Vector3,
	direction: Vector3,
	closest_dist_ref: Array,
	closest_pos_ref: Array,
	closest_norm_ref: Array,
	found_ref: Array,
	exclude_node: Node = null,
) -> void:
	if node == exclude_node:
		return
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		var mesh: Mesh = mi.mesh
		if mesh != null:
			var to_global: Transform3D = mi.global_transform
			var hit := _intersect_mesh_triangles(
				mesh, to_global, origin, direction,
				closest_dist_ref[0]
			)
			if not hit.is_empty():
				closest_dist_ref[0] = hit.distance
				closest_pos_ref[0] = hit.position
				closest_norm_ref[0] = hit.normal
				found_ref[0] = true
	for child: Node in node.get_children():
		_find_mesh_hit_ref(
			child, origin, direction,
			closest_dist_ref, closest_pos_ref,
			closest_norm_ref, found_ref, exclude_node
		)

static func _intersect_mesh_triangles(
	mesh: Mesh,
	to_global: Transform3D,
	origin: Vector3,
	direction: Vector3,
	max_distance: float,
) -> Dictionary:
	var surfaces: int = mesh.get_surface_count()
	var best_t: float = max_distance
	var best_hit: Dictionary = {}
	for s: int in surfaces:
		var arrays := mesh.surface_get_arrays(s)
		if arrays == null or arrays.size() == 0:
			continue
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var raw_normals: Variant = arrays[Mesh.ARRAY_NORMAL]
		var raw_indices: Variant = arrays[Mesh.ARRAY_INDEX]
		var has_normals: bool = raw_normals != null and (raw_normals as PackedVector3Array).size() > 0
		var has_indices: bool = raw_indices != null and (raw_indices as PackedInt32Array).size() > 0
		if vertices.size() < 3:
			continue
		if has_indices:
			var idx: PackedInt32Array = raw_indices as PackedInt32Array
			var nrm: PackedVector3Array
			if has_normals:
				nrm = raw_normals as PackedVector3Array
			for i: int in range(0, idx.size() - 2, 3):
				var v0: Vector3 = to_global * vertices[idx[i]]
				var v1: Vector3 = to_global * vertices[idx[i + 1]]
				var v2: Vector3 = to_global * vertices[idx[i + 2]]
				var t: float = _ray_triangle_intersect(
					origin, direction, v0, v1, v2
				)
				if t > 0.0 and t < best_t:
					best_t = t
					var hit_pos: Vector3 = origin + direction * t
					var face_normal: Vector3 = (v1 - v0).cross(v2 - v0)
					if face_normal.length_squared() > 0.001:
						face_normal = face_normal.normalized()
					elif has_normals and nrm.size() > idx[i]:
						face_normal = (
							to_global.basis * nrm[idx[i]]
						).normalized()
					else:
						face_normal = Vector3.UP
					if face_normal.dot(direction) > 0.0:
						face_normal = -face_normal
					best_hit = {
						"position": hit_pos,
						"normal": face_normal,
						"distance": t,
					}
		else:
			var nrm: PackedVector3Array
			if has_normals:
				nrm = raw_normals as PackedVector3Array
			for i: int in range(0, vertices.size() - 2, 3):
				var v0: Vector3 = to_global * vertices[i]
				var v1: Vector3 = to_global * vertices[i + 1]
				var v2: Vector3 = to_global * vertices[i + 2]
				var t: float = _ray_triangle_intersect(
					origin, direction, v0, v1, v2
				)
				if t > 0.0 and t < best_t:
					best_t = t
					var hit_pos: Vector3 = origin + direction * t
					var face_normal: Vector3 = (v1 - v0).cross(v2 - v0)
					if face_normal.length_squared() > 0.001:
						face_normal = face_normal.normalized()
					elif has_normals and nrm.size() > i:
						face_normal = (
							to_global.basis * nrm[i]
						).normalized()
					else:
						face_normal = Vector3.UP
					if face_normal.dot(direction) > 0.0:
						face_normal = -face_normal
					best_hit = {
						"position": hit_pos,
						"normal": face_normal,
						"distance": t,
					}
	return best_hit

static func _ray_triangle_intersect(
	origin: Vector3,
	direction: Vector3,
	v0: Vector3,
	v1: Vector3,
	v2: Vector3,
) -> float:
	var edge1: Vector3 = v1 - v0
	var edge2: Vector3 = v2 - v0
	var h: Vector3 = direction.cross(edge2)
	var a: float = edge1.dot(h)
	if absf(a) < 0.0001:
		return -1.0
	var f: float = 1.0 / a
	var s: Vector3 = origin - v0
	var u: float = f * s.dot(h)
	if u < 0.0 or u > 1.0:
		return -1.0
	var q: Vector3 = s.cross(edge1)
	var v: float = f * direction.dot(q)
	if v < 0.0 or u + v > 1.0:
		return -1.0
	var t: float = f * edge2.dot(q)
	if t > 0.0001:
		return t
	return -1.0

static func floor_plane_intersect(
	camera: Camera3D, mouse_pos: Vector2
) -> Vector3:
	var origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var direction: Vector3 = camera.project_ray_normal(mouse_pos)
	if absf(direction.y) < 0.0001:
		return origin + direction * 10.0
	var t: float = -origin.y / direction.y
	if t < 0.0:
		return origin + direction * 10.0
	return origin + direction * t

static func find_target_parent(scene_root: Node) -> Node:
	if scene_root == null:
		return null
	var named: Node = _find_node_recursive(scene_root, "GoPlacerParent")
	if named != null:
		return named
	return scene_root

static func _find_node_recursive(
	node: Node, target_name: String
) -> Node:
	if node.name == target_name:
		return node
	for child: Node in node.get_children():
		var found: Node = _find_node_recursive(child, target_name)
		if found != null:
			return found
	return null

static func apply_placement_transform(
	node: Node3D,
	position: Vector3,
	normal: Vector3,
	azimuth: float,
	align_to_normal: bool,
	aabb_snap: bool = false,
) -> void:
	var offset: Vector3 = Vector3.ZERO
	if aabb_snap:
		offset = flush_aabb_offset(node, normal, align_to_normal)
	node.global_position = position + offset
	if align_to_normal and absf(normal.dot(Vector3.UP)) < 0.999:
		var align_basis := _basis_up_aligned(normal, azimuth)
		node.basis = align_basis
	else:
		node.basis = Basis(Vector3.RIGHT, Vector3.UP, Vector3.BACK)
		node.rotation.y = azimuth

static func flush_aabb_offset(
	node: Node3D, hit_normal: Vector3, align_to_normal: bool
) -> Vector3:
	if hit_normal.is_zero_approx():
		return Vector3.ZERO
	var aabb: AABB = _get_visual_aabb(node)
	if aabb.size == Vector3.ZERO:
		return Vector3.ZERO
	var mn: Vector3 = aabb.position
	var mx: Vector3 = aabb.position + aabb.size
	var inward: Vector3 = -hit_normal
	if align_to_normal:
		var bottom_dist: float = absf(mn.y)
		return hit_normal * (bottom_dist - AABB_FLUSH_BIAS)
	var dist: float = (
		mx.x * maxf(inward.x, 0.0)
		+ mn.x * minf(inward.x, 0.0)
		+ mx.y * maxf(inward.y, 0.0)
		+ mn.y * minf(inward.y, 0.0)
		+ mx.z * maxf(inward.z, 0.0)
		+ mn.z * minf(inward.z, 0.0)
	)
	var offset: Vector3 = hit_normal * (dist - AABB_FLUSH_BIAS)
	if absf(hit_normal.y) <= 0.5 and mn.y < 0.0:
		offset.y += absf(mn.y)
	return offset

static func _get_visual_aabb(node: Node3D) -> AABB:
	if node is MeshInstance3D and node.mesh != null:
		return (node as MeshInstance3D).get_aabb()
	if node is CollisionShape3D:
		var shape: Shape3D = (node as CollisionShape3D).shape
		if shape != null:
			var s: AABB = shape.get_debug_mesh().get_aabb()
			return s
	var combined := AABB()
	for child: Node in node.get_children():
		if child is Node3D:
			var child_aabb: AABB = _get_visual_aabb(child)
			if child_aabb.size != Vector3.ZERO:
				var xform: Transform3D = child.transform
				child_aabb = xform * child_aabb
				if combined.size == Vector3.ZERO:
					combined = child_aabb
				else:
					combined = combined.merge(child_aabb)
	return combined

static func _basis_up_aligned(normal: Vector3, azimuth: float) -> Basis:
	var y: Vector3 = normal.normalized()
	var ref: Vector3 = Vector3.UP
	if absf(y.dot(ref)) > 0.999:
		ref = Vector3.FORWARD
	var x: Vector3 = y.cross(ref).normalized()
	if x.length_squared() < 0.001:
		x = Vector3.RIGHT
	var z: Vector3 = x.cross(y).normalized()
	var identity := Basis(x, y, z).orthonormalized()
	var rot := Basis(y, azimuth)
	return (rot * identity).orthonormalized()
