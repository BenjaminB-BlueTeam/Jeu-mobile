extends Button
## One tappable cell of the world map grid. Color-codes sector type so the
## player can read the map at a glance (gold = own HQ, green = raidable
## target, red = locked/active, gray = empty).

const COLOR_PLAYER := Color(0.85, 0.65, 0.15, 1)
const COLOR_INACTIVE := Color(0.3, 0.55, 0.25, 1)
const COLOR_ACTIVE := Color(0.55, 0.2, 0.2, 1)
const COLOR_EMPTY := Color(0.25, 0.25, 0.25, 1)

var sector_id: String = ""
var sector_data: Dictionary = {}

signal sector_tapped(sector_id: String)

func _ready() -> void:
	pressed.connect(func() -> void: sector_tapped.emit(sector_id))

func set_sector(data: Dictionary, is_player: bool = false) -> void:
	sector_data = data
	sector_id = data.get("id", "")
	text = "HQ" if is_player else data.get("name", "-")

	if is_player:
		self_modulate = COLOR_PLAYER
	elif data.get("type", "") == "npc_inactive":
		self_modulate = COLOR_INACTIVE
	elif data.get("type", "") == "npc_active":
		self_modulate = COLOR_ACTIVE
	else:
		self_modulate = COLOR_EMPTY
