extends StaticBody2D
class_name BaseTower

signal tower_clicked(tower_instance)

@export var tower_name := "Base Tower"
@export var damage := 25
@export var fire_rate := 1.0  # seconds between shots
@export var range_radius := 150.0
@export var projectile_scene: PackedScene  # Assign different projectiles per tower

# --- Upgrade-related properties ---
@export var base_upgrade_cost := 50
@export var upgrade_cost_growth := 1.5  # multiplier for next upgrade
var damage_upgrade_level: int = 1
var firerate_upgrade_level: int = 1
var range_upgrade_level: int = 1

var enemies_in_range: Array = []
var fire_timer: Timer
var range_area: Area2D

func _ready():
	scale = Vector2.ONE
	_setup_range_detection()
	_setup_fire_timer()
	call_deferred("_seed_enemies_already_in_range")

func _setup_range_detection():
	range_area = $TowerRange
	if not is_instance_valid(range_area):
		push_error("TowerRange Area2D missing on tower scene.")
		return
	range_area.body_entered.connect(_on_enemy_entered)
	range_area.body_exited.connect(_on_enemy_exited)

func _setup_fire_timer():
	fire_timer = Timer.new()
	fire_timer.wait_time = max(0.05, fire_rate)
	fire_timer.autostart = true
	fire_timer.timeout.connect(_try_shoot)
	add_child(fire_timer)

func apply_fire_rate():
	if is_instance_valid(fire_timer):
		fire_timer.wait_time = max(0.05, fire_rate)

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tower_clicked.emit(self)

func _seed_enemies_already_in_range():
	for body in range_area.get_overlapping_bodies():
		_on_enemy_entered(body)

func _on_enemy_entered(body):
	if body == self or not is_instance_valid(body):
		return
	if body.is_in_group("enemies") and not enemies_in_range.has(body):
		enemies_in_range.append(body)

func _on_enemy_exited(body):
	if is_instance_valid(body):
		enemies_in_range.erase(body)

func _try_shoot():
	# Clean dead references
	enemies_in_range = enemies_in_range.filter(func (e): return is_instance_valid(e))
	if enemies_in_range.is_empty():
		return

	var target = _determine_target(enemies_in_range)
	if target and is_instance_valid(target):
		_fire_projectile(target)
		_on_tower_fired()  # Hook for subclasses

# Virtual method - override in subclasses for custom firing behavior
func _fire_projectile(target_enemy):
	if not projectile_scene:
		push_error("No projectile scene assigned to " + tower_name)
		return
		
	var projectile: Node2D = projectile_scene.instantiate()

	var projectiles_container := get_tree().get_first_node_in_group("projectiles_container")
	if projectiles_container:
		projectiles_container.add_child(projectile)
	else:
		get_tree().current_scene.add_child(projectile)

	if projectile.has_method("setup"):
		projectile.setup(global_position, target_enemy, damage)

# Virtual method - override for custom firing effects
func _on_tower_fired():
	# Default firing flash effect
	modulate = Color(1, 0.6, 0.6)
	var t := create_tween()
	t.tween_property(self, "modulate", Color.WHITE, 0.08)

# Virtual method - override for custom targeting logic
func _determine_target(list: Array) -> Node:
	var best = null
	var best_progress := -INF
	for enemy in list:
		if "path_progress" in enemy and enemy.path_progress > best_progress:
			best_progress = enemy.path_progress
			best = enemy
	return best

# ----------------
# Upgrade Methods
# ----------------

func get_upgrade_cost(upgrade_type: String = "") -> int:
	match upgrade_type:
		"damage":
			return int(base_upgrade_cost * pow(upgrade_cost_growth, damage_upgrade_level - 1))
		"firerate":
			return int(base_upgrade_cost * pow(upgrade_cost_growth, firerate_upgrade_level - 1))
		"range":
			return int(base_upgrade_cost * pow(upgrade_cost_growth, range_upgrade_level - 1))
		_:
			return int(base_upgrade_cost * pow(upgrade_cost_growth, damage_upgrade_level - 1))

func upgrade_damage():
	damage_upgrade_level += 1
	damage = int(damage * 1.25)  # +25% damage
	_on_damage_upgraded()

func upgrade_firerate():
	firerate_upgrade_level += 1
	fire_rate = max(0.1, fire_rate * 0.9)  # 10% faster fire rate
	apply_fire_rate()
	_on_firerate_upgraded()

func upgrade_range():
	range_upgrade_level += 1
	range_radius *= 1.1  # +10% range
	
	# Update detection area radius
	if is_instance_valid(range_area):
		var collision_shape = range_area.get_node("CollisionShape2D")
		if collision_shape and collision_shape.shape is CircleShape2D:
			var shape: CircleShape2D = collision_shape.shape
			shape.radius = range_radius
	
	_on_range_upgraded()

# Virtual methods for upgrade feedback - override for custom effects
func _on_damage_upgraded():
	modulate = Color(1, 0.6, 0.6)  # Red tint
	var t := create_tween()
	t.tween_property(self, "modulate", Color.WHITE, 0.2)

func _on_firerate_upgraded():
	modulate = Color(0.6, 0.6, 1)  # Blue tint
	var t := create_tween()
	t.tween_property(self, "modulate", Color.WHITE, 0.2)

func _on_range_upgraded():
	modulate = Color(0.6, 1, 0.6)  # Green tint
	var t := create_tween()
	t.tween_property(self, "modulate", Color.WHITE, 0.2)

func upgrade(upgrade_type: String):
	match upgrade_type:
		"damage":
			upgrade_damage()
		"firerate":
			upgrade_firerate()
		"range":
			upgrade_range()
		_:
			upgrade_damage()

func get_stats() -> Dictionary:
	return {
		"name": tower_name,
		"damage": damage,
		"fire_rate": fire_rate,
		"range": range_radius,
		"damage_level": damage_upgrade_level,
		"firerate_level": firerate_upgrade_level,
		"range_level": range_upgrade_level,
		"damage_cost": get_upgrade_cost("damage"),
		"firerate_cost": get_upgrade_cost("firerate"),
		"range_cost": get_upgrade_cost("range")
	}
