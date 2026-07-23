extends PopupPanel
## Building upgrade panel: current -> next level, cost, duration. Confirm
## delegates entirely to GameState.start_building -- cost/time shown here are
## read from GameState, never computed in this script.

var _building_id: String = ""

@onready var _title_label: Label = $VBoxContainer/TitleLabel
@onready var _cost_label: Label = $VBoxContainer/CostLabel
@onready var _time_label: Label = $VBoxContainer/TimeLabel
@onready var _confirm_button: Button = $VBoxContainer/ConfirmButton
@onready var _status_label: Label = $VBoxContainer/StatusLabel

func _ready() -> void:
	_confirm_button.pressed.connect(_on_confirm_pressed)

func open_for(building_id: String) -> void:
	_building_id = building_id
	var level: int = GameState.buildings[building_id]["level"]
	_confirm_button.text = I18n.t("ui_build") if level == 0 else I18n.t("ui_upgrade")
	_title_label.text = "%s (%s %d -> %d)" % [I18n.t("building_" + building_id), I18n.t("ui_level_abbr"), level, level + 1]

	var cost := GameState.get_building_cost(building_id)
	var parts := PackedStringArray()
	for res in cost:
		parts.append("%s %d" % [I18n.t("res_" + res), int(ceil(cost[res]))])
	_cost_label.text = ", ".join(parts)

	_time_label.text = "%ds" % int(ceil(GameState.get_build_time_seconds(building_id)))
	_status_label.text = ""
	popup_centered()

func _on_confirm_pressed() -> void:
	if GameState.build_queue["active"]:
		_status_label.text = I18n.t("ui_queue_busy")
		return
	var level: int = GameState.buildings[_building_id]["level"]
	if level == 0 and GameState.get_used_fields() >= GameState.get_max_fields():
		_status_label.text = I18n.t("ui_insufficient_fields")
		return
	if not GameState.start_building(_building_id):
		_status_label.text = I18n.t("ui_insufficient_resources")
		return
	hide()
