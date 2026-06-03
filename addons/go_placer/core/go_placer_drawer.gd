@tool
class_name GoPlacerDrawer
extends VBoxContainer

var _plugin: EditorPlugin = null
var _content: VBoxContainer = null
var _header_btn: Button = null
var _drawer_title: String = ""

func set_plugin(plugin: EditorPlugin) -> void:
	_plugin = plugin

func set_open(value: bool) -> void:
	if _content == null or _header_btn == null:
		return
	if _content.visible == value:
		return
	_content.visible = value
	_header_btn.set_pressed_no_signal(value)
	_header_btn.text = ("\u25bc  " if value else "\u25b6  ") + _drawer_title

func is_open() -> bool:
	return _content != null and _content.visible

func refresh() -> void:
	pass

func _setup_drawer(title: String, open: bool = false) -> void:
	_drawer_title = title
	_header_btn = Button.new()
	_header_btn.text = ("\u25bc  " if open else "\u25b6  ") + title
	_header_btn.toggle_mode = true
	_header_btn.button_pressed = open
	_header_btn.flat = true
	_header_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_header_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_btn.add_theme_font_size_override("font_size", 11)
	add_child(_header_btn)

	_content = VBoxContainer.new()
	_content.visible = open
	add_child(_content)

	_header_btn.toggled.connect(func(pressed: bool) -> void:
		_content.visible = pressed
		_header_btn.text = ("\u25bc  " if pressed else "\u25b6  ") + _drawer_title
	)

func _op_button(text: String, tooltip: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 11)
	btn.tooltip_text = tooltip
	btn.disabled = true
	return btn