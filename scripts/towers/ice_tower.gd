extends BaseTower

@export var slow_duration := 3.0
@export var slow_amount := 0.5

func _ready():
	tower_name = "Frost Tower"
	damage = 10  # Low damage but slows enemies
	fire_rate = 1.5
	range_radius = 120.0
	base_upgrade_cost = 40
	projectile_scene = preload("res://scenes/projectiles/ice_projectile.tscn")
	super._ready()

# Override projectile creation to add slow effect data
func _fire_projectile(target_enemy):
	super._fire_projectile(target_enemy)
	
	# Configure the slow effect on the projectile we just created
	var projectiles_container = get_tree().get_first_node_in_group("projectiles_container")
	if projectiles_container and projectiles_container.get_child_count() > 0:
		var last_projectile = projectiles_container.get_child(projectiles_container.get_child_count() - 1)
		if last_projectile.has_method("set_slow_effect"):
			last_projectile.set_slow_effect(slow_amount, slow_duration)

# Custom firing effect
func _on_tower_fired():
	modulate = Color(0.6, 0.8, 1.2)  # Icy blue flash
	var t := create_tween()
	t.tween_property(self, "modulate", Color.WHITE, 0.12)
