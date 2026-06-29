extends Window

var drag_offset: Vector2 = Vector2.ZERO
var is_dragging: bool = false

func set_text(text: String) -> void:
	$Panel/Control/CanvasLayer/RichTextLabel.text = text

func set_font_size(font_size: int) -> void:
	$Panel/Control/CanvasLayer/RichTextLabel.add_theme_font_size_override("normal_font_size", font_size)

func set_tritanopia(mat: Material) -> void:
	$Panel.material = mat
