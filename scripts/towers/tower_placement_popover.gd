# TowerPlacementTooltip.gd
extends BaseTooltip
class_name TowerPlacementTooltip

signal place_tower_selected(choice, placement_spot)

var placing_tower_spot = null
var placement_tower_options: Array = []

# UI References
@onready var scroll_container: ScrollContainer = $PanelContainer/ContentContainer/ScrollContainer
@onready var tower_buttons_container: VBoxContainer = $PanelContainer/ContentContainer/ScrollContainer/TowerButtonsContainer

func _ready() -> void:
	super._ready()
	setup_scroll_container()

func setup_scroll_container() -> void:
	# Set fixed size constraints for scrolling
	scroll_container.custom_minimum_size = Vector2(250, 150)
	scroll_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	scroll_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER

func setup_for_placement(placement_spot, tower_options: Array) -> void:
	placing_tower_spot = placement_spot
	placement_tower_options = tower_options.duplicate(true)
	create_tower_buttons()
	show_tooltip()

func create_tower_buttons() -> void:
	clear_existing_buttons()
	for j in range(10): # This loop seems redundant, maybe for testing?
		for i in range(placement_tower_options.size()):
			var tower_option = placement_tower_options[i]
			var button = create_tower_button(tower_option, i)
			tower_buttons_container.add_child(button)

func clear_existing_buttons() -> void:
	for child in tower_buttons_container.get_children():
		child.queue_free()

func create_tower_button(tower_option: Dictionary, index: int) -> Button:
	var button = Button.new()
	var tower_name = tower_option.get("name", "Tower")
	var tower_cost = int(tower_option.get("cost", 0))
	
	button.text = "%s ($%d)" % [tower_name, tower_cost]
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.x = 220
	
	# Create a new theme for the button to control its style
	var button_theme = Theme.new()
	
	# Define a style for the normal state (yellow text)
	button_theme.set_color("font_color", "Button", Color(1.0, 1.0, 1.0))
	button_theme.set_color("font_hover_color", "Button", Color(0.0, 1.0, 0.0))


	
	# Apply the custom theme to the button
	button.theme = button_theme
	
	# Connect the button press
	button.pressed.connect(_on_tower_button_pressed.bind(index))
	
	return button

func dismiss() -> void:
	placing_tower_spot = null
	placement_tower_options.clear()
	super.dismiss()

func _on_tower_button_pressed(tower_index: int) -> void:
	if placing_tower_spot and tower_index < placement_tower_options.size():
		var selected_tower = placement_tower_options[tower_index]
		place_tower_selected.emit(selected_tower, placing_tower_spot)
		dismiss()
