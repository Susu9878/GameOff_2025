extends Node2D

# ⚙️ Referencias de nodos
@onready var Waves = get_tree().current_scene.get_node("way_3/Line2D")
@onready var countdown_label = count
@onready var fade_screen: Sprite2D = $CanvasLayer/BlackScreen

# 🛠️ Settings
@export var fade_in_duration: float = 2
@export var initial_delay: float = 3.0  # Espera inicial antes del countdown
@export var wave_duration: float = 15.0  # Duración de cada wave (30 segundos)
@export var total_waves: int = 5  # Número total de waves (excluyendo el 0)

# ➡️ Race state
var current_wave: int = 0
var race_started: bool = false
var wave_timer: float = 0.0
var carrera_timer: float = 0.0

# ==============================================================================
# 🚀 INITIALIZATION
# ==============================================================================

func _ready():
	PlayerState.acabadaCarrera = false
	# Fade in inicial
	await start_fade_in()
	
	# Esperar 3 segundos iniciales
	await get_tree().create_timer(initial_delay).timeout
	
	# Iniciar countdown
	await start_countdown()
	
	# Empezar la carrera
	start_race()

func _process(delta):
	
	if race_started:
		carrera_timer += delta
		wave_timer += delta
		
		# Verificar si es tiempo de cambiar de wave
		if wave_timer >= wave_duration:
			wave_timer = 0.0
			advance_to_next_wave()
	if carrera_timer > 83.5:
		await start_fade_out()
		PlayerState.acabadaCarrera = true
		get_tree().change_scene_to_file("res://scores_scene.tscn")
	
# ==============================================================================
# 🎬 FADE IN
# ==============================================================================
func start_fade_out():
	"""Fade in desde negro al inicio"""
	if not is_instance_valid(fade_screen):
		push_warning("FadeScreen not found")
		return
	
	var initial_color = fade_screen.modulate
	initial_color.a = 0.0
	fade_screen.modulate = initial_color
	fade_screen.visible = true
	
	var fade_tween = create_tween()
	fade_tween.set_trans(Tween.TRANS_LINEAR)
	fade_tween.tween_property(fade_screen, "modulate:a", 2.0, fade_in_duration)
	
	await fade_tween.finished
	fade_screen.visible = false
	
func start_fade_in():
	"""Fade in desde negro al inicio"""
	if not is_instance_valid(fade_screen):
		push_warning("FadeScreen not found")
		return
	
	var initial_color = fade_screen.modulate
	initial_color.a = 2.0
	fade_screen.modulate = initial_color
	fade_screen.visible = true
	
	var fade_tween = create_tween()
	fade_tween.set_trans(Tween.TRANS_LINEAR)
	fade_tween.tween_property(fade_screen, "modulate:a", 0.0, fade_in_duration)
	
	await fade_tween.finished
	fade_screen.visible = false

# ==============================================================================
# ⏱️ COUNTDOWN
# ==============================================================================

func start_countdown():
	"""Ejecuta el countdown 3, 2, 1, GO!"""
	if not countdown_label:
		push_warning("Countdown label not found")
		return
	
	# 3
	countdown_label.text = "3"
	await get_tree().create_timer(1.0).timeout
	
	# 2
	countdown_label.text = "2"
	await get_tree().create_timer(1.0).timeout
	
	# 1
	countdown_label.text = "1"
	await get_tree().create_timer(1.0).timeout
	
	# GO!
	countdown_label.text = "GO!"
	await get_tree().create_timer(1.0).timeout
	
	# Ocultar countdown
	if countdown_label:
		var fade_tween = create_tween()
		fade_tween.tween_property(countdown_label, "modulate:a", 0.0, 0.5)
		await fade_tween.finished
		countdown_label.visible = false

# ==============================================================================
# 🏁 RACE MANAGEMENT
# ==============================================================================

func start_race():
	"""Inicia el ciclo de la carrera"""
	race_started = true
	current_wave = 1  # Empezar desde wave 1 (nunca usar wave 0)
	wave_timer = 0.0
	
	# Establecer el primer wave
	set_wave(current_wave)
	
	print("¡Carrera iniciada! Wave inicial: %d" % current_wave)

func advance_to_next_wave():
	"""Avanza al siguiente wave"""
	current_wave += 1
	
	# Si llegamos al final de los waves, reiniciar o terminar
	if current_wave > total_waves:
		current_wave = 1  # Reiniciar desde wave 1 (o puedes terminar la carrera)
		print("¡Ciclo de waves completado! Reiniciando desde wave 1")
	
	Waves.set_wave_config(current_wave)
	
	print("Avanzando a Wave %d" % current_wave)

func set_wave(wave_index: int):
	"""Establece el wave actual (nunca usa wave 0)"""
	if Waves and wave_index > 0:
		Waves.set_wave_config(wave_index)
		print("Wave configurado: %d" % wave_index)
	else:
		push_warning("No se puede establecer wave 0 o Waves no encontrado")

# ==============================================================================
# 🎮 PUBLIC METHODS (opcional para control externo)
# ==============================================================================

func pause_race():
	"""Pausa la carrera"""
	race_started = false
	print("Carrera pausada")

func resume_race():
	"""Reanuda la carrera"""
	race_started = true
	print("Carrera reanudada")

func stop_race():
	"""Detiene la carrera completamente"""
	race_started = false
	current_wave = 0
	wave_timer = 0.0
	print("Carrera detenida")

func get_current_wave() -> int:
	"""Retorna el wave actual"""
	return current_wave

func get_time_remaining_in_wave() -> float:
	"""Retorna el tiempo restante en el wave actual"""
	return wave_duration - wave_timer
