extends Label

var score = 0
var combo = 0	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
#Hit value * (1 + (Combo multiplier)
func updateScore(n: int):
	match n:
		1:
			combo += 1
			score += 300 * (1 + combo)
		2:
			combo += 1
			score += 100 * (1 + combo)
		3: 
			combo += 1
			score += 50 * (1 + combo)
		4:
			combo =0
	
	text = "Score: %s\nCombo x%s" % [score, combo]
