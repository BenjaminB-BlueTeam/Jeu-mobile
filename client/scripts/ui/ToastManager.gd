extends CanvasLayer
## Global toast notifications (raid return, locked sectors). Built
## programmatically -- no separate Toast.tscn needed for a single label.

var _label: Label

func _ready() -> void:
	layer = 100
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.anchor_left = 0.1
	_label.anchor_right = 0.9
	_label.anchor_top = 0.85
	_label.anchor_bottom = 0.95
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label.modulate.a = 0.0
	add_child(_label)
	GameState.raid_returned.connect(_on_raid_returned)

func _on_raid_returned(sector_name: String, resource: String, amount: float) -> void:
	show_toast(I18n.t("ui_raid_returned_toast", {"amount": int(amount), "resource": I18n.t("res_" + resource)}))

func show_toast(text: String) -> void:
	_label.text = text
	var tween := create_tween()
	tween.tween_property(_label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.5)
	tween.tween_property(_label, "modulate:a", 0.0, 0.5)
