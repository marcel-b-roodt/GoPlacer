@tool
class_name InstanceFactory
extends RefCounted

const _ENTRY_SCRIPT := preload(
	"res://addons/go_placer/palette/go_placer_palette_entry.gd"
)

static func create_from_entry(
	entry: GoPlacerPaletteEntry
) -> Node:
	if entry == null or entry.asset == null:
		return null
	if entry.asset is PackedScene:
		return (entry.asset as PackedScene).instantiate()
	if entry.asset is Mesh:
		var mi := MeshInstance3D.new()
		mi.mesh = entry.asset as Mesh
		return mi
	return null