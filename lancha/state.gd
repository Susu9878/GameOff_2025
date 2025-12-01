extends Node

# Global player state variables
var distance_to_target: float = 0.0
var boost_up_active: bool = false
var boost_down_active: bool = false
var acrobacy: int = 0
var combo_count: int = 0
var acabadaCarrera: bool = false

# ----- SISTEMA DE PUNTOS -----
var total_points: int = 0

# Reference to the player node (optional, for direct access)
var player: CharacterBody2D = null

# Señal para notificar cambios en los puntos
signal points_changed(new_points: int)

# Ruta del archivo donde se guardarán los puntajes
const SCORE_FILE_PATH: String = "res://scores.txt"

func _ready():
	total_points = 0
	print("PlayerState singleton initialized")

func _process(delta: float) -> void:
	if acabadaCarrera:
		sendScore()
		acabadaCarrera = false  # Evita que se guarde múltiples veces

# Optional: Function to set player reference
func set_player(player_node: CharacterBody2D):
	player = player_node
	print("Player reference set in PlayerState")

# Optional: Helper functions to update values
func update_distance(distance: float):
	distance_to_target = distance

func update_boost_up(active: bool):
	boost_up_active = active

func update_acrobacia(acrobacia_value: int):
	acrobacy = acrobacia_value

func update_boost_down(active: bool):
	boost_down_active = active

# ----- FUNCIONES DEL SISTEMA DE PUNTOS -----
func update_combo(combo: int):
	combo_count = combo

func add_points(points: int):
	"""Agrega puntos al total"""
	total_points += points
	points_changed.emit(total_points)
	print("Puntos agregados: +%d | Total: %d" % [points, total_points])

func subtract_points(points: int):
	"""Resta puntos al total (no puede ser negativo)"""
	total_points = max(0, total_points - points)
	points_changed.emit(total_points)
	print("Puntos restados: -%d | Total: %d" % [points, total_points])

func reset_points():
	"""Reinicia los puntos a 0"""
	total_points = 0
	points_changed.emit(total_points)
	print("Puntos reiniciados a 0")

func get_points() -> int:
	"""Retorna los puntos actuales"""
	return total_points

func get_combo() -> int:
	return combo_count

# ----- SISTEMA DE GUARDADO -----
func sendScore():
	"""Guarda el puntaje actual en un archivo de texto"""
	# Verificar si el archivo existe, si no, crearlo
	if not FileAccess.file_exists(SCORE_FILE_PATH):
		var new_file = FileAccess.open(SCORE_FILE_PATH, FileAccess.WRITE)
		if new_file == null:
			print("Error al crear el archivo: ", FileAccess.get_open_error())
			return
		new_file.close()
		print("Archivo de puntajes creado: ", SCORE_FILE_PATH)
	
	var file = FileAccess.open(SCORE_FILE_PATH, FileAccess.READ_WRITE)
	
	if file == null:
		print("Error al abrir el archivo: ", FileAccess.get_open_error())
		return
	
	# Leer puntajes existentes
	var existing_scores = []
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line != "":
			existing_scores.append(line)
	
	# Obtener la fecha y hora actual
	var datetime = Time.get_datetime_dict_from_system()
	var timestamp = "%04d-%02d-%02d %02d:%02d:%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
	
	# Crear nueva entrada con timestamp
	var new_entry = "%s | Score: %d | Combo: %d | Acrobacy: %d" % [
		timestamp, total_points, combo_count, acrobacy
	]
	
	existing_scores.append(new_entry)
	
	# Reabrir en modo escritura para guardar todo
	file.close()
	file = FileAccess.open(SCORE_FILE_PATH, FileAccess.WRITE)
	
	if file == null:
		print("Error al reabrir el archivo para escritura")
		return
	
	# Escribir todos los puntajes
	for score in existing_scores:
		file.store_line(score)
	
	file.close()
	print("Puntaje guardado exitosamente: %s" % new_entry)

func load_scores() -> Array:
	"""Carga todos los puntajes guardados desde el archivo"""
	var scores = []
	
	if not FileAccess.file_exists(SCORE_FILE_PATH):
		print("No se encontró archivo de puntajes")
		return scores
	
	var file = FileAccess.open(SCORE_FILE_PATH, FileAccess.READ)
	
	if file == null:
		print("Error al abrir el archivo de puntajes")
		return scores
	
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line != "":
			scores.append(line)
	
	file.close()
	return scores

func get_high_score() -> int:
	"""Obtiene el puntaje más alto registrado"""
	var scores = load_scores()
	var high_score = 0
	
	for score_line in scores:
		# Extraer el número del puntaje de la línea
		var parts = score_line.split("|")
		if parts.size() > 1:
			var score_part = parts[1].strip_edges()
			var score_value = score_part.replace("Score: ", "").to_int()
			if score_value > high_score:
				high_score = score_value
	
	return high_score

func clear_scores():
	"""Borra todos los puntajes guardados"""
	var file = FileAccess.open(SCORE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.close()
		print("Archivo de puntajes limpiado")
	else:
		print("Error al limpiar el archivo de puntajes")
