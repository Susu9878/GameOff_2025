extends Line2D

# ----- CONFIGURACIÓN DE OLAS -----
var wave_speed := 2.0
var base_height := 100.0
var time := 0.0

# ----- CONFIGURACIONES DE OLAS (Amplitud, Frecuencia, Velocidad) -----
var wave_configs := [
	# Config 0: Olas suaves
	{
		"amplitude": [5.0, 10.0, 7.0],
		"frequency": [0.0016, 0.005, 0.003],
		"phase_speed": [2.0, 2.3, 1.8]
	},
	# Config 1: Olas medianas variadas
	{
		"amplitude": [60.0, 10.0, 60.0, 10.0, 30.0, 20.0],
		"frequency": [0.008, 0.004, 0.004, 0.005, 0.006, 0.009],
		"phase_speed": [2.0, 2.3, 1.8, 2.0, 2.3, 1.8]
	},
	# Config 2: Olas grandes lentas
	{
		"amplitude": [150.0, 100.0, 120.0],
		"frequency": [0.006, 0.009, 0.004],
		"phase_speed": [0.8, 1.2, 0.6]
	},
	# Config 3: Olas agitadas rápidas
	{
		"amplitude": [100.0, 70.0, 85.0],
		"frequency": [0.010, 0.015, 0.007],
		"phase_speed": [1.8, 2.0, 1.5]
	},
	# Config 4: Olas gigantes tranquilas
	{
		"amplitude": [180.0, 140.0, 160.0],
		"frequency": [0.005, 0.007, 0.003],
		"phase_speed": [0.9, 1.1, 0.5]
	},
	# Config 5: Olas irregulares mixtas
	{
		"amplitude": [110.0, 130.0, 95.0],
		"frequency": [0.009, 0.006, 0.011],
		"phase_speed": [1.3, 0.9, 1.6]
	}
]

# Variables de configuración actual
@export var current_config := 0
var target_config := 0
var is_transitioning := false
var transition_progress := 0.0
var transition_speed := 4.0 
# Variables de onda actual (interpoladas)
var current_amplitude := []
var current_frequency := []
var current_phase_speed := []

# ----- COLISIÓN -----
var segments: Array = []

func _ready():
	# Hacer la línea invisible (pero mantener las colisiones)
	modulate.a = 0.0  # Método 1: Transparencia total
	# O alternativamente:
	# visible = false  # Método 2: Completamente invisible
	
	# Prevenir múltiples inicializaciones si es un singleton
	if segments.size() > 0:
		print("Wave system already initialized, skipping...")
		return
	
	if points.size() == 0:
		_initialize_points()
	
	# Inicializar con la primera configuración
	_initialize_wave_values()
	_create_segment_colliders()
	
	print("Wave system initialized with ", current_amplitude.size(), " waves (line invisible)")

func _initialize_wave_values():
	# Cargar los valores de la configuración actual
	var config = wave_configs[current_config]
	
	# Asegurarse de que los arrays tengan el tamaño correcto
	current_amplitude.resize(config["amplitude"].size())
	current_frequency.resize(config["frequency"].size())
	current_phase_speed.resize(config["phase_speed"].size())
	
	# Copiar los valores
	for i in range(config["amplitude"].size()):
		current_amplitude[i] = config["amplitude"][i]
		current_frequency[i] = config["frequency"][i]
		current_phase_speed[i] = config["phase_speed"][i]

func set_wave_config(config_index: int):
	target_config = config_index % wave_configs.size()
	
	if target_config != current_config:
		is_transitioning = true
		transition_progress = 0.0
		print("Transitioning to config ", target_config)
	else:
		print("Already at config ", config_index)

func next_config():
	set_wave_config(current_config + 1)

func previous_config():
	set_wave_config(current_config - 1 if current_config > 0 else wave_configs.size() - 1)

func instant_config(config_index: int):
	# Cambio instantáneo sin transición
	current_config = config_index % wave_configs.size()
	target_config = current_config
	is_transitioning = false
	_initialize_wave_values()
	print("Instantly changed to config ", current_config)

func _initialize_points():
	var viewport_width = get_viewport_rect().size.x
	var point_spacing = 5
	
	for x in range(0, int(viewport_width) + point_spacing, point_spacing):
		add_point(Vector2(x, base_height))

func _create_segment_colliders():
	# Solo crear colliders si no existen
	if segments.size() > 0:
		return
	
	for i in range(points.size() - 1):
		var segment = StaticBody2D.new()
		var collision = CollisionShape2D.new()
		var shape = SegmentShape2D.new()
		
		collision.shape = shape
		segment.add_child(collision)
		add_child(segment)
		
		segments.append({"body": segment, "shape": shape})

func _process(delta):
	time += delta * wave_speed
	
	# Manejar transición entre configuraciones
	if is_transitioning:
		_update_transition(delta)
	
	# Generar las olas con los valores actuales
	for i in range(points.size()):
		var x = points[i].x
		var y = base_height
		
		# Superponer ondas con valores interpolados
		for wave_index in range(current_amplitude.size()):
			var amp = current_amplitude[wave_index]
			var freq = current_frequency[wave_index]
			var speed = current_phase_speed[wave_index]
			
			y += sin(x * freq - time * speed) * amp
		
		points[i].y = y
	
	_update_segment_colliders()
	points = points

func _update_transition(delta):
	transition_progress += delta * transition_speed
	
	if transition_progress >= 1.0:
		# Transición completa
		transition_progress = 1.0
		is_transitioning = false
		current_config = target_config
		print("Transition complete! Now at config ", current_config)
	
	# Interpolar entre configuración actual y objetivo
	var current_cfg = wave_configs[current_config]
	var target_cfg = wave_configs[target_config]
	
	# Interpolar cada parámetro de cada onda
	for i in range(current_amplitude.size()):
		if i < target_cfg["amplitude"].size():
			current_amplitude[i] = lerp(
				current_cfg["amplitude"][i],
				target_cfg["amplitude"][i],
				transition_progress
			)
			current_frequency[i] = lerp(
				current_cfg["frequency"][i],
				target_cfg["frequency"][i],
				transition_progress
			)
			current_phase_speed[i] = lerp(
				current_cfg["phase_speed"][i],
				target_cfg["phase_speed"][i],
				transition_progress
			)

func _update_segment_colliders():
	for i in range(segments.size()):
		if i < points.size() - 1:
			var shape: SegmentShape2D = segments[i]["shape"]
			shape.a = points[i]
			shape.b = points[i + 1]

# ===== FUNCIONES DE DEBUG/UTILIDAD =====
func get_current_config() -> int:
	return current_config

func is_in_transition() -> bool:
	return is_transitioning

func get_transition_progress() -> float:
	return transition_progress

func set_transition_speed(speed: float):
	transition_speed = max(0.1, speed)  # Mínimo 0.1 para evitar transiciones demasiado lentas

# ===== FUNCIÓN PARA HACER VISIBLE/INVISIBLE LA LÍNEA =====
func set_line_visible(is_visible: bool):
	"""Permite hacer visible o invisible la línea en tiempo de ejecución"""
	if is_visible:
		modulate.a = 1.0
	else:
		modulate.a = 0.0
