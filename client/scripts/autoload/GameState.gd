extends Node
## Client-side cache of the server's authoritative state. Never computes
## costs, timers or production itself -- every value comes from the last
## Edge Function response (CLAUDE.md rule #1: zero gameplay logic client-side).

signal state_updated(data: Dictionary)

const POLL_INTERVAL_SECONDS := 30.0

var current_state: Dictionary = {}

func _ready() -> void:
	var poll_timer := Timer.new()
	poll_timer.wait_time = POLL_INTERVAL_SECONDS
	poll_timer.autostart = true
	poll_timer.timeout.connect(_refresh)
	add_child(poll_timer)

	get_tree().root.focus_entered.connect(_refresh)
	SupabaseClient.auth_ready.connect(_refresh)

func _refresh() -> void:
	if SupabaseClient.access_token == "":
		return
	SupabaseClient.call_function("get-base-state", {}, _on_response)

func start_building(building_type: String) -> void:
	SupabaseClient.call_function("start-building", { "building_type": building_type }, _on_response)

func start_research(research_code: String) -> void:
	SupabaseClient.call_function("start-research", { "research_code": research_code }, _on_response)

func _on_response(response_code: int, data) -> void:
	if response_code != 200 or data == null:
		push_warning("Server call failed (%d): %s" % [response_code, str(data)])
		return
	current_state = data
	state_updated.emit(current_state)
