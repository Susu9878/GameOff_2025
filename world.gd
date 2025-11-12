extends Node2D

@onready var way = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	way = 2
func _process(delta):
	print(way)
	
