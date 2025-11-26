extends Line2D

# ----- CONFIGURACIÓN DE OLAS -----
var wave_speed := 2.0
var base_height := 100.0
var time := 0.0

# ----- 5 PRESETS DE OLAS -----
var wave_presets := [
	# Preset 0: Olas medianas suaves
	[
		{"amplitude": 60.0, "frequency": 0.008, "phase_speed": 2.0},
		{"amplitude": 10.0, "frequency": 0.004, "phase_speed": 2.3},
		{"amplitude": 60.0, "frequency": 0.004, "phase_speed": 1.8},
		{"amplitude": 10.0, "frequency": 0.005, "phase_speed": 2.0},
		{"amplitude": 30.0, "frequency": 0.006, "phase_speed": 2.3},
		{"amplitude": 20.0, "frequency": 0.009, "phase_speed": 1.8}
	],
	# Preset 1: Olas grandes lentas
	[
		{"amplitude": 150.0, "frequency": 0.006, "phase_speed": 0.8},
		{"amplitude": 100.0, "frequency": 0.009, "phase_speed": 1.2},
		{"amplitude": 120.0, "frequency": 0.004, "phase_speed": 0.6}
	],
	# Preset 2: Olas agitadas rápidas
	[
		{"amplitude": 100.0, "frequency": 0.010, "phase_speed": 1.8},
		{"amplitude": 70.0, "frequency": 0.015, "phase_speed": 2.0},
		{"amplitude": 85.0, "frequency": 0.007, "phase_speed": 1.5}
	],
	# Preset 3: Olas gigantes tranquilas
	[
		{"amplitude": 180.0, "frequency": 0.005, "phase_speed": 0.9},
		{"amplitude": 140.0, "frequency": 0.007, "phase_speed": 1.1},
		{"amplitude": 160.0, "frequency": 0.003, "phase_speed": 0.5}
	],
	# Preset 4: Olas irregulares mixtas
	[
		{"amplitude": 110.0, "frequency": 0.009, "phase_speed": 1.3},
		{"amplitude": 130.0, "frequency": 0.006, "phase_speed": 0.9},
		{"amplitude": 95.0, "frequency": 0.011, "phase_speed": 1.6}
	]
]

var current_preset := 0
var waves := []

# ----- COLISIÓN -----
var segments: Array = []

func _ready():
	if points.size() == 0:
		_initialize_points()
	
	# Cargar preset inicial
	set_wave_preset(current_preset)
	_create_segment_colliders()

func set_wave_preset(preset_index: int):
	current_preset = preset_index % wave_presets.size()
	waves = wave_presets[current_preset].duplicate(true)
	print("Cambiado a preset ", current_preset)

func next_preset():
	set_wave_preset(current_preset + 1)

func _initialize_points():
	var viewport_width = get_viewport_rect().size.x
	var point_spacing = 5
	
	for x in range(0, int(viewport_width) + point_spacing, point_spacing):
		add_point(Vector2(x, base_height))

func _create_segment_colliders():
	for seg in segments:
		seg.queue_free()
	segments.clear()
	
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
	
	for i in range(points.size()):
		var x = points[i].x
		var y = base_height
		
		# Superponer ondas del preset actual
		for wave in waves:
			y += sin(x * wave["frequency"] - time * wave["phase_speed"]) * wave["amplitude"]
		
		points[i].y = y
	
	_update_segment_colliders()
	points = points

func _update_segment_colliders():
	for i in range(segments.size()):
		if i < points.size() - 1:
			var shape: SegmentShape2D = segments[i]["shape"]
			shape.a = points[i]
			shape.b = points[i + 1]
