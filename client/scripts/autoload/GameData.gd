extends Node
## Loads the balancing JSON from design/config/ at startup. Data only, no
## logic. PROTOTYPE NOTE: reads via "res://../design/config/..." which only
## resolves when running from the Godot editor/source checkout, not from an
## exported build -- acceptable for this offline feel-test, revisit before
## any real export.

var global_cfg: Dictionary = {}
var buildings_cfg: Dictionary = {}
var units_cfg: Dictionary = {}
var sectors_cfg: Dictionary = {}

func _ready() -> void:
	global_cfg = _load_json("res://../design/config/global.json")
	buildings_cfg = _load_json("res://../design/config/buildings.json")
	units_cfg = _load_json("res://../design/config/units.json")
	sectors_cfg = _load_json("res://../design/config/sectors.json")

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing config file: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(file.get_as_text())
