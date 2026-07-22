extends Button
## One tappable cell of the world map grid.

var sector_id: String = ""
var sector_data: Dictionary = {}

signal sector_tapped(sector_id: String)

func _ready() -> void:
	pressed.connect(func() -> void: sector_tapped.emit(sector_id))

func set_sector(data: Dictionary, is_player: bool = false) -> void:
	sector_data = data
	sector_id = data.get("id", "")
	text = "HQ" if is_player else data.get("name", "-")
