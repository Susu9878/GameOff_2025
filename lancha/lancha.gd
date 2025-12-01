extends CharacterBody2D

# Configuración de flotación
@onready var raycast = $RayCast2D

@onready var sprite = $AnimatedSprite2D
@onready var par = $AnimatedSprite2D/particles
@onready var effect = $effect

var float_offset = 0.0
var float_force = 500.0
var base_float_force = 700.0
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
const HOP_FORCE = -250.0

# ----- SISTEMA DE PUNTOS -----
const ACROBACY_POINTS = 100  # Puntos por acrobacia completada

# ----- SISTEMA DE AUDIO Y COMBOS -----
@onready var acrobacy_sound = $acrobacy
var combo_count = 0  # Contador de acrobacias en fila
var combo_reset_timer = 0.0
const COMBO_RESET_TIME = 0.7  # Tiempo para resetear combo (segundos)

# ----- SISTEMA DE EFECTO VISUAL -----
var effect_active = false
var effect_scale = 0.0
var effect_growing = true
const EFFECT_SCALE_SPEED = 8.0  # Velocidad del lerp (más alto = más rápido)
const EFFECT_MAX_SCALE = 2.0  # Escala máxima del efecto (3x más grande)

# Escala frigia (modos para pitch)
# Frigio: 1, b2, b3, 4, 5, b6, b7, 8
const PHRYGIAN_SCALE = [
	1.0,
	1.067,
	1.189,
	1.335,
	1.498,
	1.587,
	1.782, 
	2.0 * 1.0,
	2.0 * 1.067, 
	2.0 * 1.189,  
	2.0 * 1.335,  
	2.0 * 1.498,  
	2.0 * 1.587,  
	2.0 * 1.782,  
	2.0 * 2.0,
	4.0 * 1.067,  
	4.0 * 1.189,  
	4.0 * 1.335,  
	4.0 * 1.498,  
	4.0 * 1.587,  
	4.0 * 1.782,  
	4.0 * 2.0,
]
const LEAN_ANGLE = -40.0
const LEAN_FORWARD_ANGLE = 20.0
const LEAN_SPEED = 20.0
const LEAN_RECOVERY_SPEED = 15.0

# ----- CONFIGURACIÓN DE ACELERACIÓN HORIZONTAL -----
const BOOST_ACCELERATION = 200.0
const MAX_BOOST_SPEED = 350.0
const SPEED_RECOVERY = 2.0
const X_OFFSET_RECOVERY = 2.0

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
var is_leaning_back = false
var is_leaning_forward = false
var lean_offset = -0.01
var boost_speed = 0.0
var original_x = 0.0
var x_offset = 0.0

# ----- CONFIGURACIÓN DE BOOST -----
const BOOST_UP_MIN_MULTIPLIER = 4.0
const BOOST_UP_MAX_MULTIPLIER = 50.0
const BOOST_DOWN_MIN_MULTIPLIER = 2
const BOOST_DOWN_MAX_MULTIPLIER = 5
const BOOST_RAMP_TIME = 1.4
const HEIGHT_THRESHOLD = 10.0
const EXTRA_BOOST_FORCE = 0.0
const BOOST_COOLDOWN = 1

# ----- VARIABLES LOCALES (actualizan al global) -----
var distance_to_target = 0.0
var boost_up_active = false
var boost_down_active = false

var boost_up_timer = 0.0
var boost_down_timer = 0.0
@onready var was_below_target = true
var boost_cooldown_timer = 0.0

func _ready():
	PlayerState.clear_scores()
	PlayerState.total_points = 0
	
	if not Engine.has_singleton("World"):
		push_error("¡ERROR! El Singleton 'World' no está configurado.")
	
	# Registrar este nodo en el PlayerState global
	if has_node("/root/PlayerState"):
		PlayerState.set_player(self)
	
	base_float_force = float_force
	base_gravity = gravity
	original_x = position.x
	
	# Inicializar efecto en escala 0 e invisible
	if effect:
		effect.scale = Vector2.ZERO
		effect.visible = false

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
	if is_rotating:
		$AnimatedSprite2D.play("acr")
	else:
		$AnimatedSprite2D.play("default")
	# Actualizar efecto visual
	update_effect(delta)
	
	# Actualizar lean (inclinación)
	update_lean(delta)
	
	# Actualizar posición X por boost
	update_boost_position(delta)
	
	# Actualizar timer de combo
	if combo_count > 0:
		combo_reset_timer -= delta
		if combo_reset_timer <= 0:
			combo_count = 0
			print("Combo reseteado")
	
	# Actualizar cooldown (solo cuando NO está activo el boost)
	if boost_cooldown_timer > 0 and not boost_up_active:
		boost_cooldown_timer -= delta
	
	# Boost Up - incrementa progresivamente mientras lo mantienes presionado
	if Input.is_action_pressed("boost_up") and not boost_up_active and boost_cooldown_timer <= 0:
		$AnimatedSprite2D.play("jump")
		boost_up_active = true
		PlayerState.update_boost_up(true)  # Actualizar global
		boost_up_timer = 0.0
		is_leaning_back = true
		is_leaning_forward = false
	
	if boost_up_active:
		boost_up_timer += delta
		
		# ACELERACIÓN INMEDIATA
		boost_speed = min(boost_speed + BOOST_ACCELERATION * delta, MAX_BOOST_SPEED)
		
		if boost_up_timer >= BOOST_RAMP_TIME:
			boost_up_active = false
			PlayerState.update_boost_up(false)  # Actualizar global
			boost_up_timer = 0.0
			float_force = base_float_force
			was_below_target = true
			is_leaning_back = false
			boost_cooldown_timer = BOOST_COOLDOWN
			print("Boost máximo alcanzado (1 seg) - Cooldown activado por %.1f segundos" % BOOST_COOLDOWN)
		else:
			var boost_progress = clamp(boost_up_timer / BOOST_RAMP_TIME, 0.0, 1.0)
			var current_multiplier = lerp(BOOST_UP_MIN_MULTIPLIER, BOOST_UP_MAX_MULTIPLIER, boost_progress)
			float_force = base_float_force * current_multiplier
			
			if not Input.is_action_pressed("boost_up"):
				boost_up_active = false
				PlayerState.update_boost_up(false)  # Actualizar global
				boost_up_timer = 0.0
				float_force = base_float_force
				was_below_target = true
				is_leaning_back = false
				boost_cooldown_timer = BOOST_COOLDOWN
				print("Boost terminado (soltado) - Cooldown activado por %.1f segundos" % BOOST_COOLDOWN)
	else:
		# Desacelerar cuando NO está activo el boost
		boost_speed = lerp(boost_speed, 0.0, SPEED_RECOVERY * delta)
	
	# Boost Down - incrementa progresivamente la gravedad
	if Input.is_action_pressed("boost_down"):
		if not boost_down_active:
			boost_down_active = true
			PlayerState.update_boost_down(true)  # Actualizar global
			boost_down_timer = 0.0
			is_leaning_forward = true
			is_leaning_back = false
			
		boost_down_timer += delta
		
		var boost_progress = clamp(boost_down_timer / BOOST_RAMP_TIME, 0.0, 1.0)
		var current_multiplier = lerp(BOOST_DOWN_MIN_MULTIPLIER, BOOST_DOWN_MAX_MULTIPLIER, boost_progress)
		gravity = base_gravity * current_multiplier
	else:
		if boost_down_active:
			boost_down_active = false
			PlayerState.update_boost_down(false)  # Actualizar global
			boost_down_timer = 0.0
			gravity = base_gravity

func update_effect(delta):
	"""Actualiza el efecto visual de acrobacia con escala animada"""
	if not effect:
		return
	
	if effect_active:
		if effect_growing:
			# Crecer de 0 a 3
			effect_scale = lerp(effect_scale, EFFECT_MAX_SCALE, EFFECT_SCALE_SPEED * delta)
			effect.scale = Vector2(effect_scale, effect_scale)
			
			# Cuando llegue cerca de 3, empezar a decrecer
			if effect_scale >= EFFECT_MAX_SCALE * 0.95:
				effect_growing = false
		else:
			# Decrecer de 3 a 0
			effect_scale = lerp(effect_scale, 0.0, EFFECT_SCALE_SPEED * delta)
			effect.scale = Vector2(effect_scale, effect_scale)
			
			# Cuando llegue cerca de 0, desactivar
			if effect_scale <= 0.05:
				effect_active = false
				effect.visible = false
				effect_scale = 0.0

func trigger_effect():
	"""Activa el efecto visual de acrobacia"""
	if effect:
		effect.visible = true
		effect.play("default")  # Asegúrate que tu AnimatedSprite2D tenga una animación
		effect_active = true
		effect_growing = true
		effect_scale = 0.0

func update_lean(delta):
	var target_lean = 0.0
	var current_speed = LEAN_SPEED
	
	if is_leaning_back:
		target_lean = deg_to_rad(LEAN_ANGLE)
	elif is_leaning_forward:
		target_lean = deg_to_rad(LEAN_FORWARD_ANGLE)
	else:
		target_lean = 0.0
		current_speed = LEAN_RECOVERY_SPEED
	
	lean_offset = lerp(lean_offset, target_lean, current_speed * delta)
	
	if not is_leaning_back and not is_leaning_forward:
		if abs(lean_offset) < 0.01:
			lean_offset = 0.0
	
	if is_leaning_forward and not boost_down_active:
		if abs(lean_offset) < 0.1:
			is_leaning_forward = false

func update_boost_position(delta):
	x_offset += boost_speed * delta
	
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
			
			# ¡ACROBACIA COMPLETADA! Agregar puntos
			award_acrobacy_points()
			
			# ¡ACTIVAR EFECTO VISUAL!
			trigger_effect()
		else:
			sprite.rotation += rotation_step

func award_acrobacy_points():
	"""Otorga puntos al jugador cuando completa una acrobacia"""
	PlayerState.add_points(ACROBACY_POINTS)
	
	# Incrementar combo
	combo_count += 1
	PlayerState.update_combo(combo_count)
	combo_reset_timer = COMBO_RESET_TIME
	
	# Reproducir sonido con pitch basado en la escala frigia
	play_acrobacy_sound()
	
	print("¡Acrobacia completada! +%d puntos | Combo: x%d | Total: %d" % [ACROBACY_POINTS, combo_count, PlayerState.total_points])

func play_acrobacy_sound():
	"""Reproduce el sonido de acrobacia con pitch según combo en escala frigia"""
	if acrobacy_sound:
		# Obtener el índice en la escala (circular)
		var scale_index = (combo_count - 1) % PHRYGIAN_SCALE.size()
		
		# Aplicar pitch de la escala frigia
		acrobacy_sound.pitch_scale = PHRYGIAN_SCALE[scale_index]
		
		# Reproducir sonido
		acrobacy_sound.play()
		
		print("Sonido reproducido con pitch: %.3f (nota %d de escala frigia)" % [acrobacy_sound.pitch_scale, scale_index + 1])
	else:
		push_warning("AudioStreamPlayer '$acrobacy' no encontrado")

func handle_surface_alignment(delta, distance_to_target: float):
	if is_rotating:
		return
	
	if raycast.is_colliding():
		var surface_normal = raycast.get_collision_normal()
		var target_angle = surface_normal.angle() - PI / 2.0
		
		target_angle += lean_offset
		
		if abs(distance_to_target) <= SURFACE_ALIGNMENT_RANGE:
			sprite.rotation = lerp_angle(sprite.rotation, target_angle, SURFACE_ROTATION_SPEED * delta)
		else:
			sprite.rotation = lerp_angle(sprite.rotation, lean_offset, SURFACE_ROTATION_SPEED * delta)

func _physics_process(delta):
	handle_rotation(delta)
	
	velocity.x = horizontal_speed
	
	if raycast.is_colliding():
		var collision_point = raycast.get_collision_point()
		var target_y = collision_point.y - float_offset
		distance_to_target = target_y - position.y
		PlayerState.update_distance(distance_to_target)  # Actualizar global
		
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
			combo_reset_timer = 0
			combo_count = 0
			par.visible = true
			var float_strength = abs(distance_to_target) / 10.0
			vertical_velocity -= float_force * float_strength * delta
		
		vertical_velocity *= damping
		vertical_velocity = clamp(vertical_velocity, -500.0, 500.0)
	else:
		vertical_velocity += gravity * delta
	
	velocity.y = vertical_velocity
	move_and_slide()
	
	position.x = original_x + x_offset
