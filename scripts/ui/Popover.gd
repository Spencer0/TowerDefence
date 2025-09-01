# File: BasePopover.gd
extends Control

class_name BasePopover

signal dismissed

@onready var name_label = $PanelContainer/VContainer/LabelsContainer/Name
@onready var damage_label = $PanelContainer/VContainer/LabelsContainer/Damage
@onready var firerate_label = $PanelContainer/VContainer/LabelsContainer/FireRate
@onready var labels_container = $PanelContainer/VContainer/LabelsContainer
@onready var upgrade_damage_button = $PanelContainer/VContainer/UpgradeDamageButton
@onready var upgrade_firerate_button = $PanelContainer/VContainer/UpgradeFireRateButton

func _ready():
	hide()
	upgrade_damage_button.pressed.connect(_on_upgrade_damage_pressed)
	upgrade_firerate_button.pressed.connect(_on_upgrade_firerate_pressed)

# Virtual functions to be overridden by children
func _on_upgrade_damage_pressed():
	print("hit")
	pass

func _on_upgrade_firerate_pressed():
	print("hit")
	pass

func dismiss():
	hide()
	dismissed.emit()
