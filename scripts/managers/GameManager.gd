extends Node2D

# --- Player state ---
@export var player_health: int = 20
@export var starting_money: int = 5000
var player_money := 0
var player_gems := 0
@export var last_level_play: Resource

# --- Wave state ---
var current_wave := 0

# --- UI references (optional) ---
@export var health_label: Label
@export var money_label: Label
@export var gems_label: Label
@export var wave_label: Label

func _ready():
	add_to_group("game_manager")
	player_money = starting_money
	update_ui()

	# Optional: waves
	var wave_manager := $WaveManager
	if wave_manager and wave_manager.has_signal("wave_completed"):
		wave_manager.wave_completed.connect(_on_wave_completed)
		start_next_wave()

# ------------------ WAVES ------------------

func start_next_wave():
	current_wave += 1
	if has_node("WaveManager"):
		$WaveManager.start_wave(current_wave)
	update_ui()

func _on_wave_completed():
	print("Wave %d completed!" % current_wave)
	await get_tree().create_timer(2.0).timeout
	start_next_wave()

# ------------------ ECONOMY & UI ------------------

func take_damage(amount: int):
	player_health -= amount
	update_ui()
	if player_health <= 0:
		game_over()

func add_money(amount: int):
	player_money += amount
	update_ui()

func spend_money(amount: int) -> bool:
	if player_money >= amount:
		player_money -= amount
		update_ui()
		return true
	return false

func add_gems(amount: int):
	player_gems += amount
	update_ui()

func spend_gems(amount: int) -> bool:
	if player_gems >= amount:
		player_gems -= amount
		update_ui()
		return true
	return false

func update_ui():
	if health_label:
		health_label.text = "Health: %d" % player_health
	if money_label:
		money_label.text = "Money: %d" % player_money
	if gems_label:
		gems_label.text = "Gems: %d" % player_gems
	if wave_label:
		wave_label.text = "Wave: %d" % current_wave

func game_over():
	print("Game Over!")
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")
