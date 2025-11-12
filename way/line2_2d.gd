extends Line2D

# Export variables for customization
@export var collision_width: float = 10.0
@export var auto_update: bool = true

var collision_polygon: CollisionPolygon2D
var static_body: StaticBody2D

func _ready():
	create_collider()

func create_collider():
	# Remove old collider if it exists
	if static_body:
		static_body.queue_free()
	
	# Create StaticBody2D
	static_body = StaticBody2D.new()
	add_child(static_body)
	
	# Create CollisionPolygon2D
	collision_polygon = CollisionPolygon2D.new()
	static_body.add_child(collision_polygon)
	
	# Generate the collision shape
	update_collision_shape()

func update_collision_shape():
	if not collision_polygon or points.size() < 2:
		return
	
	var collision_points: PackedVector2Array = []
	
	# Create offset points on both sides of the line
	var left_points: PackedVector2Array = []
	var right_points: PackedVector2Array = []
	
	for i in range(points.size()):
		var current_point = points[i]
		var perpendicular: Vector2
		
		if i == 0:
			# First point - use direction to next point
			var direction = (points[i + 1] - current_point).normalized()
			perpendicular = Vector2(-direction.y, direction.x)
		elif i == points.size() - 1:
			# Last point - use direction from previous point
			var direction = (current_point - points[i - 1]).normalized()
			perpendicular = Vector2(-direction.y, direction.x)
		else:
			# Middle points - average of both directions
			var dir1 = (current_point - points[i - 1]).normalized()
			var dir2 = (points[i + 1] - current_point).normalized()
			var avg_direction = (dir1 + dir2).normalized()
			perpendicular = Vector2(-avg_direction.y, avg_direction.x)
		
		# Add offset points
		left_points.append(current_point + perpendicular * collision_width / 2)
		right_points.append(current_point - perpendicular * collision_width / 2)
	
	# Combine points: left side forward, right side backward
	collision_points.append_array(left_points)
	for i in range(right_points.size() - 1, -1, -1):
		collision_points.append(right_points[i])
	
	collision_polygon.polygon = collision_points

func _process(_delta):
	activate_collider()
	# Auto-update collider if enabled
	if auto_update:
		update_collision_shape()

# Helper function to manually trigger update
func refresh_collider():
	update_collision_shape()

func activate_collider():
	if World.way == 1:
		collision_polygon.disabled = false
	else:
		collision_polygon.disabled = true
