extends Node2D

# Configuración del Beat
const BPM = 75.0
const BEAT_WINDOW = 0.25  # Ventana de tiempo en segundos para aceptar input (±0.15s)
const WARMUP_BEATS = 5 # Número de beats de espera antes de comenzar
const INITIAL_DELAY = 0.5  # Retraso inicial en segundos antes del primer beat

# Configuración de la Cámara
@onready var sprite = $Sprite2D
@onready var camera = $Camera2D

const SHAKE_INTENSITY = 3.0
const SHAKE_DURATION = 0.15
const ZOOM_AMOUNT = 0.3  # Cuánto hace zoom (0.15 = 15% más cerca)
const ZOOM_DURATION = 0.4

# ----- CONFIGURACIÓN DE ALPHA FLASH -----
const BEAT_FLASH_ALPHA_MIN = 0.0012  # Alpha mínimo en el beat
const BEAT_FLASH_RECOVERY_SPEED = 2# Velocidad de recuperación del alpha

# Variables de Beat
var beat_interval: float
var time_since_start: float = 0.0  # Tiempo total desde que inició
var time_since_last_beat: float = 0.0
var beat_count: int = 0
var game_started: bool = false  # Nueva variable para controlar el inicio
var first_beat_triggered: bool = false  # Para saber si ya pasó el primer beat

# Variables de Cámara
var camera_original_position: Vector2
var camera_original_zoom: Vector2
var is_shaking = false
var shake_timer = 0.0
var is_zooming = false
var zoom_timer = 0.0

# Variables de Alpha Flash
var target_alpha = 0.01
var current_alpha = .01

# Señal para notificar cuando hay un beat
signal on_beat
signal game_start  # Nueva señal para cuando el juego comienza

# Teclas a detectar (puedes agregar más)
const VALID_KEYS = ["Q", "W", "E", "A", "S", "D", "acrobacia_3", "F"]

func _ready():
	# Calcular el intervalo entre beats
	beat_interval = 60.0 / BPM  # Segundos por beat
	
	if camera:
		camera_original_position = camera.position
		camera_original_zoom = camera.zoom
	else:
		push_error("¡No se encontró la cámara! Asegúrate de tener un nodo Camera2D como hijo.")
	
	print("Beat interval: ", beat_interval, " segundos")
	print("Ventana de aceptación: ±", BEAT_WINDOW, " segundos")
	print("Esperando ", INITIAL_DELAY, " segundos antes del primer beat...")

func _process(delta):
	time_since_start += delta
	
	# Verificar si ya pasó el delay inicial y activar el primer beat
	if not first_beat_triggered and time_since_start >= INITIAL_DELAY:
		first_beat_triggered = true
		beat_count = 1
		time_since_last_beat = 0.0
		
		print("Warmup Beat #", beat_count, " / ", WARMUP_BEATS)
		
		# Emitir señal de beat
		on_beat.emit()
		
		# Bajar el alpha del sprite local
		target_alpha = BEAT_FLASH_ALPHA_MIN
	
	# Solo continuar con el conteo de beats después del primer beat
	if first_beat_triggered:
		time_since_last_beat += delta
		
		# Cuando se completa un beat, reiniciar
		if time_since_last_beat >= beat_interval:
			time_since_last_beat -= beat_interval
			beat_count += 1
			
			# Verificar si es un beat de calentamiento o del juego
			if beat_count <= WARMUP_BEATS:
				print("Warmup Beat #", beat_count, " / ", WARMUP_BEATS)
				
				# Si llegamos al último beat de calentamiento, iniciar el juego
				if beat_count == WARMUP_BEATS:
					game_started = true
					game_start.emit()
					print("========== ¡JUEGO INICIADO! ==========")
			else:
				print("Beat #", beat_count - WARMUP_BEATS)
			
			# Emitir señal de beat (siempre, para efectos visuales)
			on_beat.emit()
			
			# Bajar el alpha del sprite local
			target_alpha = BEAT_FLASH_ALPHA_MIN
	
	# Actualizar el efecto de flash del beat en el sprite
	update_sprite_flash(delta)
	
	# Manejar shake de cámara
	if is_shaking:
		shake_timer -= delta
		if shake_timer <= 0:
			is_shaking = false
			camera.offset = Vector2.ZERO
		else:
			# Shake aleatorio
			camera.offset = Vector2(
				randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY),
				randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY)
			)
	
	# Manejar zoom de cámara
	if is_zooming:
		zoom_timer += delta
		var progress = zoom_timer / ZOOM_DURATION
		
		if progress >= 1.0:
			is_zooming = false
			camera.zoom = camera_original_zoom
		else:
			# Efecto de zoom in y out (curva ease)
			var zoom_factor = 1.0
			if progress < 0.5:
				# Zoom in (primera mitad)
				zoom_factor = 1.0 + (ZOOM_AMOUNT * (progress * 2.0))
			else:
				# Zoom out (segunda mitad)
				zoom_factor = 1.0 + (ZOOM_AMOUNT * (2.0 - progress * 2.0))
			
			camera.zoom = camera_original_zoom * zoom_factor

func update_sprite_flash(delta):
	# Interpolar suavemente el alpha actual hacia el target
	current_alpha = lerp(current_alpha, target_alpha, BEAT_FLASH_RECOVERY_SPEED * delta)
	
	# Aplicar el alpha al sprite
	if sprite:
		sprite.modulate.a = current_alpha
	
	# Recuperar gradualmente el alpha a 1.0
	if target_alpha < 1.0:
		target_alpha = min(target_alpha + BEAT_FLASH_RECOVERY_SPEED * delta, 1.0)

func _input(event):
	# Solo aceptar input después de que el juego haya comenzado
	if not game_started:
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		var key_string = OS.get_keycode_string(event.keycode)
		
		# Verificar si es una tecla válida
		if key_string in VALID_KEYS:
			check_beat_timing(key_string)

func check_beat_timing(key: String):
	# Calcular qué tan cerca está del beat
	var time_to_next_beat = beat_interval - time_since_last_beat
	var time_from_last_beat = time_since_last_beat
	
	# Tomar el menor (más cercano al beat)
	var closest_beat_time = min(time_from_last_beat, time_to_next_beat)
	
	print("Tecla '", key, "' presionada. Timing: ", closest_beat_time, "s del beat")
	
	# Verificar si está dentro de la ventana de aceptación
	if closest_beat_time <= BEAT_WINDOW:
		on_beat_success(key, closest_beat_time)
	else:
		on_beat_miss(key, closest_beat_time)

func on_beat_success(key: String, timing: float):
	print("✓ ¡PERFECTO! Tecla '", key, "' en el beat (±", timing, "s)")
	
	# Activar efectos de cámara
	trigger_camera_shake()
	trigger_camera_zoom()
	
	# Aquí puedes agregar más efectos:
	# - Puntos/score
	# - Partículas
	# - Sonidos
	# - etc.

func on_beat_miss(key: String, timing: float):
	print("✗ Fallaste. Tecla '", key, "' fuera del beat (", timing, "s)")
	
	# Aquí puedes agregar penalizaciones o feedback negativo

func trigger_camera_shake():
	is_shaking = true
	shake_timer = SHAKE_DURATION

func trigger_camera_zoom():
	is_zooming = true
	zoom_timer = 0.0

# Función opcional para visualizar el beat
func get_beat_progress() -> float:
	return time_since_last_beat / beat_interval

# Función para verificar si el juego ya comenzó
func is_game_started() -> bool:
	return game_started
