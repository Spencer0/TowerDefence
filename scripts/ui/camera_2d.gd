extends Camera2D

var zoom_level: float = 1.0
var is_panning: bool = false
var pan_start: Vector2 = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	# Zoom with mouse wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_level += 0.1
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_level -= 0.1
		# Clamp zoom between 0.5 and 2.0
		zoom_level = clamp(zoom_level, 0.5, 2.0)
		zoom = Vector2(zoom_level, zoom_level)
		
		# Pan with middle mouse button
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_panning = true
				pan_start = get_viewport().get_mouse_position()
			else:
				is_panning = false

func _process(delta: float) -> void:
	if is_panning:
		var mouse_pos = get_viewport().get_mouse_position()
		var delta_pos = (mouse_pos - pan_start) / zoom_level
		position -= delta_pos
		pan_start = mouse_pos
