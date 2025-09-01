extends BaseProjectile

func _ready():
	projectile_name = "Rock"
	super._ready()

# Rock projectile uses default behavior from BaseProjectile
# No special effects needed - just deals damage
