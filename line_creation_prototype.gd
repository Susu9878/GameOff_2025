extends Node2D

var rythm = [0,0,1,2,1,2,0,2,1,0,2,1,0,0]
var spacing_x = 400
var spacing_y = 75
var point_radius = 5
var line_width = 10.0
var line_color = Color.WHITE
var point_color = Color.RED

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	queue_redraw()
	create_collider()

func _draw() -> void:
	for i in range(rythm.size()):
		var pos_x = i * spacing_x #+ 50
		var pos_y = rythm[i] * spacing_y
		
		if i < rythm.size() - 1:
			var next_x = (i+1) * spacing_x #+ 50
			var next_y = rythm[i+1] * spacing_y
			draw_line(Vector2(pos_x, pos_y), Vector2(next_x, next_y), line_color, line_width)
		
		draw_circle(Vector2(pos_x, pos_y), point_radius, point_color)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
