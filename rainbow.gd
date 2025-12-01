extends RichTextLabel

# ⚙️ EXPORT SETTINGS
@export_group("Stamp Animation")
@export var stamp_scale_start: float = 3.0  # Escala inicial grande
@export var stamp_scale_end: float = 1.0    # Escala final normal
@export var stamp_duration: float = 0.3     # Duración del efecto de estampado
@export var alpha_start: float = 0.0        # Alpha inicial (invisible)
@export var alpha_end: float = 1.0          # Alpha final (visible)

@export_group("Style")
@export var font_size: int = 60
@export var outline_size: int = 4
@export var outline_color: Color = Color.BLACK
@export var text_color: Color = Color.WHITE

# ==============================================================================
# 🚀 INITIALIZATION
# ==============================================================================

func _ready() -> void:
	# Apply basic style properties
	_apply_styles()
	
	# Set initial state (large and invisible)
	scale = Vector2(stamp_scale_start, stamp_scale_start)
	modulate.a = alpha_start
	
	# Start stamp animation
	stamp_in()

func _apply_styles():
	"""Applies essential styles for visibility."""
	add_theme_font_size_override("normal_font_size", font_size)
	add_theme_constant_override("outline_size", outline_size)
	add_theme_color_override("font_outline_color", outline_color)
	add_theme_color_override("default_color", text_color)

# ==============================================================================
# 🎬 STAMP ANIMATION
# ==============================================================================

func stamp_in():
	"""Anima el efecto de estampado: escala de grande a normal + fade in rápido"""
	var tween = create_tween()
	tween.set_parallel(true)  # Ejecutar ambas animaciones al mismo tiempo
	
	# 1. Escala: de grande a normal con bounce
	tween.tween_property(self, "scale", Vector2(stamp_scale_end, stamp_scale_end), stamp_duration)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	# 2. Alpha: fade in rápido
	tween.tween_property(self, "modulate:a", alpha_end, stamp_duration * 0.5)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

# ==============================================================================
# 💬 PUBLIC METHOD
# ==============================================================================

func setup_countdown(text_content: String):
	"""Configura el texto del countdown"""
	clear()
	text = "[center]%s[/center]" % text_content
	
	# Reiniciar animación cada vez que se cambia el texto
	scale = Vector2(stamp_scale_start, stamp_scale_start)
	modulate.a = alpha_start
	stamp_in()

func set_countdown_text(countdown_text: String):
	"""Alias para setup_countdown"""
	setup_countdown(countdown_text)
