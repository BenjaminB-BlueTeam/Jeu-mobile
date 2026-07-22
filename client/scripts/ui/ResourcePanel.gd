extends HBoxContainer
## Displays resource/power values exactly as received from GameState. No
## client-side computation.

@onready var _steel_label: Label = $SteelLabel
@onready var _components_label: Label = $ComponentsLabel
@onready var _fuel_label: Label = $FuelLabel
@onready var _power_label: Label = $PowerLabel

func _ready() -> void:
	GameState.state_updated.connect(_on_state_updated)

func _on_state_updated(data: Dictionary) -> void:
	var resources: Dictionary = data.get("resources", {})
	var power: Dictionary = data.get("power", {})
	_steel_label.text = "%s: %d" % [I18n.t("res_steel"), int(resources.get("steel", 0))]
	_components_label.text = "%s: %d" % [I18n.t("res_components"), int(resources.get("components", 0))]
	_fuel_label.text = "%s: %d" % [I18n.t("res_fuel"), int(resources.get("fuel", 0))]
	_power_label.text = "%s: %d/%d" % [I18n.t("res_power"), int(power.get("available", 0)), int(power.get("required", 0))]
