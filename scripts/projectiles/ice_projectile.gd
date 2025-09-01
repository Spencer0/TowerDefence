extends BaseProjectile

# Slow effect properties
@export var slow_amount: float = 0.5  # Reduces speed by 50%
@export var slow_duration: float = 3.0  # Lasts 3 seconds

func _ready():
	projectile_name = "Frost Bolt"
	super._ready()

# Override to set custom slow values (called from FrostTower)
func set_slow_effect(amount: float, duration: float):
	slow_amount = amount
	slow_duration = duration

# Apply slow effect to the enemy
func _apply_effects_to_enemy(enemy: Node2D):
	if enemy.has_method("apply_slow_effect"):
		enemy.apply_slow_effect(slow_amount, slow_duration)
		print("Applied slow effect: ", slow_amount, " for ", slow_duration, " seconds")

# Custom explosion with frost effect
func _play_explosion_animation():
	if anim_sprite:
		# You could add a frost explosion animation here
		anim_sprite.play("hit")  # For now, use the same hit animation
		
		# Add some frost particles or effects here if desired
		_create_frost_effect()
		
		anim_sprite.animation_finished.connect(func():
			queue_free())

# Create visual frost effect on impact
func _create_frost_effect():
	# Create a simple frost effect (you can enhance this)
	var frost_effect = ColorRect.new()
	frost_effect.color = Color(0.7, 0.9, 1.0, 0.6)  # Light blue
	frost_effect.size = Vector2(30, 30)
	frost_effect.position = Vector2(-15, -15)  # Center it
	add_child(frost_effect)
	
	# Animate the frost effect
	var tween = create_tween()
	tween.parallel().tween_property(frost_effect, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(frost_effect, "scale", Vector2(2, 2), 0.5)
	tween.tween_callback(frost_effect.queue_free)
