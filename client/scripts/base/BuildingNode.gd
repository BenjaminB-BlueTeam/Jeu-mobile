extends Button
## One tappable building tile on the Base grid. Shows the building sprite
## (Kenney Tiny Battle, CC0) in a colored panel with a name/level label below.
## Pure display -- costs and timers live in GameState, never computed here.

@export var building_id: String = ""
@export var accent: Color = Color(0.5, 0.5, 0.5)
@export var sprite: Texture2D

signal building_tapped(building_id: String)

var _label: Label

func _ready() -> void:
	text = ""
	_apply_style()
	_build_children()
	pressed.connect(func() -> void: building_tapped.emit(building_id))
	GameState.state_changed.connect(_refresh)
	_refresh()

func _build_children() -> void:
	if sprite:
		var icon := TextureRect.new()
		icon.texture = sprite
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.offset_top = 6
		icon.offset_bottom = -32
		add_child(icon)

	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_label.offset_top = -30
	_label.offset_bottom = -2
	_label.add_theme_color_override("font_color", Color(0.97, 0.97, 0.94))
	_label.add_theme_font_size_override("font_size", 18)
	add_child(_label)

func _apply_style() -> void:
	add_theme_stylebox_override("normal", _tile_box(accent.darkened(0.45)))
	add_theme_stylebox_override("hover", _tile_box(accent.darkened(0.25)))
	add_theme_stylebox_override("pressed", _tile_box(accent.darkened(0.1)))

func _tile_box(fill: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = accent
	box.set_border_width_all(3)
	box.set_corner_radius_all(8)
	return box

func _refresh() -> void:
	if building_id == "" or not GameState.buildings.has(building_id) or _label == null:
		return
	var level: int = GameState.buildings[building_id]["level"]
	_label.text = "%s  %s %d" % [I18n.t("building_" + building_id), I18n.t("ui_level_abbr"), level]
