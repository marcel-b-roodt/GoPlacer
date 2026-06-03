@tool
class_name GhostManagerTest
extends GdUnitTestSuite

const _GHOST_MANAGER_SCRIPT := preload(
	"res://addons/go_placer/placement/ghost_manager.gd"
)
const _ENTRY_SCRIPT := preload(
	"res://addons/go_placer/palette/go_placer_palette_entry.gd"
)

var _scene_root: Node3D = null

func before_test() -> void:
	_scene_root = Node3D.new()
	_scene_root.name = "TestRoot"

func after_test() -> void:
	if _scene_root != null and is_instance_valid(_scene_root):
		_scene_root.queue_free()

func test_spawn_null_entry() -> void:
	var gm: GhostManager = _GHOST_MANAGER_SCRIPT.new()
	var result := gm.spawn(null, _scene_root)
	assert_bool(result).is_false()
	assert_bool(gm.is_active()).is_false()

func test_spawn_null_asset() -> void:
	var gm: GhostManager = _GHOST_MANAGER_SCRIPT.new()
	var entry: GoPlacerPaletteEntry = _ENTRY_SCRIPT.new()
	var result := gm.spawn(entry, _scene_root)
	assert_bool(result).is_false()
	assert_bool(gm.is_active()).is_false()
	entry.queue_free()

func test_spawn_mesh_entry() -> void:
	var gm: GhostManager = _GHOST_MANAGER_SCRIPT.new()
	var entry: GoPlacerPaletteEntry = _ENTRY_SCRIPT.new()
	var mesh := BoxMesh.new()
	entry.asset = mesh
	var result := gm.spawn(entry, _scene_root)
	assert_bool(result).is_true()
	assert_bool(gm.is_active()).is_true()
	assert_object(gm.get_ghost()).is_not_null()
	gm.clear()
	assert_bool(gm.is_active()).is_false()
	entry.queue_free()
	mesh.queue_free()

func test_clear_frees_ghost() -> void:
	var gm: GhostManager = _GHOST_MANAGER_SCRIPT.new()
	var entry: GoPlacerPaletteEntry = _ENTRY_SCRIPT.new()
	var mesh := BoxMesh.new()
	entry.asset = mesh
	gm.spawn(entry, _scene_root)
	var ghost: Node3D = gm.get_ghost()
	gm.clear()
	assert_object(gm.get_ghost()).is_null()
	entry.queue_free()
	mesh.queue_free()

func test_exclusion_rids_collected() -> void:
	var gm: GhostManager = _GHOST_MANAGER_SCRIPT.new()
	var entry: GoPlacerPaletteEntry = _ENTRY_SCRIPT.new()
	var mesh := BoxMesh.new()
	entry.asset = mesh
	gm.spawn(entry, _scene_root)
	var rids: Array[RID] = gm.get_exclusion_rids()
	assert_bool(rids.is_empty()).is_false()
	gm.clear()
	entry.queue_free()
	mesh.queue_free()

func test_spawn_replaces_previous_ghost() -> void:
	var gm: GhostManager = GhostManager.new()
	var entry1: GoPlacerPaletteEntry = _ENTRY_SCRIPT.new()
	var mesh1 := BoxMesh.new()
	mesh1.size = Vector3(1.0, 1.0, 1.0)
	entry1.asset = mesh1
	gm.spawn(entry1, _scene_root)

	var entry2: GoPlacerPaletteEntry = _ENTRY_SCRIPT.new()
	var mesh2 := SphereMesh.new()
	entry2.asset = mesh2
	gm.spawn(entry2, _scene_root)

	assert_bool(gm.is_active()).is_true()
	gm.clear()
	entry1.queue_free()
	entry2.queue_free()
	mesh1.queue_free()
	mesh2.queue_free()