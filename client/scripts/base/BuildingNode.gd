extends Button
## One tappable building tile on the Base grid. Self-styles into a colored
## panel (fill + border from `accent`) so buildings read as distinct at a
## glance without depending on emoji/glyph font coverage. Pure display
## (name/level) -- costs and timers live in GameState, never computed here.

@export var building_id: String = ""
@export var accent: Color = Color(0.5, 0.5, 0.5)

signal building_tapped(building_id: String)

func _ready() -> void:
	_apply_style()
	pressed.connect(func() -> void: building_tapped.emit(building_id))
	GameState.state_changed.connect(_refresh)
	_refresh()

func _apply_style() -> void:
	add_theme_stylebox_override("normal", _tile_box(accent.darkened(0.4)))
	add_theme_stylebox_override("hover", _tile_box(accent.darkened(0.2)))
	add_theme_stylebox_override("pressed", _tile_box(accent.darkened(0.05)))
	add_theme_color_override("font_color", Color(0.95, 0.95, 0.92))
	add_theme_font_size_override("font_size", 22)

func _tile_box(fill: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = accent
	box.set_border_width_all(3)
	box.set_corner_radius_all(8)
	box.content_margin_left = 8
	box.content_margin_right = 8
	return box

func _refresh() -> void:
	if building_id == "" or not GameState.buildings.has(building_id):
		return
	var level: int = GameState.buildings[building_id]["level"]
	text = "%s\n%s %d" % [I18n.t("building_" + building_id), I18n.t("ui_level_abbr"), level]
