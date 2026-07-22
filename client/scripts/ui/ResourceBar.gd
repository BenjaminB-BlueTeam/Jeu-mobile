extends HBoxContainer
## Displays the lazy-eval projection (value + production rate per resource) and
## the energy balance as a signed flux. Refreshed on a short timer -- never
## incremented directly (see GameState.gd header). Values/rates are read from
## GameState, never computed here.

const COLOR_SURPLUS := Color(0.55, 0.9, 0.55)
const COLOR_DEFICIT := Color(1.0, 0.5, 0.5)

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
	_steel_label.text = _fmt("res_steel", res.get("steel", 0.0), "steel")
	_components_label.text = _fmt("res_components", res.get("components", 0.0), "components")
	_fuel_label.text = _fmt("res_fuel", res.get("fuel", 0.0), "fuel")

	var energy := GameState.get_energy_report()
	var balance: int = int(round(energy["balance"]))
	_power_label.text = "%s: %+d" % [I18n.t("res_power"), balance]
	_power_label.modulate = COLOR_SURPLUS if balance >= 0 else COLOR_DEFICIT

func _fmt(name_key: String, value: float, resource: String) -> String:
	var rate: int = int(round(GameState.get_production_rate(resource)))
	var suffix := I18n.t("ui_rate_per_hour", {"rate": rate}) if rate > 0 else ""
	return "%s: %d %s" % [I18n.t(name_key), int(value), suffix]
