extends TextureButton

class_name RadialMenuButton

# Radius of the menu circle. Smaller = buttons stay closer to the center.
@export var radius = 40
# Tween duration in seconds.
@export var speed = 0.25
# Final button scale when the menu opens.
@export var button_scale = Vector2(0.5, 0.5)
# Starting/closing scale for a "pop out" effect.
@export var hidden_scale = Vector2(0.2, 0.2)
# Choose the visible arc: right-side only by default.
@export var arc_start_angle = -PI / 1.7
@export var arc_end_angle = PI / 3.5
# Offset the entire menu from the center. Use Vector2(20, 0) to shift right.
@export var menu_offset = Vector2(10, 0)

var num = 0
var active = false

func _ready():
	$Buttons.hide()
	num = $Buttons.get_child_count()
	for b in $Buttons.get_children():
		b.position = Vector2.ZERO
		b.scale = hidden_scale

func toggle_menu():
	disabled = true
	if active:
		hide_menu()
	else:
		show_menu()

func _on_tween_finished():
	disabled = false
	if not active:
		$Buttons.hide()

func show_menu():
	$Buttons.show()
	active = true
	var tw = create_tween().set_parallel()
	tw.finished.connect(_on_tween_finished)

	for i in range(num):
		var b = $Buttons.get_child(i)
		var t = float(i) / max(num - 1, 1)
		var angle = lerp(arc_start_angle, arc_end_angle, t)
		var dest = Vector2(radius, 0).rotated(angle) + menu_offset

		tw.tween_property(b, "position", dest, speed).from(Vector2.ZERO).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(b, "scale", button_scale, speed).from(hidden_scale).set_trans(Tween.TRANS_LINEAR)

func hide_menu():
	active = false
	var tw = create_tween().set_parallel()
	tw.finished.connect(_on_tween_finished)

	for b in $Buttons.get_children():
		tw.tween_property(b, "position", Vector2.ZERO, speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_property(b, "scale", hidden_scale, speed).set_trans(Tween.TRANS_LINEAR)


func _on_paw_pressed():
	# Example: Trigger a pet interaction or animation
	print("Paw button pressed - petting the character!")
	# Add your petting logic here, e.g., play animation or sound
	hide_menu()


func _on_info_pressed():
	# Example: Show game info or open a dialog
	print("Info button pressed - showing game information!")
	# Add your info display logic here
	hide_menu()


func _on_quit_pressed():
	# Example: Quit the game
	print("Quit button pressed - exiting game!")
	get_tree().quit()
