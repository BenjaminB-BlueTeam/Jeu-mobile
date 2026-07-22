extends Label
## Countdown display only. completed_at is a server timestamp; the remaining
## time is recomputed every frame from it, never advanced independently.

var _completed_at_unix: float = -1.0
var _building_type: String = ""

func _ready() -> void:
	GameState.state_updated.connect(_on_state_updated)

func _process(_delta: float) -> void:
	if _completed_at_unix < 0.0:
		return
	var remaining := _completed_at_unix - Time.get_unix_time_from_system()
	if remaining <= 0.0:
		text = ""
		_completed_at_unix = -1.0
		return
	text = "%s: %s" % [I18n.t("building_" + _building_type), _format_duration(remaining)]

func _on_state_updated(data: Dictionary) -> void:
	var queue = data.get("building_queue")
	if queue == null:
		_completed_at_unix = -1.0
		text = ""
		return
	_building_type = queue.get("building_type", "")
	_completed_at_unix = Time.get_unix_time_from_datetime_string(queue.get("completed_at", ""))

func _format_duration(seconds: float) -> String:
	var s := int(seconds)
	return "%02d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]
