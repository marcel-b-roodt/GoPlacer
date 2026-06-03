@tool
class_name PlacementGizmo
extends RefCounted

const _SNAP_HELPER_SCRIPT := preload(
	"res://addons/go_placer/placement/snap_helper.gd"
)

const GIZMO_RADIUS := 1.5
const GIZMO_SEGMENTS := 64
const GIZMO_COLOR := Color(1.0, 1.0, 0.3, 0.8)
const GIZMO_LINE_COLOR := Color(1.0, 1.0, 0.3, 0.5)

var _arc: MeshInstance3D = null
var _line: MeshInstance3D = null

func show(
	scene_root: Node, position: Vector3,
	normal: Vector3, azimuth: float, align_to_normal: bool
) -> void:
	hide()
	if scene_root == null:
		return
	var arc_mesh := _create_arc_mesh(GIZMO_RADIUS, azimuth, GIZMO_SEGMENTS)
	_arc = MeshInstance3D.new()
	_arc.mesh = arc_mesh
	_arc.material_override = _create_line_mat(GIZMO_COLOR)
	scene_root.add_child(_arc)
	_arc.owner = scene_root
	var forward: Vector3 = Vector3.FORWARD * GIZMO_RADIUS
	if align_to_normal and normal != Vector3.UP:
		var basis := SnapHelper._basis_up_aligned(normal, 0.0)
		forward = basis * Vector3.FORWARD * GIZMO_RADIUS
	var line_mesh := _create_line_mesh(position, position + forward)
	_line = MeshInstance3D.new()
	_line.mesh = line_mesh
	_line.material_override = _create_line_mat(GIZMO_LINE_COLOR)
	scene_root.add_child(_line)
	_line.owner = scene_root
	position_gizmo(position, normal, align_to_normal)

func update(azimuth: float) -> void:
	if _arc == null:
		return
	_arc.mesh = _create_arc_mesh(GIZMO_RADIUS, azimuth, GIZMO_SEGMENTS)

func position_gizmo(
	position: Vector3, normal: Vector3, align_to_normal: bool
) -> void:
	var gizmo_basis: Basis = Basis.IDENTITY
	if align_to_normal and normal != Vector3.UP:
		gizmo_basis = SnapHelper._basis_up_aligned(normal, 0.0)
	if _arc != null and is_instance_valid(_arc):
		_arc.global_position = position
		_arc.global_basis = gizmo_basis
	if _line != null and is_instance_valid(_line):
		_line.global_position = position
		_line.global_basis = gizmo_basis

func hide() -> void:
	if _arc != null and is_instance_valid(_arc):
		_arc.queue_free()
	_arc = null
	if _line != null and is_instance_valid(_line):
		_line.queue_free()
	_line = null

func _create_arc_mesh(
	radius: float, angle: float, segments: int
) -> ArrayMesh:
	var points := PackedVector3Array()
	var steps: int = max(2, int(abs(angle) / (2.0 * PI) * segments) + 2)
	for i: int in range(steps + 1):
		var t: float = float(i) / float(steps) * angle
		var x: float = cos(t) * radius
		var z: float = sin(t) * radius
		points.append(Vector3(x, 0.0, z))
	points.append(Vector3.ZERO)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p: Vector3 in points:
		st.add_vertex(p)
	st.commit()
	var mesh := ArrayMesh.new()
	st.commit(mesh)
	return mesh

func _create_line_mesh(from: Vector3, to: Vector3) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	st.add_vertex(from)
	st.add_vertex(to)
	st.commit()
	var mesh := ArrayMesh.new()
	st.commit(mesh)
	return mesh

func _create_line_mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	return mat