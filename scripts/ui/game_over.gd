# GameOver.gd
extends Control

@onready var replay_button = $CanvasLayer/BoxContainer/HBoxContainer/ReplayButton
@onready var main_menu_button = $CanvasLayer/BoxContainer/HBoxContainer/MenuButton
@export var game_over_state : GameOver

func _ready():
	replay_button.pressed.connect(_on_replay_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)

func _on_replay_button_pressed():
	var last_level_path = game_over_state.previous_level_path
	if last_level_path:
		get_tree().change_scene_to_file(last_level_path)
	else:
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
		
func _on_main_menu_button_pressed():
	# Change scene back to the main menu.
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
