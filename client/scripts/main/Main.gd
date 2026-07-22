extends Node
## Switches between Base and WorldMap, and saves on window close so the
## lazy-eval timestamp is fresh for the next session.

@onready var _base: Node2D = $Base
@onready var _map: Node2D = $WorldMap

func _ready() -> void:
	_base.map_requested.connect(_show_map)
	_map.base_requested.connect(_show_base)
	_show_base()
	get_tree().root.close_requested.connect(_on_close_requested)

func _show_base() -> void:
	_base.visible = true
	_map.visible = false

func _show_map() -> void:
	_base.visible = false
	_map.visible = true

func _on_close_requested() -> void:
	GameState.save_now()
	get_tree().quit()
