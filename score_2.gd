extends RichTextLabel

@export var text_speed: float = 0.05

func _ready():
	visible_characters = 0
	start_typing()

func start_typing():
	for i in get_total_character_count():
		visible_characters = i + 1
		await get_tree().create_timer(text_speed).timeout
