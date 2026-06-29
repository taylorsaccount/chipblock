extends Window

signal tritanopia_toggled(enabled: bool, trit_mat: ShaderMaterial, purple_mat: ShaderMaterial)

var drag_offset: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var settings_ref

var mywindow
var label
var panel
var base_panel_scale: Vector2
var new_size: int = 19
var base_font_size: int

var info_font_size: int = 19
var tritanopia_enabled: bool = false
var _trit_mat: ShaderMaterial
var _purple_mat: ShaderMaterial

func _ready() -> void:
	mouse_entered.connect(grab_focus)
	$Settings/Panel/HSlider2.value_changed.connect(_on_h_slider_2_value_changed)
	$Settings/Panel/CheckButton.toggled.connect(_on_check_button_toggled)
	_trit_mat = ShaderMaterial.new()
	_trit_mat.shader = preload("res://tritanopia.gdshader")
	_purple_mat = ShaderMaterial.new()
	_purple_mat.shader = preload("res://red_to_purple.gdshader")

func _on_check_button_toggled(enabled: bool) -> void:
	tritanopia_enabled = enabled
	$Settings.material = _trit_mat if enabled else null
	$Settings/Panel.material = _purple_mat if enabled else null
	tritanopia_toggled.emit(enabled, _trit_mat, _purple_mat)

func _on_h_slider_2_value_changed(value: float) -> void:
	info_font_size = int(value)

func setup() -> void:
	if mywindow != null and label == null:
		label = mywindow.get_node("HBoxContainer/DialogueManager/DialogueBox/PanelContainer/MarginContainer/RichTextLabel")
		panel = mywindow.get_node("HBoxContainer/DialogueManager/DialogueBox/PanelContainer")
		base_panel_scale = panel.scale
		new_size = label.get_theme_font_size("normal_font_size", "RichTextLabel")
		base_font_size = new_size

func _on_texture_button_2_pressed():
	visible = false
	if settings_ref != null:
		settings_ref.visible = true

func _on_h_slider_value_changed(value):
	new_size = int(value)
	if label != null and panel != null:
		label.add_theme_font_size_override("normal_font_size", new_size)
		var scale_factor = float(new_size) / float(base_font_size)
		panel.scale = base_panel_scale * scale_factor


func _on_close_pressed():
	get_tree().quit()
