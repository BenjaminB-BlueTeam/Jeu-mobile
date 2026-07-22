extends Node2D
## Root of the Base scene. Wires the grid, the build menu and GameState
## together. No gameplay computation: only forwards player intent
## (start_building) to the server and renders whatever GameState reports.

const GRID_SIZE := 5
const BUILDING_SLOT_SCENE := preload("res://scenes/base/BuildingSlot.tscn")

@onready var _grid: GridContainer = $CanvasLayer/UI/BaseGrid
@onready var _build_menu = $CanvasLayer/BuildMenu

func _ready() -> void:
	_grid.columns = GRID_SIZE
	for i in range(GRID_SIZE * GRID_SIZE):
		var slot := BUILDING_SLOT_SCENE.instantiate()
		slot.slot_pressed.connect(_on_slot_pressed)
		_grid.add_child(slot)

	GameState.state_updated.connect(_on_state_updated)
	_build_menu.build_selected.connect(_on_build_selected)

func _on_slot_pressed(_building_type: String) -> void:
	_build_menu.popup_centered()

func _on_build_selected(building_type: String) -> void:
	GameState.start_building(building_type)

func _on_state_updated(data: Dictionary) -> void:
	var buildings: Array = data.get("buildings", [])
	var slots := _grid.get_children()
	for i in range(slots.size()):
		if i < buildings.size():
			slots[i].set_building(buildings[i]["building_type"], buildings[i]["level"])
		else:
			slots[i].set_building("", 0)
