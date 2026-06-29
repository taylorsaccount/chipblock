extends PanelContainer

@onready var label: RichTextLabel = $MarginContainer/RichTextLabel
@onready var audio_player = $"../../../../AudioStreamPlayer"

const MAX_WIDTH := 116

func display_text(text_to_display: String, speech_sfx: AudioStream) -> void:
	label.bbcode_enabled = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(MAX_WIDTH, 0)
	label.bbcode_text = text_to_display
	audio_player.stream = speech_sfx
	if not label.character_revealed.is_connected(audio_player.play):
		label.character_revealed.connect(audio_player.play)

	# Set correct width so the label reflows at MAX_WIDTH before measuring height
	size = Vector2(get_minimum_size().x, size.y)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var content_h := float(label.get_content_height()) + 4.0
	label.visible_ratio = 0.0
	label.custom_minimum_size = Vector2(MAX_WIDTH, content_h)
	custom_minimum_size = Vector2.ZERO  # clear old floor so the new full_size is accurate
	await get_tree().process_frame

	var full_size := get_minimum_size()
	custom_minimum_size = full_size  # floor: prevents anchor recalc from shrinking below content

	# Write position + size via the four offset properties directly.
	# With anchor = 0.5 / 0.5 on all sides, setting offsets is the only way to
	# reliably encode both position and size without the anchor system fighting us.
	# Anchor spread = 0 so parent resizes never touch these values.
	var ps := get_parent_control().size
	var tx := maxf(0.0, ps.x * 0.5 - full_size.x * 0.5)
	var ty := maxf(0.0, ps.y * 0.5 - full_size.y - 24.0)
	offset_left   = tx - ps.x * 0.5
	offset_right  = tx + full_size.x - ps.x * 0.5
	offset_top    = ty - ps.y * 0.5
	offset_bottom = ty + full_size.y - ps.y * 0.5

	pivot_offset = Vector2(full_size.x * 0.5, full_size.y)
	scale = Vector2(1.0, 0.01)

	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(label.reveal_text)
