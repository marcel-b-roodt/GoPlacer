@tool
class_name GoPlacerItemList
extends ItemList

signal drop_received(data: Variant)
signal item_deselected()

func _ready() -> void:
	allow_reselect = true
	set_drag_forwarding(
		Callable(),
		Callable(self, "_item_can_drop"),
		Callable(self, "_item_drop")
	)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var clicked: int = get_item_at_position(event.position)
			if clicked >= 0 and is_selected(clicked):
				deselect_all()
				item_deselected.emit()
				accept_event()
				return

func _item_can_drop(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var dict: Dictionary = data
	if not dict.has("files"):
		return false
	return true

func _item_drop(_at_position: Vector2, data: Variant) -> void:
	drop_received.emit(data)
