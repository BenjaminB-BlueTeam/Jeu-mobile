extends Node
## Single source of truth for resolving building/ground sprites, with a
## cascading fallback so tiered art can be generated progressively without any
## code change. Stateless: every function is a pure resolution given inputs.
## Replaces the logic formerly local to BuildingNode.gd (deleted, see
## docs/superpowers/specs/2026-07-23-base-map-view-design.md §2/§5).

## design/docs/direction-artistique.md §12:
## tier = clamp(floor(level/levels_per_tier) + 1, 1, max_tier).
func _building_tier(building_id: String, level: int) -> int:
	var cfg: Dictionary = GameData.buildings_cfg.get(building_id, {}).get("visual_tier", {})
	var levels_per_tier: int = cfg.get("levels_per_tier", 10)
	var max_tier_level: int = cfg.get("max_tier_level", 40)
	var max_tier: int = int(max_tier_level / levels_per_tier)
	return clamp(int(floor(float(max(level, 1)) / levels_per_tier)) + 1, 1, max_tier)

## Fallback: bld_<id>_t<tier>.png -> ... -> _t1 -> no-suffix -> null (no icon).
func get_building_texture(building_id: String, level: int) -> Texture2D:
	var tier := _building_tier(building_id, level)
	for t in range(tier, 0, -1):
		var tiered_path := "res://assets/tiles/bld_%s_t%d.png" % [building_id, t]
		if ResourceLoader.exists(tiered_path):
			return load(tiered_path)
	var base_path := "res://assets/tiles/bld_%s.png" % building_id
	if ResourceLoader.exists(base_path):
		return load(base_path)
	return null
