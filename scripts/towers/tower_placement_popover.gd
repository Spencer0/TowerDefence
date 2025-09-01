extends "res://scripts/ui/Popover.gd"
class_name TowerPlacementPopover

# Emits a DICTIONARY payload with the chosen tower {name, cost, scene} and the spot
signal place_tower_selected(choice, placement_spot)

var placing_tower_spot: Node = null
var placement_tower_options: Array = []  # [{name, cost, scene}, ...]

func setup_for_placement(placement_spot, tower_options: Array):
	print("Running")
	placing_tower_spot = placement_spot
	placement_tower_options = tower_options.duplicate(true)

	name_label.text = "Choose Tower"
	labels_container.hide()

	# Reuse the two buttons in BasePopover as Option A/B.
	if placement_tower_options.size() > 0:
		var a = placement_tower_options[0]
		upgrade_damage_button.text = "%s (%d)" % [a.name, int(a.cost)]
		upgrade_damage_button.show()
	else:
		upgrade_damage_button.hide()

	if placement_tower_options.size() > 1:
		var b = placement_tower_options[1]
		upgrade_firerate_button.text = "%s (%d)" % [b.name, int(b.cost)]
		upgrade_firerate_button.show()
	else:
		upgrade_firerate_button.hide()

	show()

func dismiss():
	placing_tower_spot = null
	placement_tower_options.clear()
	super.dismiss()

func _on_upgrade_damage_pressed():
	print("placing")
	if placing_tower_spot and placement_tower_options.size() > 0:
		place_tower_selected.emit(placement_tower_options[0], placing_tower_spot)
		dismiss()

func _on_upgrade_firerate_pressed():
	print("tower 2")
	if placing_tower_spot and placement_tower_options.size() > 1:
		print("tower 2")
		place_tower_selected.emit(placement_tower_options[1], placing_tower_spot)
		dismiss()


func _on_upgrade_fire_rate_button_pressed():
	print("tower 2")
	pass # Replace with function body.
