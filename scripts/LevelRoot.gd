extends Node2D
@onready var pause_menu = $PauseScreen # Ensure the node path is correct
@onready var portrait_button = $UI/Portrait
@onready var pause_menu_scene = preload("res://scenes/ui/pause_screen.tscn")
@export var current_level_path : GameOver
var pause_menu_instance = null

func _ready():
	current_level_path.previous_level_path = get_tree().current_scene.scene_file_path
	portrait_button.pressed.connect(_on_portrait_tower_pressed)
	pause_menu.visible = false
	get_tree().paused = false

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	if get_tree().paused:
		get_tree().paused = false
		if pause_menu_instance:
			pause_menu_instance.queue_free()
			pause_menu_instance = null
	else:
		get_tree().paused = true
		pause_menu_instance = pause_menu_scene.instantiate()
		add_child(pause_menu_instance)
		# Connect the button's signal to the main game's toggle_pause() function
		var resume_button = pause_menu_instance.get_node("ReplayButton")
		resume_button.pressed.connect(self.toggle_pause)

func _on_portrait_tower_pressed():
		toggle_pause()
		print("portrait click!")
