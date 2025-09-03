# TowerUpgradeTooltip.gd
extends BaseTooltip
class_name TowerUpgradeTooltip

signal upgrade_tower_damage(tower_instance)
signal upgrade_tower_firerate(tower_instance)

var inspecting_tower: Node = null

# UI References
@onready var stats_container: VBoxContainer = $PanelContainer/ContentContainer/VBoxContainer/StatsContainer
@onready var name_label: Label = $PanelContainer/ContentContainer/VBoxContainer/StatsContainer/NameLabel
@onready var damage_label: Label = $PanelContainer/ContentContainer/VBoxContainer/StatsContainer/DamageLabel
@onready var firerate_label: Label = $PanelContainer/ContentContainer/VBoxContainer/StatsContainer/FirerateLabel
@onready var buttons_container: VBoxContainer = $PanelContainer/ContentContainer/VBoxContainer/ButtonsContainer
@onready var upgrade_damage_button: Button = $PanelContainer/ContentContainer/VBoxContainer/ButtonsContainer/UpgradeDamageButton
@onready var upgrade_firerate_button: Button = $PanelContainer/ContentContainer/VBoxContainer/ButtonsContainer/UpgradeFirerateButton

func _ready() -> void:
	super._ready()
	setup_connections()
	
func setup_connections() -> void:
	upgrade_damage_button.pressed.connect(_on_upgrade_damage_pressed)
	upgrade_firerate_button.pressed.connect(_on_upgrade_firerate_pressed)

func setup_for_upgrade(tower: Node) -> void:
	inspecting_tower = tower
	update_display(tower)
	show_tooltip()

func update_display(tower: Node) -> void:
	update_labels(tower)
	update_buttons(tower)

func update_labels(tower: Node) -> void:
	var tower_name = tower.get("tower_name") if tower.has_method("get") else "Tower"
	var damage = tower.get("damage") if tower.has_method("get") else "?"
	var fire_rate = tower.get("fire_rate") if tower.has_method("get") else "?"
	
	name_label.text = str(tower_name)
	damage_label.text = "Damage: %s" % str(damage)
	firerate_label.text = "Fire Rate: %s" % str(fire_rate)

func update_buttons(tower: Node) -> void:
	var damage_cost = 0
	var firerate_cost = 0
	
	if tower.has_method("get_upgrade_cost"):
		damage_cost = tower.get_upgrade_cost("damage")
		firerate_cost = tower.get_upgrade_cost("firerate")
	
	upgrade_damage_button.text = "Upgrade Damage ($%d)" % damage_cost
	upgrade_firerate_button.text = "Upgrade Firerate ($%d)" % firerate_cost

func update_stats(tower: Node) -> void:
	update_display(tower)

func dismiss() -> void:
	inspecting_tower = null
	super.dismiss()

func _on_upgrade_damage_pressed() -> void:
	if inspecting_tower:
		upgrade_tower_damage.emit(inspecting_tower)

func _on_upgrade_firerate_pressed() -> void:
	if inspecting_tower:
		upgrade_tower_firerate.emit(inspecting_tower)
