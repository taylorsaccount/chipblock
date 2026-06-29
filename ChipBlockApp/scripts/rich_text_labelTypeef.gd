extends RichTextLabel

signal character_revealed

const TIME_TO_DISPLAY_SECONDS: float = 1.2
const FINAL_WIDTH: float = 100.0

var _last_visible_chars: int = 0

func _process(_delta: float) -> void:
	var current = visible_characters
	if current > _last_visible_chars:
		_last_visible_chars = current
		character_revealed.emit()

func _ready() -> void:
	fit_content = false
	scroll_active = false
	custom_minimum_size = Vector2.ZERO
	await get_tree().process_frame  # wait for Godot to calculate content height
	_run_tween()

func reveal_text() -> void:
	fit_content = false
	scroll_active = false
	_last_visible_chars = 0
	visible_ratio = 0.0
	await get_tree().process_frame
	_run_tween()

func _run_tween() -> void:
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_parallel(true)
	tween.tween_property(self, "visible_ratio", 1.0, TIME_TO_DISPLAY_SECONDS)
