# HoverDiamond.gd
extends Node2D

var tile_size: Vector2 = Vector2(128, 64) # overwritten by BuildManager at runtime
var valid: bool = false
var visible_cell: bool = false

func set_tile_size(size: Vector2) -> void:
	tile_size = size
	queue_redraw()

func set_state(show: bool, is_valid: bool, world_center: Vector2) -> void:
	visible_cell = show
	valid = is_valid
	global_position = world_center
	queue_redraw()

func _draw() -> void:
	if not visible_cell:
		return

	var w := tile_size.x
	var h := tile_size.y
	var points := PackedVector2Array([
		Vector2(0, -20 -h * 0.5),
		Vector2(w * 0.5, 0-20),
		Vector2(0,  -20 + h * 0.5),
		Vector2(-w * 0.5, 0-20),
	])

	var col =  Color(0, 1, 0, 0.25) if valid else Color(1, 0, 0, 0.25)
	draw_colored_polygon(points, col, [], null)
	# subtle border
	draw_polyline(points + PackedVector2Array([points[0]]), col.darkened(0.3), 2.0, true)
