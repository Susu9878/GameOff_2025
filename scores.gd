extends Node

# 🎮 HIGH SCORE SYSTEM
# Manages score tracking, saving, and display

const SCORE_FILE_PATH = "res://highscores.txt"
const MAX_SCORES = 10

# Score entry structure
class ScoreEntry:
	var initials: String
	var score: int
	
	func _init(init: String = "AAA", scr: int = 0):
		initials = init
		score = scr
	
	static func from_string(line: String) -> ScoreEntry:
		var parts = line.split(":")
		if parts.size() == 2:
			return ScoreEntry.new(parts[0], int(parts[1]))
		return null

# 📊 CORE FUNCTIONS

func update_current_run_score(score: int):
	"""Actualiza el score del run actual en tiempo real"""
	# Puedes usar esto para mostrar el score actual comparado con records
	pass

func load_scores() -> Array:
	"""Carga los scores desde el archivo"""
	var scores: Array = []
	
	if not FileAccess.file_exists(SCORE_FILE_PATH):
		print("No score file found, creating new one")
		return scores
	
	var file = FileAccess.open(SCORE_FILE_PATH, FileAccess.READ)
	if file:
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			if line != "":
				var entry = ScoreEntry.from_string(line)
				if entry:
					scores.append(entry)
		file.close()
		print("Loaded %d scores" % scores.size())
	else:
		print("Failed to open score file")
	
	return scores

func save_scores(scores: Array) -> bool:
	"""Guarda los scores al archivo"""
	var file = FileAccess.open(SCORE_FILE_PATH, FileAccess.WRITE)
	if file:
		for entry in scores:
			file.store_line(entry.to_string())
		file.close()
		print("Saved %d scores to %s" % [scores.size(), SCORE_FILE_PATH])
		return true
	else:
		print("Failed to save scores")
		return false

func add_score(initials: String, score: int) -> int:
	"""
	Agrega un nuevo score y retorna su posición (1-10)
	Retorna -1 si no calificó para el top 10
	"""
	var scores = load_scores()
	var new_entry = ScoreEntry.new(initials.to_upper().substr(0, 3), score)
	
	scores.append(new_entry)
	
	# Ordenar de mayor a menor
	scores.sort_custom(func(a, b): return a.score > b.score)
	
	# Encontrar posición del nuevo score
	var position = -1
	for i in range(scores.size()):
		if scores[i] == new_entry:
			position = i + 1
			break
	
	# Mantener solo top 10
	if scores.size() > MAX_SCORES:
		scores.resize(MAX_SCORES)
	
	save_scores(scores)
	
	print("Score added: %s - %d | Position: %d" % [initials, score, position])
	
	# Retornar posición solo si está en el top 10
	return position if position <= MAX_SCORES else -1

func get_top_scores(count: int = MAX_SCORES) -> Array:
	"""Retorna los top N scores"""
	var scores = load_scores()
	if scores.size() > count:
		scores.resize(count)
	return scores

func get_highest_score() -> int:
	"""Retorna el score más alto"""
	var scores = load_scores()
	if scores.size() > 0:
		return scores[0].score
	return 0

func is_high_score(score: int) -> bool:
	"""Verifica si un score califica para el top 10"""
	var scores = load_scores()
	
	if scores.size() < MAX_SCORES:
		return true
	
	# Verificar si es mayor que el score más bajo
	var lowest_score = scores[scores.size() - 1].score
	return score > lowest_score

func format_scores_display() -> String:
	"""Formatea los scores para mostrar"""
	var scores = get_top_scores()
	var display = ""
	
	if scores.size() == 0:
		return "No scores yet!"
	
	for i in range(scores.size()):
		var entry = scores[i]
		display += "%2d. %s .......... %d\n" % [i + 1, entry.initials, entry.score]
	
	return display
