extends HBoxContainer
## Displays the lazy-eval projection (value / capacity + production rate per
## resource) and the energy balance as a signed flux. Refreshed on a short
## timer -- never incremented directly (see GameState.gd header). Values, rates
## and capacity are read from GameState, never computed here.

const COLOR_NORMAL := Color(1, 1, 1)
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
	var cap := GameState.get_storage_capacity()
	_set_resource(_steel_label, "res_steel", res.get("steel", 0.0), "steel", cap)
	_set_resource(_components_label, "res_components", res.get("components", 0.0), "components", cap)
	_set_resource(_fuel_label, "res_fuel", res.get("fuel", 0.0), "fuel", cap)

	var energy := GameState.get_energy_report()
	var balance: int = int(round(energy["balance"]))
	_power_label.text = "%s: %+d" % [I18n.t("res_power"), balance]
	_power_label.modulate = COLOR_SURPLUS if balance >= 0 else COLOR_DEFICIT

## Capacity is implicit: never shown. At the cap the resource stops rising and
## its number turns red; otherwise it shows the live production rate.
func _set_resource(label: Label, name_key: String, value: float, resource: String, cap: float) -> void:
	var at_cap := cap != INF and value >= cap - 0.5
	var suffix := ""
	if not at_cap:
		var rate: int = int(round(GameState.get_production_rate(resource)))
		if rate > 0:
			suffix = I18n.t("ui_rate_per_hour", {"rate": rate})
	label.text = "%s: %d %s" % [I18n.t(name_key), int(value), suffix]
	label.modulate = COLOR_DEFICIT if at_cap else COLOR_NORMAL
