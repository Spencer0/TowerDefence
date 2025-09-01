extends "res://scripts/ui/Popover.gd"
class_name TowerUpgradePopover

signal upgrade_tower_damage(tower_instance)
signal upgrade_tower_firerate(tower_instance)

var inspecting_tower: Node = null

func setup_for_upgrade(tower):
	inspecting_tower = tower
	update_labels_from(tower)
	labels_container.show()
	_update_button_texts(tower)
	show()

func update_stats(tower):
	# Provide the method your GameManager expects.
	update_labels_from(tower)
	_update_button_texts(tower)

func update_labels_from(tower):
	name_label.text = "Name: %s" % str(tower.tower_name if "tower_name" in tower else "Tower")
	damage_label.text = "Damage: %s" % str(tower.damage if "damage" in tower else "?")
	firerate_label.text = "Fire Rate: %s" % str(tower.fire_rate if "fire_rate" in tower else "?")

func _update_button_texts(tower):
	# Get the costs and update button text to include prices
	var damage_cost = tower.get_upgrade_cost("damage") if tower.has_method("get_upgrade_cost") else 0
	var firerate_cost = tower.get_upgrade_cost("firerate") if tower.has_method("get_upgrade_cost") else 0
	
	upgrade_damage_button.text = "Upgrade Damage ($%d)" % damage_cost
	upgrade_firerate_button.text = "Upgrade Firerate ($%d)" % firerate_cost

func dismiss():
	inspecting_tower = null
	super.dismiss()

func _on_upgrade_damage_pressed():
	print("press")
	if inspecting_tower:
		print("press")
		upgrade_tower_damage.emit(inspecting_tower)

func _on_upgrade_firerate_pressed():
	print("press")
	if inspecting_tower:
		print("press")
		upgrade_tower_firerate.emit(inspecting_tower)

func _on_upgrade_fire_rate_button_pressed():
	print("pressed")
	pass # Replace with function body.
