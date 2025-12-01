extends RichTextLabel

# ⚙️ EXPORT SETTINGS
@export_group("Stamp Animation")
@export var stamp_scale_start: float = 3.0
@export var stamp_scale_end: float = 1.0
@export var stamp_duration: float = 0.2
@export var wait_before_start: float = 2  # Tiempo antes de empezar countdown
@export var time_between_stamps: float = .7  # Tiempo entre cada número

@export_group("Style")
@export var font_size: int = 60
@export var outline_size: int = 4
@export var outline_color: Color = Color.BLACK
@export var text_color: Color = Color.WHITE

# Mensajes del countdown
var countdown_messages = ["3", "2", "1", "Go!"]

func _ready() -> void:
	# Aplicar estilos
	add_theme_font_size_override("normal_font_size", font_size)
	add_theme_constant_override("outline_size", outline_size)
	add_theme_color_override("font_outline_color", outline_color)
	add_theme_color_override("default_color", text_color)
	
	# Invisible al inicio
	modulate.a = 0.0
	
	# Esperar antes de empezar
	await get_tree().create_timer(wait_before_start).timeout
	if $go:
		$go.play()
	# Hacer countdown
	for message in countdown_messages:
		stamp_text(message)
		await get_tree().create_timer(time_between_stamps).timeout
	
	# Desaparecer al final
	fade_out()

func stamp_text(message: String):
	# Establecer el texto
	text = message
	
	# Reset a estado inicial
	scale = Vector2(stamp_scale_start, stamp_scale_start)
	modulate.a = 0.0
	
	# Animar estampado
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(self, "scale", Vector2(stamp_scale_end, stamp_scale_end), stamp_duration)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "modulate:a", 1.0, stamp_duration * 0.5)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

func fade_out():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)
