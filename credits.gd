extends Control

# Usamos @onready para obtener la referencia al Sprite2D una vez que la escena está lista.
# Asegúrate de que la ruta sea correcta según dónde colocaste tu Sprite2D.
# Si BlackScreen es un hijo directo de 'Control' (donde está este script):
@onready var black_screen_sprite: Sprite2D = $BlackScreen

# Si BlackScreen está en otro lugar, ajusta la ruta. Por ejemplo:
# @onready var black_screen_sprite: Sprite2D = $"Ruta/Hacia/BlackScreen"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if black_screen_sprite:
		# Asegurarse de que el sprite esté completamente transparente al inicio
		# Modulate.a controla el alpha.
		black_screen_sprite.modulate.a = 0.0
	else:
		print("ERROR: El Sprite2D 'BlackScreen' no se encontró. ¡Revisa la ruta!")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Función para manejar el efecto de fade-out (subir el alpha)
func _fade_out_sprite(duration: float = 0.5) -> void:
	if not black_screen_sprite:
		return
		
	var tween = create_tween()
	
	# Animar la propiedad 'modulate:a' del Sprite2D de 0 (transparente) a 1 (opaco)
	tween.tween_property(black_screen_sprite, "modulate:a", 1.0, duration) 
	
	# Esperar a que la animación termine
	await tween.finished

func _on_exhibition_1_pressed() -> void:
	$button.play()
	
	var fade_duration = 3 # Duración del fade en segundos
	
	# Iniciar el fade-out y esperar a que termine
	await _fade_out_sprite(fade_duration)

	# Después de que el fade esté completo, cambiar la escena
	get_tree().change_scene_to_file("res://menu de exhibicion/exhibition_menu.tscn")
