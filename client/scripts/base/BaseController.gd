extends Node2D
## Root of the Base scene. Wires building taps to the right panel: the 4
## resource producers open the upgrade panel, the Vehicle Factory opens unit
## production instead (it has no meaningful "upgrade" in this prototype,
## see design/config/buildings.json _note).

signal map_requested

const RESOURCE_PRODUCING_BUILDINGS := ["steel_mine", "component_workshop", "fuel_refinery", "power_plant"]

@onready var _building_detail_panel = $CanvasLayer/BuildingDetailPanel
@onready var _unit_production_panel = $CanvasLayer/UnitProductionPanel
@onready var _commander: ColorRect = $BuildingsLayer/CommanderSprite
@onready var _map_button: Button = $CanvasLayer/UI/MapButton

func _ready() -> void:
	var building_positions := {}
	for node in $BuildingsLayer.get_children():
		if node is Button and node.has_signal("building_tapped"):
			building_positions[node.building_id] = node.position
			node.building_tapped.connect(_on_building_tapped)
	_commander.set_building_positions(building_positions)

	_map_button.text = I18n.t("ui_world_map")
	_map_button.pressed.connect(func() -> void: map_requested.emit())

func _on_building_tapped(building_id: String) -> void:
	if building_id in RESOURCE_PRODUCING_BUILDINGS:
		_building_detail_panel.open_for(building_id)
	else:
		_unit_production_panel.open_for("light_unit")
