extends Node2D

# ⚙️ Drag and drop your nodes here in the Inspector
@onready var animated_sprite: AnimatedSprite2D = $backspritetext
@onready var tutorial_label: RichTextLabel = $text_tutorial
@onready var starcheck: Area2D = $starcheck
@onready var starcheck2: Area2D = $starcheck2
@onready var starcheck3: Area2D = $starcheck3
@onready var Waves = get_tree().current_scene.get_node("way_3/Line2D") 
@onready var fade_screen: Sprite2D = $CanvasLayer/BlackScreen # ⬅️ User's BlackScreen reference

# 🛠️ Settings
@export var fade_in_duration: float = 4# Duration for the fade-in effect
@export var fade_out_duration: float = 3.0 # Duration for the fade-out effect at the end
@export var scale_duration: float = 1.0
@export var text_speed: float = 0.06
@export var wait_between_messages: float = 1.7
@export var fade_duration: float = 0.1
@export var pause_duration_5s: float = 5.0

# 📝 Font settings
@export var font_path: String = "res://beatcheck/Computerfont.ttf"
@export var font_size: int = 24

# ✨ Star oscillation settings - HORIZONTAL (X)
@export var star_oscillation_speed_x: float = .3
@export var star_oscillation_amplitude_x: float = 300.0

# ✨ Star oscillation settings - VERTICAL (Y)
@export var star_oscillation_speed_y: float = 2.2
@export var star_oscillation_amplitude_y: float = 500.0

# Star initial positions
var star1_initial_x: float = 0.0
var star1_initial_y: float = 0.0
var star2_initial_x: float = 0.0
var star2_initial_y: float = 0.0
var star3_initial_x: float = 0.0
var star3_initial_y: float = 0.0

# Star time offsets for different patterns
var star1_time_x: float = 0.0
var star1_time_y: float = 0.0
var star2_time_x: float = .2
var star2_time_y: float = .4
var star3_time_x: float = .4
var star3_time_y: float = .6

# 🎯 Checkpoint settings
@export var required_acrobacy_points: float = 100000.0
@export var required_stars: int = 3

# 📦 Message queues for phases
const MESSAGES_INTRO = [
	"Incoming transmission...",
	"Hello Rookie !",
	"I see you've come to compete on the Soundriders exhibition ",
	"First you will need to know your vehicle",
	"What you are riding on is a certified B-AH3450",
	"...",
	"Uh... well... you can just call it Sound-Cycle",
	"Press up key arrow to accelerate and down key to increment gravity pull",
	"Give it a try and collect the stars!"
]

const MESSAGES_PHASE_2_BOOST = [
	"...",
	"Oh ! Hahaha, forgot to mention", 
	"Boost yourself up and mantain height by doing tricks !",
	"Try pressing S and F for tricks ",
	"And spacebar for your upwards boost !"
]

const MESSAGES_PHASE_3_ACROBACY = [
	"Nice! You're getting the hang of it!",
	"Try reaching 100,000 points!",
	"Make COMBOS to MULTIPLY your score",
	"But make sure you LAND before losing your combo..."
]

const MESSAGES_COMPLETE = [
	"Wow !",
	"That was fast rider !",
	"I think your training is over... continue to amaze me on the soundwaves !"
]

# 📝 Tutorial configuration map
enum PhaseName {
	INTRO,
	PAUSE_5S,
	BOOST_TALK,
	STARS,
	ACROBACY,
	FINAL_MESSAGE, # Phase for displaying the final message
	FINAL_CLEANUP # The actual end state (cleanup)
}

# ⚠️ FIX: Changed const to var because direct function references (Callables) are not allowed in const dictionaries in Godot 4.x
var TUTORIAL_PHASES = {
	PhaseName.INTRO: {
		"type": "TALK",
		"messages": MESSAGES_INTRO,
		"next_phase": PhaseName.PAUSE_5S,
	},
	PhaseName.PAUSE_5S: {
		"type": "WAIT",
		"wait_time": 5.0,
		"completion_check": check_time_passed,
		"next_phase": PhaseName.BOOST_TALK,
		"on_enter": on_enter_pause,
	},
	PhaseName.BOOST_TALK: {
		"type": "TALK",
		"messages": MESSAGES_PHASE_2_BOOST,
		"next_phase": PhaseName.STARS,
		"on_enter": on_enter_stars_talk,
	},
	PhaseName.STARS: {
		"type": "WAIT",
		"completion_check": check_star_collection,
		"next_phase": PhaseName.ACROBACY,
		"on_enter": on_enter_stars_wait,
	},
	PhaseName.ACROBACY: {
		"type": "TALK_WAIT",
		"messages": MESSAGES_PHASE_3_ACROBACY,
		"completion_check": check_acrobacy_points,
		"next_phase": PhaseName.FINAL_MESSAGE, # Leads to the final message phase
		"on_enter": on_enter_acrobacy,
	},
	PhaseName.FINAL_MESSAGE: { # Phase for final message display
		"type": "TALK",
		"messages": MESSAGES_COMPLETE,
		"next_phase": PhaseName.FINAL_CLEANUP, # Leads to final cleanup
		"on_enter": on_enter_final_message,
	},
	PhaseName.FINAL_CLEANUP: { # Final cleanup phase
		"type": "COMPLETE",
		"on_enter": tutorial_complete,
	},
}

# ➡️ Tutorial state
var current_phase_name: PhaseName = PhaseName.INTRO
var current_config: Dictionary = {}
var current_message_index: int = 0
var full_text: String = ""
var current_char: int = 0
var is_typing: bool = false
var is_advancing: bool = false
var is_talking: bool = false
var wait_timer: float = 0.0

# 🕹️ Tracking player actions
var stars_collected: int = 0
var initial_acrobacy: float = 0.0
var has_comboed = false

# ==============================================================================
# 🚀 Godot Lifecycle Methods
# ==============================================================================

func _ready():
	
	# 1. INITIALIZE SPRITE AND TEXT TO STARTING STATE (As requested) 
	animated_sprite.visible = true
	animated_sprite.scale = Vector2(0, 1) # ⬅️ Sprite starts at 0 horizontal scale
	tutorial_label.text = ""             # ⬅️ Text starts empty
	
	# 2. Start the visual fade-in effect
	await start_fade_in()
	
	# 3. Initialize other components after the fade
	Waves.set_wave_config(0)
	
	if animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.get_animation_names().size() > 0:
		animated_sprite.play()
	
	tutorial_label.modulate = Color(0.0, 0.743, 0.138, 1.0)
	tutorial_label.visible = true
	apply_custom_font()
	
	if starcheck:
		star1_initial_x = starcheck.position.x
		star1_initial_y = starcheck.position.y
		starcheck.area_entered.connect(_on_starcheck_area_entered)
	if starcheck2:
		star2_initial_x = starcheck2.position.x
		star2_initial_y = starcheck2.position.y
		starcheck2.area_entered.connect(_on_starcheck_2_area_entered)
	if starcheck3:
		star3_initial_x = starcheck3.position.x
		star3_initial_y = starcheck3.position.y
		starcheck3.area_entered.connect(_on_starcheck_3_area_entered)
	
	# 4. Start the tutorial phases
	advance_phase(current_phase_name)

func _process(delta):
	
	if current_phase_name == PhaseName.STARS:
		_oscillate_stars(delta)
	
	if current_config.has("type"):
		match current_config.type:
			"WAIT":
				if current_phase_name == PhaseName.PAUSE_5S:
					wait_timer += delta
					current_config.completion_check.call()
				elif current_phase_name == PhaseName.STARS:
					current_config.completion_check.call()
			"TALK_WAIT":
				# Solo verificar cuando NO está hablando
				if not is_talking:
					current_config.completion_check.call()

# ==============================================================================
# 🎬 Visual Effects and Utility (Fade-In Function)
# ==============================================================================

func start_fade_in():
	"""Fades the black Sprite2D from opaque to transparent by animating its modulate alpha."""
	if not is_instance_valid(fade_screen):
		push_error("FadeScreen (Sprite2D) node not found. Cannot perform fade-in.")
		return
	
	# Ensure the fade screen starts fully opaque (alpha = 1.0)
	var initial_color = fade_screen.modulate
	initial_color.a = 2.0
	fade_screen.modulate = initial_color
	fade_screen.visible = true
	
	var fade_tween = create_tween()
	fade_tween.set_trans(Tween.TRANS_LINEAR)
	
	# Fade the alpha from 1.0 (opaque) to 0.0 (transparent)
	fade_tween.tween_property(fade_screen, "modulate:a", 0.0, fade_in_duration)
	
	await fade_tween.finished
	
	# Keep the fade screen but make it invisible (we'll need it for fade out)


func start_fade_out():
	"""Fades the black Sprite2D from transparent to opaque at the end of the tutorial."""
	if not is_instance_valid(fade_screen):
		push_error("FadeScreen (Sprite2D) node not found. Cannot perform fade-out.")
		return
	
	# Make sure the fade screen is visible and starts transparent
	fade_screen.visible = true
	var initial_color = fade_screen.modulate
	initial_color.a = 0.0
	fade_screen.modulate = initial_color
	
	var fade_tween = create_tween()
	fade_tween.set_trans(Tween.TRANS_LINEAR)
	
	# Fade the alpha from 0.0 (transparent) to 1.0 (opaque)
	fade_tween.tween_property(fade_screen, "modulate:a", 1.0, fade_out_duration)
	
	await fade_tween.finished
	
	print("Fade out complete - Ready for scene change")


# ==============================================================================
# ➡️ Phase Management
# ==============================================================================

func advance_phase(phase_name: PhaseName):
	if is_advancing:
		return
	is_advancing = true
	
	if phase_name == PhaseName.FINAL_CLEANUP:
		current_phase_name = phase_name
		current_config = TUTORIAL_PHASES[phase_name]
		current_config.on_enter.call()
		is_advancing = false
		return
	
	var next_config = TUTORIAL_PHASES.get(phase_name)
	if next_config == null:
		push_error("Tutorial phase not found: ", phase_name)
		is_advancing = false
		return
	
	if current_phase_name != phase_name:
		await hide_sprite()
	
	current_phase_name = phase_name
	current_config = next_config
	current_message_index = 0
	
	if current_config.has("on_enter"):
		current_config.on_enter.call()
	
	if current_config.type == "TALK" or current_config.type == "TALK_WAIT":
		await animate_sprite()
		is_talking = true
		show_next_message()
	
	is_advancing = false

# ==============================================================================
# 💬 Talking Sequence (TALK type phases)
# ==============================================================================

func show_next_message():
	var current_queue = current_config.get("messages", [])
	
	if current_message_index >= current_queue.size():
		print("✅ Finished talking in phase: ", current_phase_name)
		is_talking = false
		
		# Si es una fase TALK_WAIT, ocultar sprite y texto pero NO avanzar automáticamente
		# Dejar que el completion_check en _process lo maneje
		if current_config.type == "TALK_WAIT":
			await hide_sprite()
		elif current_config.type == "TALK":
			advance_phase(current_config.get("next_phase", PhaseName.FINAL_CLEANUP))
		return
	
	var message = current_queue[current_message_index]
	
	if current_message_index > 0:
		var fade_out = create_tween()
		fade_out.tween_property(tutorial_label, "modulate:a", 0.0, fade_duration)
		await fade_out.finished
	
	tutorial_label.text = ""
	full_text = message
	
	if current_message_index > 0 or current_message_index == 0 and not is_advancing:
		var fade_in = create_tween()
		fade_in.tween_property(tutorial_label, "modulate:a", 1.0, fade_duration)
		await fade_in.finished
	
	await type_text()
	
	current_message_index += 1
	await get_tree().create_timer(wait_between_messages).timeout
	
	show_next_message()

func type_text():
	is_typing = true
	current_char = 0
	if has_node("voice1"):
		$voice1.play()
	
	while current_char < full_text.length():
		tutorial_label.text += full_text[current_char]
		current_char += 1
		await get_tree().create_timer(text_speed).timeout
	
	is_typing = false
	if has_node("voice1"):
		$voice1.stop()

# ==============================================================================
# 🎬 Visual Effects and Utility
# ==============================================================================

func animate_sprite():
	# Ensure modulation is visible for the text fade in
	tutorial_label.modulate.a = 0.0
	var fade_text = create_tween()
	fade_text.tween_property(tutorial_label, "modulate:a", 1.0, fade_duration)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(animated_sprite, "scale:x", 1.0, scale_duration)
	await tween.finished
	await get_tree().create_timer(0.3).timeout

func hide_sprite():
	# Fade out text
	var fade_text = create_tween()
	fade_text.tween_property(tutorial_label, "modulate:a", 0.0, fade_duration)
	
	# Scale out sprite
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(animated_sprite, "scale:x", 0.0, scale_duration)
	
	await tween.finished
	tutorial_label.text = ""

func _oscillate_stars(delta):
	if starcheck and is_instance_valid(starcheck):
		Waves.set_wave_config(1)
		# Oscilar en X
		star1_time_x += delta * star_oscillation_speed_x
		var offset_x1 = sin(star1_time_x) * star_oscillation_amplitude_x
		starcheck.position.x = star1_initial_x + offset_x1
		
		# Oscilar en Y
		star1_time_y += delta * star_oscillation_speed_y
		var offset_y1 = sin(star1_time_y) * star_oscillation_amplitude_y
		starcheck.position.y = star1_initial_y + offset_y1
		
	if starcheck2 and is_instance_valid(starcheck2):
		# Oscilar en X
		star2_time_x += delta * star_oscillation_speed_x
		var offset_x2 = sin(star2_time_x) * star_oscillation_amplitude_x
		starcheck2.position.x = star2_initial_x + offset_x2
		
		# Oscilar en Y
		star2_time_y += delta * star_oscillation_speed_y
		var offset_y2 = sin(star2_time_y) * star_oscillation_amplitude_y
		starcheck2.position.y = star2_initial_y + offset_y2
	
	if starcheck3 and is_instance_valid(starcheck3):
		# Oscilar en X
		star3_time_x += delta * star_oscillation_speed_x
		var offset_x3 = sin(star3_time_x) * star_oscillation_amplitude_x
		starcheck3.position.x = star3_initial_x + offset_x3
		
		# Oscilar en Y
		star3_time_y += delta * star_oscillation_speed_y
		var offset_y3 = sin(star3_time_y) * star_oscillation_amplitude_y
		starcheck3.position.y = star3_initial_y + offset_y3

func apply_custom_font():
	if ResourceLoader.exists(font_path):
		var custom_font = load(font_path)
		if custom_font:
			tutorial_label.add_theme_font_override("normal_font", custom_font)
			tutorial_label.add_theme_font_size_override("normal_font_size", font_size)

# ==============================================================================
# 📢 Star Signals & Collection
# ==============================================================================

func _collect_star(star_node: Area2D, star_name: String):
	if current_phase_name == PhaseName.STARS and is_instance_valid(star_node):
		stars_collected += 1
		
		var anim_sprite = star_node.get_node_or_null("AnimatedSprite2D")
		if anim_sprite:
			anim_sprite.play("get")
		
		var sound_node = get_node_or_null(star_name)
		if sound_node:
			sound_node.play()
		
		await get_tree().create_timer(0.2).timeout
		
		if sound_node:
			sound_node.stop()
		
		star_node.queue_free()

func _on_starcheck_area_entered(area: Area2D) -> void:
	if area.is_in_group("player") or area.name == "Player":
		_collect_star(starcheck, "star")
		starcheck = null

func _on_starcheck_2_area_entered(area: Area2D) -> void:
	if area.is_in_group("player") or area.name == "Player":
		_collect_star(starcheck2, "star2")
		starcheck2 = null

func _on_starcheck_3_area_entered(area: Area2D) -> void:
	if area.is_in_group("player") or area.name == "Player":
		_collect_star(starcheck3, "star3")
		starcheck3 = null

# ==============================================================================
# 🚦 Phase Entry/Wait Logic (on_enter functions and completion checks)
# ==============================================================================

# --- PAUSE_5S Phase (WAIT) ---

func on_enter_pause():
	wait_timer = 0.0

func check_time_passed():
	if wait_timer >= pause_duration_5s:
		advance_phase(current_config.next_phase)

# --- BOOST_TALK Phase (TALK) ---

func on_enter_stars_talk():
	pass

# --- STARS Phase (WAIT) ---

func on_enter_stars_wait():
	pass

func check_star_collection():
	if stars_collected >= required_stars:
		advance_phase(current_config.next_phase)

# --- ACROBACY Phase (TALK_WAIT) ---

func on_enter_acrobacy():
	# Guardar los puntos iniciales cuando comienza esta fase
	initial_acrobacy = PlayerState.get_points()
	print("🎯 Starting ACROBACY phase. Initial points: ", initial_acrobacy)
	print("🎯 Required points: ", required_acrobacy_points)

func check_acrobacy_points():
	var current_points = PlayerState.get_points()
	
	# Debug cada 60 frames (aproximadamente cada segundo a 60 FPS)
	if Engine.get_process_frames() % 60 == 0:
		print("🔍 Checking acrobacy: ", current_points, " / ", required_acrobacy_points)
	
	if current_points >= required_acrobacy_points:
		print("✅ Acrobacy completed! Total points: ", current_points)
		advance_phase(current_config.next_phase)

# --- FINAL_MESSAGE Phase (Final Message) ---

func on_enter_final_message():
	pass

# --- FINAL_CLEANUP Phase (Final Cleanup) ---

func tutorial_complete():
	# Final cleanup: Hide UI elements
	await hide_sprite()
	
	animated_sprite.visible = false
	tutorial_label.visible = false
	
	print("Tutorial System Fully Shut Down.")
	
	# Fade to black
	await start_fade_out()
	
	# TODO: Agregar aquí el cambio de escena
	# Ejemplo:
	# get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	# o
	get_tree().change_scene_to_packed(preload("res://menu de exhibicion/exhibition_menu.tscn"))
	
	print("Ready to change scene!")

# ==============================================================================
# ⏭️ Skip Logic
# ==============================================================================

func skip_to_next_message():
	if is_typing:
		tutorial_label.text = full_text
		is_typing = false
	elif current_phase_name == PhaseName.PAUSE_5S:
		advance_phase(current_config.next_phase)

func skip_all():
	advance_phase(PhaseName.FINAL_CLEANUP)

func _input(event):
	if event.is_action_pressed("skip_tutorial"):
		skip_to_next_message()
	
	# 🐛 DEBUG: Presiona P para mostrar debug info
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		print("⚡ Current Phase: ", current_phase_name)
		print("⚡ Current Points: ", PlayerState.get_points())
		print("⚡ Required Points: ", required_acrobacy_points)
		print("⚡ Stars Collected: ", stars_collected, " / ", required_stars)
		print("⚡ Is Talking: ", is_talking)
		print("⚡ Is Advancing: ", is_advancing)
		print("⚡ Phase Type: ", current_config.get("type", "N/A"))

	
	# 🐛 DEBUG: Presiona O para saltar a ACROBACY
	if event is InputEventKey and event.pressed and event.keycode == KEY_O:
		print("⚡ DEBUG: Skipping to ACROBACY phase")
		advance_phase(PhaseName.ACROBACY)
	
	# 🐛 DEBUG: Presiona I para saltar a FINAL_MESSAGE
	if event is InputEventKey and event.pressed and event.keycode == KEY_I:
		print("⚡ DEBUG: Skipping to FINAL_MESSAGE phase")
		advance_phase(PhaseName.FINAL_MESSAGE)
	
	# 🐛 DEBUG: Presiona U para completar tutorial inmediatamente
	if event is InputEventKey and event.pressed and event.keycode == KEY_U:
		print("⚡ DEBUG: Skipping to END")
		advance_phase(PhaseName.FINAL_CLEANUP)
