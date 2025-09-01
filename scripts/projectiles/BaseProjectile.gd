extends Area2D
class_name BaseProjectile

@export var speed = 300.0
@export var damage = 25
@export var projectile_name = "Base Projectile"

var target: Node2D
var direction: Vector2
var hit := false

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var cleanup_timer: Timer = $CleanupTimer

func _ready():
	_setup_animations()
	body_entered.connect(_on_body_entered)
	cleanup_timer.timeout.connect(_on_cleanup_timer_timeout)

# Virtual method - override in subclasses for custom animation setup
func _setup_animations():
	if anim_sprite:
		anim_sprite.play("fly")

func setup(start_pos: Vector2, target_enemy: Node2D, projectile_damage: int):
	global_position = start_pos
	target = target_enemy
	damage = projectile_damage
	
	if target and is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
		rotation = direction.angle()
	else:
		direction = Vector2.UP
		queue_free()

func _physics_process(delta):
	if hit:
		return # stop moving once we hit
		
	# Clean up if target is no longer valid
	if not is_instance_valid(target):
		queue_free()
		return
	
	# Move projectile
	_move_projectile(delta)
	
	# Update direction for homing (can be overridden)
	_update_direction()

# Virtual method - override for different movement patterns
func _move_projectile(delta: float):
	global_position += direction * speed * delta

# Virtual method - override for different homing behaviors
func _update_direction():
	if is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
		rotation = direction.angle()

func _on_body_entered(body):
	if hit:
		return # already exploded
		
	if body.is_in_group("enemies"):
		_apply_effects_to_enemy(body)
		body.take_damage(damage)
		_explode()

# Virtual method - override in subclasses for special effects
func _apply_effects_to_enemy(enemy: Node2D):
	# Base projectile has no special effects
	pass

# Virtual method - override for custom explosion effects
func _explode():
	hit = true
	speed = 0
	
	if is_instance_valid(cleanup_timer):
		cleanup_timer.stop()
	
	_play_explosion_animation()

# Virtual method - override for different explosion animations
func _play_explosion_animation():
	if anim_sprite:
		anim_sprite.play("hit")
		anim_sprite.animation_finished.connect(func():
			queue_free())

func _on_cleanup_timer_timeout():
	queue_free()
