extends Button
## One tappable building on the Base grid. Pure display (name/level) --
## costs and timers live in GameState, never computed here.

@export var building_id: String = ""

signal building_tapped(building_id: String)

func _ready() -> void:
	pressed.connect(func() -> void: building_tapped.emit(building_id))
	GameState.state_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	if building_id == "" or not GameState.buildings.has(building_id):
		return
	var level: int = GameState.buildings[building_id]["level"]
	text = "%s\n%s %d" % [I18n.t("building_" + building_id), I18n.t("ui_level_abbr"), level]
