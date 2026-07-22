extends HBoxContainer
## Displays the lazy-eval projection, refreshed on a short timer -- never
## incremented directly (see GameState.gd header). This is what makes the
## bar visually "rise in real time" from a stored timestamp.

@onready var _steel_label: Label = $SteelLabel
@onready var _components_label: Label = $ComponentsLabel
@onready var _fuel_label: Label = $FuelLabel
@onready var _power_label: Label = $PowerLabel

func _ready() -> void:
	var refresh_timer := Timer.new()
	refresh_timer.wait_time = 0.5
	refresh_timer.autostart = true
	refresh_timer.timeout.connect(_refresh)
	add_child(refresh_timer)
	_refresh()

func _refresh() -> void:
	var res := GameState.get_current_resources()
	_steel_label.text = "%s: %d" % [I18n.t("res_steel"), int(res.get("steel", 0))]
	_components_label.text = "%s: %d" % [I18n.t("res_components"), int(res.get("components", 0))]
	_fuel_label.text = "%s: %d" % [I18n.t("res_fuel"), int(res.get("fuel", 0))]
	_power_label.text = "%s: %d" % [I18n.t("res_power"), int(res.get("power", 0))]
