extends Node
class_name BuildManager

# --- Scene references ---
@export var ground_layer: TileMapLayer        # Your isometric buildable layer
@export var placements: Node2D               # Container for tower instances
@export var hover_diamond: Node2D            # Optional hover highlight

# --- Popover/Tooltip scenes ---
@onready var upgrade_popover_scene: PackedScene = preload("res://scenes/ui/tower_upgrade_popover.tscn")
@onready var placement_popover_scene: PackedScene = preload("res://scenes/ui/tower_placement_popover.tscn")
@export var tooltip_scene: PackedScene       # TowerPlacementTooltip scene (fallback if needed)

# --- Tower catalog ---
@export var towerA_name := "Rock Tower"
@export var towerA_cost := 100
@export var towerA_scene: PackedScene
@export var towerB_name := "Ice Tower"
@export var towerB_cost := 150
@export var towerB_scene: PackedScene

# --- Internal state ---
var _occupied := {}          # Dictionary<Vector2i, Node> of towers
var _tile_size := Vector2.ZERO
var _active_tooltip: BaseTooltip = null

# --- Popovers ---
var upgrade_popover: Control = null
var placement_popover: Control = null

# --- Selection state ---
var selected_tower: Node = null
var hover_cell: Vector2i

func _ready() -> void:
	assert(ground_layer)
	_tile_size = ground_layer.tile_set.tile_size
	if hover_diamond and hover_diamond.has_method("set_tile_size"):
		hover_diamond.set_tile_size(_tile_size)
	
	_make_popovers()
	_connect_popovers()
	set_process_unhandled_input(true)

# --- Hover and input handling ---
func _process(_dt: float) -> void:
	_update_hover()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_viewport().get_mouse_position()

		# If click is inside either popover, do nothing
		if (upgrade_popover and upgrade_popover.visible and upgrade_popover.get_global_rect().has_point(mouse_pos)):
			return
		if (placement_popover and placement_popover.visible and placement_popover.get_global_rect().has_point(mouse_pos)):
			return

		# Check for tile clicks
		var cell := _get_hover_cell()
		if cell == null:
			# Click on empty space - hide all popovers
			_hide_all_popovers()
			return

		# Tile already occupied → check for tower click
		if _occupied.has(cell):
			var tower = _occupied[cell]
			if tower and tower.has_signal("tower_clicked"):
				_on_tower_clicked(tower)
			return

		# Tile is buildable → show placement tooltip
		if _can_place_at(cell):
			_show_placement_tooltip(cell)
		else:
			_hide_all_popovers()

# --- Hover diamond ---
func _update_hover() -> void:
	if hover_diamond == null:
		return

	var cell := _get_hover_cell()
	if cell == null:
		hover_diamond.call("set_state", false, false, Vector2.ZERO)
		return

	hover_cell = cell
	var can_build := _can_place_at(cell) and not _occupied.has(cell)
	var center_local := ground_layer.map_to_local(cell)
	var center_world := ground_layer.to_global(center_local)
	hover_diamond.call("set_state", true, can_build, center_world)

# ------------------ POPOVERS ------------------

func _make_popovers():
	var ui_root = get_tree().root.get_node("Main/UI/HUD") # adjust if needed
	if ui_root == null:
		# Fallback - try to find any Control in the tree or use root
		ui_root = get_tree().root
		if ui_root == null:
			push_error("Could not find UI root for popovers")
			return

	if upgrade_popover_scene:
		upgrade_popover = upgrade_popover_scene.instantiate()
		ui_root.add_child(upgrade_popover)
		upgrade_popover.hide()

	if placement_popover_scene:
		placement_popover = placement_popover_scene.instantiate()
		ui_root.add_child(placement_popover)
		placement_popover.hide()

func _connect_popovers():
	if placement_popover == null or upgrade_popover == null:
		return
		
	# Placement popover connections
	if placement_popover.has_signal("place_tower_selected"):
		placement_popover.place_tower_selected.connect(_on_place_tower_selected)
	if placement_popover.has_signal("dismissed"):
		placement_popover.dismissed.connect(_on_popover_dismissed)

	# Upgrade popover connections
	if upgrade_popover.has_signal("dismissed"):
		upgrade_popover.dismissed.connect(_on_popover_dismissed)
	if upgrade_popover.has_signal("upgrade_tower_damage"):
		upgrade_popover.upgrade_tower_damage.connect(_on_upgrade_damage)
	if upgrade_popover.has_signal("upgrade_tower_firerate"):
		upgrade_popover.upgrade_tower_firerate.connect(_on_upgrade_firerate)
	if upgrade_popover.has_signal("upgrade_tower_range"):
		upgrade_popover.upgrade_tower_range.connect(_on_upgrade_range)

func _hide_all_popovers():
	if upgrade_popover:
		upgrade_popover.hide()
	if placement_popover:
		placement_popover.hide()
	if _active_tooltip:
		_active_tooltip.dismiss()
		_active_tooltip = null
	selected_tower = null

func _on_popover_dismissed():
	selected_tower = null
	hover_cell = Vector2i.ZERO

# ------------------ TOWER PLACEMENT ------------------

func _show_placement_tooltip(cell: Vector2i) -> void:
	_hide_all_popovers()
	
	if placement_popover == null:
		# Fallback to old tooltip system if popover not available
		_show_tooltip_fallback(cell)
		return

	var options := _get_tower_options()
	placement_popover.setup_for_placement(cell, options)
	placement_popover.position = get_viewport().get_mouse_position() + Vector2(14, 14)
	if placement_popover.has_method("show_tooltip"):
		placement_popover.show_tooltip()
	else:
		placement_popover.show()

func _show_tooltip_fallback(cell: Vector2i) -> void:
	if _active_tooltip:
		_active_tooltip.dismiss()
		_active_tooltip.queue_free()

	if tooltip_scene == null:
		return

	var tooltip := tooltip_scene.instantiate() as BaseTooltip
	get_tree().root.add_child(tooltip)
	tooltip.position = ground_layer.to_global(ground_layer.map_to_local(cell))
	
	# Try to set up the tooltip if it has the expected methods
	if tooltip.has_method("setup_for_placement"):
		tooltip.setup_for_placement(cell, _get_tower_options())
	if tooltip.has_signal("place_tower_selected"):
		tooltip.place_tower_selected.connect(_on_place_tower_selected)

	_active_tooltip = tooltip

func _on_place_tower_selected(choice: Dictionary, cell_or_spot) -> void:
	if choice.is_empty():
		return

	# Handle both Vector2i (cell) and Node (spot) for compatibility
	var cell: Vector2i
	if cell_or_spot is Vector2i:
		cell = cell_or_spot
	elif cell_or_spot != null and cell_or_spot.has_method("get_cell"):
		cell = cell_or_spot.get_cell()
	else:
		push_error("Invalid cell_or_spot parameter in _on_place_tower_selected")
		return

	# Connect to GameManager for money
	var gm := get_tree().get_first_node_in_group("game_manager")
	if gm == null or not gm.spend_money(choice.cost):
		print("Not enough money. Need: %d" % choice.cost)
		# Flash error if we have a spot object
		return

	var tower: Node2D = choice.scene.instantiate()
	var center_local := ground_layer.map_to_local(cell)
	var bottom_tip_local := center_local + Vector2(0, _tile_size.y * 0.5)
	tower.global_position = ground_layer.to_global(bottom_tip_local)

	placements.add_child(tower)
	_occupied[cell] = tower
	
	# Connect tower click signal
	if tower.has_signal("tower_clicked"):
		tower.tower_clicked.connect(_on_tower_clicked)

	_hide_all_popovers()

# ------------------ TOWER UPGRADES ------------------

func _on_tower_clicked(tower_instance: Node) -> void:
	# Toggle behavior: clicking the same tower closes the popover
	if selected_tower == tower_instance and upgrade_popover and upgrade_popover.visible:
		_hide_all_popovers()
		return

	selected_tower = tower_instance
	_hide_all_popovers()

	if upgrade_popover == null:
		# Fallback tooltip system
		var tooltip := tooltip_scene.instantiate() as BaseTooltip
		get_tree().root.add_child(tooltip)
		tooltip.position = tower_instance.global_position
		if tooltip.has_method("show_tooltip"):
			tooltip.show_tooltip()
		_active_tooltip = tooltip
		return

	upgrade_popover.setup_for_upgrade(tower_instance)
	upgrade_popover.position = get_viewport().get_mouse_position() + Vector2(14, 14)
	if upgrade_popover.has_method("show_tooltip"):
		upgrade_popover.show_tooltip()
	else:
		upgrade_popover.show()

func _on_upgrade_damage(tower_instance: Node) -> void:
	if tower_instance == null or not tower_instance.has_method("get_upgrade_cost"):
		return
		
	var cost = tower_instance.get_upgrade_cost("damage")
	var gm := get_tree().get_first_node_in_group("game_manager")
	
	if gm and gm.spend_money(cost):
		tower_instance.upgrade_damage()
		if upgrade_popover and upgrade_popover.has_method("update_stats"):
			upgrade_popover.update_stats(tower_instance)
		print("Upgraded tower damage! New damage: %d" % tower_instance.damage)
	else:
		var current_money = gm.player_money if gm else 0
		print("Not enough money for damage upgrade. Need: %d, Have: %d" % [cost, current_money])

func _on_upgrade_firerate(tower_instance: Node) -> void:
	if tower_instance == null or not tower_instance.has_method("get_upgrade_cost"):
		return
		
	var cost = tower_instance.get_upgrade_cost("firerate")
	var gm := get_tree().get_first_node_in_group("game_manager")
	
	if gm and gm.spend_money(cost):
		tower_instance.upgrade_firerate()
		if upgrade_popover and upgrade_popover.has_method("update_stats"):
			upgrade_popover.update_stats(tower_instance)
		print("Upgraded tower fire rate! New fire rate: %.2f" % tower_instance.fire_rate)
	else:
		var current_money = gm.player_money if gm else 0
		print("Not enough money for fire rate upgrade. Need: %d, Have: %d" % [cost, current_money])

func _on_upgrade_range(tower_instance: Node) -> void:
	if tower_instance == null or not tower_instance.has_method("get_upgrade_cost"):
		return
		
	var cost = tower_instance.get_upgrade_cost("range")
	var gm := get_tree().get_first_node_in_group("game_manager")
	
	if gm and gm.spend_money(cost):
		tower_instance.upgrade_range()
		if upgrade_popover and upgrade_popover.has_method("update_stats"):
			upgrade_popover.update_stats(tower_instance)
		print("Upgraded tower range! New range: %.1f" % tower_instance.range_radius)
	else:
		var current_money = gm.player_money if gm else 0
		print("Not enough money for range upgrade. Need: %d, Have: %d" % [cost, current_money])

# ------------------ HELPERS ------------------

func _get_hover_cell() -> Vector2i:
	var camera := get_viewport().get_camera_2d()
	var mouse_screen := get_viewport().get_mouse_position()
	var mouse_world: Vector2
	
	if camera:
		# Transform screen coordinates to world coordinates through camera
		mouse_world = camera.get_global_mouse_position()
	else:
		# Fallback if no camera found
		mouse_world = mouse_screen
	
	var local := ground_layer.to_local(mouse_world)
	return ground_layer.local_to_map(local)

func _can_place_at(cell: Vector2i) -> bool:
	var td := ground_layer.get_cell_tile_data(cell)
	if td == null:
		return false
	return td.has_custom_data("Buildable") and td.get_custom_data("Buildable")

func _get_tower_options() -> Array:
	var arr: Array = []
	if towerA_scene:
		arr.append({"id":"A","name":towerA_name,"cost":towerA_cost,"scene":towerA_scene})
	if towerB_scene:
		arr.append({"id":"B","name":towerB_name,"cost":towerB_cost,"scene":towerB_scene})
	return arr

# --- Public interface for external systems ---
func get_tower_at_cell(cell: Vector2i) -> Node:
	return _occupied.get(cell, null)

func remove_tower_at_cell(cell: Vector2i) -> bool:
	if _occupied.has(cell):
		var tower = _occupied[cell]
		_occupied.erase(cell)
		if tower and is_instance_valid(tower):
			tower.queue_free()
		return true
	return false

func _flash_cell_error(cell: Vector2i) -> void:
	# Option 1: Use hover diamond to show error state
	if hover_diamond and hover_diamond.has_method("flash_error"):
		var center_local := ground_layer.map_to_local(cell)
		var center_world := ground_layer.to_global(center_local)
		hover_diamond.flash_error(center_world)
		return
	
	# Option 2: Create a temporary error indicator
	var error_indicator := ColorRect.new()
	error_indicator.color = Color.RED
	error_indicator.color.a = 0.6
	error_indicator.size = _tile_size
	error_indicator.position = ground_layer.to_global(ground_layer.map_to_local(cell)) - _tile_size * 0.5
	get_tree().root.add_child(error_indicator)
	
	# Flash animation
	var tween := create_tween()
	tween.set_loops(3)
	tween.tween_property(error_indicator, "modulate:a", 0.0, 0.15)
	tween.tween_property(error_indicator, "modulate:a", 1.0, 0.15)
	
	# Clean up
	await tween.finished
	error_indicator.queue_free()
