extends CharacterBody2D

var float_offset = -9
var float_force = 1000.0
var damping = 0.9
var time = 0.0

@onready var raycast = $RayCast2D


func _physics_process(delta):
	time += delta
	
	
	if raycast.is_colliding():
		var collision_point = raycast.get_collision_point()
		var target_y = collision_point.y - float_offset
		var distance = target_y - global_position.y  # Usar global_position
		
		# Aplicar fuerza de flotación
		var float_strength = clamp(abs(distance) / 10.0, 0.1, 2.0)  # Limitar el rango
		velocity.y += distance * float_force * float_strength * delta
		
		# Amortiguación
		velocity.y *= damping
	else:
		# Opcional: aplicar gravedad o mantener velocidad
		velocity.y *= damping
	
	move_and_slide()
