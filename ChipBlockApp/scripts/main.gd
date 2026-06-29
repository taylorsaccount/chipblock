extends Node2D
var move_speed = 5
var direction = Vector2(1, 0) 
var is_chilling = false
var current_states 
enum cat_states{WALK, SLEEP, IDLE}
var selected = false
var mouse_offset = Vector2(0, 0)

var dir
var state_timer = 0.0
var walk_duration = 4.0
var sleep_duration = 8.0
var idle_duration = 3.0

var mywin = preload("res://mywindow.tscn")
var dialogue_window
var dialogue_manager
var dialogue_hide_timer: Timer
var _dialogue_panel

@onready var normal_sound = preload("res://voices/normal.mp3")
@onready var scared_sound = preload("res://voices/scared.mp3")
@onready var angry_sound = preload("res://voices/angry.mp3")

var settings = preload("res://settings.tscn")
var swin
var agreewin = preload("res://window.tscn")
var awin
var infowin = preload("res://infowindow.tscn")
var iwin
var notif = preload("res://voices/universfield-system-notification-02-352442.mp3")
@onready var notif_player: AudioStreamPlayer = $NotifPlayer

var tracker_stats := ConfigFile.new()
var stats_path := "user://tracker_stats.cfg"

   


func _input(event):
	# Handle left mouse button press
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		if swin != null:
			swin.visible = !swin.visible
		
		if not is_chilling:
			start_chilling()
			
		# Show the dialogue window when clicked
		show_click_dialogue()
			
			
var timer_time :float = 5.0

var mood_active: bool = false
var mood_timer: float = 0.0
const MOOD_DURATION: float = 5.0
var _current_mood: String = ""
const _TRACKER_MOODS := ["nervous", "scared", "panic", "happy"]

var is_expanded: bool = false
var fat_overlay: Window = null
var _dbg_t: float = 0.0
var _last_mask_anim: String = ""

# Function to show the dialogue window with specific lines - can be called from click or other events
func show_dialogue_window(lines: Array[String], speech_sfx: AudioStream = null):
	dialogue_window.visible = true
	DisplayServer.window_move_to_foreground(dialogue_window.get_window_id())
	dialogue_manager.start_dialogue(lines, speech_sfx)
	dialogue_hide_timer.start(timer_time)

# Specific dialogue for clicking
func show_click_dialogue():
	show_dialogue_window(["Hey!!!!!!", "Dont touch me!!!!!"], angry_sound)

# Function to hide the dialogue window
func hide_dialogue_window():
	dialogue_window.visible = false

func random_generation():
	# Weighted random: 75% sleep, 15% walk, 10% idle
	var rand_value = randf()
	if rand_value < 0.75:
		dir = 0  # SLEEP
		state_timer = sleep_duration
		print("State: SLEEP Duration: ", state_timer)
	elif rand_value < 0.9:
		dir = 1  # WALK
		state_timer = walk_duration
		print("State: WALK Duration: ", state_timer)
	else:
		dir = 2  # IDLE
		state_timer = idle_duration
		print("State: IDLE Duration: ", state_timer)
	random_direction()
	
func random_direction():
	match dir:
		0:
			current_states = cat_states.SLEEP
		1:
			current_states = cat_states.WALK
		2: current_states = cat_states.IDLE
	update_state()

func update_state():
	if mood_active:
		print("[update_state] skipped (mood_active=true)")
		return
	$AnimatedSprite2D.offset = Vector2(0, 0)
	match current_states:
		cat_states.WALK:
			move_speed = 5
			$AnimatedSprite2D.offset = Vector2(0, 0)
			$AnimatedSprite2D.play("walk")
		cat_states.SLEEP:
			move_speed = 0
			$AnimatedSprite2D.offset = Vector2(0, 0)
			$AnimatedSprite2D.play("sleep")
		cat_states.IDLE:
			move_speed = 0
			$AnimatedSprite2D.offset = Vector2(0, 0)
			$AnimatedSprite2D.play("look_around")


func _ready() -> void:

	tracker_stats.load(stats_path)
	var ws_node = preload("res://scripts/websocket.gd").new()
	add_child(ws_node)
	ws_node.mood_changed.connect(pet_react)
	ws_node.tracker_data_updated.connect(func(url, trackers, fingerprinters):
		var total = tracker_stats.get_value("stats", "total_trackers", 0)
		total += trackers.size()
		tracker_stats.set_value("stats", "total_trackers", total)
		tracker_stats.save(stats_path)
		if swin != null:
			swin.update_tracker_display(url, trackers, fingerprinters, total)
			swin.update_feed_label(total)
	)


	random_generation()
	update_state()
	$Timer.wait_time = state_timer
	$Timer.start()
	if is_chilling:return
	
	
	var window = get_window()
	
	get_viewport().transparent_bg = true
	window.transparent = true
	
	window.borderless = true
	
	window.always_on_top = true
	
	window.unresizable = false
	
	var usable_rect = DisplayServer.screen_get_usable_rect()
	
	var target_y = usable_rect.end.y - window.size.y
	
	var target_x = usable_rect.end.x - window.size.x
	
	window.position = Vector2i(target_x, target_y)
	
	_update_mouse_mask()
	$AnimatedSprite2D.frame_changed.connect(_update_mouse_mask)
	
	
	
	get_viewport().set_embedding_subwindows(false)
	swin = settings.instantiate()
	add_child(swin)
	swin.visible = false
	var screen_size = DisplayServer.screen_get_size()
	swin.position = Vector2i(screen_size.x / 2 - 317, screen_size.y / 2 - 344)
	swin.feed_pressed.connect(func():
		tracker_stats.set_value("stats", "total_trackers", 0)
		tracker_stats.save(stats_path)
		swin.update_feed_label(0)
		pet_react("eat")
	)

	# Instantiate the dialogue window and add it as a child
	dialogue_window = mywin.instantiate()
	dialogue_window.unresizable = false
	add_child(dialogue_window)
	swin.mywindow = dialogue_window
	
	# Get reference to the dialogue manager
	dialogue_manager = dialogue_window.get_node("HBoxContainer/DialogueManager")
	_dialogue_panel = dialogue_window.get_node("HBoxContainer/DialogueManager/DialogueBox/PanelContainer")
	swin.scwin.tritanopia_toggled.connect(_on_tritanopia_toggled)

	# Set window properties
	
	dialogue_window.title = "Chip wants to talk"
	
	# Hide the window initially
	dialogue_window.visible = false
	# Connect the close button to hide the window
	dialogue_window.close_requested.connect(hide_dialogue_window)

	dialogue_hide_timer = Timer.new()
	dialogue_hide_timer.one_shot = true
	dialogue_hide_timer.timeout.connect(hide_dialogue_window)
	add_child(dialogue_hide_timer)
		
	
	
	Engine.max_fps = 30
	
	
func _process(_delta):
	if mood_active:
		mood_timer -= _delta
		_dbg_t += _delta
		if _dbg_t >= 1.0:
			_dbg_t = 0.0
		if mood_timer <= 0:
			mood_active = false
			restore_size()
			update_state()

	if selected:
		followMouse()
	
	var window = get_window()
	var bubble_h = _dialogue_panel.size.y * _dialogue_panel.scale.y
	dialogue_window.position = Vector2(
		window.position.x - (dialogue_window.size.x - window.size.x) / 2.0,
		window.position.y - bubble_h +40
	)
	if not mood_active:
		var move_vector = Vector2i(direction*move_speed)
		window.position += move_vector
		var usable_rect = DisplayServer.screen_get_usable_rect()
		if window.position.x + window.size.x > usable_rect.end.x:
			direction.x = -1
			$AnimatedSprite2D.flip_h = true
		elif window.position.x < usable_rect.position.x:
			direction.x = 1
			$AnimatedSprite2D.flip_h = false

func _update_mouse_mask():
	if is_expanded:
		return
	var anim = $AnimatedSprite2D
	var texture = anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)

	var image: Image
	var tex_size: Vector2
	var do_translate := false
	var translate_offset := Vector2.ZERO

	if texture is AtlasTexture:
		if anim.animation == _last_mask_anim:
			return
		_last_mask_anim = anim.animation
		var region: Rect2 = texture.region
		image = texture.get_image().get_region(Rect2i(region))
		tex_size = region.size
		do_translate = true
		translate_offset = anim.position + anim.offset - region.size / 2.0
	else:
		_last_mask_anim = ""
		image = texture.get_image()
		tex_size = texture.get_size()

	if anim.flip_h:
		image.flip_x()

	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(image)
	var polygons := bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, tex_size), 0.1)

	if do_translate:
		var moved: Array[PackedVector2Array] = []
		for poly in polygons:
			var p := PackedVector2Array()
			for v: Vector2 in poly:
				p.append(v + translate_offset)
			moved.append(p)
		DisplayServer.window_set_mouse_passthrough(moved)
	else:
		DisplayServer.window_set_mouse_passthrough(polygons)
	
func start_chilling():
	if mood_active:
		print("[start_chilling] skipped (mood_active=true)")
		return
	is_chilling = true
	$AnimatedSprite2D.play("idle")
	move_speed = 0
	await get_tree().create_timer(3.0).timeout
	
	is_chilling = false 
	update_state()

	
func _on_timer_timeout():
	random_generation()
	update_state()
	$Timer.wait_time = state_timer
	$Timer.start()
	
	
	if current_states == cat_states.SLEEP:
		show_dialogue_window(["[wave amp=30 freq=2 speed=3 ease=2.0]Zzz...[/wave]"])
	


func pet_react(mood: String):
	print("[pet_react] called with: ", mood, " | mood_active=", mood_active, " | mood_timer=", mood_timer)
	if mood_active and mood_timer > MOOD_DURATION:
		# news overrides tracker moods; tracker moods cannot override news
		var news_beats_tracker = (mood == "news" and _current_mood in _TRACKER_MOODS)
		if not news_beats_tracker:
			print("[pet_react] BLOCKED (sticky mood still active)")
			return
	if _current_mood == "news" and mood_active and mood in _TRACKER_MOODS:
		return
	_current_mood = mood
	mood_active = true
	mood_timer = MOOD_DURATION
	match mood:
		
		"nervous":
			if iwin == null:
				iwin = infowin.instantiate()
				add_child(iwin)
				iwin.set_font_size(swin.scwin.info_font_size)
				if swin.scwin.tritanopia_enabled:
					iwin.set_tritanopia(swin.scwin._purple_mat)
				iwin.position = Vector2i(dialogue_window.position) + Vector2i(-200, -500)
				iwin.set_text.call_deferred("Nothing too worrying, though keep in mind that third-party tracking data can still pile and be used to target you in various ways. Cookie-blocker extensions or another browser would be helpful, as cookies can be easily blocked. Check your browser settings, you might find some options to block them!.")
				notif_player.stream = notif
				notif_player.play()
				var iwin_timer = get_tree().create_timer(10.0)
				iwin_timer.timeout.connect(func():
					if iwin != null:
						iwin.queue_free()
						iwin = null
				)
			


			$AnimatedSprite2D.offset = Vector2(0, 40)
			show_dialogue_window(["[wave amp=30 freq=5 speed=3 ease=2.0]There's a tracker or two running :0[/wave]"], scared_sound)
			$AnimatedSprite2D.play("mad_chip")

		"scared":
			mood_timer = 9999.0
			if iwin == null:
				iwin = infowin.instantiate()
				add_child(iwin)
				iwin.set_font_size(swin.scwin.info_font_size)
				if swin.scwin.tritanopia_enabled:
					iwin.set_tritanopia(swin.scwin._purple_mat)
				iwin.position = Vector2i(dialogue_window.position) + Vector2i(-200, -500)
				iwin.set_text.call_deferred("While trackers are worrying, the actual concerns lies with the fingerprinters found, as they are hard to detect, block, delete and function without consent. To avoid being profiled consider privacy focused browsers, extensions or look at your browser settings. Do you want any recommendations?")
				notif_player.stream = notif
				notif_player.play()

			if awin == null:
				awin = agreewin.instantiate()
				add_child(awin)
				awin.position = Vector2i(iwin.position) + Vector2i(-250, -200)
				awin.get_node("Panel/agree").pressed.connect(func():
					mood_active = false
					update_state()
					if iwin != null:
						iwin.set_text("Recommendations vary on browsers, specifically on what privacy means for the user and how easy it is to use. Brave is a great start, as it blocks everything by default. Firefox is another good option, though extensions like uBlock origin will be needed. Open-source options also exist like the Mullvad Browser, LibreWolf, Zen Browser and Waterfox.
You’ll only need extensions if your browser doesnt already block cookies, fingerprinting or ads. But for good overall extensions Privacy Badger and uBlock Origin will do a good job.
Keep in mind that privacy comes at the cost of accessibility, some websites may break, some browsers might be difficult to understand. That is the price for privacy nowadays.")
						var close_timer = get_tree().create_timer(5.0)
						close_timer.timeout.connect(func():
							if iwin != null:
								iwin.queue_free()
								iwin = null
						)
					awin.queue_free()
					awin = null
				)
				awin.get_node("Panel/disagree").pressed.connect(func():
					mood_active = false
					update_state()
					if iwin != null:
						iwin.set_text("Alright, keep the warnings in mind though! ")
						var close_timer = get_tree().create_timer(5.0)
						close_timer.timeout.connect(func():
							if iwin != null:
								iwin.queue_free()
								iwin = null
						)
					awin.queue_free()
					awin = null
				)



			$AnimatedSprite2D.offset = Vector2(0, 40)
			show_dialogue_window(["[pulse freq=1.0 ease=2.0]a few trackers AND fingerprinters were found!! :c[/pulse]"], scared_sound)
			$AnimatedSprite2D.play("scared_chip")
			
		"panic":
			mood_timer = 9999.0
			if iwin == null:
				iwin = infowin.instantiate()
				add_child(iwin)
				iwin.set_font_size(swin.scwin.info_font_size)
				if swin.scwin.tritanopia_enabled:
					iwin.set_tritanopia(swin.scwin._purple_mat)
				iwin.position = Vector2i(dialogue_window.position) + Vector2i(-200, -500)
				iwin.set_text.call_deferred("This website contains more than 10 individual trackers and multiple fingerprinters. While some cookies can be used for accessibility and ease of use, this many alongside the amount of fingerprinters is concerning. I would not recommend browsing without privacy protection.  Have you thought about browsers or extentions? Do you need recommendations?")
				notif_player.stream = notif
				notif_player.play()

			if awin == null:
				awin = agreewin.instantiate()
				add_child(awin)
				awin.position = Vector2i(iwin.position) + Vector2i(-250, -200)
				awin.get_node("Panel/agree").pressed.connect(func():
					mood_active = false
					update_state()
					if iwin != null:
						iwin.set_text("Recommendations vary on browsers, specifically on what privacy means for the user and how easy it is to use. Brave is a great start, as it blocks everything by default. Firefox is another good option, though extensions like uBlock origin will be needed. Open-source options also exist like the Mullvad Browser, LibreWolf, Zen Browser and Waterfox.
You’ll only need extensions if your browser doesnt already block cookies, fingerprinting or ads. But for good overall extensions Privacy Badger and uBlock Origin will do a good job.
Keep in mind that privacy comes at the cost of accessibility, some websites may break, some browsers might be difficult to understand. That is the price for privacy nowadays.")
						var close_timer = get_tree().create_timer(5.0)
						close_timer.timeout.connect(func():
							if iwin != null:
								iwin.queue_free()
								iwin = null
						)
					awin.queue_free()
					awin = null
				)
				awin.get_node("Panel/disagree").pressed.connect(func():
					mood_active = false
					update_state()
					if iwin != null:
						iwin.set_text("Understandable, just keep in mind that you are browsing tracker-heavy sites. Privacy focused browsers like brave or firefox are quite easy to use and set up, it’s worth researching it.")
						var close_timer = get_tree().create_timer(5.0)
						close_timer.timeout.connect(func():
							if iwin != null:
								iwin.queue_free()
								iwin = null
						)
					awin.queue_free()
					awin = null
				)

			$AnimatedSprite2D.offset = Vector2(0, 0)
			show_dialogue_window(["[shake rate=20.0 level=5 connected=1]There’s so many trackers!!!!!!!! AAAAAAAAAAAAA >:0[/shake]"], angry_sound)
			$AnimatedSprite2D.play("mad_surprise_chip")

		"happy":
			$AnimatedSprite2D.offset = Vector2(0, 10)
			show_dialogue_window(["[rainbow freq=1.0 sat=0.8 val=0.8 speed=1.0]YAY there's nothing :3[/rainbow]"], normal_sound)
			$AnimatedSprite2D.play("happy_chip")

		
		"social":
			mood_timer = 9999.0
			var sc = DisplayServer.screen_get_size()
			if iwin == null:
				iwin = infowin.instantiate()
				add_child(iwin)
				iwin.set_font_size(swin.scwin.info_font_size)
				if swin.scwin.tritanopia_enabled:
					iwin.set_tritanopia(swin.scwin._purple_mat)
				iwin.position = Vector2i(sc.x / 2 - 250, sc.y / 2 - 50)
				iwin.set_text.call_deferred("You’ve spent 5 minutes on social media!! Did you do anything productive today? ")
				notif_player.stream = notif
				notif_player.play()

			if awin == null:
				awin = agreewin.instantiate()
				add_child(awin)
				awin.position = Vector2i(sc.x / 2 - 150, sc.y / 2 - 300)
				awin.get_node("Panel/agree").pressed.connect(func():
					mood_active = false
					restore_size()
					if iwin != null:
						iwin.set_text("That’s good, relaxing after some work is understandable then. Just keep in mind that the largest collectors of data nowadays are socials like tiktok, instagram, Facebook etc. These services can still be used, but keep in mind the data they have about you. If you are truly concerned, alternatives like Bluesky exist, functioning as an open-source model that can be self-hosted.")
						var close_timer = get_tree().create_timer(5.0)
						close_timer.timeout.connect(func():
							if iwin != null:
								iwin.queue_free()
								iwin = null
						)
					awin.queue_free()
					awin = null
				)
				awin.get_node("Panel/disagree").pressed.connect(func():
					mood_active = false
					restore_size()
					if iwin != null:
						iwin.set_text("You should probably get off then and get to work! Or do something fun! Social media is designed to keep you glued to your screen, which is achieved by collecting data about you. The algorhythms you may have heard about utilise data to microtarget posts or advertisements.  These can be used for nefarious purposes too, like in the Cambridge Analytica case in 2018. And with AI being a huge industry, and firms like Oracle and Palantir weaponizing data as a service, your data is worth more than ever. Consider using open-source alternatives like Bluesky.")
						var close_timer = get_tree().create_timer(5.0)
						close_timer.timeout.connect(func():
							if iwin != null:
								iwin.queue_free()
								iwin = null
						)
					awin.queue_free()
					awin = null
				)

			$AnimatedSprite2D.play("fat_chip")
			await get_tree().process_frame
			expand_to_screen()
			show_dialogue_window(["[tornado radius=10.0 freq=3.0 connected=1]BOOOO social media is bad for you >:([/tornado]"], normal_sound)

		"news":
			mood_timer = 9999.0
			if iwin == null:
				iwin = infowin.instantiate()
				add_child(iwin)
				iwin.set_font_size(swin.scwin.info_font_size)
				if swin.scwin.tritanopia_enabled:
					iwin.set_tritanopia(swin.scwin._purple_mat)
				iwin.position = Vector2i(dialogue_window.position) + Vector2i(-200, -500)
				iwin.set_text.call_deferred("Are you currently seeing ads? ")
				notif_player.stream = notif
				notif_player.play()

			if awin == null:
				awin = agreewin.instantiate()
				add_child(awin)
				awin.position = Vector2i(iwin.position) + Vector2i(-250, -200)
				awin.get_node("Panel/agree").pressed.connect(func():
					mood_active = false
					update_state()
					if iwin != null:
						iwin.set_text("Well, i assume you dont want to see them, as it would be letting all kinds of cookies and fingerprinters do their job and help microtarget products to you based on your data. Using browsers like Brave, Firefox, Mullvad, or extensions like uBlock Origin will block ads quite effectively and save you a good amount of time.")
						var close_timer = get_tree().create_timer(5.0)
						close_timer.timeout.connect(func():
							if iwin != null:
								iwin.queue_free()
								iwin = null
						)
					awin.queue_free()
					awin = null
				)
				awin.get_node("Panel/disagree").pressed.connect(func():
					mood_active = false
					update_state()
					if iwin != null:
						iwin.set_text("oh, that’s good! Good on you for using a good browser or an extension.")
						var close_timer = get_tree().create_timer(5.0)
						close_timer.timeout.connect(func():
							if iwin != null:
								iwin.queue_free()
								iwin = null
						)
					awin.queue_free()
					awin = null
				)

			$AnimatedSprite2D.offset = Vector2(0, 0)
			show_dialogue_window(["Do you really wanna see ads [wave amp=30 freq=5 speed=3 ease=2.0]?… : p[/wave]"], normal_sound)
			$AnimatedSprite2D.play("mad_surprise_chip")

		"eat":
			mood_timer = 5.0
			$AnimatedSprite2D.offset = Vector2(0, 0)
			show_dialogue_window(["*yum* *nom* *nom* *nom*"], normal_sound)
			$AnimatedSprite2D.play("feed")
			

func expand_to_screen():
	is_expanded = true
	$AnimatedSprite2D.visible = false
	var screen_size = DisplayServer.screen_get_size()

	var anim = $AnimatedSprite2D
	var tex = anim.sprite_frames.get_frame_texture("fat_chip", 0)
	var tex_size = tex.get_size()
	var fit_scale = min(float(screen_size.x) / tex_size.x, float(screen_size.y) / tex_size.y) * 0.9

	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.scale = Vector2(fit_scale, fit_scale)
	sprite.position = Vector2(screen_size) / 2.0

	fat_overlay = Window.new()
	fat_overlay.size = screen_size
	fat_overlay.position = Vector2i(0, 0)
	fat_overlay.transparent = true
	fat_overlay.transparent_bg = true
	fat_overlay.borderless = true
	fat_overlay.always_on_top = true
	fat_overlay.unfocusable = true
	fat_overlay.popup_window = true
	fat_overlay.unresizable = true
	fat_overlay.mouse_passthrough = true
	fat_overlay.add_child(sprite)
	add_child(fat_overlay)
	if iwin != null:
		iwin.grab_focus()
	if awin != null:
		awin.grab_focus()

func restore_size():
	if is_expanded:
		if fat_overlay != null:
			fat_overlay.queue_free()
			fat_overlay = null
		$AnimatedSprite2D.visible = true
		is_expanded = false
		_update_mouse_mask()

func followMouse():
	position = get_global_mouse_position() + mouse_offset

func _on_tritanopia_toggled(enabled: bool, trit_mat: ShaderMaterial, purple_mat: ShaderMaterial) -> void:
	var tm: Material = trit_mat if enabled else null
	var pm: Material = purple_mat if enabled else null
	$AnimatedSprite2D.material = tm
	_dialogue_panel.material = tm
	swin.set_tritanopia(tm, pm)
	if iwin != null:
		iwin.set_tritanopia(pm)
	
