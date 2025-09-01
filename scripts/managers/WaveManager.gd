extends Node

@export var enemy_scene: PackedScene
@export var spawn_point: Marker2D
@export var target_point: Marker2D

var enemies_in_wave := 0
var enemies_spawned := 0
var spawn_timer: Timer
var base_spawn_interval := 1.0   # seconds between spawns at wave 1
var spawn_interval := 1.0

signal wave_completed

func _ready():
	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_spawn_enemy)
	add_child(spawn_timer)

func start_wave(wave_number: int):
	print("Starting wave %d" % wave_number)
	enemies_spawned = 0
	enemies_in_wave = 5 + (wave_number - 1) * 2  # difficulty scaling
	
	# Apply 10% faster spawns each wave
	spawn_interval = base_spawn_interval * pow(0.9, wave_number - 1)
	spawn_timer.wait_time = spawn_interval
	
	print("Spawning %d enemies, interval = %.2f seconds" % [enemies_in_wave, spawn_interval])
	
	spawn_timer.start()

func _spawn_enemy():
	if enemies_spawned < enemies_in_wave:
		if enemy_scene and spawn_point and target_point:
			var enemy = enemy_scene.instantiate()
			enemy.position = spawn_point.global_position
			enemy.target = target_point.global_position
			enemy.tree_exiting.connect(_on_enemy_died)

			var enemies_parent = get_tree().get_first_node_in_group("enemies_container")
			if enemies_parent:
				enemies_parent.add_child(enemy)
			else:
				add_child(enemy)

			enemies_spawned += 1
			print("Spawned enemy %d/%d" % [enemies_spawned, enemies_in_wave])
	else:
		spawn_timer.stop()
		print("Wave spawning complete — waiting for cleanup")

func _on_enemy_died():
	var remaining = get_tree().get_nodes_in_group("enemies")
	if remaining.is_empty():
		emit_signal("wave_completed")
