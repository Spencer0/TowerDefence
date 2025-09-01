extends BaseTower

func _ready():
	tower_name = "Rock Tower"
	damage = 25
	fire_rate = 1.0
	range_radius = 150.0
	base_upgrade_cost = 50
	projectile_scene = preload("res://scenes/projectiles/rock_projectile.tscn")
	# Set the projectile scene in the editor or here
	# projectile_scene = preload("res://scenes/projectiles/RockProjectile.tscn")
	super._ready()
