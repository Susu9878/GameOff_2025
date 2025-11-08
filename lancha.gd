extends CharacterBody2D

@onready var raycast = $RayCast2D
var float_offset = 10.0  # Distancia sobre el agua
var float_force = 800.0  # Fuerza de flotación
var gravity = 600.0  # Gravedad cuando cae
var damping = 0.95  # Amortiguación
var vertical_velocity = 0.0  # Velocidad vertical actual
var horizontal_speed = 0.0  # Velocidad horizontal constante (ajusta según necesites)

func _physics_process(delta):
	# Movimiento horizontal constante (siempre avanza)
	velocity.x = horizontal_speed
	
	if raycast.is_colliding():
		var collision_point = raycast.get_collision_point()
		var target_y = collision_point.y - float_offset
		var distance = target_y - position.y
		
		# Aplicar física basada en la diferencia de altura
		if distance > 0:  # El objetivo está abajo - aplicar gravedad
			vertical_velocity += gravity * delta
		else:  # El objetivo está arriba - aplicar fuerza de flotación
			var float_strength = abs(distance) / 10.0
			vertical_velocity -= float_force * float_strength * delta
		
		# Aplicar amortiguación
		vertical_velocity *= damping
		
		# Limitar velocidad vertical máxima
		vertical_velocity = clamp(vertical_velocity, -500.0, 500.0)
		
		# Actualizar velocidad vertical
		velocity.y = vertical_velocity
	else:
		# Si no hay colisión, aplicar gravedad normal
		vertical_velocity += gravity * delta
		velocity.y = vertical_velocity
	
	# Mover el personaje usando move_and_slide para mejor colisión
	move_and_slide()
