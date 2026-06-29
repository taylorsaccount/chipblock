extends Window

signal feed_pressed

var drag_offset: Vector2 = Vector2.ZERO
var is_dragging: bool = false
@onready var label: RichTextLabel = $Panel/Panel/CanvasLayer/RichTextLabel
@onready var feed_label: Label = $Panel/feedbutton/Label
@onready var labelh: Label = $Panel/TextureButton3/Label2



func _process(_delta: float) -> void:
	
	
	
	if Input.is_action_just_pressed("lClick"):
		var local_mouse = Vector2(DisplayServer.mouse_get_position()) - Vector2(position)
		var on_button = false
		for child in $Panel.get_children():
			if child is BaseButton and child.get_rect().has_point(local_mouse):
				on_button = true
				break
		if not on_button:
			is_dragging = true
			drag_offset = Vector2(DisplayServer.mouse_get_position()) - Vector2(position)
	if Input.is_action_just_released("lClick"):
		is_dragging = false
		drag_offset = Vector2.ZERO
	if is_dragging:
		position = Vector2i(Vector2(DisplayServer.mouse_get_position()) - drag_offset)





var scwin
var mywindow

func _ready() -> void:
	
	labelh.visible = false
	
	mouse_entered.connect(grab_focus)
	scwin = preload("res://settingschange.tscn").instantiate()
	scwin.settings_ref = self
	scwin.visible = false
	get_tree().root.add_child.call_deferred(scwin)
	$Panel/feedbutton.pressed.connect(_on_feedbutton_pressed)

func _on_feedbutton_pressed() -> void:
	feed_pressed.emit()

func update_feed_label(total: int) -> void:
	feed_label.text = "Feed chip [%d] trackers" % total

func update_tracker_display(url: String, trackers: Array, fingerprinters: Array, total: int = 0) -> void:
	var tracker_lines = trackers.map(func(t): return "• " + str(t[0]))
	var fp_lines = fingerprinters.map(func(f): return "• " + str(f[0]))
	label.text = "[b]%s[/b]\n\n[b]Total trackers seen:[/b] %d\n\n[b]Trackers (%d):[/b]\n%s\n\n[b]Fingerprinters (%d):[/b]\n%s" % [
		url if url != "" else "Unknown",
		total,
		trackers.size(),
		"\n".join(tracker_lines) if tracker_lines.size() > 0 else "None",
		fingerprinters.size(),
		"\n".join(fp_lines) if fp_lines.size() > 0 else "None"
	]

func _on_texture_button_2_pressed():
	scwin.mywindow = mywindow
	scwin.setup()
	scwin.position = position
	visible = false
	scwin.visible = true
	



func _on_texture_button_pressed():
	OS.shell_open("https://privacybadger.org/#What-is-a-third-party-tracker")
	OS.shell_open("https://coveryourtracks.eff.org/learn")


func set_tritanopia(trit_mat: Material, purple_mat: Material) -> void:
	$Panel.material = trit_mat
	$Panel/Panel.material = purple_mat

func _on_close_pressed():
	hide()
	



func _on_texture_button_3_mouse_entered():
	labelh.visible = true


func _on_texture_button_3_mouse_exited():
	labelh.visible = false
