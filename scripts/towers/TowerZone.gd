extends Control
# Put this node in group: "tower_placement_spot"

signal clicked(placement_spot)

@export var has_tower := false
@onready var button_node: Button = $Button
@onready var spawn_point: Marker2D = $SpawnPoint
var normal_color := Color(1, 1, 1, 0.5)

func _ready():
	button_node.modulate = normal_color
	button_node.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	if has_tower:
		return
	# First click should OPEN the placement popover (GameManager listens to this).
	clicked.emit(self)

# GameManager will call this after it successfully spends money and instantiates the tower.
func mark_placed():
	has_tower = true
	hide_and_disable()

func flash_error_tween():
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_property(button_node, "modulate", Color(1, 0.3, 0.3, 0.5), 0.1)
	tween.tween_property(button_node, "modulate", normal_color, 0.1)
	tween.tween_property(button_node, "modulate", Color(1, 0.3, 0.3, 0.5), 0.1)
	tween.tween_property(button_node, "modulate", normal_color, 0.1)

func hide_and_disable():
	hide()
	# Either of these works in Godot 4; mouse_filter is the Control-friendly way.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_deferred("input_pickable", false)
