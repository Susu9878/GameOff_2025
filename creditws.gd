extends Node

@export var typing_speed: float = 0.05
@export var wait_after_label: float = 5  # Espera después de cada label

@onready var labels = [$RichTextLabel2, $RichTextLabel3, $RichTextLabel4, $RichTextLabel5, $RichTextLabel6]
var full_texts = []

func _ready():
	# Guardar todos los textos y limpiar todos los labels desde el inicio
	for label in labels:
		full_texts.append(label.text)
		label.text = ""
	
	start_typing()

func start_typing():
	for i in range(labels.size()):
		var label = labels[i]
		var full_text = full_texts[i]
		
		# Escribir cada letra
		for char_index in range(full_text.length()):
			label.text += full_text[char_index]
			await get_tree().create_timer(typing_speed).timeout
		
		await get_tree().create_timer(wait_after_label).timeout
		
		if i < labels.size() - 1:
			label.text = ""
	
	print("Typewriter finished")
