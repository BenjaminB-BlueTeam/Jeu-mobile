extends Node2D
## Root of the WorldMap scene. Builds the sector grid from
## design/config/sectors.json and wires taps to the raid panel.

signal base_requested

const SECTOR_SCENE := preload("res://scenes/map/SectorNode.tscn")

@onready var _grid: GridContainer = $CanvasLayer/UI/SectorGrid
@onready var _raid_panel = $CanvasLayer/RaidPanel
@onready var _back_button: Button = $CanvasLayer/UI/BackButton

func _ready() -> void:
	_back_button.text = I18n.t("ui_back_to_base")
	_back_button.pressed.connect(func() -> void: base_requested.emit())
	_build_grid()

func _build_grid() -> void:
	var grid_size: int = GameData.sectors_cfg["grid_size"]
	_grid.columns = grid_size

	var player: Dictionary = GameData.sectors_cfg["player_sector"]
	var by_coord := {}
	for sector in GameData.sectors_cfg["sectors"]:
		by_coord["%d_%d" % [sector["x"], sector["y"]]] = sector

	for y in range(grid_size):
		for x in range(grid_size):
			var node: Button = SECTOR_SCENE.instantiate()
			_grid.add_child(node)
			var key := "%d_%d" % [x, y]
			if x == int(player["x"]) and y == int(player["y"]):
				node.set_sector({"id": "player", "name": "HQ"}, true)
				node.disabled = true
			elif by_coord.has(key):
				node.set_sector(by_coord[key])
				node.sector_tapped.connect(_on_sector_tapped)
			else:
				node.set_sector({"id": "", "name": "-"})
				node.disabled = true

func _on_sector_tapped(sector_id: String) -> void:
	var sector := GameState.find_sector(sector_id)
	if sector.is_empty():
		return
	if sector["type"] != "npc_inactive":
		ToastManager.show_toast(I18n.t("ui_sector_locked"))
		return
	_raid_panel.open_for(sector_id)
