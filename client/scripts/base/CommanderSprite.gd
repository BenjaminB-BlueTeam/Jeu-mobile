extends ColorRect
## Placeholder Commander (no assets provided/generated for this prototype):
## a colored rect that tweens to the tapped building, holds a "construction"
## pose briefly, then returns to idle -- purely cosmetic, mirrors the design
## decision that the Commander is a client-side visual layer over the
## server's action queue (see univers-du-jeu.md §11, compendium §7).

var _building_positions: Dictionary = {}
var _idle_position: Vector2

func _ready() -> void:
	_idle_position = position
	GameState.commander_move_requested.connect(_on_move_requested)

func set_building_positions(positions: Dictionary) -> void:
	_building_positions = positions

func _on_move_requested(building_id: String) -> void:
	if not _building_positions.has(building_id):
		return
	var target: Vector2 = _building_positions[building_id]
	var tween := create_tween()
	tween.tween_property(self, "position", target, 0.6)
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.3)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3)
	tween.tween_interval(1.0)
	tween.tween_property(self, "position", _idle_position, 0.6)
