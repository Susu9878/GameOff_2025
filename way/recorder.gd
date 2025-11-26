extends Node2D

# Recording settings
@export var record_key: Key = KEY_SPACE
@export var beat_interval: float = 0.1  # Tiempo entre cada beat (en segundos)
@export var save_folder: String = "res://recorded_rhythms/"
@export var scene_name: String = "rhythm_line"
@export var max_rhythm_value: int = 9  # Valores de 0 a 9 (10 niveles)

# Recording state
var is_recording: bool = false
var rhythm_data: Array = []
var beat_timer: float = 0.0
var was_pressed: bool = false
var recording_time: float = 0.0
var current_level: int = 0  # Nivel actual del ritmo

func _ready() -> void:
	randomize()
	print("=== RHYTHM RECORDER ===")
	print("Press F1 to START recording")
	print("Press F2 to STOP and SAVE recording")
	print("Press '%s' to register beats" % OS.get_keycode_string(record_key))
	print("Use UP/DOWN arrows to change level (0-9)")
	print("======================")
	current_level = 0

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_F1):
		if not is_recording:
			start_recording()
	
	if Input.is_key_pressed(KEY_F2):
		if is_recording:
			stop_and_save_recording()
	
	# Change level with arrow keys
	if is_recording:
		if Input.is_action_just_pressed("ui_up"):
			current_level = min(current_level + 1, max_rhythm_value)
			print("Level: %d" % current_level)
		if Input.is_action_just_pressed("ui_down"):
			current_level = max(current_level - 1, 0)
			print("Level: %d" % current_level)
	
	if is_recording:
		beat_timer += delta
		recording_time += delta
		
		# Check if it's time for a new beat
		if beat_timer >= beat_interval:
			beat_timer = 0.0
			
			# Check if key is pressed
			var is_pressed = Input.is_key_pressed(record_key)
			
			# Only register current level if key was just pressed (not held)
			if is_pressed and not was_pressed:
				rhythm_data.append(current_level)
				print("Beat %d: HIT (%d)" % [rhythm_data.size(), current_level])
			else:
				rhythm_data.append(-1)  # -1 means no beat
			
			was_pressed = is_pressed

func start_recording() -> void:
	is_recording = true
	rhythm_data.clear()
	beat_timer = 0.0
	recording_time = 0.0
	was_pressed = false
	current_level = 0
	print("\n>>> RECORDING STARTED! <<<")
	print("Press '%s' on the beat!" % OS.get_keycode_string(record_key))
	print("Current level: %d" % current_level)

func stop_and_save_recording() -> void:
	if rhythm_data.is_empty():
		print("No data recorded!")
		return
	
	is_recording = false
	print("\n>>> RECORDING STOPPED! <<<")
	print("Total beats recorded: %d" % rhythm_data.size())
	print("Recording duration: %.2f seconds" % recording_time)
	
	# Save data
	save_rhythm_binary()
	
	print("\n=== FILE SAVED ===")
	print("Ready to record again! Press F1 to start.")

func save_rhythm_binary() -> void:
	# Create folder if it doesn't exist
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(save_folder):
		dir.make_dir_recursive(save_folder)
	
	# Generate filename with timestamp
	var time = Time.get_datetime_dict_from_system()
	var timestamp = "%04d%02d%02d_%02d%02d%02d" % [
		time.year, time.month, time.day,
		time.hour, time.minute, time.second
	]
	
	var txt_path = save_folder + scene_name + "_" + timestamp + ".txt"
	
	# Convert rhythm data to binary format (0 = no beat, 1 = beat)
	var binary_data = []
	for value in rhythm_data:
		if value == -1:
			binary_data.append(0)  # No beat
		else:
			binary_data.append(1)  # Beat
	
	# Save as text
	var file = FileAccess.open(txt_path, FileAccess.WRITE)
	if file:
		file.store_string(str(binary_data))
		file.close()
		print("Rhythm data saved to: %s" % txt_path)
	else:
		print("ERROR: Could not save rhythm data!")
