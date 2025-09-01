extends CanvasLayer

@export var tower_scene: PackedScene
@export var tower_cost: int = 100

var placing_tower := false
var game_manager: Node2D
@export var portrait_button: TextureButton
@export var portrait_menu: CanvasLayer

func _ready():
	game_manager = get_node("../GameManager")

func _input(event):
	if placing_tower and (event.is_action_pressed("ui_cancel") \
		or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed)):
		game_manager.stop_placing_tower()

# Called by TowerZone when a tower is successfully placed
func tower_placed_successfully():
	game_manager.stop_placing_tower()
	print("Tower placed successfully!")
