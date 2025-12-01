extends RichTextLabel

# Configuración de fuente y estilo
@export_group("Font Settings")
@export var font_path: String = "res://way/Sprintura Demo.otf"
@export var font_size: int = 24

@export_group("Outline Settings")
@export var outline_size: int = 3
@export var outline_color: Color = Color.DARK_GREEN

@export_group("Text Color")
@export var text_color: Color = Color.SKY_BLUE

@export_group("Shadow Settings (Optional)")
@export var enable_shadow: bool = false
@export var shadow_offset: Vector2 = Vector2(2, 2)
@export var shadow_color: Color = Color(0, 0, 0, 0.5)

@export_group("Animation Settings")
@export var enable_shake_on_text_change: bool = false
@export var shake_intensity: float = 3.0
@export var shake_duration: float = 0.2

# Variables internas
var is_shaking = false
var shake_timer = 0.0
var original_position = Vector2.ZERO
var last_text = ""

func _ready() -> void:
	# Guardar posición original
	original_position = position
	
	# Aplicar estilos
	apply_styles()
	
	# Guardar el texto inicial
	last_text = text

func apply_styles():
	"""Aplica todos los estilos configurados al RichTextLabel"""
	
	# Cargar y aplicar fuente personalizada
	if ResourceLoader.exists(font_path):
		var custom_font = load(font_path)
		if custom_font:
			add_theme_font_override("normal_font", custom_font)
			add_theme_font_size_override("normal_font_size", font_size)
			print("Fuente cargada: ", font_path)
		else:
			push_warning("No se pudo cargar la fuente: " + font_path)
	else:
		push_warning("Archivo de fuente no encontrado: " + font_path)
	
	# Aplicar outline (contorno)
	add_theme_constant_override("outline_size", outline_size)
	add_theme_color_override("font_outline_color", outline_color)
	
	# Aplicar color del texto
	add_theme_color_override("default_color", text_color)
	
	# Aplicar sombra (si está habilitada)
	if enable_shadow:
		add_theme_constant_override("shadow_offset_x", int(shadow_offset.x))
		add_theme_constant_override("shadow_offset_y", int(shadow_offset.y))
		add_theme_color_override("font_shadow_color", shadow_color)

func _process(delta: float) -> void:
	# Detectar cambios de texto y activar shake si está habilitado
	if enable_shake_on_text_change and text != last_text:
		trigger_shake()
		last_text = text
	
	# Manejar animación de shake
	if is_shaking:
		shake_timer -= delta
		if shake_timer <= 0:
			is_shaking = false
			position = original_position
		else:
			# Shake aleatorio
			var shake_offset = Vector2(
				randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)
			)
			position = original_position + shake_offset

func trigger_shake():
	"""Activa manualmente el efecto de shake"""
	is_shaking = true
	shake_timer = shake_duration

# Funciones públicas para cambiar estilos en runtime
func set_font_size(new_size: int):
	"""Cambia el tamaño de la fuente"""
	font_size = new_size
	add_theme_font_size_override("normal_font_size", font_size)

func set_text_color(new_color: Color):
	"""Cambia el color del texto"""
	text_color = new_color
	add_theme_color_override("default_color", text_color)

func set_outline_color(new_color: Color):
	"""Cambia el color del contorno"""
	outline_color = new_color
	add_theme_color_override("font_outline_color", outline_color)

func set_outline_size(new_size: int):
	"""Cambia el grosor del contorno"""
	outline_size = new_size
	add_theme_constant_override("outline_size", outline_size)

func reload_styles():
	"""Recarga todos los estilos (útil si cambias valores en runtime)"""
	apply_styles()
