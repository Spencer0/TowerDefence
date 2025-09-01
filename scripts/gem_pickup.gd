extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var tween: Tween

var gem_count_to_show: int = 0

func setup(gem_count: int):
	gem_count_to_show = gem_count
	
	# Wait for the node to be ready before setting up
	if not is_node_ready():
		await ready
	
	# Set the gem count text
	label.text = "+%d" % gem_count_to_show
	
	# Start the pickup animation
	animate_pickup()

func animate_pickup():
	# Create tween for animations
	tween = create_tween()
	tween.set_parallel(true)  # Allow multiple animations at once
	
	# Move upward while fading out
	var start_pos = global_position
	var end_pos = start_pos + Vector2(0, -50)
	
	# Position animation
	tween.tween_property(self, "global_position", end_pos, 1.0)
	
	# Fade out animation
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	
	# Scale animation (optional - makes it feel more juicy)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.8).set_delay(0.2)
	
	# Remove after animation completes
	tween.finished.connect(queue_free)
