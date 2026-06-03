@tool
class_name InstanceFactoryTest
extends GdUnitTestSuite

const _INSTANCE_FACTORY_SCRIPT := preload(
	"res://addons/go_placer/placement/instance_factory.gd"
)
const _ENTRY_SCRIPT := preload(
	"res://addons/go_placer/palette/go_placer_palette_entry.gd"
)

func test_create_from_entry_null() -> void:
	var result: Node = InstanceFactory.create_from_entry(null)
	assert_object(result).is_null()

func test_create_from_entry_null_asset() -> void:
	var entry: GoPlacerPaletteEntry = _ENTRY_SCRIPT.new()
	var result: Node = InstanceFactory.create_from_entry(entry)
	assert_object(result).is_null()
	entry.queue_free()

func test_create_from_entry_mesh() -> void:
	var entry: GoPlacerPaletteEntry = _ENTRY_SCRIPT.new()
	var mesh := BoxMesh.new()
	entry.asset = mesh
	var result: Node = InstanceFactory.create_from_entry(entry)
	assert_object(result).is_not_null()
	assert_bool(result is MeshInstance3D).is_true()
	if result != null:
		result.queue_free()
	entry.queue_free()
	mesh.queue_free()

func test_create_from_entry_unknown_asset() -> void:
	var entry: GoPlacerPaletteEntry = _ENTRY_SCRIPT.new()
	var texture := GradientTexture1D.new()
	entry.asset = texture
	var result: Node = InstanceFactory.create_from_entry(entry)
	assert_object(result).is_null()
	entry.queue_free()