extends Node2D
## Root of the BaseMap scene: assembles the base from design/config/
## base_layout.json (slots) + GameState.buildings (levels), purely client-side
## rendering. See docs/superpowers/specs/2026-07-23-base-map-view-design.md.
## Replaces the old Base.tscn/BaseController.gd/BuildingNode.gd (deleted).

signal map_requested

const SLOT_SCENE := preload("res://scenes/base/SlotArea.tscn")
const UNIT_BUILDINGS := ["vehicle_factory"]
const GROUND_ALTERNATIVES := 4
const PATH_COLOR := Color(0.55, 0.42, 0.28, 1)
const PATH_WIDTH := 24.0
const DECOR_COUNT := 40
const DECOR_TEXTURES := ["res://assets/tiles/tree.png", "res://assets/tiles/grass_flowers.png"]

@onready var _ground_layer: TileMapLayer = $GroundLayer
@onready var _paths_layer: Node2D = $PathsLayer
@onready var _decor_layer: Node2D = $DecorLayer
@onready var _buildings_layer: Node2D = $BuildingsLayer
@onready var _commander: Sprite2D = $CommanderSprite
@onready var _camera: Camera2D = $Camera2D
@onready var _canvas_layer: CanvasLayer = $CanvasLayer
@onready var _building_detail_panel = $CanvasLayer/BuildingDetailPanel
@onready var _unit_production_panel = $CanvasLayer/UnitProductionPanel
@onready var _map_button: Button = $CanvasLayer/UI/MapButton

var _base_id: String = "base_local_1"
var _biome: String = "plains"
var _configured := false

func _ready() -> void:
	_map_button.text = I18n.t("ui_world_map")
	_map_button.pressed.connect(func() -> void: map_requested.emit())
	if not _configured:
		configure(_base_id, _biome)

## Public entry point: Main.gd calls this before the scene is first shown (or
## right after instancing) with the base to display. Safe to call once; if
## _ready() runs before configure() is called, it configures with defaults so
## the scene is still viewable standalone (e.g. running BaseMap.tscn directly
## for a quick check).
func configure(base_id: String, biome: String) -> void:
	_base_id = base_id
	_biome = biome
	_configured = true
	_clear_dynamic_layers()
	_build_ground()
	_build_slots()
	_build_paths()
	_build_decor()
	_setup_camera()

## Removes all previously-built ground cells / slots / paths / decor so
## configure() is idempotent -- it can safely run more than once (it does on
## every real run: BaseMap's own _ready() self-configures with defaults before
## Main._ready() gets a chance to call configure() explicitly with the real
## base, since child _ready() runs before parent _ready() in Godot). Uses
## .free() (immediate) rather than .queue_free() (deferred) because the
## rebuild functions below run later in this same call and need the layers to
## already be genuinely empty, not just scheduled for removal.
func _clear_dynamic_layers() -> void:
	_ground_layer.clear()
	for child in _buildings_layer.get_children():
		child.free()
	for child in _paths_layer.get_children():
		child.free()
	for child in _decor_layer.get_children():
		child.free()

func _build_ground() -> void:
	var grid: Dictionary = GameData.base_layout_cfg["grid_size"]
	for y in range(grid["h"]):
		for x in range(grid["w"]):
			var seed_val: int = hash("%s_%d_%d" % [_base_id, x, y])
			var alt: int = seed_val % GROUND_ALTERNATIVES
			_ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0), alt)

func _slot_center(rect: Dictionary, tile_size: int) -> Vector2:
	var half: float = rect["size"] * tile_size / 2.0
	return Vector2(rect["x"] * tile_size + half, rect["y"] * tile_size + half)

func _build_slots() -> void:
	var layout: Dictionary = GameData.base_layout_cfg
	var tile_size: int = layout["tile_size_px"]
	var assignments: Dictionary = layout["assignments"]
	var by_slot_id := {}
	for building_id in assignments:
		by_slot_id[assignments[building_id]] = building_id

	var building_positions := {}
	var all_slot_defs: Array = [dict_with_id(layout["hq_slot"], "hq")] + layout["slots"] + layout["defense_slots"]
	for rect in all_slot_defs:
		var slot: Area2D = SLOT_SCENE.instantiate()
		slot.slot_id = rect["id"]
		slot.size_tiles = rect["size"]
		slot.tile_size_px = tile_size
		slot.building_id = by_slot_id.get(rect["id"], "")
		slot.position = _slot_center(rect, tile_size)
		_buildings_layer.add_child(slot)
		if slot.building_id != "":
			slot.accent = _accent_for(slot.building_id)
			# HQ is decorative only (see design/config/buildings.json):
			# not tappable, no mechanical effect. Override SlotArea's generic
			# default (input_pickable = building_id != "") which would
			# otherwise make it clickable, and skip the click wiring entirely.
			if slot.building_id == "headquarters":
				slot.input_pickable = false
			else:
				slot.slot_clicked.connect(_on_slot_clicked)
			building_positions[slot.building_id] = slot.get_world_center()

	_commander.set_building_positions(building_positions)

func dict_with_id(rect: Dictionary, id_value) -> Dictionary:
	var copy := rect.duplicate()
	copy["id"] = id_value
	return copy

func _accent_for(building_id: String) -> Color:
	var accents := {
		"headquarters": Color(0.85, 0.65, 0.15, 1),
		"steel_mine": Color(0.62, 0.66, 0.72, 1),
		"component_workshop": Color(0.35, 0.62, 0.78, 1),
		"fuel_refinery": Color(0.82, 0.5, 0.24, 1),
		"power_plant": Color(0.85, 0.78, 0.3, 1),
		"storage_depot": Color(0.55, 0.5, 0.68, 1),
		"vehicle_factory": Color(0.5, 0.55, 0.32, 1),
		"advanced_reactor": Color(0.8, 0.35, 0.2, 1),
		"auxiliary_generator": Color(0.7, 0.75, 0.45, 1),
		"engineering_corps": Color(0.3, 0.6, 0.6, 1),
		"land_clearing": Color(0.55, 0.42, 0.28, 1),
	}
	return accents.get(building_id, Color(0.5, 0.5, 0.5, 1))

## Connects HQ + assigned slots with straight Line2D segments, greedily
## nearest-neighbor from HQ outward (a small Prim's-algorithm-style tree) --
## an organic branching path derived purely from slot geometry, no extra config.
func _build_paths() -> void:
	var centers: Array[Vector2] = []
	for child in _buildings_layer.get_children():
		if child is Area2D and child.building_id != "":
			centers.append(child.position)
	if centers.size() < 2:
		return
	var connected: Array[Vector2] = [centers[0]]
	var remaining: Array[Vector2] = centers.slice(1)
	while remaining.size() > 0:
		var best_i := -1
		var best_dist := INF
		var best_from := Vector2.ZERO
		for i in remaining.size():
			for from in connected:
				var d: float = from.distance_to(remaining[i])
				if d < best_dist:
					best_dist = d
					best_i = i
					best_from = from
		var to: Vector2 = remaining[best_i]
		var line := Line2D.new()
		line.points = PackedVector2Array([best_from, to])
		line.width = PATH_WIDTH
		line.default_color = PATH_COLOR
		_paths_layer.add_child(line)
		connected.append(to)
		remaining.remove_at(best_i)

func _occupied_cells() -> Dictionary:
	var occupied := {}
	var layout: Dictionary = GameData.base_layout_cfg
	var all_rects: Array = [dict_with_id(layout["hq_slot"], "hq")] + layout["slots"] + layout["defense_slots"]
	for rect in all_rects:
		for dx in range(rect["size"]):
			for dy in range(rect["size"]):
				occupied[Vector2i(rect["x"] + dx, rect["y"] + dy)] = true
	return occupied

## Procedural decor (trees/flowers), seeded by base_id so it's stable across
## reloads of the same base but varies between bases. Denser near the map
## edges (framing effect, cf. design/da/reference-01.jpg) than in the open
## interior where slots/paths need to stay readable.
func _build_decor() -> void:
	var layout: Dictionary = GameData.base_layout_cfg
	var tile_size: int = layout["tile_size_px"]
	var grid: Dictionary = layout["grid_size"]
	var occupied := _occupied_cells()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(_base_id + "_decor")

	var placed := 0
	var attempts := 0
	while placed < DECOR_COUNT and attempts < DECOR_COUNT * 20:
		attempts += 1
		var x: int = rng.randi_range(0, grid["w"] - 1)
		var y: int = rng.randi_range(0, grid["h"] - 1)
		var cell := Vector2i(x, y)
		if occupied.has(cell):
			continue
		var edge_dist: int = min(min(x, grid["w"] - 1 - x), min(y, grid["h"] - 1 - y))
		if edge_dist > 2 and rng.randf() > 0.25:
			continue
		var sprite := Sprite2D.new()
		sprite.texture = load(DECOR_TEXTURES[rng.randi_range(0, DECOR_TEXTURES.size() - 1)])
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = Vector2(x * tile_size + tile_size / 2.0, y * tile_size + tile_size / 2.0)
		sprite.scale = Vector2(6, 6)
		_decor_layer.add_child(sprite)
		occupied[cell] = true
		placed += 1

func _setup_camera() -> void:
	var layout: Dictionary = GameData.base_layout_cfg
	var tile_size: int = layout["tile_size_px"]
	var grid: Dictionary = layout["grid_size"]
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = grid["w"] * tile_size
	_camera.limit_bottom = grid["h"] * tile_size
	_camera.position = Vector2(grid["w"] * tile_size / 2.0, grid["h"] * tile_size / 2.0)

## CanvasLayer ignores its Node2D parent's `visible` -- must be toggled
## explicitly or it stays drawn on top of whichever scene is active.
func set_active(active: bool) -> void:
	visible = active
	_canvas_layer.visible = active

func _on_slot_clicked(building_id: String) -> void:
	if building_id in UNIT_BUILDINGS:
		_unit_production_panel.open_for("light_unit")
	else:
		_building_detail_panel.open_for(building_id)
