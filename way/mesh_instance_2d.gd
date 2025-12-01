extends MeshInstance2D

# Configuración de la animación
@export var animation_duration: float = 2.0  # Duración de la animación en segundos
@export var animation_curve: Curve  # Curva de animación opcional

var shader_material: ShaderMaterial
var time_elapsed: float = 0.0
var is_animating: bool = true

func _ready():
	# Obtener el material del shader
	if material is ShaderMaterial:
		shader_material = material
		# Iniciar con curvatura en 0
		shader_material.set_shader_parameter("curvature_progress", 0.0)
	else:
		push_error("El material no es un ShaderMaterial")

func _process(delta: float):
	if is_animating and shader_material:
		time_elapsed += delta
		
		# Calcular el progreso (0.0 a 1.0)
		var progress = clamp(time_elapsed / animation_duration, 0.0, 1.0)
		
		# Aplicar curva de animación si existe, sino usar ease out
		var eased_progress = progress
		if animation_curve:
			eased_progress = animation_curve.sample(progress)
		else:
			# Ease out cubic por defecto
			eased_progress = 1.0 - pow(1.0 - progress, 3.0)
		
		# Actualizar el parámetro del shader
		shader_material.set_shader_parameter("curvature_progress", eased_progress)
		
		# Detener cuando llegue a 1.0
		if progress >= 1.0:
			is_animating = false
			print("Animación de curvatura completada")

# Función pública para reiniciar la animación
func restart_animation():
	time_elapsed = 0.0
	is_animating = true
	if shader_material:
		shader_material.set_shader_parameter("curvature_progress", 0.0)
	print("Animación de curvatura reiniciada")

# Función para establecer la curvatura manualmente
func set_curvature_progress(value: float):
	if shader_material:
		shader_material.set_shader_parameter("curvature_progress", clamp(value, 0.0, 1.0))
		is_animating = false
