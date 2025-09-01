extends CharacterBody2D

@export var speed = 100.0
@export var health = 100
@export var reward_money = 25  # Money given when killed

# NEW: Gem drop configuration
@export var gem_drop_chance: float = 0.3  # 30% chance to drop gems
@export var min_gems: int = 1
@export var max_gems: int = 3

# NEW: Slow effect properties
var base_speed: float  # Store original speed
var current_speed_multiplier: float = 1.0
var slow_effects: Array[Dictionary] = []  # Track multiple slow effects

var target: Vector2
var nav_agent: NavigationAgent2D
var path_progress: float = 0.0
var animated_sprite: AnimatedSprite2D

func _ready():
	nav_agent = $NavigationAgent2D
	animated_sprite = $RunWithSword  # Adjust path if needed
	nav_agent.navigation_finished.connect(_on_target_reached)
	
	# Store the original speed
	base_speed = speed
	
	# Add to enemies group for easy detection
	add_to_group("enemies")
	
	# Wait one frame for nav mesh to be ready
	call_deferred("setup_navigation")

func setup_navigation():
	nav_agent.target_position = target
	
	# Wait for the navigation path to be ready before calculating its length
	await get_tree().process_frame

func _physics_process(delta):
	# Update slow effects
	_update_slow_effects(delta)
	
	if nav_agent.is_navigation_finished():
		animated_sprite.stop()  # Stop animation when not moving
		return
		
	var next_path_position = nav_agent.get_next_path_position()
	var direction = (next_path_position - global_position).normalized()
	
	# Apply current speed (with slow effects)
	var effective_speed = base_speed * current_speed_multiplier
	velocity = direction * effective_speed
	move_and_slide()
	
	# Update animation based on direction
	update_animation(direction)
	
	var remaining_path_length = nav_agent.distance_to_target()
	path_progress = 1.0 - (remaining_path_length / nav_agent.path_max_distance)

# NEW: Apply slow effect
func apply_slow_effect(slow_amount: float, duration: float):
	print("Enemy slow effect applied: ", slow_amount, " for ", duration, "s")
	
	# Add new slow effect
	var slow_effect = {
		"multiplier": 1.0 - slow_amount,  # 0.5 slow = 0.5 speed multiplier
		"duration": duration,
		"timer": duration
	}
	slow_effects.append(slow_effect)
	
	# Update current speed multiplier
	_recalculate_speed_multiplier()
	
	# Visual feedback for being slowed
	_show_slow_effect()

# NEW: Update all active slow effects
func _update_slow_effects(delta: float):
	var effects_to_remove = []
	
	# Update timers for all slow effects
	for i in range(slow_effects.size()):
		slow_effects[i].timer -= delta
		if slow_effects[i].timer <= 0:
			effects_to_remove.append(i)
	
	# Remove expired effects (in reverse order to maintain indices)
	for i in range(effects_to_remove.size() - 1, -1, -1):
		slow_effects.remove_at(effects_to_remove[i])
	
	# Recalculate speed multiplier
	_recalculate_speed_multiplier()

# NEW: Recalculate speed multiplier based on active effects
func _recalculate_speed_multiplier():
	if slow_effects.is_empty():
		current_speed_multiplier = 1.0
		_hide_slow_effect()
		return
	
	# Use the strongest slow effect (lowest multiplier)
	var strongest_multiplier = 1.0
	for effect in slow_effects:
		if effect.multiplier < strongest_multiplier:
			strongest_multiplier = effect.multiplier
	
	current_speed_multiplier = strongest_multiplier

# NEW: Visual feedback for slow effect
func _show_slow_effect():
	# Tint the enemy blue when slowed
	modulate = Color(0.7, 0.7, 1.2)

# NEW: Remove visual feedback when no longer slowed
func _hide_slow_effect():
	modulate = Color.WHITE

func update_animation(direction: Vector2):
	if direction.length() < 0.1:  # Not moving enough to warrant animation
		animated_sprite.stop()
		return
	
	# Convert direction to angle in radians
	var angle = direction.angle()
	# Convert to degrees for easier understanding
	var degrees = rad_to_deg(angle)
	
	# Normalize angle to 0-360 range
	if degrees < 0:
		degrees += 360
	
	# Determine animation based on angle ranges
	# For isometric view, adjust these ranges as needed
	var animation_name = ""
	
	if degrees >= 315 or degrees < 45:        # Right (0°)
		# Use right animation or flip left
		animation_name = "left"
		animated_sprite.flip_h = true
	elif degrees >= 45 and degrees < 135:     # Down-right to Down-left
		if degrees >= 45 and degrees < 90:    # Down-right
			animation_name = "down_left"
			animated_sprite.flip_h = true
		else:                                 # Down-left  
			animation_name = "down_left"
			animated_sprite.flip_h = false
	elif degrees >= 135 and degrees < 225:   # Left (180°)
		animation_name = "left"
		animated_sprite.flip_h = false
	elif degrees >= 225 and degrees < 315:   # Up range
		if degrees >= 225 and degrees < 270:  # Up-left
			animation_name = "up_left" 
			animated_sprite.flip_h = false
		else:                                 # Up-right
			animation_name = "up_left"
			animated_sprite.flip_h = true
	
	# Fallback to down if no match
	if animation_name == "":
		animation_name = "down"
	
	animated_sprite.play(animation_name)

func take_damage(amount):
	health -= amount
	print("Enemy took ", amount, " damage. Health: ", health)
	if health <= 0:
		die(true)  # true = killed by player, give reward

func die(give_reward: bool = false):
	print("Enemy destroyed!")
	
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	
	# Give money reward if killed by player
	if give_reward:
		if game_manager and game_manager.has_method("add_money"):
			game_manager.add_money(reward_money)
			print("Player rewarded %d money for kill!" % reward_money)
		
		# Handle gem drops
		handle_gem_drop(game_manager)
	
	# Remove from group before freeing
	remove_from_group("enemies")
	queue_free()

func handle_gem_drop(game_manager):
	if not game_manager:
		return
		
	# Roll for gem drop
	var drop_roll = randf()
	if drop_roll <= gem_drop_chance:
		# Calculate gem amount
		var gems_to_drop = randi_range(min_gems, max_gems)
		game_manager.add_gems(gems_to_drop)
		print("Enemy dropped %d gems!" % gems_to_drop)
		
		# Spawn visual effect
		spawn_gem_effect(gems_to_drop)

func spawn_gem_effect(gem_count: int):
	# Create gem pickup scene
	var gem_pickup = preload("res://scenes/gem_pickup.tscn").instantiate()
	
	# Position it at enemy location
	gem_pickup.global_position = global_position
	gem_pickup.setup(gem_count)
	
	# Add to scene tree (find appropriate parent)
	var effects_parent = get_tree().get_first_node_in_group("effects_container")
	if effects_parent:
		effects_parent.add_child(gem_pickup)
	else:
		# Fallback to current parent
		get_parent().add_child(gem_pickup)
		
func _on_target_reached():
	print("Enemy reached target!")
	
	# Deal damage to player
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_method("take_damage"):
		game_manager.take_damage(10)  # Adjust damage as needed
		print("Enemy dealt 10 damage to player!")
	else:
		print("WARNING: Could not find game_manager or take_damage method!")
	
	# Remove the enemy (no reward for reaching target)
	die(false)
