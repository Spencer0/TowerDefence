extends Control

func _ready():
	# Get the start button and connect its signal
	var start_button = $VBoxContainer/StartButton
	start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed():
	print("Starting game...")
	# Change to the main game scene
	get_tree().change_scene_to_file("res://scenes/levels/Level.tscn")
