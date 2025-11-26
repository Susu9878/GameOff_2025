extends CharacterBody2D

# Configuración de flotación
@onready var raycast = $RayCast2D
@onready var sprite = $AnimatedSprite2D
@onready var par = $AnimatedSprite2D/particles
var float_offset = 0.0
var float_force = 500.0
var base_float_force = 500.0
var gravity = 1000.0
var base_gravity = 1000.0
var damping = .95
var vertical_velocity = 0.0
var horizontal_speed = 0.0
var hop_count = 3
# Configuración de rotación con superficie
const SURFACE_ROTATION_SPEED = 5.0
const SURFACE_ALIGNMENT_RANGE = 1000

# Configuración de Acrobacias con ACELERACIÓN
const ROTATION_ACCELERATION = 100.0
const MAX_ROTATION_SPEED = 120.0
const ROTATION_DECELERATION = 100.0
const HOP_FORCE = -200.0

# ----- CONFIGURACIÓN DE LEAN (INCLINACIÓN) -----
const LEAN_ANGLE = -40.0  # Ángulo de inclinación hacia atrás (en grados)
const LEAN_FORWARD_ANGLE = 20.0  # Ángulo de inclinación hacia adelante
const LEAN_SPEED = 200.0  # Velocidad de inclinación (aumentado para inmediatez)
const LEAN_RECOVERY_SPEED = 15.0  # Velocidad de recuperación (aumentado)

# ----- CONFIGURACIÓN DE ACELERACIÓN HORIZONTAL -----
const BOOST_ACCELERATION = 200.0  # Aceleración horizontal durante boost
const MAX_BOOST_SPEED = 350.0  # Velocidad máxima durante boost
const SPEED_RECOVERY = 3.0  # Qué tan rápido regresa a la posición original (aumentado)
const X_OFFSET_RECOVERY = 5.0  # Velocidad de retorno a posición X original

# Acrobacia 1: Giro completo adelante
const ACROBACIA_1_ROTATION = -360.0
# Acrobacia 2: Doble giro
const ACROBACIA_2_ROTATION = 360.0
# Acrobacia 3: Giro hacia atrás
const ACROBACIA_3_ROTATION = -360.0

# Variables de estado de rotación
var is_rotating = false
var target_rotation = 0.0
var current_rotation_speed = 0.0
var rotation_direction = -1.0
var on_water = false

# Variables de lean y aceleración
var is_leaning_back = false  # Renombrado para claridad
var is_leaning_forward = false  # Renombrado para claridad
var lean_offset = -0.01  # Offset de inclinación actual
var boost_speed = 0.0  # Velocidad adicional por boost
var original_x = 0.0  # Posición X original
var x_offset = 0.0  # Offset acumulado en X

# ----- CONFIGURACIÓN DE BOOST -----
const BOOST_UP_MIN_MULTIPLIER = 4.0
const BOOST_UP_MAX_MULTIPLIER = 50.0
const BOOST_DOWN_MIN_MULTIPLIER = 2
const BOOST_DOWN_MAX_MULTIPLIER = 5
const BOOST_RAMP_TIME = 1.4
const HEIGHT_THRESHOLD = 10.0
const EXTRA_BOOST_FORCE = 0.0
const BOOST_COOLDOWN = 1

var boost_up_active = false
var boost_down_active = false
var boost_up_timer = 0.0
var boost_down_timer = 0.0
var was_below_target = true
var boost_cooldown_timer = 0.0

func _ready():
	if not Engine.has_singleton("World"):
		push_error("¡ERROR! El Singleton 'World' no está configurado.")
	
	base_float_force = float_force
	base_gravity = gravity
	original_x = position.x  # Guardar posición X inicial

func _input(event):
	# Acrobacia 1 - Tecla 1 (o Q)
	if event.is_action_pressed("acrobacia_1") and not is_rotating:
		perform_acrobacia(ACROBACIA_1_ROTATION)
	
	# Acrobacia 2 - Tecla 2 (o W)
	elif event.is_action_pressed("acrobacia_2") and not is_rotating:
		perform_acrobacia(ACROBACIA_2_ROTATION)
	
	# Acrobacia 3 - Tecla 3 (o E)
	elif event.is_action_pressed("acrobacia_3") and not is_rotating:
		jump()

func _process(delta):
	sprite.play("default")
	
	# Actualizar lean (inclinación)
	update_lean(delta)
	
	# Actualizar posición X por boost
	update_boost_position(delta)
	
	# Actualizar cooldown (solo cuando NO está activo el boost)
	if boost_cooldown_timer > 0 and not boost_up_active:
		boost_cooldown_timer -= delta
	
	# Boost Up - incrementa progresivamente mientras lo mantienes presionado
	if Input.is_action_pressed("boost_up") and not boost_up_active and boost_cooldown_timer <= 0:
		boost_up_active = true
		boost_up_timer = 0.0
		is_leaning_back = true  # Activar inclinación hacia atrás
		is_leaning_forward = false  # Desactivar inclinación adelante
	
	if boost_up_active:
		boost_up_timer += delta
		
		# ACELERACIÓN INMEDIATA - mover esto AQUÍ en _process
		boost_speed = min(boost_speed + BOOST_ACCELERATION * delta, MAX_BOOST_SPEED)
		
		if boost_up_timer >= BOOST_RAMP_TIME:
			boost_up_active = false
			boost_up_timer = 0.0
			float_force = base_float_force
			was_below_target = true
			is_leaning_back = false
			# NO resetear boost_speed aquí para que desacelere gradualmente
			boost_cooldown_timer = BOOST_COOLDOWN
			print("Boost máximo alcanzado (1 seg) - Cooldown activado por %.1f segundos" % BOOST_COOLDOWN)
		else:
			var boost_progress = clamp(boost_up_timer / BOOST_RAMP_TIME, 0.0, 1.0)
			var current_multiplier = lerp(BOOST_UP_MIN_MULTIPLIER, BOOST_UP_MAX_MULTIPLIER, boost_progress)
			float_force = base_float_force * current_multiplier
			
			if not Input.is_action_pressed("boost_up"):
				boost_up_active = false
				boost_up_timer = 0.0
				float_force = base_float_force
				was_below_target = true
				is_leaning_back = false  # Desactivar inclinación
				# NO resetear boost_speed aquí para que desacelere gradualmente
				boost_cooldown_timer = BOOST_COOLDOWN
				print("Boost terminado (soltado) - Cooldown activado por %.1f segundos" % BOOST_COOLDOWN)
	else:
		# Desacelerar cuando NO está activo el boost
		boost_speed = lerp(boost_speed, 0.0, SPEED_RECOVERY * delta)
	
	# Boost Down - incrementa progresivamente la gravedad
	if Input.is_action_pressed("boost_down"):
		if not boost_down_active:
			boost_down_active = true
			boost_down_timer = 0.0
			is_leaning_forward = true  # Activar inclinación hacia adelante
			is_leaning_back = false  # Desactivar inclinación atrás
			
		boost_down_timer += delta
		
		var boost_progress = clamp(boost_down_timer / BOOST_RAMP_TIME, 0.0, 1.0)
		var current_multiplier = lerp(BOOST_DOWN_MIN_MULTIPLIER, BOOST_DOWN_MAX_MULTIPLIER, boost_progress)
		gravity = base_gravity * current_multiplier
	else:
		if boost_down_active:
			boost_down_active = false
			boost_down_timer = 0.0
			gravity = base_gravity

func update_lean(delta):
	var target_lean = 0.0
	var current_speed = LEAN_SPEED  # Velocidad por defecto (rápida)
	
	# Determinar el ángulo objetivo basado en el estado
	if is_leaning_back:
		target_lean = deg_to_rad(LEAN_ANGLE)
	elif is_leaning_forward:
		target_lean = deg_to_rad(LEAN_FORWARD_ANGLE)
	else:
		target_lean = 0.0
		current_speed = LEAN_RECOVERY_SPEED  # Usar velocidad de recuperación
	
	# Interpolar hacia el ángulo objetivo con la velocidad apropiada
	lean_offset = lerp(lean_offset, target_lean, current_speed * delta)
	
	# Si estamos volviendo a neutral y casi llegamos, resetear
	if not is_leaning_back and not is_leaning_forward:
		if abs(lean_offset) < 0.01:
			lean_offset = 0.0
	
	# Desactivar is_leaning_forward solo cuando hayamos vuelto a la posición neutral
	if is_leaning_forward and not boost_down_active:
		if abs(lean_offset) < 0.1:
			is_leaning_forward = false

func update_boost_position(delta):
	# Aplicar el movimiento horizontal por boost
	x_offset += boost_speed * delta
	
	# Regresar a la posición original cuando no hay boost activo
	if not boost_up_active:
		x_offset = lerp(x_offset, 0.0, X_OFFSET_RECOVERY * delta)

func perform_acrobacia(rotation_degrees: float):
	is_rotating = true
	target_rotation = sprite.rotation + deg_to_rad(rotation_degrees)
	vertical_velocity = HOP_FORCE
	current_rotation_speed = 0.0
	rotation_direction = sign(rotation_degrees)

func jump():
	if hop_count != 0:
		vertical_velocity = HOP_FORCE - 200
		hop_count -= 1
	else:
		return

func handle_rotation(delta):
	if is_rotating:
		var rotation_diff = target_rotation - sprite.rotation
		var distance_remaining = abs(rotation_diff)
		
		if distance_remaining > PI / 4:
			current_rotation_speed = min(
				current_rotation_speed + ROTATION_ACCELERATION * delta,
				MAX_ROTATION_SPEED
			)
		else:
			var decel_factor = distance_remaining / (PI / 4)
			var target_speed = MAX_ROTATION_SPEED * decel_factor
			current_rotation_speed = lerp(
				current_rotation_speed,
				target_speed,
				ROTATION_DECELERATION * delta
			)
		
		var rotation_step = current_rotation_speed * delta * rotation_direction
		
		if distance_remaining < abs(rotation_step) * 1.5:
			sprite.rotation = target_rotation
			is_rotating = false
			current_rotation_speed = 0.0
			sprite.rotation = fmod(sprite.rotation, TAU)
		else:
			sprite.rotation += rotation_step

func handle_surface_alignment(delta, distance_to_target: float):
	if is_rotating:
		return
	
	if raycast.is_colliding():
		var surface_normal = raycast.get_collision_normal()
		var target_angle = surface_normal.angle() - PI / 2.0
		
		# SIEMPRE aplicar el lean offset, independientemente del rango
		target_angle += lean_offset
		
		# Solo interpolar si estamos dentro del rango de alineación
		if abs(distance_to_target) <= SURFACE_ALIGNMENT_RANGE:
			sprite.rotation = lerp_angle(sprite.rotation, target_angle, SURFACE_ROTATION_SPEED * delta)
		else:
			# Fuera del rango, aplicar solo el lean sin interpolación suave
			sprite.rotation = lerp_angle(sprite.rotation, lean_offset, SURFACE_ROTATION_SPEED * delta)

func _physics_process(delta):
	handle_rotation(delta)
	
	# Movimiento horizontal normal (sin velocidad adicional)
	velocity.x = horizontal_speed
	
	var distance_to_target = 0.0
	
	if raycast.is_colliding():
		var collision_point = raycast.get_collision_point()
		var target_y = collision_point.y - float_offset
		distance_to_target = target_y - position.y
		
		handle_surface_alignment(delta, distance_to_target)
		
		if boost_up_active and boost_cooldown_timer <= 0:
			if abs(distance_to_target) <= HEIGHT_THRESHOLD:
				if was_below_target:
					vertical_velocity += EXTRA_BOOST_FORCE
					print("¡Boost extra activado!")
				was_below_target = false
			else:
				if distance_to_target > 0:
					was_below_target = true
		
		if distance_to_target > 0:
			par.visible = false
			vertical_velocity += gravity * delta
		else:
			hop_count = 3
			par.visible = true
			var float_strength = abs(distance_to_target) / 10.0
			vertical_velocity -= float_force * float_strength * delta
		
		vertical_velocity *= damping
		vertical_velocity = clamp(vertical_velocity, -500.0, 500.0)
	else:
		vertical_velocity += gravity * delta
	
	velocity.y = vertical_velocity
	move_and_slide()
	
	# Aplicar el offset de posición X después de move_and_slide
	position.x = original_x + x_offset
