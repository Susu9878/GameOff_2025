extends Node

# Referencias a los nodos UI
@onready var message_label: RichTextLabel = $RichTextLabel
@onready var input_label: RichTextLabel = $RichTextLabel2
@onready var typewriter_sound = $AudioStreamPlayer2D

# Constantes
const HIGHSCORE_FILE_PATH: String = "res://highscores.txt"
const MAX_INITIALS_LENGTH: int = 3
const TOP_PLAYERS_COUNT: int = 10

# Variables de estado
var current_initials: String = ""
var player_score: int = 0
var player_combo: int = 0
var showing_rankings: bool = false

# Variables para el efecto typewriter
var typewriter_text: String = ""
var typewriter_index: int = 0
var typewriter_speed: float = 0.03
var typewriter_timer: float = 0.0
var is_typing: bool = false
var was_typing: bool = false

func _ready():
	# Obtener los datos del último score
	load_last_score()
	
	# Mostrar mensaje inicial con efecto typewriter
	show_input_screen()
	
	# El nodo necesita procesar input
	set_process_input(true)
	set_process(true)

func load_last_score():
	"""Carga el último puntaje del archivo scores.txt"""
	const SCORE_FILE_PATH: String = "res://scores.txt"
	
	if not FileAccess.file_exists(SCORE_FILE_PATH):
		player_score = 0
		player_combo = 0
		return
	
	var file = FileAccess.open(SCORE_FILE_PATH, FileAccess.READ)
	if file == null:
		return
	
	var last_line = ""
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line != "":
			last_line = line
	
	file.close()
	
	# Parsear la última línea
	# Formato: "2024-11-30 14:30:45 | Score: 5000 | Combo: 12 | Acrobacy: 3"
	if last_line != "":
		var parts = last_line.split("|")
		if parts.size() >= 3:
			player_score = parts[1].replace("Score:", "").strip_edges().to_int()
			player_combo = parts[2].replace("Combo:", "").strip_edges().to_int()

func _process(delta):
	"""Procesa el efecto typewriter"""
	if is_typing:
		# Si acaba de empezar a typear, iniciar el audio
		if not was_typing and typewriter_sound:
			typewriter_sound.play()
			was_typing = true
		
		# Si el audio terminó de reproducirse, reiniciarlo
		if typewriter_sound and not typewriter_sound.playing:
			typewriter_sound.play()
		
		typewriter_timer += delta
		
		if typewriter_timer >= typewriter_speed:
			typewriter_timer = 0.0
			
			if typewriter_index < typewriter_text.length():
				message_label.clear()
				message_label.append_text(typewriter_text.substr(0, typewriter_index + 1))
				typewriter_index += 1
			else:
				is_typing = false
	else:
		# Si terminó de typear, detener el audio
		if was_typing and typewriter_sound:
			typewriter_sound.stop()
			was_typing = false

func show_input_screen():
	"""Muestra la pantalla para ingresar iniciales"""
	typewriter_text = "¡CARRERA TERMINADA!\n\n"
	typewriter_text += "Tu Puntuación: %d\n" % player_score
	typewriter_text += "Combo Máximo: %d\n\n" % player_combo
	typewriter_text += "Ingresa tus iniciales (3 letras):"
	
	typewriter_index = 0
	is_typing = true
	message_label.clear()
	
	input_label.clear()
	input_label.append_text("___")

func _input(event):
	if showing_rankings:
		# Si ya está mostrando rankings, esperar Enter para continuar
		if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
			# Aquí puedes cambiar de escena o reiniciar
			get_tree().change_scene_to_file("res://menu de exhibicion/exhibition_menu.tscn")  # Ajusta la ruta
		return
	
	# No permitir input mientras está escribiendo el mensaje inicial
	if is_typing:
		return
	
	if event is InputEventKey and event.pressed:
		var key = event.keycode
		
		# Teclas de letra (A-Z)
		if key >= KEY_A and key <= KEY_Z and current_initials.length() < MAX_INITIALS_LENGTH:
			var letter = char(key)
			current_initials += letter
			update_input_display()
		
		# Backspace para borrar
		elif key == KEY_BACKSPACE and current_initials.length() > 0:
			current_initials = current_initials.substr(0, current_initials.length() - 1)
			update_input_display()
		
		# Enter para confirmar (solo si tiene 3 letras)
		elif key == KEY_ENTER and current_initials.length() == MAX_INITIALS_LENGTH:
			save_highscore()
			show_rankings()

func update_input_display():
	"""Actualiza el display del input"""
	input_label.clear()
	var display_text = current_initials
	
	# Agregar guiones bajos para las letras faltantes
	while display_text.length() < MAX_INITIALS_LENGTH:
		display_text += "_"
	
	input_label.append_text("%s" % display_text)

func save_highscore():
	"""Guarda el highscore en el archivo"""
	# Verificar si el archivo existe, si no, crearlo
	if not FileAccess.file_exists(HIGHSCORE_FILE_PATH):
		var new_file = FileAccess.open(HIGHSCORE_FILE_PATH, FileAccess.WRITE)
		if new_file == null:
			print("Error al crear el archivo de highscores: ", FileAccess.get_open_error())
			return
		new_file.close()
		print("Archivo de highscores creado: ", HIGHSCORE_FILE_PATH)
	
	var file = FileAccess.open(HIGHSCORE_FILE_PATH, FileAccess.READ_WRITE)
	
	if file == null:
		print("Error al abrir el archivo de highscores: ", FileAccess.get_open_error())
		return
	
	# Leer highscores existentes
	var highscores = []
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line != "":
			highscores.append(line)
	
	# Agregar el nuevo score
	var new_entry = "%s|%d|%d" % [current_initials.to_upper(), player_score, player_combo]
	highscores.append(new_entry)
	
	# Ordenar por puntaje (descendente)
	highscores.sort_custom(func(a, b): 
		var score_a = int(a.split("|")[1])
		var score_b = int(b.split("|")[1])
		return score_a > score_b
	)
	
	# Mantener solo los top 10
	if highscores.size() > TOP_PLAYERS_COUNT:
		highscores.resize(TOP_PLAYERS_COUNT)
	
	# Guardar de nuevo
	file.close()
	file = FileAccess.open(HIGHSCORE_FILE_PATH, FileAccess.WRITE)
	
	for score in highscores:
		file.store_line(score)
	
	file.close()
	print("Highscore guardado: ", new_entry)

func show_rankings():
	"""Muestra el top 10 de jugadores"""
	showing_rankings = true
	
	# Preparar el texto completo para el efecto typewriter
	typewriter_text = "═══ TOP 10 JUGADORES ═══\n\n"
	
	if not FileAccess.file_exists(HIGHSCORE_FILE_PATH):
		typewriter_text += "No hay registros aún"
	else:
		var file = FileAccess.open(HIGHSCORE_FILE_PATH, FileAccess.READ)
		if file != null:
			var rank = 1
			while not file.eof_reached() and rank <= TOP_PLAYERS_COUNT:
				var line = file.get_line().strip_edges()
				if line != "":
					var parts = line.split("|")
					if parts.size() >= 3:
						var initials = parts[0]
						var score = parts[1]
						var combo = parts[2]
						
						typewriter_text += "%d. %s - %s pts (Combo: %s)\n" % [rank, initials, score, combo]
						rank += 1
			file.close()
	
	typewriter_text += "\nPresiona ENTER para continuar"
	
	# Iniciar efecto typewriter
	typewriter_index = 0
	is_typing = true
	message_label.clear()
	input_label.clear()

func get_highscores() -> Array:
	"""Retorna un array con los highscores en formato dict"""
	var scores = []
	
	if not FileAccess.file_exists(HIGHSCORE_FILE_PATH):
		return scores
	
	var file = FileAccess.open(HIGHSCORE_FILE_PATH, FileAccess.READ)
	if file == null:
		return scores
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line != "":
			var parts = line.split("|")
			if parts.size() >= 3:
				scores.append({
					"initials": parts[0],
					"score": int(parts[1]),
					"combo": int(parts[2])
				})
	
	file.close()
	return scores
