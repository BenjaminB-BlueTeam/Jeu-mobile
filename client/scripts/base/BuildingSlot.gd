extends Button
## Grid placeholder for one building. Pure display: level/name text comes
## from server data, no formulas computed here.

var building_type: String = ""
var level: int = 0

signal slot_pressed(building_type: String)

func _ready() -> void:
	pressed.connect(func() -> void: slot_pressed.emit(building_type))

func set_building(new_type: String, new_level: int) -> void:
	building_type = new_type
	level = new_level
	if new_type == "":
		text = I18n.t("slot_empty")
	else:
		text = "%s\n%s %d" % [I18n.t("building_" + new_type), I18n.t("level_abbr"), level]
