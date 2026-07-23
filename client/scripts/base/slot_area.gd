extends Area2D
## One clickable building slot on the BaseMap. Mirrors the old BuildingNode.gd
## (deleted) but in free 2D space instead of a Button grid: a colored rect +
## icon + level label, driven by GameState, refreshed on state_changed.
## Unassigned slots (building_id == "") render as empty terrain and ignore
## input -- reserved for future building types / defenses.

@export var slot_id: Variant = 0
@export var building_id: String = ""
@export var size_tiles: int = 2
@export var tile_size_px: int = 128
@export var accent: Color = Color(0.5, 0.5, 0.5)

signal slot_clicked(building_id: String)

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _background: Polygon2D = $Background
@onready var _icon: Sprite2D = $Icon
@onready var _label: Label = $Label

func _ready() -> void:
	var side: float = size_tiles * tile_size_px
	var shape := RectangleShape2D.new()
	shape.size = Vector2(side, side)
	_collision.shape = shape

	var half := side / 2.0
	_background.polygon = PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half),
	])

	_label.position = Vector2(-half, half - 28)
	_label.size = Vector2(side, 24)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", Color(0.97, 0.97, 0.94))
	_label.add_theme_font_size_override("font_size", 16)

	input_pickable = building_id != ""
	input_event.connect(_on_input_event)
	if building_id != "":
		GameState.state_changed.connect(refresh)
	refresh()

func get_world_center() -> Vector2:
	return global_position

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if building_id == "":
		return
	var pressed: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	if pressed:
		slot_clicked.emit(building_id)

func refresh() -> void:
	if building_id == "":
		_background.color = Color(0.25, 0.3, 0.2, 0.4)
		_icon.texture = null
		_label.text = ""
		return

	if building_id == "headquarters":
		# HQ is config-only/decorative (design/config/buildings.json): it has
		# no entry in GameState.buildings and no level. Render it as a
		# permanently "built" tile without touching GameState at all.
		_icon.texture = AssetResolver.get_building_texture("headquarters", 1)
		_icon.modulate = Color(1, 1, 1, 1)
		_background.color = accent.darkened(0.45)
		_label.text = I18n.t("building_headquarters")
		return

	if not GameState.buildings.has(building_id):
		return
	var level: int = GameState.buildings[building_id]["level"]
	var texture := AssetResolver.get_building_texture(building_id, level)
	if texture:
		_icon.texture = texture
	if level <= 0:
		_background.color = Color(0.15, 0.15, 0.15, 0.35)
		_icon.modulate = Color(1, 1, 1, 0.25)
		_label.text = I18n.t("ui_build")
	else:
		_background.color = accent.darkened(0.45)
		_icon.modulate = Color(1, 1, 1, 1)
		_label.text = "%s  %s %d" % [I18n.t("building_" + building_id), I18n.t("ui_level_abbr"), level]
