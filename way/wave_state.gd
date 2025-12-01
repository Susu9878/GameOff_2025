extends Node

# Global wave state variables
var wave_preset = 0
# Reference to the wave node (optional, for direct access)
var wave: Line2D = null

func _ready():
	print("PlayerState singleton initialized")

# Optional: Function to set wave reference
func set_wave(wave_node: Line2D):
	wave = wave_node
	print("Player reference set in PlayerState")

# Optional: Helper functions to update values
func wave_presets(preset: int):
	wave_preset = preset
