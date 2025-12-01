extends CanvasLayer

# ⚡ CORE VARIABLES
var airtime_duration: float = 0.0
var airtime_multiplier_text: String = ""
var is_bonus_visible: bool = false
var combo_count = 0
var previous_combo_count: int = 0 

# --- NUEVO: Contador de tiempo para ocultar el combo ---
var combo_time_remaining: float = 0.0 

# ⚙️ BONUS DISPLAY SETTINGS
@export var showin_speed: float = 5.0
@export var bonus_pop_duration: float = .2
@export var bonus_pop_scale: Vector2 = Vector2(1.2, 1.2)
@export var base_airtime_point_value: int = 100

const BONUS_VISIBLE_POS = 100.0
const BONUS_HIDDEN_POS = -1800.0

# 💥 SHAKE CONFIGURATION
var is_shaking: bool = false
var shake_timer: float = 0.0
const SHAKE_DURATION: float = 0.3
const SHAKE_INTENSITY: float = 20.0
var original_points_position: Vector2 = Vector2.ZERO

# 🎨 FONT & STYLE CONFIGURATION
@export var font_path: String = "res://way/Sprintura Demo.otf"
@export var font_size: int = 40
@export var outline_size: int = 0
@export var outline_color: Color = Color.BLACK
@export var text_color: Color = Color.GREEN

# 🌟 NEON COLORS FOR AIRTIME BONUS
@export var neon_cyan: Color = Color(0.0, 1.0, 1.0)  # Cyan brillante
@export var neon_magenta: Color = Color(1.0, 0.0, 1.0)  # Magenta brillante
@export var neon_yellow: Color = Color(1.0, 1.0, 0.0)  # Amarillo brillante

# --- COMBO SETTINGS ---
@export var combo_pop_duration: float = 0.1
@export var combo_max_scale: Vector2 = Vector2(2, 2) 
@export var combo_timeout_seconds: float = 1.0

# --- FLOATING LABEL SETTINGS ---
@export_category("Floating Label Settings")
@export var floating_label_duration: float = 1.5
@export var floating_label_rise_distance: float = 100.0
@export var floating_label_font_size: int = 50
@export var floating_label_spawn_x: float = 1560.0  # Posición X donde aparece la etiqueta
@export var floating_label_spawn_y: float = 860 # Posición Y donde aparece la etiqueta

# 🚀 NODES
@onready var airtime_bonus_container: Node2D = $AirtimeBonus
@onready var bonus_label: RichTextLabel = $AirtimeBonus/air
@onready var points_label: RichTextLabel = $AirtimeBonus2/points
@onready var combo_text: RichTextLabel = $combo/combo
@onready var combo_count_label: RichTextLabel = $combo/combo_count

func _ready() -> void:
	# Inicializar posición oculta
	airtime_bonus_container.position.x = BONUS_HIDDEN_POS
	
	# Guardar posición original del texto de puntos
	original_points_position = points_label.position
	
	# Aplicar estilos a los textos
	apply_text_style(points_label, text_color)
	apply_text_style(bonus_label, neon_cyan)  # Neon cyan para bonus
	apply_text_style(combo_text, text_color)
	apply_text_style(combo_count_label, text_color)
	
	# Inicializar la escala y opacidad del bonus y combo
	bonus_label.scale = Vector2.ONE
	combo_count_label.scale = Vector2.ONE
	
	# Ocultar el texto del combo al inicio
	combo_text.modulate.a = 0.0
	combo_count_label.modulate.a = 0.0
	
	# Conectar señal de cambio de puntos
	if PlayerState.has_signal("points_changed"):
		PlayerState.points_changed.connect(_on_points_changed)

## 🎨 Style Application
func apply_text_style(label: RichTextLabel, color: Color = Color.WHITE):
	"""Aplica fuente, outline y color al RichTextLabel"""
	# Cargar fuente personalizada
	if ResourceLoader.exists(self.font_path):
		var custom_font = load(self.font_path)
		if custom_font:
			label.add_theme_font_override("normal_font", custom_font)
			label.add_theme_font_size_override("normal_font_size", self.font_size)
	
	# Aplicar outline
	label.add_theme_constant_override("outline_size", self.outline_size)
	label.add_theme_color_override("font_outline_color", self.outline_color)
	label.add_theme_color_override("default_color", color)

## 🔄 Core Logic
func _process(delta: float) -> void:
	# --- Manejo y Animación del Combo ---
	combo_count = PlayerState.get_combo()
	
	# 1. Detectar el cambio de combo
	if combo_count > previous_combo_count and combo_count > 1:
		tween_combo_pop()
		# Reiniciar el contador de tiempo restante
		combo_time_remaining = combo_timeout_seconds
		
	previous_combo_count = combo_count
	
	# Lógica de la cuenta regresiva del combo
	if combo_time_remaining > 0:
		combo_time_remaining -= delta
		if combo_time_remaining <= 0:
			# El tiempo se acabó, multiplicamos y ocultamos el combo
			_apply_combo_multiplier()
			_hide_combo()
	
	# 2. Actualizar el texto del combo
	combo_count_label.clear()
	combo_count_label.add_text(str(combo_count))
	
	# Update the points text
	points_label.clear()
	points_label.add_text(str(PlayerState.total_points))
	
	# Handle point shake 
	if is_shaking:
		shake_timer -= delta
		if shake_timer <= 0:
			is_shaking = false
			points_label.position = original_points_position
		else:
			var shake_offset = Vector2(
				randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY),
				randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY)
			)
			points_label.position = original_points_position + shake_offset
	
	# --- Airtime Bonus System ---
	
	# 1. Player is in Airtime (Flying)
	if PlayerState.distance_to_target > 40:
		airtime_duration += delta
		
		# Solo mostramos el bonus si la duración es suficiente (0.1s para evitar un flash)
		if airtime_duration >= 0.1:
			
			is_bonus_visible = true
			
			# Formatear el tiempo a 1 decimal
			airtime_multiplier_text = "%.1f" % airtime_duration
			
			# Update text of the bonus (Potential points)
			bonus_label.clear()
			var potential_bonus = int(airtime_duration * base_airtime_point_value)
			bonus_label.add_text("+" + str(potential_bonus))
			
			# Trigger the pop-up effect for the label
			if bonus_label.scale == Vector2.ONE:
				tween_scale_pop()
			
			# Move towards visible position (show)
			airtime_bonus_container.position.x = lerp(airtime_bonus_container.position.x, BONUS_VISIBLE_POS, delta * showin_speed)
		
	# 2. Player has landed (or is close to landing)
	elif PlayerState.distance_to_target < 20:
		# Si el bonus estaba visible Y el tiempo de vuelo fue suficiente, aplicamos el score.
		if is_bonus_visible and airtime_duration >= 1.0:
			apply_airtime_bonus() # Aplica puntos y reinicia airtime_duration a 0.0
			
		# En todo caso, ocultamos el display.
		airtime_bonus_container.position.x = lerp(airtime_bonus_container.position.x, BONUS_HIDDEN_POS, delta * showin_speed)
		is_bonus_visible = false
		
		# Si el bonus no se aplicó (fue menos de 1.0s) reseteamos el tiempo aquí
		if airtime_duration > 0.0:
			airtime_duration = 0.0

# --- Scoring and Bonus Calculation ---
func apply_airtime_bonus():
	"""
	Calculates the bonus points based on airtime duration and applies them 
	to the PlayerState score.
	"""
	# Calculate the bonus points (Airtime Duration * Base Point Value)
	var bonus_points: int = int(airtime_duration * base_airtime_point_value)

	if bonus_points > 0:
		# 1. Add the calculated points to the total score
		PlayerState.add_points(bonus_points)
		
		# 2. Create floating label showing added points
		create_floating_label("+" + str(bonus_points), neon_yellow)
		
		# 3. Trigger shake to indicate successful bonus application
		trigger_shake() 
		
	# Reset state after applying points
	airtime_duration = 0.0

## 🎯 Combo Multiplier
func _apply_combo_multiplier():
	"""Aplica el multiplicador de combo a los puntos actuales"""
	if combo_count > 1:
		var current_points = PlayerState.total_points
		
		# Calcular multiplicador: +0.5 por cada 5 combos
		# Ejemplo: 5 combos = x1.5, 10 combos = x2.0, 15 combos = x2.5
		var multiplier = 1.0 + (float(combo_count) / 5.0) * 0.5
		
		# Calcular puntos a añadir
		var multiplied_total = int(current_points * multiplier)
		var added_points = multiplied_total - current_points
		
		# Añadir los puntos adicionales del multiplicador
		PlayerState.add_points(added_points)
		
		# Crear etiqueta flotante mostrando el multiplicador
		create_floating_label("x%.1f" % multiplier, neon_magenta)
		
		# Trigger shake
		trigger_shake()
		
		print("¡Combo multiplicador aplicado! x%.1f (%d combos) = +%d puntos | Total: %d" % [multiplier, combo_count, added_points, PlayerState.total_points])

## 🏷️ Floating Label System
func create_floating_label(text: String, color: Color = Color.WHITE):
	"""Crea una etiqueta flotante que muestra puntos añadidos o multiplicadores"""
	print("Creando etiqueta flotante: ", text)
	
	# Crear el nodo de etiqueta como hijo del CanvasLayer (misma jerarquía que otros labels)
	var label = RichTextLabel.new()
	label.bbcode_enabled = false
	label.fit_content = true
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	# Establecer tamaño mínimo
	label.custom_minimum_size = Vector2(200, 80)
	
	# Aplicar estilo personalizado
	if ResourceLoader.exists(self.font_path):
		var custom_font = load(self.font_path)
		if custom_font:
			label.add_theme_font_override("normal_font", custom_font)
			label.add_theme_font_size_override("normal_font_size", floating_label_font_size)
	
	label.add_theme_constant_override("outline_size", outline_size + 2)
	label.add_theme_color_override("font_outline_color", outline_color)
	label.add_theme_color_override("default_color", color)
	
	# Establecer texto
	label.text = text
	
	# Añadir a la misma jerarquía que el resto de labels (como hijo de self/CanvasLayer)
	add_child(label)
	
	# Posicionar usando las variables exportadas
	label.position = Vector2(floating_label_spawn_x, floating_label_spawn_y)
	label.z_index = 100
	
	print("Etiqueta creada en posición: ", label.position)
	
	# Animar: subir y desvanecer
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Escala pop inicial
	label.scale = Vector2.ZERO
	tween.tween_property(label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Movimiento hacia arriba
	tween.tween_property(label, "position:y", floating_label_spawn_y - floating_label_rise_distance, floating_label_duration)
	
	# Fade out
	tween.tween_property(label, "modulate:a", 0.0, floating_label_duration * 0.7).set_delay(floating_label_duration * 0.3)
	
	# Eliminar después de la animación
	await tween.finished
	label.queue_free()
	print("Etiqueta eliminada")

## 💥 Visual Feedback
func trigger_shake():
	"""Activa el efecto de shake en el texto de puntos"""
	is_shaking = true
	shake_timer = SHAKE_DURATION

func tween_scale_pop():
	"""Animates the bonus label's scale for a pop-up effect."""
	var tween = create_tween()
	
	# Pop-up: Scale quickly up
	tween.tween_property(bonus_label, "scale", bonus_pop_scale, bonus_pop_duration)
	
	# Return: Scale back to normal quickly
	tween.tween_property(bonus_label, "scale", Vector2.ONE, bonus_pop_duration).set_delay(0.05)

## ✨ Animación del Combo
func tween_combo_pop():
	"""
	Anima la escala y el color del texto del combo al aumentar, y lo hace visible.
	"""
	var tween = create_tween()
	
	# Asegurarse de que el texto del combo sea visible al hacer pop
	combo_text.modulate.a = 1.0
	combo_count_label.modulate.a = 1.0

	# 1. Animación de escala Pop-Up
	tween.tween_property(combo_count_label, "scale", combo_max_scale, combo_pop_duration)
	tween.tween_property(combo_count_label, "scale", Vector2.ONE, combo_pop_duration * 2).set_delay(0.05)
	
	# 2. Animación de color Arcoíris
	var start_color = Color(1.0, 0.0, 0.0)
	var end_color = self.text_color 
	
	combo_count_label.modulate = start_color
	
	tween.set_parallel(true).tween_property(combo_count_label, "modulate", end_color, combo_pop_duration * 2)
	
## 🕒 Lógica de Ocultar Combo
func _hide_combo():
	"""
	Oculta los textos del combo cuando el tiempo restante es <= 0.
	"""
	# Ocultar los textos animando su transparencia a 0.0
	var hide_tween = create_tween()
	var hide_duration = 0.3 # Fade out rápido

	hide_tween.tween_property(combo_text, "modulate:a", 0.0, hide_duration)
	hide_tween.tween_property(combo_count_label, "modulate:a", 0.0, hide_duration)

## 📡 Signals
func _on_points_changed(new_points: int):
	# Activar shake cuando cambian los points (if not already shaking from bonus)
	if not is_shaking:
		trigger_shake()
	print("¡Puntos actualizados! Nuevo total: ", new_points)
