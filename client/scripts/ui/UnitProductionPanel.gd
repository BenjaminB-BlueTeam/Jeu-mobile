extends PopupPanel
## Vehicle Factory production panel. Own independent queue (unit_queue),
## can run at the same time as the building queue.

var _unit_id: String = ""

@onready var _title_label: Label = $VBoxContainer/TitleLabel
@onready var _quantity_spin: SpinBox = $VBoxContainer/QuantitySpinBox
@onready var _cost_label: Label = $VBoxContainer/CostLabel
@onready var _time_label: Label = $VBoxContainer/TimeLabel
@onready var _confirm_button: Button = $VBoxContainer/ConfirmButton
@onready var _status_label: Label = $VBoxContainer/StatusLabel

func _ready() -> void:
	_confirm_button.text = I18n.t("ui_produce")
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_quantity_spin.value_changed.connect(func(_v: float) -> void: _refresh_costs())

func open_for(unit_id: String) -> void:
	_unit_id = unit_id
	_title_label.text = I18n.t("unit_" + unit_id)
	_quantity_spin.min_value = 1
	_quantity_spin.max_value = 20
	_quantity_spin.value = 1
	_status_label.text = ""
	_refresh_costs()
	popup_centered()

func _refresh_costs() -> void:
	var quantity := int(_quantity_spin.value)
	var cost := GameState.get_unit_cost(_unit_id, quantity)
	var parts := PackedStringArray()
	for res in cost:
		parts.append("%s %d" % [I18n.t("res_" + res), int(ceil(cost[res]))])
	_cost_label.text = ", ".join(parts)
	_time_label.text = "%ds" % int(ceil(GameState.get_unit_time_seconds(_unit_id, quantity)))

func _on_confirm_pressed() -> void:
	if GameState.unit_queue["active"]:
		_status_label.text = I18n.t("ui_queue_busy")
		return
	var quantity := int(_quantity_spin.value)
	if not GameState.start_unit_production(_unit_id, quantity):
		_status_label.text = I18n.t("ui_insufficient_resources")
		return
	hide()
