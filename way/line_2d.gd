extends Node2D

# Rhythm data
var rythm = [0, 0, 0, 1, 0, 1, 0, 0, 2, 1, 0, 0, 1, 2, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 2, 1, 0, 0, 1, 2, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 2, 1, 0, 0, 1, 2, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 2, 1, 0, 0, 1, 2, 1, 0]

# Collision properties
@export var spacing_x: float = 400.0
@export var spacing_y: float = 60.0
@export var collision_width: float = 10.0

var static_body: StaticBody2D
var collision_polygon: CollisionPolygon2D
var beat_check_scene = preload("res://beatcheck/beat_check.tscn")

func _ready() -> void:
	spawn_beat_checks()
	create_collider()

func spawn_beat_checks() -> void:
	for i in range(rythm.size()):
		if rythm[i] == 2:
			var beat_check = beat_check_scene.instantiate()
			var pos_x = i * spacing_x
			var pos_y = rythm[i] * spacing_y
			beat_check.position = Vector2(pos_x, pos_y)
			add_child(beat_check)

func create_collider() -> void:
	# Create StaticBody2D
	static_body = StaticBody2D.new()
	add_child(static_body)
	
	# Create CollisionPolygon2D
	collision_polygon = CollisionPolygon2D.new()
	static_body.add_child(collision_polygon)
	
	# Generate collision shape once
	collision_polygon.polygon = generate_collision_polygon()

func generate_collision_polygon() -> PackedVector2Array:
	var point_count = rythm.size()
	if point_count < 2:
		return PackedVector2Array()
	
	var left_points = PackedVector2Array()
	var right_points = PackedVector2Array()
	var half_width = collision_width * 0.5
	
	left_points.resize(point_count)
	right_points.resize(point_count)
	
	# Calculate all perpendiculars and offset points
	for i in point_count:
		var current = Vector2(i * spacing_x, rythm[i] * spacing_y)
		var perpendicular: Vector2
		
		if i == 0:
			var next = Vector2(spacing_x, rythm[1] * spacing_y)
			var direction = (next - current).normalized()
			perpendicular = Vector2(-direction.y, direction.x)
		elif i == point_count - 1:
			var prev = Vector2((i - 1) * spacing_x, rythm[i - 1] * spacing_y)
			var direction = (current - prev).normalized()
			perpendicular = Vector2(-direction.y, direction.x)
		else:
			var prev = Vector2((i - 1) * spacing_x, rythm[i - 1] * spacing_y)
			var next = Vector2((i + 1) * spacing_x, rythm[i + 1] * spacing_y)
			var dir1 = (current - prev).normalized()
			var dir2 = (next - current).normalized()
			var avg_direction = (dir1 + dir2).normalized()
			perpendicular = Vector2(-avg_direction.y, avg_direction.x)
		
		left_points[i] = current + perpendicular * half_width
		right_points[i] = current - perpendicular * half_width
	
	# Combine points: left forward + right backward
	var collision_points = PackedVector2Array()
	collision_points.resize(point_count * 2)
	
	for i in point_count:
		collision_points[i] = left_points[i]
		collision_points[point_count * 2 - 1 - i] = right_points[i]
	
	return collision_points

func _process(_delta: float) -> void:
	if collision_polygon:
		collision_polygon.disabled = (World.way != 2)

# Update rhythm and regenerate collider
func set_rhythm(new_rhythm: Array) -> void:
	rythm = new_rhythm
	if collision_polygon:
		collision_polygon.polygon = generate_collision_polygon()
