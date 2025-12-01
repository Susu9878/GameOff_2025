extends Control

# 🎯 HIGH SCORE UI CONTROLLER
# Maneja la interfaz de ingreso y visualización de scores

@onready var message_label: RichTextLabel = $Node2D/RichTextLabel
@onready var input_display_label: RichTextLabel = $Node2D/RichTextLabel2

enum State {
	SHOWING_SCORE,
	ENTERING_INITIALS,
	SHOWING_HIGHSCORES
}

var current_state: State = State.SHOWING_SCORE
var player_score: int = 0
var player_initials: String = ""
var current_initial_index: int = 0
const MAX_INITIALS = 3

# Configuración de estilo
@export_group("Style")
@export var font_path: String = "res://way/Sprintura Demo.otf"
@export var font_size: int = 40
@export var message_color: Color = Color.WHITE
@export var input_color: Color = Color.GREEN
@export var outline_size: int = 4
@export var outline_color: Color = Color.BLACK

# Referencia al sistema de high scores
var highscore_system: Node

func _ready():
	# Obtener sistema de high scores
	if has_node("/root/HighScoreSystem"):
		highscore_system = get_node("/root/HighScoreSystem")
	else:
		push_error("HighScoreSystem AutoLoad no encontrado!")
		return
	
	apply_styles()
	
	# Obtener el score del jugador desde PlayerState
	player_score = PlayerState.get_points() if has_node("/root/PlayerState") else 0
	
	start_sequence()

func apply_styles():
	"""Aplica estilos a los labels"""
	for label in [message_label, input_display_label]:
		if ResourceLoader.exists(font_path):
			var custom_font = load(font_path)
			if custom_font:
				label.add_theme_font_override("normal_font", custom_font)
				label.add_theme_font_size_override("normal_font_size", font_size)
		
		label.add_theme_constant_override("outline_size", outline_size)
		label.add_theme_color_override("font_outline_color", outline_color)
	
	message_label.add_theme_color_override("default_color", message_color)
	input_display_label.add_theme_color_override("default_color", input_color)

func start_sequence():
	"""Inicia la secuencia de high score"""
	current_state = State.SHOWING_SCORE
	show_player_score()

func show_player_score():
	"""Muestra el score del jugador"""
	message_label.clear()
	message_label.add_text("[center]YOUR SCORE[/center]")
	
	input_display_label.clear()
	input_display_label.add_text("[center]%d[/center]" % player_score)
	
	# Esperar 2 segundos y luego verificar si es high score
	await get_tree().create_timer(2.0).timeout
	
	if highscore_system.is_high_score(player_score):
		start_initial_entry()
	else:
		show_not_highscore()

func show_not_highscore():
	"""Muestra mensaje cuando no califica y luego muestra la tabla"""
	message_label.clear()
	message_label.add_text("[center]NOT A HIGH SCORE[/center]")
	
	await get_tree().create_timer(2.0).timeout
	show_highscores()

func start_initial_entry():
	"""Inicia el proceso de entrada de iniciales"""
	current_state = State.ENTERING_INITIALS
	player_initials = ""
	current_initial_index = 0
	
	message_label.clear()
	message_label.add_text("[center]ENTER YOUR INITIALS[/center]")
	
	update_initials_display()

func update_initials_display():
	"""Actualiza la visualización de las iniciales"""
	input_display_label.clear()
	
	var display = "[center]"
	
	# Mostrar las iniciales ya ingresadas
	for i in range(MAX_INITIALS):
		if i < player_initials.length():
			display += player_initials[i]
		elif i == current_initial_index:
			display += "_"  # Cursor
		else:
			display += " "
		
		if i < MAX_INITIALS - 1:
			display += " "
	
	display += "[/center]"
	input_display_label.add_text(display)

func _input(event):
	if current_state != State.ENTERING_INITIALS:
		return
	
	if event is InputEventKey and event.pressed:
		var key_code = event.keycode
		
		# A-Z keys
		if key_code >= KEY_A and key_code <= KEY_Z:
			var letter = char(key_code)
			player_initials += letter
			current_initial_index += 1
			update_initials_display()
			
			# Si completó las 3 iniciales
			if player_initials.length() >= MAX_INITIALS:
				finish_initial_entry()
		
		# Backspace para borrar
		elif key_code == KEY_BACKSPACE and player_initials.length() > 0:
			player_initials = player_initials.substr(0, player_initials.length() - 1)
			current_initial_index = max(0, current_initial_index - 1)
			update_initials_display()

func finish_initial_entry():
	"""Finaliza la entrada de iniciales y guarda el score"""
	# Asegurar que tenga 3 caracteres
	while player_initials.length() < MAX_INITIALS:
		player_initials += "A"
	
	# Guardar el score
	var position = highscore_system.add_score(player_initials, player_score)
	
	print("Score saved! Position: %d" % position)
	
	# Mostrar mensaje de confirmación
	message_label.clear()
	if position > 0 and position <= 10:
		message_label.add_text("[center]RANK #%d![/center]" % position)
	
	# Esperar un momento y mostrar la tabla
	await get_tree().create_timer(1.5).timeout
	show_highscores()

func show_highscores():
	"""Muestra la tabla de high scores"""
	current_state = State.SHOWING_HIGHSCORES
	
	message_label.clear()
	message_label.add_text("[center]HIGH SCORES[/center]")
	
	input_display_label.clear()
	var scores_text = highscore_system.format_scores_display()
	input_display_label.add_text("[center]%s[/center]" % scores_text)
	
	# Después de 8 segundos, volver al menú principal
	await get_tree().create_timer(8.0).timeout
	return_to_menu()

func return_to_menu():
	"""Vuelve al menú principal"""
	# Resetear PlayerState
	if has_node("/root/PlayerState"):
		PlayerState.reset_points()
		PlayerState.reset_combo()
	
	# Cambiar a la escena del menú principal
	# get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	print("Returning to menu...")
