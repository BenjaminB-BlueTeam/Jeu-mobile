extends Sprite2D
## The Commander: a tank sprite (Kenney Tiny Battle, CC0) that tweens to the
## tapped building's slot center, bumps, then returns to idle -- purely
## cosmetic, mirrors the design decision that the Commander is a client-side
## visual layer over the server's action queue (see univers-du-jeu.md §11,
## compendium §7). Positions are slot *centers*, supplied by BaseMap (see
## docs/superpowers/specs/2026-07-23-base-map-view-design.md §5) -- no offset
## math here, unlike the old Button-grid version.

var _building_positions: Dictionary = {}
var _idle_position: Vector2

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
	tween.tween_property(self, "scale", scale * 1.2, 0.3)
	tween.tween_property(self, "scale", scale, 0.3)
	tween.tween_interval(1.0)
	tween.tween_property(self, "position", _idle_position, 0.6)
