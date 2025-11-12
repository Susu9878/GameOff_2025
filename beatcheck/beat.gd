extends StaticBody2D
var player_inside_g = false
var player_area = null
var player_inside_b = false
var player_inside_m = false
var way 

func _physics_process(delta: float) -> void:
	check_beat()
			
func check_beat():
	if Input.is_action_just_pressed("ui_down"):
		if player_inside_b and !player_inside_m and !player_inside_g:
			World.way = 2
			print (World.way)
		elif player_inside_m  and !player_inside_g:
			World.way = 1
			print (World.way)
		elif player_inside_g:  # Solo evaluar si el player está d
			World.way = 0
			print (World.way)
		
func _on_mid_area_entered(area: Area2D) -> void:
	if area.name == "Player":
		print("mid entró")
		player_inside_m = true
		player_area = area
func _on_mid_area_exited(area: Area2D) -> void:
	if area.name == "Player":
		print("mid salió")
		player_inside_m = false
		player_area = null		
func _on_good_area_entered(area: Area2D) -> void:
	if area.name == "Player":
		print("good entró")
		player_inside_g = true
		player_area = area
		if !Input.is_action_just_pressed("ui_down"):
			World.way = 2
		
func _on_good_area_exited(area: Area2D) -> void:
	if area.name == "Player":
		print("good salió")
		player_inside_g = false
		player_area = null
func _on_bad_area_entered(area: Area2D) -> void:
	if area.name == "Player":
		print("bien entró")
		player_inside_b = true
		player_area = area
		
func _on_bad_area_exited(area: Area2D) -> void:
	if area.name == "Player":
		print("bien salió")
		player_inside_b = false
		player_area = null
