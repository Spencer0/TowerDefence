extends Control
class_name BaseTooltip

signal dismissed

@onready var panel_container: PanelContainer = $PanelContainer
@onready var content_container: MarginContainer = $PanelContainer/ContentContainer

func _ready() -> void:
	hide()
	setup_style()
	
func setup_style() -> void:
	# Create semi-transparent rounded style
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.1, 0.9)  # Semi-transparent dark
	style_box.border_width_left = 2
	style_box.border_width_top = 2
	style_box.border_width_right = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(0.4, 0.4, 0.4, 1.0)  # Gray border
	style_box.corner_radius_top_left = 8
	style_box.corner_radius_top_right = 8
	style_box.corner_radius_bottom_left = 8
	style_box.corner_radius_bottom_right = 8
	
	# Apply style to PanelContainer, not Panel
	panel_container.add_theme_stylebox_override("panel", style_box)

func show_tooltip() -> void:
	show()
	# Ensure tooltip stays within viewport bounds
	clamp_to_viewport()

func clamp_to_viewport() -> void:
	# Wait one frame for the tooltip to calculate its size
	await get_tree().process_frame
	
	var viewport_size = get_viewport().get_visible_rect().size
	var tooltip_size = panel_container.get_rect().size
	
	# Get current position and clamp it
	var current_pos = position
	var clamped_pos = Vector2()
	
	# Clamp X position (left/right edges)
	clamped_pos.x = clampf(current_pos.x, 0, viewport_size.x - tooltip_size.x)
	
	# Clamp Y position (top/bottom edges)  
	clamped_pos.y = clampf(current_pos.y, 0, viewport_size.y - tooltip_size.y)
	
	# Apply the clamped position
	position = clamped_pos

func dismiss() -> void:
	hide()
	dismissed.emit()

func _gui_input(event: InputEvent) -> void:
	# Allow dismissing by clicking outside or pressing Escape
	if event is InputEventMouseButton and event.pressed:
		if not get_rect().has_point(event.position):
			dismiss()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		dismiss()
