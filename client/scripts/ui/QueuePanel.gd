extends Label
## Countdown display for all 3 independent queues (construction, unit
## production, raid). Pure display: remaining time is recomputed every frame
## from the stored completed_at/return_at timestamps, never advanced on its
## own.

func _process(_delta: float) -> void:
	var parts := PackedStringArray()
	var now := Time.get_unix_time_from_system()

	if GameState.build_queue["active"]:
		var remaining: int = max(0, GameState.build_queue["completed_at"] - now)
		parts.append("%s: %ds" % [I18n.t("building_" + GameState.build_queue["building_id"]), remaining])

	if GameState.unit_queue["active"]:
		var remaining_units: int = max(0, GameState.unit_queue["completed_at"] - now)
		parts.append("%s x%d: %ds" % [I18n.t("unit_" + GameState.unit_queue["unit_id"]), int(GameState.unit_queue["quantity"]), remaining_units])

	if GameState.raid["active"] and not GameState.raid["resolved"]:
		var remaining_raid: int = max(0, GameState.raid["return_at"] - now)
		parts.append("%s: %ds" % [I18n.t("ui_send_raid"), remaining_raid])

	text = "\n".join(parts)
