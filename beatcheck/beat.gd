extends StaticBody2D

var player_inside_g = false
var player_area = null
var player_inside_b = false
var player_inside_m = false
var way
var input_pressed = false  # Marca si ya presionó el input en esta zona

func _physics_process(delta: float) -> void:
	check_beat()
			
func check_beat():
	if Input.is_action_just_pressed("acrobacia_3"):
		input_pressed = true
		# Verificar en orden de prioridad: good > mid > bad
		if player_inside_g:
			World.way = 0
			print("GOOD! Way = ", World.way)
		elif player_inside_m:
			World.way = 1
			print("MID! Way = ", World.way)
		elif player_inside_b and !player_inside_m and !player_inside_g:
			World.way = 2
			print("BAD! Way = ", World.way)
		else:
			# Si no está en ninguna área, podría ser miss
			print("MISS! No area detected")

# --- GOOD AREA ---
func _on_good_area_entered(area: Area2D) -> void:
	if area.name == "Player":
		print("good entró")
		player_inside_g = true
		player_area = area
		input_pressed = false  # Reset al entrar en nueva zona

func _on_good_area_exited(area: Area2D) -> void:
	if area.name == "Player":
		print("good salió")
		# Si sale sin haber presionado = MISS
		if !input_pressed:
			print("MISS! Salió de good sin presionar")
			World.way = 3  # Puedes usar 3 para miss o manejar como quieras
		player_inside_g = false
		player_area = null

# --- MID AREA ---
func _on_mid_area_entered(area: Area2D) -> void:
	if area.name == "Player":
		print("mid entró")
		player_inside_m = true
		player_area = area
		if not player_inside_g:  # Solo reset si no está en good
			input_pressed = false

func _on_mid_area_exited(area: Area2D) -> void:
	if area.name == "Player":
		print("mid salió")
		# Si sale sin haber presionado y no está en good = MISS
		if !input_pressed and !player_inside_g:
			print("MISS! Salió de mid sin presionar")
			World.way = 3
		player_inside_m = false
		player_area = null

# --- BAD AREA ---
func _on_bad_area_entered(area: Area2D) -> void:
	if area.name == "Player":
		print("bad entró")
		player_inside_b = true
		player_area = area
		if not player_inside_m and not player_inside_g:  # Solo reset si no está en otras áreas
			input_pressed = false

func _on_bad_area_exited(area: Area2D) -> void:
	if area.name == "Player":
		print("bad salió")
		# Si sale sin haber presionado y no está en otras áreas = MISS
		if !input_pressed and !player_inside_m and !player_inside_g:
			print("MISS! Salió de bad sin presionar")
			World.way = 2
		player_inside_b = false
		player_area = null
