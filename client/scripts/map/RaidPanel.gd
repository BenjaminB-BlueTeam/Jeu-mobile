extends PopupPanel
## Target selection + dispatch. Travel time and unit availability are read
## from GameState, never computed here.

var _sector_id: String = ""

@onready var _title_label: Label = $VBoxContainer/TitleLabel
@onready var _quantity_spin: SpinBox = $VBoxContainer/QuantitySpinBox
@onready var _travel_label: Label = $VBoxContainer/TravelLabel
@onready var _send_button: Button = $VBoxContainer/SendButton
@onready var _status_label: Label = $VBoxContainer/StatusLabel

func _ready() -> void:
	_send_button.text = I18n.t("ui_send_raid")
	_send_button.pressed.connect(_on_send_pressed)

func open_for(sector_id: String) -> void:
	_sector_id = sector_id
	var sector := GameState.find_sector(sector_id)
	var available: int = GameState.units_available.get("light_unit", 0)

	_title_label.text = sector.get("name", "")
	_quantity_spin.min_value = 1
	_quantity_spin.max_value = max(1, available)
	_quantity_spin.value = min(1, max(1, available))

	var travel := GameState.get_raid_travel_time_seconds(sector)
	_travel_label.text = "%s: %ds -- %s: %d" % [I18n.t("ui_send_raid"), int(ceil(travel)), I18n.t("ui_available_units"), available]
	_status_label.text = ""
	popup_centered()

func _on_send_pressed() -> void:
	if GameState.raid["active"] and not GameState.raid["resolved"]:
		_status_label.text = I18n.t("ui_queue_busy")
		return
	var quantity := int(_quantity_spin.value)
	if not GameState.start_raid(_sector_id, quantity):
		_status_label.text = I18n.t("ui_insufficient_resources")
		return
	hide()
