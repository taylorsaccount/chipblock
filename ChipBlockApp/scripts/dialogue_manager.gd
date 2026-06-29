extends CanvasLayer

@onready var dialogue_box: Control = $DialogueBox
@onready var text_box: PanelContainer = $DialogueBox/PanelContainer

var dialogue_lines: Array[String] = []
var current_line_index: int = 0
var is_dialogue_active: bool = false

var sfx: AudioStream

func _ready() -> void:
	dialogue_box.visible = false
	start_dialogue(["Hey!!!!!!you're meannnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnand horrible and a lot of stuff that is annoying and i will kill you",
					"Dont touch me!!!!!"])

func start_dialogue(lines: Array[String], speech_sfx: AudioStream = null):
	dialogue_lines = lines
	current_line_index = 0
	is_dialogue_active = true
	dialogue_box.visible = true
	sfx = speech_sfx
	text_box.display_text(dialogue_lines[current_line_index], sfx)

func _input(event):
	if not is_dialogue_active:
			return
	if event.is_action_pressed("ui_accept"):
		advance_dialogue()

func advance_dialogue():
	if current_line_index < dialogue_lines.size() - 1:
		current_line_index += 1
		text_box.display_text(dialogue_lines[current_line_index], sfx)
	else:
		#get_tree().paused = false
		is_dialogue_active = false
		dialogue_box.visible = false
