@tool
class_name GoPlacerPalette
extends Resource

const _ENTRY_SCRIPT := preload(
	"res://addons/go_placer/palette/go_placer_palette_entry.gd"
)

@export var palette_name: String = ""
@export var entries: Array[GoPlacerPaletteEntry] = []

func add_entry(
	asset: Resource,
	display_name: String = "",
	tags: PackedStringArray = PackedStringArray(),
) -> void:
	var entry: GoPlacerPaletteEntry = _ENTRY_SCRIPT.new()
	entry.asset = asset
	if display_name != "":
		entry.display_name = display_name
	elif asset.resource_name != "":
		entry.display_name = asset.resource_name
	elif asset.resource_path != "":
		entry.display_name = asset.resource_path.get_file().get_basename()
	entry.tags = tags
	entries.append(entry)
	emit_changed()

func remove_entry(index: int) -> void:
	if index >= 0 and index < entries.size():
		entries.remove_at(index)
		emit_changed()

func move_entry(from_index: int, to_index: int) -> void:
	if from_index < 0 or from_index >= entries.size():
		return
	if to_index < 0 or to_index >= entries.size():
		return
	var entry: GoPlacerPaletteEntry = entries.pop_at(from_index)
	entries.insert(to_index, entry)
	emit_changed()
