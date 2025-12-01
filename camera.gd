extends Node2D

# Configuración de la Cámara
@onready var sprite = $Sprite2D
@onready var camera = $Camera2D

const SHAKE_INTENSITY = 3.0
const SHAKE_DURATION = 0.15

# Configuración de Zoom Dinámico basado en distancia
const BASE_ZOOM = 3.2 # Zoom base
const ZOOM_MAX = 4.0  # Zoom cuando está muy cerca del target
const ZOOM_MIN = 2.8 # Zoom cuando está muy lejos del target
const MIN_DISTANCE_FOR_ZOOM = 10.0  # Distancia mínima (zoom máximo)
const MAX_DISTANCE_FOR_ZOOM = 100.0  # Distancia máxima (zoom mínimo)
const ZOOM_LERP_SPEED = 3.0  # Velocidad de transición del zoom

# Variables de Cámara
var camera_original_position: Vector2
var camera_original_zoom: Vector2
var is_shaking = false
var shake_timer = 0.0
var target_zoom = BASE_ZOOM  # Zoom objetivo basado en distancia
var current_smooth_zoom = BASE_ZOOM  # Zoom suavizado actual

func _ready():
	if camera:
		camera_original_position = camera.position
		camera_original_zoom = camera.zoom
		current_smooth_zoom = camera.zoom.x
	else:
		push_error("¡No se encontró la cámara! Asegúrate de tener un nodo Camera2D como hijo.")

func _process(delta):
	# Bloquear posición Y de la cámara
	if camera:
		camera.position.y = camera_original_position.y
	
	# Calcular el zoom basado en la distancia al target
	update_distance_based_zoom(delta)
	
	# Manejar shake de cámara
	if is_shaking:
		shake_timer -= delta
		if shake_timer <= 0:
			is_shaking = false
			camera.offset.x = 0
		else:
			# Shake aleatorio solo en X (Y bloqueado)
			camera.offset.x = randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY)
	else:
		camera.offset.x = 0

func update_distance_based_zoom(delta):
	# Obtener la distancia del PlayerState
	var distance = abs(PlayerState.distance_to_target)
	
	# Normalizar la distancia (0 = cerca, 1 = lejos)
	var normalized_distance = clamp((distance - MIN_DISTANCE_FOR_ZOOM) / (MAX_DISTANCE_FOR_ZOOM - MIN_DISTANCE_FOR_ZOOM), 0.0, 1.0)
	
	# Interpolar entre zoom máximo (cerca) y mínimo (lejos)
	# Cuando está cerca (normalized_distance = 0) -> ZOOM_MAX
	# Cuando está lejos (normalized_distance = 1) -> ZOOM_MIN
	target_zoom = lerp(ZOOM_MAX, ZOOM_MIN, normalized_distance)
	
	# Suavizar el zoom actual hacia el target
	current_smooth_zoom = lerp(current_smooth_zoom, target_zoom, ZOOM_LERP_SPEED * delta)
	
	# Aplicar el zoom suavizado
	camera.zoom = Vector2(current_smooth_zoom, current_smooth_zoom)

# Función pública para activar shake desde otros scripts
func trigger_camera_shake():
	is_shaking = true
	shake_timer = SHAKE_DURATION
	PlayerState.acrobacy += 1
