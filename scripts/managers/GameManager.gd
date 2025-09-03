extends Node2D

# --- Player state ---
@export var player_health: int = 20
@export var starting_money: int = 500
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

# --- Popovers ---
@onready var upgrade_popover_scene: PackedScene = preload("res://scenes/ui/tower_upgrade_popover.tscn")
@onready var placement_popover_scene: PackedScene = preload("res://scenes/ui/tower_placement_popover.tscn")
var upgrade_popover: Control = null
var placement_popover: Control = null

# --- Selection state ---
var selected_tower: Node = null
var open_spot: Node = null

# --- Tower catalog (examples) ---
@export var towerA_name := "Rock Tower"
@export var towerA_cost := 100
@export var towerA_scene: PackedScene

@export var towerB_name := "Ice Tower"
@export var towerB_cost := 150
@export var towerB_scene: PackedScene

func _ready():
	add_to_group("game_manager")
	player_money = starting_money
	_make_popovers()
	_connect_popovers()
	_connect_placement_spots()
	update_ui()

	# Optional: waves
	var wave_manager := $WaveManager
	if wave_manager and wave_manager.has_signal("wave_completed"):
		wave_manager.wave_completed.connect(_on_wave_completed)
		start_next_wave()

# ------------------ POPOVERS ------------------

func _make_popovers():
	var ui_root: Control = get_tree().root.get_node("Main/UI/HUD") # adjust if needed

	upgrade_popover = upgrade_popover_scene.instantiate()
	ui_root.add_child(upgrade_popover)
	upgrade_popover.hide()

	placement_popover = placement_popover_scene.instantiate()
	ui_root.add_child(placement_popover)
	placement_popover.hide()

func _connect_popovers():
	# Placement
	placement_popover.place_tower_selected.connect(_on_place_tower_selected)
	placement_popover.dismissed.connect(_on_popover_dismissed)

	# Upgrade
	upgrade_popover.dismissed.connect(_on_popover_dismissed)
	upgrade_popover.upgrade_tower_damage.connect(_on_upgrade_damage)
	upgrade_popover.upgrade_tower_firerate.connect(_on_upgrade_firerate)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_viewport().get_mouse_position()

		# If click is inside either popover, do nothing
		if (upgrade_popover.visible and upgrade_popover.get_global_rect().has_point(mouse_pos)):
			return
		if (placement_popover.visible and placement_popover.get_global_rect().has_point(mouse_pos)):
			return

		# Otherwise, hide them all
		upgrade_popover.hide()
		placement_popover.hide()

# ------------------ TOWER PLACEMENT ------------------

func _connect_placement_spots():
	for spot in get_tree().get_nodes_in_group("tower_placement_spot"):
		spot.clicked.connect(_on_placement_spot_clicked)

func _on_placement_spot_clicked(spot):
	if spot.has_tower:
		return
	# Close other UI, remember this spot, and open placement popover
	upgrade_popover.hide()
	open_spot = spot
	var options := _get_tower_options()
	placement_popover.setup_for_placement(spot, options)
	placement_popover.position = get_viewport().get_mouse_position() + Vector2(14, 14)
	placement_popover.show_tooltip()

func _get_tower_options() -> Array:
	var arr: Array = []
	if towerA_scene:
		arr.append({"id":"A","name":towerA_name,"cost":towerA_cost,"scene":towerA_scene})
	if towerB_scene:
		arr.append({"id":"B","name":towerB_name,"cost":towerB_cost,"scene":towerB_scene})
	return arr

func _on_place_tower_selected(choice: Dictionary, spot):
	if choice.is_empty() or spot == null:
		return

	if not spend_money(int(choice.cost)):
		spot.flash_error_tween()
		return

	var tower: Node2D = choice.scene.instantiate()
	tower.global_position = spot.spawn_point.global_position

	var towers_container := get_tree().get_first_node_in_group("towers_container")
	if towers_container:
		towers_container.add_child(tower)
	else:
		add_child(tower)

	# Hook tower clicks
	if tower.has_signal("tower_clicked"):
		tower.tower_clicked.connect(_on_tower_clicked)

	spot.mark_placed()
	update_ui()
	placement_popover.dismiss()

# ------------------ TOWER UPGRADES ------------------

func _on_tower_clicked(tower_instance):
	# Toggle behavior: clicking the same tower closes the popover.
	if selected_tower == tower_instance and upgrade_popover.visible:
		upgrade_popover.dismiss()
		return

	selected_tower = tower_instance
	placement_popover.hide()

	upgrade_popover.setup_for_upgrade(tower_instance)
	upgrade_popover.position = get_viewport().get_mouse_position() + Vector2(14, 14)
	upgrade_popover.show_tooltip()

func _on_popover_dismissed():
	selected_tower = null
	open_spot = null

func _on_upgrade_damage(tower_instance):
	if tower_instance == null:
		return
	var cost = tower_instance.get_upgrade_cost("damage")
	if spend_money(cost):
		tower_instance.upgrade_damage()
		upgrade_popover.update_stats(tower_instance)
		print("Upgraded tower damage! New damage: %d" % tower_instance.damage)
	else:
		print("Not enough money for damage upgrade. Need: %d, Have: %d" % [cost, player_money])

func _on_upgrade_firerate(tower_instance):
	if tower_instance == null:
		return
	var cost = tower_instance.get_upgrade_cost("firerate")
	if spend_money(cost):
		tower_instance.upgrade_firerate()
		upgrade_popover.update_stats(tower_instance)
		print("Upgraded tower fire rate! New fire rate: %.2f" % tower_instance.fire_rate)
	else:
		print("Not enough money for fire rate upgrade. Need: %d, Have: %d" % [cost, player_money])

# Optional: Add range upgrade function for future use
func _on_upgrade_range(tower_instance):
	if tower_instance == null:
		return
	var cost = tower_instance.get_upgrade_cost("range")
	if spend_money(cost):
		tower_instance.upgrade_range()
		upgrade_popover.update_stats(tower_instance)
		print("Upgraded tower range! New range: %.1f" % tower_instance.range_radius)
	else:
		print("Not enough money for range upgrade. Need: %d, Have: %d" % [cost, player_money])

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
