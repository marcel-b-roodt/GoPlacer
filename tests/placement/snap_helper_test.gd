@tool
class_name SnapHelperTest
extends GdUnitTestSuite

const _SNAP_HELPER_SCRIPT := preload(
	"res://addons/go_placer/placement/snap_helper.gd"
)

func test_ray_triangle_intersect_hit_center() -> void:
	var v0 := Vector3(0.0, 0.0, 0.0)
	var v1 := Vector3(1.0, 0.0, 0.0)
	var v2 := Vector3(0.0, 1.0, 0.0)
	var origin := Vector3(0.25, 0.25, 5.0)
	var direction := Vector3(0.0, 0.0, -1.0)
	var t: float = SnapHelper._ray_triangle_intersect(
		origin, direction, v0, v1, v2
	)
	assert_float(t).is_greater(0.0)

func test_ray_triangle_intersect_miss() -> void:
	var v0 := Vector3(0.0, 0.0, 0.0)
	var v1 := Vector3(1.0, 0.0, 0.0)
	var v2 := Vector3(0.0, 1.0, 0.0)
	var origin := Vector3(5.0, 5.0, 5.0)
	var direction := Vector3(0.0, 0.0, -1.0)
	var t: float = SnapHelper._ray_triangle_intersect(
		origin, direction, v0, v1, v2
	)
	assert_float(t).is_less(0.0)

func test_ray_triangle_intersect_parallel() -> void:
	var v0 := Vector3(0.0, 0.0, 0.0)
	var v1 := Vector3(1.0, 0.0, 0.0)
	var v2 := Vector3(0.0, 1.0, 0.0)
	var origin := Vector3(0.25, 0.25, 0.5)
	var direction := Vector3(1.0, 0.0, 0.0)
	var t: float = SnapHelper._ray_triangle_intersect(
		origin, direction, v0, v1, v2
	)
	assert_float(t).is_less(0.0)

func test_ray_triangle_intersect_behind() -> void:
	var v0 := Vector3(0.0, 0.0, 0.0)
	var v1 := Vector3(1.0, 0.0, 0.0)
	var v2 := Vector3(0.0, 1.0, 0.0)
	var origin := Vector3(0.25, 0.25, -1.0)
	var direction := Vector3(0.0, 0.0, -1.0)
	var t: float = SnapHelper._ray_triangle_intersect(
		origin, direction, v0, v1, v2
	)
	assert_float(t).is_less(0.0)

func test_basis_up_aligned_floor() -> void:
	var basis := SnapHelper._basis_up_aligned(Vector3.UP, 0.0)
	assert_vector(basis.y).is_equal_approx(Vector3.UP, Vector3(0.001, 0.001, 0.001))

func test_basis_up_aligned_wall_x() -> void:
	var basis := SnapHelper._basis_up_aligned(Vector3.RIGHT, 0.0)
	assert_vector(basis.y).is_equal_approx(Vector3.RIGHT, Vector3(0.001, 0.001, 0.001))

func test_basis_up_aligned_wall_z() -> void:
	var basis := SnapHelper._basis_up_aligned(Vector3.BACK, 0.0)
	assert_vector(basis.y).is_equal_approx(Vector3.BACK, Vector3(0.001, 0.001, 0.001))

func test_basis_up_aligned_ceiling() -> void:
	var basis := SnapHelper._basis_up_aligned(Vector3.DOWN, 0.0)
	assert_vector(basis.y).is_equal_approx(Vector3.DOWN, Vector3(0.001, 0.001, 0.001))

func test_basis_up_aligned_45_degree() -> void:
	var normal := Vector3(1.0, 1.0, 0.0).normalized()
	var basis := SnapHelper._basis_up_aligned(normal, 0.0)
	assert_vector(basis.y).is_equal_approx(normal, Vector3(0.001, 0.001, 0.001))

func test_basis_up_aligned_near_up_uses_forward_ref() -> void:
	var normal := Vector3(0.0, 0.9999, 0.01).normalized()
	var basis := SnapHelper._basis_up_aligned(normal, 0.0)
	assert_vector(basis.y).is_equal_approx(normal, Vector3(0.001, 0.001, 0.001))

func test_basis_up_aligned_azimuth_90() -> void:
	var basis_0 := SnapHelper._basis_up_aligned(Vector3.UP, 0.0)
	var basis_90 := SnapHelper._basis_up_aligned(Vector3.UP, PI / 2.0)
	var angle := basis_0.y.angle_to(basis_90.y)
	assert_float(angle).is_equal_approx(0.0, 0.001)

func test_basis_up_aligned_azimuth_rotates_xz() -> void:
	var basis_0 := SnapHelper._basis_up_aligned(Vector3.UP, 0.0)
	var basis_90 := SnapHelper._basis_up_aligned(Vector3.UP, PI / 2.0)
	var angle := basis_0.x.angle_to(basis_90.x)
	assert_float(absf(angle - PI / 2.0)).is_equal_approx(0.0, 0.01)

func test_flush_aabb_offset_floor_zero_aabb() -> void:
	var mi := MeshInstance3D.new()
	var offset := SnapHelper.flush_aabb_offset(mi, Vector3.UP, false)
	assert_vector(offset).is_equal_approx(Vector3.ZERO, Vector3(0.001, 0.001, 0.001))
	mi.queue_free()

func test_flush_aabb_offset_floor() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.0, 2.0, 2.0)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var offset := SnapHelper.flush_aabb_offset(mi, Vector3.UP, false)
	assert_float(offset.y).is_less(0.0)
	assert_float(absf(offset.y) - 1.0).is_equal_approx(0.0, 0.01)
	mi.queue_free()
	mesh.queue_free()

func test_flush_aabb_offset_floor_align_to_normal() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.0, 2.0, 2.0)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var offset := SnapHelper.flush_aabb_offset(mi, Vector3.UP, true)
	assert_float(offset.y).is_less(0.0)
	mi.queue_free()
	mesh.queue_free()

func test_flush_aabb_offset_zero_normal() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.0, 2.0, 2.0)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var offset := SnapHelper.flush_aabb_offset(mi, Vector3.ZERO, false)
	assert_vector(offset).is_equal_approx(Vector3.ZERO, Vector3(0.001, 0.001, 0.001))
	mi.queue_free()
	mesh.queue_free()

func test_snap_angle_free() -> void:
	var result := SnapHelper.snap_angle(37.5, 0.0)
	assert_float(result).is_equal(37.5)

func test_snap_angle_15() -> void:
	var result := SnapHelper.snap_angle(37.5, 15.0)
	assert_float(result).is_equal(45.0)

func test_snap_angle_90() -> void:
	var result := SnapHelper.snap_angle(37.5, 90.0)
	assert_float(result).is_equal(0.0)

func test_find_target_parent_returns_root_when_no_parent() -> void:
	var root := Node3D.new()
	root.name = "Root"
	var found := SnapHelper.find_target_parent(root)
	assert_object(found).is_same(root)
	root.queue_free()

func test_find_target_parent_finds_named_node() -> void:
	var root := Node3D.new()
	root.name = "Root"
	var parent := Node3D.new()
	parent.name = "GoPlacerParent"
	root.add_child(parent)
	var found := SnapHelper.find_target_parent(root)
	assert_object(found).is_same(parent)
	root.queue_free()