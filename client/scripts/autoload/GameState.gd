extends Node
## PROTOTYPE core-loop: ALL gameplay logic (costs, timers, production, raid
## resolution) runs HERE, client-side, in GDScript. This is a throwaway
## feel-test, NOT how the real game works: Iron Front's final architecture is
## server-authoritative (see CLAUDE.md at repo root) -- the server computes,
## the client only displays and sends commands. Nothing in this file should
## be reused once the server-authoritative client is built (see the separate,
## unrelated `phase-1-economy` branch for that architecture).
##
## Lazy evaluation is still used here (same principle as the real design):
## resources are never incremented frame-by-frame. A timestamp
## (`resources_last_collected_at`) is stored, and every read projects
## `stored + rate_per_hour * elapsed_hours`. The projection is "flushed"
## (frozen into `resources`, timestamp reset) at 3 moments only: before a
## production rate changes (building level-up), before a spend, and before
## saving -- see `_flush_resources()`.

signal state_changed
signal commander_move_requested(building_id: String)
signal raid_returned(sector_name: String, resource: String, amount: float)

const RESOURCE_KEYS := ["steel", "components", "fuel", "power"]
const BUILDING_TO_RESOURCE := {
	"steel_mine": "steel",
	"component_workshop": "components",
	"fuel_refinery": "fuel",
	"power_plant": "power",
}

var resources: Dictionary = {"steel": 500.0, "components": 0.0, "fuel": 0.0, "power": 0.0}
var resources_last_collected_at: int = 0

var buildings: Dictionary = {
	"steel_mine": {"level": 1},
	"component_workshop": {"level": 1},
	"fuel_refinery": {"level": 1},
	"power_plant": {"level": 1},
	"vehicle_factory": {"level": 1},
}

var build_queue: Dictionary = {"active": false, "building_id": "", "target_level": 0, "started_at": 0, "completed_at": 0}
var unit_queue: Dictionary = {"active": false, "unit_id": "light_unit", "quantity": 0, "started_at": 0, "completed_at": 0}
var units_available: Dictionary = {"light_unit": 0}
var raid: Dictionary = {"active": false, "target_sector_id": "", "sent_units": {}, "departed_at": 0, "return_at": 0, "resolved": true}

func _ready() -> void:
	var loaded := SaveManager.load_game()
	if loaded.is_empty():
		resources_last_collected_at = Time.get_unix_time_from_system()
	else:
		_apply_save(loaded)

	_resolve_build_queue()
	_resolve_unit_queue()
	_resolve_raid()

	var poll_timer := Timer.new()
	poll_timer.wait_time = 1.0
	poll_timer.autostart = true
	poll_timer.timeout.connect(_on_poll_tick)
	add_child(poll_timer)

func _apply_save(data: Dictionary) -> void:
	resources = data.get("resources", resources)
	resources_last_collected_at = data.get("resources_last_collected_at", Time.get_unix_time_from_system())
	buildings = data.get("buildings", buildings)
	build_queue = data.get("build_queue", build_queue)
	unit_queue = data.get("unit_queue", unit_queue)
	units_available = data.get("units_available", units_available)
	raid = data.get("raid", raid)

func _on_poll_tick() -> void:
	var had_active: bool = build_queue["active"] or unit_queue["active"] or (raid["active"] and not raid["resolved"])
	_resolve_build_queue()
	_resolve_unit_queue()
	_resolve_raid()
	if had_active:
		state_changed.emit()

## ---- Lazy-eval resource projection ----

func _production_rate_per_hour(building_id: String) -> float:
	var resource: String = BUILDING_TO_RESOURCE.get(building_id, "")
	if resource == "":
		return 0.0
	var level: int = buildings[building_id]["level"]
	if level <= 0:
		return 0.0
	var cfg: Dictionary = GameData.buildings_cfg[building_id]
	var coef: float = cfg["produces"]["coef"]
	var growth: float = GameData.global_cfg["production_growth"]
	return coef * level * pow(growth, level)

## Pure read: projects resources up to `as_of` (defaults to now) WITHOUT
## mutating state.
func get_current_resources(as_of: int = -1) -> Dictionary:
	var now: int = as_of if as_of >= 0 else Time.get_unix_time_from_system()
	var elapsed_hours: float = max(0.0, (now - resources_last_collected_at) / 3600.0)
	var projected := {}
	for key in RESOURCE_KEYS:
		var building_id := ""
		for b in BUILDING_TO_RESOURCE:
			if BUILDING_TO_RESOURCE[b] == key:
				building_id = b
		var rate: float = _production_rate_per_hour(building_id) if building_id != "" else 0.0
		projected[key] = resources[key] + rate * elapsed_hours
	return projected

## Freezes the projection into `resources` as of `as_of` (defaults to now).
## MUST run before any rate change or spend -- see file header.
func _flush_resources(as_of: int = -1) -> void:
	var now: int = as_of if as_of >= 0 else Time.get_unix_time_from_system()
	resources = get_current_resources(now)
	resources_last_collected_at = now

func can_afford(cost: Dictionary) -> bool:
	var current := get_current_resources()
	for res in cost:
		if current.get(res, 0.0) < cost[res]:
			return false
	return true

## ---- Building queue ----

func get_building_cost(building_id: String) -> Dictionary:
	var cfg: Dictionary = GameData.buildings_cfg[building_id]
	var level: int = buildings[building_id]["level"]
	var factor: float = cfg["cost_factor"]
	var multiplier: float = pow(factor, level)
	var cost := {}
	for res in cfg["base_cost"]:
		cost[res] = cfg["base_cost"][res] * multiplier
	return cost

func _time_from_cost_seconds(cost: Dictionary) -> float:
	var steel_cost: float = cost.get("steel", 0.0)
	var components_cost: float = cost.get("components", 0.0)
	var divisor: float = GameData.global_cfg["build_time_divisor"]
	var speed: float = GameData.global_cfg["speed_factor"]
	return ((steel_cost + components_cost) / (divisor * speed)) * 3600.0

func get_build_time_seconds(building_id: String) -> float:
	return _time_from_cost_seconds(get_building_cost(building_id))

func start_building(building_id: String) -> bool:
	_resolve_build_queue()
	if build_queue["active"]:
		return false
	var cost := get_building_cost(building_id)
	if not can_afford(cost):
		return false

	_flush_resources()
	for res in cost:
		resources[res] -= cost[res]

	var now := Time.get_unix_time_from_system()
	var duration := get_build_time_seconds(building_id)
	build_queue = {
		"active": true, "building_id": building_id,
		"target_level": buildings[building_id]["level"] + 1,
		"started_at": now, "completed_at": now + int(ceil(duration)),
	}
	commander_move_requested.emit(building_id)
	SaveManager.save_game(export_state())
	state_changed.emit()
	return true

func _resolve_build_queue() -> void:
	if not build_queue["active"]:
		return
	var completed_at: int = build_queue["completed_at"]
	if Time.get_unix_time_from_system() < completed_at:
		return

	_flush_resources(completed_at)
	var building_id: String = build_queue["building_id"]
	buildings[building_id]["level"] = build_queue["target_level"]
	build_queue = {"active": false, "building_id": "", "target_level": 0, "started_at": 0, "completed_at": 0}
	SaveManager.save_game(export_state())

## ---- Unit production queue (independent from the building queue) ----

func get_unit_cost(unit_id: String, quantity: int) -> Dictionary:
	var cfg: Dictionary = GameData.units_cfg[unit_id]
	var cost := {}
	for res in cfg["base_cost"]:
		cost[res] = cfg["base_cost"][res] * quantity
	return cost

func get_unit_time_seconds(unit_id: String, quantity: int) -> float:
	return _time_from_cost_seconds(get_unit_cost(unit_id, quantity))

func start_unit_production(unit_id: String, quantity: int) -> bool:
	_resolve_unit_queue()
	if unit_queue["active"] or quantity <= 0:
		return false
	var cost := get_unit_cost(unit_id, quantity)
	if not can_afford(cost):
		return false

	_flush_resources()
	for res in cost:
		resources[res] -= cost[res]

	var now := Time.get_unix_time_from_system()
	var duration := get_unit_time_seconds(unit_id, quantity)
	unit_queue = {
		"active": true, "unit_id": unit_id, "quantity": quantity,
		"started_at": now, "completed_at": now + int(ceil(duration)),
	}
	SaveManager.save_game(export_state())
	state_changed.emit()
	return true

func _resolve_unit_queue() -> void:
	if not unit_queue["active"]:
		return
	if Time.get_unix_time_from_system() < unit_queue["completed_at"]:
		return

	var unit_id: String = unit_queue["unit_id"]
	units_available[unit_id] = units_available.get(unit_id, 0) + unit_queue["quantity"]
	unit_queue = {"active": false, "unit_id": "light_unit", "quantity": 0, "started_at": 0, "completed_at": 0}
	SaveManager.save_game(export_state())

## ---- Raid (single global travel timer, one convoy at a time) ----

func _find_sector(sector_id: String) -> Dictionary:
	for sector in GameData.sectors_cfg["sectors"]:
		if sector["id"] == sector_id:
			return sector
	return {}

func get_raid_travel_time_seconds(sector: Dictionary) -> float:
	var player: Dictionary = GameData.sectors_cfg["player_sector"]
	var dx: float = sector["x"] - player["x"]
	var dy: float = sector["y"] - player["y"]
	var distance: float = sqrt(dx * dx + dy * dy)
	var per_distance: float = GameData.units_cfg["light_unit"]["travel_time_seconds_per_distance"]
	var speed: float = GameData.global_cfg["speed_factor"]
	return max(1.0, (distance * per_distance) / speed)

func start_raid(sector_id: String, quantity: int) -> bool:
	if raid["active"] and not raid["resolved"]:
		return false
	if quantity <= 0 or units_available.get("light_unit", 0) < quantity:
		return false
	var sector := _find_sector(sector_id)
	if sector.is_empty() or sector["type"] != "npc_inactive":
		return false

	units_available["light_unit"] -= quantity
	var now := Time.get_unix_time_from_system()
	var travel := get_raid_travel_time_seconds(sector)
	raid = {
		"active": true, "target_sector_id": sector_id,
		"sent_units": {"light_unit": quantity},
		"departed_at": now, "return_at": now + int(ceil(travel)), "resolved": false,
	}
	SaveManager.save_game(export_state())
	state_changed.emit()
	return true

func _resolve_raid() -> void:
	if not raid["active"] or raid["resolved"]:
		return
	if Time.get_unix_time_from_system() < raid["return_at"]:
		return

	var sector := _find_sector(raid["target_sector_id"])
	units_available["light_unit"] = units_available.get("light_unit", 0) + int(raid["sent_units"].get("light_unit", 0))

	var looted_resource := ""
	var looted_amount := 0.0
	if not sector.is_empty():
		var loot: Dictionary = sector.get("loot", {})
		var loot_rate: float = GameData.global_cfg["loot_rate_inactive"]
		_flush_resources(raid["return_at"])
		for res in loot:
			var amount: float = loot[res] * loot_rate
			resources[res] = resources.get(res, 0.0) + amount
			if amount > looted_amount:
				looted_amount = amount
				looted_resource = res

	raid["active"] = false
	raid["resolved"] = true
	SaveManager.save_game(export_state())
	if looted_resource != "":
		raid_returned.emit(sector.get("name", ""), looted_resource, looted_amount)

## ---- Persistence ----

func export_state() -> Dictionary:
	return {
		"save_version": 1,
		"resources": resources,
		"resources_last_collected_at": resources_last_collected_at,
		"buildings": buildings,
		"build_queue": build_queue,
		"unit_queue": unit_queue,
		"units_available": units_available,
		"raid": raid,
	}

func save_now() -> void:
	_flush_resources()
	SaveManager.save_game(export_state())
