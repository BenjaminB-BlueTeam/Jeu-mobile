extends Button
## One tappable building tile on the Base grid. Shows the building sprite
## (Kenney Tiny Battle, CC0) in a colored panel with a name/level label below.
## Pure display -- costs and timers live in GameState, never computed here.
##
## Two extra display states on top of the base T1/T2 look:
## - level == 0 ("unbuilt"): dimmed placeholder tile, "Construire" label, no
##   sprite tint, no rank badge. Tapping it still opens BuildingDetailPanel,
##   which offers the "Build" (level 0 -> 1) flow.
## - level >= 1: a visual "tier" (1 + floor((level-1)/5), i.e. one step every
##   5 levels) brightens the border and icon and adds a chevron rank badge,
##   purely cosmetic, no new PNG assets (see docs/superpowers/specs/
##   2026-07-23-t3-construction-champs-design.md §4).

@export var building_id: String = ""
@export var accent: Color = Color(0.5, 0.5, 0.5)
@export var sprite: Texture2D

signal building_tapped(building_id: String)

var _label: Label
var _rank_label: Label
var _icon: TextureRect

func _ready() -> void:
	text = ""
	_build_children()
	pressed.connect(func() -> void: building_tapped.emit(building_id))
	GameState.state_changed.connect(_refresh)
	_refresh()

func _build_children() -> void:
	if sprite:
		_icon = TextureRect.new()
		_icon.texture = sprite
		_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		_icon.offset_top = 6
		_icon.offset_bottom = -32
		add_child(_icon)

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

	_rank_label = Label.new()
	_rank_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_rank_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_rank_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_rank_label.offset_left = -80
	_rank_label.offset_top = 4
	_rank_label.offset_right = -6
	_rank_label.offset_bottom = 24
	_rank_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.4, 1))
	_rank_label.add_theme_font_size_override("font_size", 14)
	add_child(_rank_label)

func _tile_box(fill: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border_color
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(8)
	return box

## tier 1 = levels 1-5, tier 2 = levels 6-10, etc. Border/icon brighten with
## tier; Godot 4's StyleBoxFlat has no dashed-border support, so the "unbuilt"
## state (see _apply_unbuilt_style) uses a thin translucent border instead of
## a dashed one to read as "not here yet".
func _apply_built_style(tier: int) -> void:
	var lighten: float = min(0.12 * (tier - 1), 0.5)
	var border_color: Color = accent.lerp(Color.WHITE, lighten)
	var border_width: int = 3 + (tier - 1) * 2
	add_theme_stylebox_override("normal", _tile_box(accent.darkened(0.45), border_color, border_width))
	add_theme_stylebox_override("hover", _tile_box(accent.darkened(0.25), border_color, border_width))
	add_theme_stylebox_override("pressed", _tile_box(accent.darkened(0.1), border_color, border_width))
	if _icon:
		_icon.modulate = Color.WHITE.lerp(Color(0.85, 0.92, 1.0), lighten)

func _apply_unbuilt_style() -> void:
	var box := _tile_box(Color(0.15, 0.15, 0.15, 0.35), Color(0.6, 0.6, 0.6, 0.6), 2)
	add_theme_stylebox_override("normal", box)
	add_theme_stylebox_override("hover", box)
	add_theme_stylebox_override("pressed", box)
	if _icon:
		_icon.modulate = Color(1, 1, 1, 0.25)

func _refresh() -> void:
	if building_id == "" or not GameState.buildings.has(building_id) or _label == null:
		return
	var level: int = GameState.buildings[building_id]["level"]
	if level <= 0:
		_apply_unbuilt_style()
		_label.text = I18n.t("ui_build")
		_rank_label.text = ""
		return
	var tier: int = 1 + int(floor(float(level - 1) / 5.0))
	_apply_built_style(tier)
	_label.text = "%s  %s %d" % [I18n.t("building_" + building_id), I18n.t("ui_level_abbr"), level]
	_rank_label.text = "▲".repeat(tier - 1)
