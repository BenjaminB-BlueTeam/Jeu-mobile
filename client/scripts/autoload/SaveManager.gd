extends Node
## Local persistence for the prototype: a single user://savegame.json file.
## All timestamps stored are absolute (unix seconds) so lazy-eval keeps
## working correctly across app restarts.

const SAVE_PATH := "user://savegame.json"

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

func save_game(data: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
