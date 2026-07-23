# BaseMap (vue Base en carte 2D) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer la vue Base T1-T3 (liste verticale de tuiles `Button`) par une vraie carte 2D
top-down ¾ à slots fixes, réutilisable pour le multi-bases, conformément à
`docs/superpowers/specs/2026-07-23-base-map-view-design.md`.

**Architecture:** Layout de slots partagé (`design/config/base_layout.json`) piloté par un nouvel
autoload `AssetResolver` (résolution de sprite bâtiment/sol, fallback en cascade) ; scène
`BaseMap.tscn` en couches `Node2D` (sol `TileMapLayer`, chemins `Line2D` dérivés géométriquement,
décor procédural seedé, bâtiments = `Area2D` par slot instanciés depuis le layout) sous une
`Camera2D` pan/zoom bornée ; les overlays UI (`ResourceBar`, `QueuePanel`, panneaux) restent sous
`CanvasLayer`, inchangés dans leur contrat. Remplacement complet de `Base.tscn`/
`BaseController.gd`/`BuildingNode.gd` ; `CommanderSprite.gd` est conservé et adapté.

**Tech Stack:** Godot 4.7 / GDScript, JSON config (`design/config/`), Python 3 (script de
validation de layout, hors client).

## Global Constraints

- Aucune logique de gameplay ajoutée/modifiée : `GameState.gd` n'est pas touché par ce plan (sauf
  Task 6, ajout pur d'une liste mock, aucune formule).
- Mapping bâtiment→slot **cosmétique uniquement** : ne change rien à `GameState.buildings`.
- GDScript de ce repo indente avec des **tabulations**, pas des espaces.
- Pas de framework de test GDScript dans ce repo. Vérification par `mcp__godot-mcp__run_project`
  avec **`scene_path` explicite** (sans ça, `run_project` relance la dernière scène ouverte dans
  l'éditeur, pas forcément `Main.tscn`) + `mcp__godot-mcp__get_editor_logs`. **Ne jamais** utiliser
  `execute_editor_script` pour lire l'état d'une instance de jeu déjà lancée séparément (elle ne
  voit pas les autoloads vivants d'un process externe — voir mémoire de session sur ce point) ;
  l'utiliser uniquement pour des actions côté éditeur qui ne dépendent pas d'un jeu en cours
  d'exécution (ex. construire et sauver une ressource `TileSet`), ou pour du code temporaire ajouté
  à un fichier qui fait réellement partie du projet en cours d'exécution (`Main.gd`), toujours
  retiré avant de committer. Appeler `mcp__godot-mcp__clear_output` avant un nouveau cycle
  run/vérification pour éviter de relire des logs d'une session précédente.
- Toute string affichée passe par `I18n.t(...)` — aucune string en dur dans le nouveau code.

---

### Task 1: `design/config/base_layout.json` + script de validation

**Files:**
- Create: `design/config/base_layout.json`
- Create: `scripts/validate_base_layout.py`

**Interfaces:**
- Produces: le fichier JSON avec les clés `grid_size`, `tile_size_px`, `hq_slot`, `slots`,
  `defense_slots`, `assignments`, consommé par `GameData.gd` (Task 5) et `base_map.gd` (Task 6/7)
  via une nouvelle clé `GameData.base_layout_cfg`.

- [ ] **Step 1: Écrire `design/config/base_layout.json`**

```json
{
  "grid_size": { "w": 12, "h": 16 },
  "tile_size_px": 128,
  "hq_slot": { "x": 4, "y": 1, "size": 3 },
  "slots": [
    { "id": 1,  "x": 1,  "y": 5,  "size": 2 },
    { "id": 2,  "x": 3,  "y": 5,  "size": 2 },
    { "id": 3,  "x": 1,  "y": 7,  "size": 2 },
    { "id": 4,  "x": 3,  "y": 8,  "size": 2 },
    { "id": 5,  "x": 8,  "y": 5,  "size": 2 },
    { "id": 6,  "x": 8,  "y": 7,  "size": 2 },
    { "id": 7,  "x": 6,  "y": 6,  "size": 2 },
    { "id": 8,  "x": 6,  "y": 8,  "size": 2 },
    { "id": 9,  "x": 1,  "y": 10, "size": 2 },
    { "id": 10, "x": 3,  "y": 11, "size": 2 },
    { "id": 11, "x": 1,  "y": 12, "size": 2 },
    { "id": 12, "x": 3,  "y": 13, "size": 2 },
    { "id": 13, "x": 10, "y": 3,  "size": 2 },
    { "id": 14, "x": 8,  "y": 10, "size": 2 },
    { "id": 15, "x": 8,  "y": 12, "size": 2 },
    { "id": 16, "x": 6,  "y": 11, "size": 2 },
    { "id": 17, "x": 6,  "y": 13, "size": 2 },
    { "id": 18, "x": 1,  "y": 2,  "size": 2 },
    { "id": 19, "x": 8,  "y": 2,  "size": 2 },
    { "id": 20, "x": 9,  "y": 14, "size": 2 }
  ],
  "defense_slots": [
    { "id": "d1", "x": 0,  "y": 0,  "size": 1 },
    { "id": "d2", "x": 11, "y": 0,  "size": 1 },
    { "id": "d3", "x": 0,  "y": 7,  "size": 1 },
    { "id": "d4", "x": 11, "y": 7,  "size": 1 },
    { "id": "d5", "x": 0,  "y": 15, "size": 1 },
    { "id": "d6", "x": 11, "y": 15, "size": 1 },
    { "id": "d7", "x": 5,  "y": 0,  "size": 1 },
    { "id": "d8", "x": 5,  "y": 15, "size": 1 }
  ],
  "assignments": {
    "headquarters": "hq",
    "steel_mine": 1,
    "component_workshop": 2,
    "fuel_refinery": 3,
    "power_plant": 4,
    "storage_depot": 5,
    "vehicle_factory": 6,
    "advanced_reactor": 7,
    "auxiliary_generator": 8,
    "engineering_corps": 9,
    "land_clearing": 10
  }
}
```

- [ ] **Step 2: Écrire le script de validation**

```python
#!/usr/bin/env python3
"""Validates design/config/base_layout.json: no two rectangles (HQ + slots +
defense_slots) overlap, and everything fits within grid_size. Run after any
manual edit to the layout file."""
import json
import sys
from pathlib import Path

LAYOUT_PATH = Path(__file__).resolve().parent.parent / "design" / "config" / "base_layout.json"


def bounds(rect: dict) -> tuple[int, int, int, int]:
    return rect["x"], rect["y"], rect["x"] + rect["size"], rect["y"] + rect["size"]


def main() -> int:
    data = json.loads(LAYOUT_PATH.read_text(encoding="utf-8"))
    grid_w = data["grid_size"]["w"]
    grid_h = data["grid_size"]["h"]

    rects = [dict(data["hq_slot"], id="hq")] + data["slots"] + data["defense_slots"]

    errors = []
    for r in rects:
        x0, y0, x1, y1 = bounds(r)
        if x0 < 0 or y0 < 0 or x1 > grid_w or y1 > grid_h:
            errors.append(f"{r['id']} out of bounds: {bounds(r)}")

    for i in range(len(rects)):
        for j in range(i + 1, len(rects)):
            a, b = rects[i], rects[j]
            ax0, ay0, ax1, ay1 = bounds(a)
            bx0, by0, bx1, by1 = bounds(b)
            if ax0 < bx1 and bx0 < ax1 and ay0 < by1 and by0 < ay1:
                errors.append(f"OVERLAP {a['id']} {bounds(a)} vs {b['id']} {bounds(b)}")

    if errors:
        for e in errors:
            print(e)
        print(f"TOTAL ERRORS: {len(errors)}")
        return 1

    print(f"OK: no overlaps, all within bounds - {len(rects)} rects total")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 3: Run it to verify the layout is valid**

Run: `python scripts/validate_base_layout.py`
Expected: `OK: no overlaps, all within bounds - 29 rects total`

(This exact layout was already hand-validated during the design phase — this run should pass
immediately. If it doesn't, the JSON was mistyped; fix coordinates and re-run.)

- [ ] **Step 4: Commit**

```bash
git add design/config/base_layout.json scripts/validate_base_layout.py
git commit -m "feat(config): add base_layout.json (slot positions) + validation script"
```

---

### Task 2: `AssetResolver` autoload

**Files:**
- Create: `client/scripts/autoload/AssetResolver.gd`
- Modify: `client/project.godot` (add to `[autoload]`)

**Interfaces:**
- Consumes: `GameData.buildings_cfg` (existing autoload, already loaded by the time any gameplay
  code runs).
- Produces: `AssetResolver.get_building_texture(building_id: String, level: int) -> Texture2D`,
  consumed by `slot_area.gd` (Task 5).
- **Deviation from spec §2:** the spec also called for `get_ground_texture(biome, variant)`. Ground
  variation is instead implemented entirely by the `TileSet`'s baked alternative tiles (Task 3) —
  a function that only ever resolves to `grass.png` (no `ground_<biome>_N.png` files exist yet) and
  is never called by any task would be dead code. If/when real per-biome ground textures are
  added, revisit by building a biome-specific `TileSet` at that point (the alternative-tile
  approach already isolates this concern to Task 3 alone).

- [ ] **Step 1: Write `AssetResolver.gd`**

```gdscript
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

## Fallback: ground_<biome>_<variant>.png -> grass.png (Kenney placeholder).
## `variant` is 1-based (matches the ground_<biome>_1/2/3.png naming in the DA
## doc); callers pick it via a seeded hash, see base_map.gd.
func get_ground_texture(biome: String, variant: int) -> Texture2D:
	var tiered_path := "res://assets/tiles/ground_%s_%d.png" % [biome, variant]
	if ResourceLoader.exists(tiered_path):
		return load(tiered_path)
	return load("res://assets/tiles/grass.png")
```

- [ ] **Step 2: Register the autoload in `client/project.godot`**

Insert `AssetResolver="*res://scripts/autoload/AssetResolver.gd"` right after the `GameData` line
in the `[autoload]` section:

```
[autoload]

I18n="*res://scripts/autoload/I18n.gd"
GameData="*res://scripts/autoload/GameData.gd"
AssetResolver="*res://scripts/autoload/AssetResolver.gd"
SaveManager="*res://scripts/autoload/SaveManager.gd"
GameState="*res://scripts/autoload/GameState.gd"
ToastManager="*res://scripts/ui/ToastManager.gd"
MCPRuntimeProbe="*res://addons/godot_mcp/runtime/mcp_runtime_probe.gd"
```

- [ ] **Step 3: Verify with a temporary check**

`mcp__godot-mcp__clear_output`, then `mcp__godot-mcp__run_project` with
`scene_path: "res://scenes/main/Main.tscn"` (the autoload's `_ready()` runs regardless of which
scene is active, but always pass `scene_path` explicitly per the Global Constraints). Since
`AssetResolver` has no `_ready()` side effects to observe directly, verify by temporarily adding one
line at the end of `Main.gd`'s `_ready()`:

```gdscript
	print("[AR-CHECK] steel_mine t1=%s land_clearing(no-art)=%s" % [
		str(AssetResolver.get_building_texture("steel_mine", 1)),
		str(AssetResolver.get_building_texture("land_clearing", 1)),
	])
```

`mcp__godot-mcp__get_editor_logs` with `source: "editor_panel"`. Expected: a line showing
`steel_mine` resolving to `bld_steel_mine.png` (the no-suffix fallback, no `_t1` art exists yet) and
`land_clearing` resolving to `<null>` (no art at all exists for it). Then
`mcp__godot-mcp__stop_project`, remove the temporary `print` line, confirm
`git diff client/scripts/main/Main.gd` is empty.

- [ ] **Step 4: Commit**

```bash
git add client/scripts/autoload/AssetResolver.gd client/project.godot
git commit -m "feat(client): add AssetResolver autoload for building/ground sprite resolution"
```

---

### Task 3: Ground `TileSet` resource

**Files:**
- Create: `client/assets/tiles/ground_tileset.tres` (via a one-time editor script, not hand-authored)

**Interfaces:**
- Produces: a `TileSet` resource with `tile_size = Vector2i(128, 128)`, one atlas source (id `0`)
  built from `grass.png` (16x16 px), with 4 alternative tiles (ids `0-3`) at the same atlas
  coordinate `Vector2i(0, 0)`, each carrying a different baked `TileData.modulate` (this is the
  per-cell "variation" mechanism — see spec §2/§3: the tint is baked into the TileSet's
  alternatives, not applied at runtime). Consumed by `client/scenes/base/BaseMap.tscn`'s
  `GroundLayer` (Task 6) via its `tile_set` property, and by `base_map.gd`'s cell-placement code
  (Task 7) via `set_cell(coords, 0, Vector2i(0, 0), alternative_tile)`.

- [ ] **Step 1: Build and save the TileSet via `execute_editor_script`**

This must run in the Godot editor context (creating/saving a resource does not require a played
game instance — this is exactly the kind of task `execute_editor_script` is for, unlike reading
live autoload state from a separately-running process).

```gdscript
var tileset := TileSet.new()
tileset.tile_size = Vector2i(128, 128)

var source := TileSetAtlasSource.new()
source.texture = load("res://assets/tiles/grass.png")
source.texture_region_size = Vector2i(16, 16)
source.create_tile(Vector2i(0, 0))

var tints := [
	Color(1.0, 1.0, 1.0, 1.0),
	Color(0.92, 1.0, 0.9, 1.0),
	Color(1.0, 0.95, 0.85, 1.0),
	Color(0.88, 0.95, 0.88, 1.0),
]
for i in range(tints.size()):
	if i == 0:
		var data0: TileData = source.get_tile_data(Vector2i(0, 0), 0)
		data0.modulate = tints[0]
	else:
		source.create_alternative_tile(Vector2i(0, 0), i)
		var data_i: TileData = source.get_tile_data(Vector2i(0, 0), i)
		data_i.modulate = tints[i]

tileset.add_source(source, 0)
var err := ResourceSaver.save(tileset, "res://assets/tiles/ground_tileset.tres")
_custom_print("save result (0 = OK): %d" % err)
```

Run via `mcp__godot-mcp__clear_output` then `mcp__godot-mcp__execute_editor_script` with the code
above.

- [ ] **Step 2: Verify the file was created**

Run: check the file exists and is non-empty — e.g. via `mcp__godot-mcp__list_project_resources`
(look for `res://assets/tiles/ground_tileset.tres`) or by reading it directly with the Read tool at
the absolute path `client/assets/tiles/ground_tileset.tres`.
Expected: the file exists and its text content contains `tile_size = Vector2i(128, 128)` and 4
distinct `modulate` entries.

- [ ] **Step 3: Commit**

```bash
git add client/assets/tiles/ground_tileset.tres
git commit -m "feat(client): create ground TileSet (grass.png source, 4 tint alternatives)"
```

---

### Task 4: `base_map_camera.gd` — pan/zoom camera

**Files:**
- Create: `client/scripts/base/base_map_camera.gd`

**Interfaces:**
- Produces: a script attachable to any `Camera2D`, self-contained (no dependency on other new
  files). Consumed by `BaseMap.tscn`'s `Camera2D` node (Task 6).

- [ ] **Step 1: Write the camera script**

```gdscript
extends Camera2D
## Pan (drag) + zoom (wheel/pinch) for the BaseMap world. Bounds are set by
## BaseMap via limit_left/right/top/bottom (world size), so this script never
## needs to know the map's dimensions itself.

const ZOOM_MIN := 0.4
const ZOOM_MAX := 1.5
const ZOOM_STEP := 0.1

var _dragging := false
var _drag_start_mouse := Vector2.ZERO
var _drag_start_camera := Vector2.ZERO

func _ready() -> void:
	zoom = Vector2(0.8, 0.8)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
			if event.pressed:
				_drag_start_mouse = event.position
				_drag_start_camera = position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(ZOOM_STEP)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(-ZOOM_STEP)
	elif event is InputEventMouseMotion and _dragging:
		var delta: Vector2 = (event.position - _drag_start_mouse) / zoom.x
		position = _drag_start_camera - delta
	elif event is InputEventScreenDrag:
		position -= event.relative / zoom.x
	elif event is InputEventMagnifyGesture:
		_apply_zoom(event.factor - 1.0)

func _apply_zoom(delta: float) -> void:
	var new_zoom: float = clamp(zoom.x + delta, ZOOM_MIN, ZOOM_MAX)
	zoom = Vector2(new_zoom, new_zoom)
```

- [ ] **Step 2: Commit**

This file has no runtime effect until attached to a node in Task 6 — commit it standalone.

```bash
git add client/scripts/base/base_map_camera.gd
git commit -m "feat(client): add BaseMap pan/zoom camera script"
```

---

### Task 5: `slot_area.gd` + `SlotArea.tscn` — one clickable building slot

**Files:**
- Create: `client/scripts/base/slot_area.gd`
- Create: `client/scenes/base/SlotArea.tscn`

**Interfaces:**
- Consumes: `AssetResolver.get_building_texture()` (Task 2), `GameState.buildings` (existing),
  `I18n.t()` (existing).
- Produces: `SlotArea` scene with script properties `slot_id: Variant` (int or String, e.g. `"hq"`),
  `building_id: String` (empty = unassigned/decorative), `size_tiles: int`, `tile_size_px: int`;
  signal `slot_clicked(building_id: String)`; public method `refresh()`. Consumed by `base_map.gd`
  (Task 7), which instantiates one `SlotArea` per entry in `base_layout.json` and reads
  `slot.get_world_center() -> Vector2` for `CommanderSprite` positioning.

- [ ] **Step 1: Write `slot_area.gd`**

```gdscript
extends Area2D
## One clickable building slot on the BaseMap. Mirrors the old BuildingNode.gd
## (deleted) but in free 2D space instead of a Button grid: a colored rect +
## icon + level label, driven by GameState, refreshed on state_changed.
## Unassigned slots (building_id == "") render as empty terrain and ignore
## input -- reserved for future building types / defenses.

@export var slot_id: Variant = 0
@export var building_id: String = ""
@export var size_tiles: int = 2
@export var tile_size_px: int = 128
@export var accent: Color = Color(0.5, 0.5, 0.5)

signal slot_clicked(building_id: String)

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _background: Polygon2D = $Background
@onready var _icon: Sprite2D = $Icon
@onready var _label: Label = $Label

func _ready() -> void:
	var side: float = size_tiles * tile_size_px
	var shape := RectangleShape2D.new()
	shape.size = Vector2(side, side)
	_collision.shape = shape

	var half := side / 2.0
	_background.polygon = PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half),
	])

	_label.position = Vector2(-half, half - 28)
	_label.size = Vector2(side, 24)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", Color(0.97, 0.97, 0.94))
	_label.add_theme_font_size_override("font_size", 16)

	input_pickable = building_id != ""
	input_event.connect(_on_input_event)
	if building_id != "":
		GameState.state_changed.connect(refresh)
	refresh()

func get_world_center() -> Vector2:
	return global_position

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if building_id == "":
		return
	var pressed := (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	if pressed:
		slot_clicked.emit(building_id)

func refresh() -> void:
	if building_id == "":
		_background.color = Color(0.25, 0.3, 0.2, 0.4)
		_icon.texture = null
		_label.text = ""
		return

	if not GameState.buildings.has(building_id):
		return
	var level: int = GameState.buildings[building_id]["level"]
	var texture := AssetResolver.get_building_texture(building_id, level)
	if texture:
		_icon.texture = texture
	if level <= 0:
		_background.color = Color(0.15, 0.15, 0.15, 0.35)
		_icon.modulate = Color(1, 1, 1, 0.25)
		_label.text = I18n.t("ui_build")
	else:
		_background.color = accent.darkened(0.45)
		_icon.modulate = Color(1, 1, 1, 1)
		_label.text = "%s  %s %d" % [I18n.t("building_" + building_id), I18n.t("ui_level_abbr"), level]
```

- [ ] **Step 2: Write `SlotArea.tscn`**

```
[gd_scene load_steps=2 format=3 uid="uid://slotarea001"]

[ext_resource type="Script" path="res://scripts/base/slot_area.gd" id="1"]

[node name="SlotArea" type="Area2D"]
script = ExtResource("1")

[node name="Background" type="Polygon2D" parent="."]
color = Color(0.3, 0.3, 0.3, 1)

[node name="Icon" type="Sprite2D" parent="."]
texture_filter = 1

[node name="Label" type="Label" parent="."]

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
```

- [ ] **Step 3: Verify with a temporary check**

`mcp__godot-mcp__clear_output`, then add a temporary block to `Main.gd`'s `_ready()`:

```gdscript
	var test_slot := preload("res://scenes/base/SlotArea.tscn").instantiate()
	test_slot.building_id = "steel_mine"
	test_slot.accent = Color(0.62, 0.66, 0.72, 1)
	add_child(test_slot)
	print("[SLOT-CHECK] label=%s icon=%s" % [test_slot._label.text, str(test_slot._icon.texture)])
	test_slot.queue_free()
```

`mcp__godot-mcp__run_project` with `scene_path: "res://scenes/main/Main.tscn"`, then
`mcp__godot-mcp__get_editor_logs` (source `editor_panel`). Expected: a `[SLOT-CHECK]` line showing
`label` containing "Mine d'acier  Niv 1" (or the current steel_mine level) and `icon` resolving to
`bld_steel_mine.png`. `mcp__godot-mcp__stop_project`, remove the temporary block, confirm
`git diff client/scripts/main/Main.gd` is empty.

- [ ] **Step 4: Commit**

```bash
git add client/scripts/base/slot_area.gd client/scenes/base/SlotArea.tscn
git commit -m "feat(client): add SlotArea (Area2D-based clickable building slot)"
```

---

### Task 6: `CommanderSprite.gd` adaptation

**Files:**
- Modify: `client/scripts/base/CommanderSprite.gd`

**Interfaces:**
- Consumes: nothing new (still listens to `GameState.commander_move_requested`, existing signal).
- Produces: `set_building_positions(positions: Dictionary)` now expects **centers** (not
  top-left + fixed offset). Consumed by `base_map.gd` (Task 7), which will pass
  `slot.get_world_center()` (Task 5) values directly.

- [ ] **Step 1: Replace the file**

```gdscript
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
```

- [ ] **Step 2: Commit**

This file has no wired caller until Task 7 instantiates it inside `BaseMap.tscn` — commit
standalone, matching the file's own internal consistency (no dead code, just an interface change).

```bash
git add client/scripts/base/CommanderSprite.gd
git commit -m "refactor(client): adapt CommanderSprite to slot-center coordinates"
```

---

### Task 7: `BaseMap.tscn` + `base_map.gd` — scene assembly

**Files:**
- Create: `client/scenes/base/BaseMap.tscn`
- Create: `client/scripts/base/base_map.gd`

**Interfaces:**
- Consumes: `design/config/base_layout.json` (via a new `GameData.base_layout_cfg`, Step 1 below),
  `AssetResolver.get_ground_texture()` (Task 2), `SlotArea` scene (Task 5),
  `base_map_camera.gd` (Task 4), `CommanderSprite.gd` (Task 6), existing
  `BuildingDetailPanel.tscn`/`UnitProductionPanel.tscn`/`ResourceBar.gd`/`QueuePanel.gd`.
- Produces: `BaseMap` root node with public method `configure(base_id: String, biome: String) -> void`
  and signal `map_requested` (same contract as the old `Base.tscn`/`BaseController.gd`, consumed by
  `Main.gd` in Task 9) and method `set_active(active: bool) -> void` (same contract as before).

- [ ] **Step 1: Add `base_layout_cfg` to `GameData.gd`**

Modify `client/scripts/autoload/GameData.gd`:

```gdscript
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
var base_layout_cfg: Dictionary = {}

func _ready() -> void:
	global_cfg = _load_json("res://../design/config/global.json")
	buildings_cfg = _load_json("res://../design/config/buildings.json")
	units_cfg = _load_json("res://../design/config/units.json")
	sectors_cfg = _load_json("res://../design/config/sectors.json")
	base_layout_cfg = _load_json("res://../design/config/base_layout.json")

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing config file: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(file.get_as_text())
```

- [ ] **Step 2: Write `base_map.gd`**

```gdscript
extends Node2D
## Root of the BaseMap scene: assembles the base from design/config/
## base_layout.json (slots) + GameState.buildings (levels), purely client-side
## rendering. See docs/superpowers/specs/2026-07-23-base-map-view-design.md.
## Replaces the old Base.tscn/BaseController.gd/BuildingNode.gd (deleted).

signal map_requested

const SLOT_SCENE := preload("res://scenes/base/SlotArea.tscn")
const UNIT_BUILDINGS := ["vehicle_factory"]
const GROUND_ALTERNATIVES := 4
const PATH_COLOR := Color(0.55, 0.42, 0.28, 1)
const PATH_WIDTH := 24.0
const DECOR_COUNT := 40
const DECOR_TEXTURES := ["res://assets/tiles/tree.png", "res://assets/tiles/grass_flowers.png"]

@onready var _ground_layer: TileMapLayer = $GroundLayer
@onready var _paths_layer: Node2D = $PathsLayer
@onready var _decor_layer: Node2D = $DecorLayer
@onready var _buildings_layer: Node2D = $BuildingsLayer
@onready var _commander: Sprite2D = $CommanderSprite
@onready var _camera: Camera2D = $Camera2D
@onready var _canvas_layer: CanvasLayer = $CanvasLayer
@onready var _building_detail_panel = $CanvasLayer/BuildingDetailPanel
@onready var _unit_production_panel = $CanvasLayer/UnitProductionPanel
@onready var _map_button: Button = $CanvasLayer/UI/MapButton

var _base_id: String = "base_local_1"
var _biome: String = "plains"
var _configured := false

func _ready() -> void:
	_map_button.text = I18n.t("ui_world_map")
	_map_button.pressed.connect(func() -> void: map_requested.emit())
	if not _configured:
		configure(_base_id, _biome)

## Public entry point: Main.gd calls this before the scene is first shown (or
## right after instancing) with the base to display. Safe to call once; if
## _ready() runs before configure() is called, it configures with defaults so
## the scene is still viewable standalone (e.g. running BaseMap.tscn directly
## for a quick check).
func configure(base_id: String, biome: String) -> void:
	_base_id = base_id
	_biome = biome
	_configured = true
	_build_ground()
	_build_slots()
	_build_paths()
	_build_decor()
	_setup_camera()

func _build_ground() -> void:
	var grid: Dictionary = GameData.base_layout_cfg["grid_size"]
	for y in range(grid["h"]):
		for x in range(grid["w"]):
			var seed_val: int = hash("%s_%d_%d" % [_base_id, x, y])
			var alt: int = seed_val % GROUND_ALTERNATIVES
			_ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0), alt)

func _slot_center(rect: Dictionary, tile_size: int) -> Vector2:
	var half: float = rect["size"] * tile_size / 2.0
	return Vector2(rect["x"] * tile_size + half, rect["y"] * tile_size + half)

func _build_slots() -> void:
	var layout: Dictionary = GameData.base_layout_cfg
	var tile_size: int = layout["tile_size_px"]
	var assignments: Dictionary = layout["assignments"]
	var by_slot_id := {}
	for building_id in assignments:
		by_slot_id[assignments[building_id]] = building_id

	var building_positions := {}
	var all_slot_defs: Array = [dict_with_id(layout["hq_slot"], "hq")] + layout["slots"] + layout["defense_slots"]
	for rect in all_slot_defs:
		var slot: Area2D = SLOT_SCENE.instantiate()
		slot.slot_id = rect["id"]
		slot.size_tiles = rect["size"]
		slot.tile_size_px = tile_size
		slot.building_id = by_slot_id.get(rect["id"], "")
		slot.position = _slot_center(rect, tile_size)
		_buildings_layer.add_child(slot)
		if slot.building_id != "":
			slot.accent = _accent_for(slot.building_id)
			slot.slot_clicked.connect(_on_slot_clicked)
			building_positions[slot.building_id] = slot.get_world_center()

	_commander.set_building_positions(building_positions)

func dict_with_id(rect: Dictionary, id_value) -> Dictionary:
	var copy := rect.duplicate()
	copy["id"] = id_value
	return copy

func _accent_for(building_id: String) -> Color:
	var accents := {
		"headquarters": Color(0.85, 0.65, 0.15, 1),
		"steel_mine": Color(0.62, 0.66, 0.72, 1),
		"component_workshop": Color(0.35, 0.62, 0.78, 1),
		"fuel_refinery": Color(0.82, 0.5, 0.24, 1),
		"power_plant": Color(0.85, 0.78, 0.3, 1),
		"storage_depot": Color(0.55, 0.5, 0.68, 1),
		"vehicle_factory": Color(0.5, 0.55, 0.32, 1),
		"advanced_reactor": Color(0.8, 0.35, 0.2, 1),
		"auxiliary_generator": Color(0.7, 0.75, 0.45, 1),
		"engineering_corps": Color(0.3, 0.6, 0.6, 1),
		"land_clearing": Color(0.55, 0.42, 0.28, 1),
	}
	return accents.get(building_id, Color(0.5, 0.5, 0.5, 1))

## Connects HQ + assigned slots with straight Line2D segments, greedily
## nearest-neighbor from HQ outward (a small Prim's-algorithm-style tree) --
## an organic branching path derived purely from slot geometry, no extra config.
func _build_paths() -> void:
	var centers: Array[Vector2] = []
	for child in _buildings_layer.get_children():
		if child is Area2D and child.building_id != "":
			centers.append(child.position)
	if centers.size() < 2:
		return
	var connected: Array[Vector2] = [centers[0]]
	var remaining: Array[Vector2] = centers.slice(1)
	while remaining.size() > 0:
		var best_i := -1
		var best_dist := INF
		var best_from := Vector2.ZERO
		for i in remaining.size():
			for from in connected:
				var d: float = from.distance_to(remaining[i])
				if d < best_dist:
					best_dist = d
					best_i = i
					best_from = from
		var to: Vector2 = remaining[best_i]
		var line := Line2D.new()
		line.points = PackedVector2Array([best_from, to])
		line.width = PATH_WIDTH
		line.default_color = PATH_COLOR
		_paths_layer.add_child(line)
		connected.append(to)
		remaining.remove_at(best_i)

func _occupied_cells() -> Dictionary:
	var occupied := {}
	var layout: Dictionary = GameData.base_layout_cfg
	var all_rects: Array = [dict_with_id(layout["hq_slot"], "hq")] + layout["slots"] + layout["defense_slots"]
	for rect in all_rects:
		for dx in range(rect["size"]):
			for dy in range(rect["size"]):
				occupied[Vector2i(rect["x"] + dx, rect["y"] + dy)] = true
	return occupied

## Procedural decor (trees/flowers), seeded by base_id so it's stable across
## reloads of the same base but varies between bases. Denser near the map
## edges (framing effect, cf. design/da/reference-01.jpg) than in the open
## interior where slots/paths need to stay readable.
func _build_decor() -> void:
	var layout: Dictionary = GameData.base_layout_cfg
	var tile_size: int = layout["tile_size_px"]
	var grid: Dictionary = layout["grid_size"]
	var occupied := _occupied_cells()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(_base_id + "_decor")

	var placed := 0
	var attempts := 0
	while placed < DECOR_COUNT and attempts < DECOR_COUNT * 20:
		attempts += 1
		var x: int = rng.randi_range(0, grid["w"] - 1)
		var y: int = rng.randi_range(0, grid["h"] - 1)
		var cell := Vector2i(x, y)
		if occupied.has(cell):
			continue
		var edge_dist: int = min(min(x, grid["w"] - 1 - x), min(y, grid["h"] - 1 - y))
		if edge_dist > 2 and rng.randf() > 0.25:
			continue
		var sprite := Sprite2D.new()
		sprite.texture = load(DECOR_TEXTURES[rng.randi_range(0, DECOR_TEXTURES.size() - 1)])
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = Vector2(x * tile_size + tile_size / 2.0, y * tile_size + tile_size / 2.0)
		sprite.scale = Vector2(6, 6)
		_decor_layer.add_child(sprite)
		occupied[cell] = true
		placed += 1

func _setup_camera() -> void:
	var layout: Dictionary = GameData.base_layout_cfg
	var tile_size: int = layout["tile_size_px"]
	var grid: Dictionary = layout["grid_size"]
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = grid["w"] * tile_size
	_camera.limit_bottom = grid["h"] * tile_size
	_camera.position = Vector2(grid["w"] * tile_size / 2.0, grid["h"] * tile_size / 2.0)

## CanvasLayer ignores its Node2D parent's `visible` -- must be toggled
## explicitly or it stays drawn on top of whichever scene is active.
func set_active(active: bool) -> void:
	visible = active
	_canvas_layer.visible = active

func _on_slot_clicked(building_id: String) -> void:
	if building_id in UNIT_BUILDINGS:
		_unit_production_panel.open_for("light_unit")
	else:
		_building_detail_panel.open_for(building_id)
```

- [ ] **Step 3: Write `BaseMap.tscn`**

```
[gd_scene load_steps=9 format=3 uid="uid://basemap001"]

[ext_resource type="Script" path="res://scripts/base/base_map.gd" id="1"]
[ext_resource type="TileSet" path="res://assets/tiles/ground_tileset.tres" id="2"]
[ext_resource type="Script" path="res://scripts/base/base_map_camera.gd" id="3"]
[ext_resource type="Script" path="res://scripts/base/CommanderSprite.gd" id="4"]
[ext_resource type="Texture2D" path="res://assets/tiles/commander_tank.png" id="5"]
[ext_resource type="Script" path="res://scripts/ui/ResourceBar.gd" id="6"]
[ext_resource type="Script" path="res://scripts/ui/QueuePanel.gd" id="7"]
[ext_resource type="PackedScene" path="res://scenes/ui/BuildingDetailPanel.tscn" id="8"]
[ext_resource type="PackedScene" path="res://scenes/ui/UnitProductionPanel.tscn" id="9"]

[node name="BaseMap" type="Node2D"]
script = ExtResource("1")

[node name="GroundLayer" type="TileMapLayer" parent="."]
tile_set = ExtResource("2")

[node name="PathsLayer" type="Node2D" parent="."]

[node name="DecorLayer" type="Node2D" parent="."]

[node name="BuildingsLayer" type="Node2D" parent="."]

[node name="CommanderSprite" type="Sprite2D" parent="."]
position = Vector2(704, 500)
scale = Vector2(4, 4)
texture = ExtResource("5")
script = ExtResource("4")

[node name="Camera2D" type="Camera2D" parent="."]
script = ExtResource("3")

[node name="CanvasLayer" type="CanvasLayer" parent="."]

[node name="UI" type="Control" parent="CanvasLayer"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2

[node name="ResourceBar" type="HBoxContainer" parent="CanvasLayer/UI"]
script = ExtResource("6")
offset_left = 16.0
offset_top = 16.0
offset_right = 704.0
offset_bottom = 44.0
theme_override_constants/separation = 24

[node name="SteelLabel" type="Label" parent="CanvasLayer/UI/ResourceBar"]
text = "Steel: 0"

[node name="ComponentsLabel" type="Label" parent="CanvasLayer/UI/ResourceBar"]
text = "Components: 0"

[node name="FuelLabel" type="Label" parent="CanvasLayer/UI/ResourceBar"]
text = "Fuel: 0"

[node name="PowerLabel" type="Label" parent="CanvasLayer/UI/ResourceBar"]
text = "Power: 0"

[node name="QueuePanel" type="Label" parent="CanvasLayer/UI"]
script = ExtResource("7")
offset_left = 16.0
offset_top = 52.0
offset_right = 704.0
offset_bottom = 124.0
autowrap_mode = 2

[node name="MapButton" type="Button" parent="CanvasLayer/UI"]
offset_left = 16.0
offset_top = 1180.0
offset_right = 216.0
offset_bottom = 1230.0
text = "World Map"

[node name="BuildingDetailPanel" parent="CanvasLayer" instance=ExtResource("8")]

[node name="UnitProductionPanel" parent="CanvasLayer" instance=ExtResource("9")]
```

Note: `UI`'s `mouse_filter = 2` (`MOUSE_FILTER_IGNORE`) on the root `Control` lets clicks pass
through empty UI areas down to the `Area2D` slots underneath — only the actual buttons/labels
inside consume input.

- [ ] **Step 4: Verify by running the scene standalone**

`mcp__godot-mcp__clear_output`, then `mcp__godot-mcp__run_project` with
`scene_path: "res://scenes/base/BaseMap.tscn"` (runs `_ready()` with defaults, no `Main.gd`
involved yet — this is why `configure()` self-invokes with defaults if not called externally).
`mcp__godot-mcp__get_editor_logs` (source `editor_panel`), expect **no errors**. Then, with the
game still running, `mcp__godot-mcp__get_editor_logs` (source `runtime`) — this is the first task
where the scene under test really is the one running, so runtime logs should be populated too;
if not, fall back to `editor_panel` (documented gotcha, see Global Constraints).

Additional check via a temporary line: add to `base_map.gd`'s `configure()`, at the very end:

```gdscript
	print("[BASEMAP-CHECK] ground_cells=%d slots=%d paths=%d decor=%d" % [
		_ground_layer.get_used_cells().size(),
		_buildings_layer.get_child_count(),
		_paths_layer.get_child_count(),
		_decor_layer.get_child_count(),
	])
```

Expected: `ground_cells=192` (12×16), `slots=29` (1 HQ + 20 + 8 defense), `paths` around `10`
(HQ + the 10 assigned buildings minus 1, since a tree with N nodes has N-1 edges), `decor=40`
(`DECOR_COUNT`, unless the attempt cap was hit first — acceptable if slightly under 40 given the
occupied-cell/edge-weighting rejection sampling). Remove this temporary line afterward, confirm
`git diff` shows only the intended code (no leftover print).

`mcp__godot-mcp__stop_project`.

- [ ] **Step 5: Commit**

```bash
git add client/scripts/autoload/GameData.gd client/scripts/base/base_map.gd client/scenes/base/BaseMap.tscn
git commit -m "feat(client): assemble BaseMap scene (ground/paths/slots/camera)"
```

---

### Task 8: Multi-base mock (API only, no UI)

**Files:**
- Modify: `client/scripts/main/Main.gd`

**Interfaces:**
- Consumes: `BaseMap.configure(base_id: String, biome: String)` (Task 7).
- Produces: nothing consumed by later tasks — this is the wiring endpoint.

- [ ] **Step 1: Add the mock list and wire it into `Main.gd`**

```gdscript
extends Node
## Switches between Base and WorldMap, and saves on window close so the
## lazy-eval timestamp is fresh for the next session.

# TODO(server): replace with the player's actual base list from Supabase
# (table `bases`, RLS scoped to the player) once the backend exists. For now,
# a single local base -- BaseMap's base_id/biome API is already in place so
# swapping this constant for a real fetched list is the only change needed.
const MOCK_BASES := [
	{ "base_id": "base_local_1", "name": "Base principale", "biome": "plains" },
]

@onready var _base: Node2D = $Base
@onready var _map: Node2D = $WorldMap

func _ready() -> void:
	_base.configure(MOCK_BASES[0]["base_id"], MOCK_BASES[0]["biome"])
	_base.map_requested.connect(_show_map)
	_map.base_requested.connect(_show_base)
	_show_base()
	get_tree().root.close_requested.connect(_on_close_requested)

func _show_base() -> void:
	_base.set_active(true)
	_map.set_active(false)

func _show_map() -> void:
	_base.set_active(false)
	_map.set_active(true)

func _on_close_requested() -> void:
	GameState.save_now()
	get_tree().quit()
```

- [ ] **Step 2: Commit**

Do not verify yet — `Main.tscn` still points at the old `Base.tscn` (Task 9 rewires it). Committing
here would leave `Main.gd` calling `configure()` on a node type that doesn't have that method until
Task 9 lands; that's fine within a single PR-equivalent set of commits on `main`, but flag it in the
task report as an expected transient inconsistency resolved by the very next task.

```bash
git add client/scripts/main/Main.gd
git commit -m "feat(client): wire mock base list into Main.gd (base_id/biome, no UI yet)"
```

---

### Task 9: Migration — delete old Base files, rewire `Main.tscn`

**Files:**
- Delete: `client/scenes/base/Base.tscn`, `client/scripts/base/BaseController.gd` (+ `.uid`),
  `client/scripts/base/BuildingNode.gd` (+ `.uid`)
- Modify: `client/scenes/main/Main.tscn`

**Interfaces:**
- Consumes: `BaseMap.tscn` (Task 7), `Main.gd`'s `MOCK_BASES`/`configure()` call (Task 8).
- Produces: the fully wired, running game — this is the integration point for the whole plan.

- [ ] **Step 1: Delete the old Base files**

```bash
git rm client/scenes/base/Base.tscn
git rm client/scripts/base/BaseController.gd client/scripts/base/BaseController.gd.uid
git rm client/scripts/base/BuildingNode.gd client/scripts/base/BuildingNode.gd.uid
```

- [ ] **Step 2: Rewire `Main.tscn`**

Replace (line 4): `[ext_resource type="PackedScene" path="res://scenes/base/Base.tscn" id="2"]`
with: `[ext_resource type="PackedScene" path="res://scenes/base/BaseMap.tscn" id="2"]`

The instanced child node keeps its name `Base` (line 10, `[node name="Base" parent="." instance=ExtResource("2")]`) — do NOT rename it, so `Main.gd`'s `@onready var _base: Node2D = $Base` keeps resolving without further changes.

- [ ] **Step 3: Full playtest verification**

`mcp__godot-mcp__clear_output`, then `mcp__godot-mcp__run_project` with
`scene_path: "res://scenes/main/Main.tscn"` (now the real integration point). Check
`mcp__godot-mcp__get_editor_logs` (source `editor_panel`, then `runtime`) for any Error/Warning —
expect none (a broken `ext_resource` path or a missing node would show as a parse/load error here).

Then, since there is no input-simulation tool, exercise the interaction path the same way earlier
tasks did — temporarily add to `Main.gd`'s `_ready()`, after `_show_base()`:

```gdscript
	var steel_slot: Area2D = null
	for child in _base.get_node("BuildingsLayer").get_children():
		if child.building_id == "steel_mine":
			steel_slot = child
			break
	steel_slot.slot_clicked.emit("steel_mine")
	print("[MIGRATION-CHECK] detail panel visible=%s title=%s" % [
		_base.get_node("CanvasLayer/BuildingDetailPanel").visible,
		_base.get_node("CanvasLayer/BuildingDetailPanel/VBoxContainer/TitleLabel").text,
	])
```

Expected: `visible=true`, `title` containing "Mine d'acier" and the current level. Remove this
temporary block afterward, confirm `git diff client/scripts/main/Main.gd` is empty (Task 8's
`MOCK_BASES` addition is the only real diff left in that file).

`mcp__godot-mcp__stop_project`.

- [ ] **Step 4: Commit**

```bash
git add client/scenes/main/Main.tscn
git commit -m "feat(client): switch Main to BaseMap, remove old Base.tscn/BaseController/BuildingNode"
```

---

### Task 10: `GUIDE_TEST.md` update + final playtest

**Files:**
- Modify: `GUIDE_TEST.md`

**Interfaces:**
- Consumes: the whole plan (end-to-end).
- Produces: nothing consumed by code — human-facing verification doc, last step of the plan.

- [ ] **Step 1: Add a new section, right after the existing T3 section (§6), before "Limites connues"**

```markdown
### 7. Carte de base (BaseMap)

Au lancement, la Base s'affiche désormais comme une vraie carte : QG en haut-centre, bâtiments
existants répartis en plusieurs zones reliées par des chemins, quelques cases vides en périphérie
(réservées aux futures défenses).

- Glisser (souris ou doigt) déplace la vue (pan), la molette (ou pincement sur mobile) zoome ; la
  vue ne doit jamais sortir des bords de la carte.
- Taper un bâtiment posé ouvre le même panneau de détail qu'avant (coût/durée/bouton
  Construire-ou-Améliorer). Taper l'Usine de véhicules ouvre le panneau de production d'unités.
  Taper une case vide (périphérie, ou l'un des emplacements non assignés) ne fait rien.
- Lancer une amélioration : le Commandant (sprite tank) doit visiblement se déplacer vers le
  bâtiment concerné, comme avant.
- Le sol a un aspect légèrement varié case par case (teintes subtiles), mais reste visuellement
  stable si vous rechargez la même partie (pas de sol qui "flickers" à chaque relance).
```

- [ ] **Step 2: Full manual playtest**

`mcp__godot-mcp__run_project` avec `scene_path: "res://scenes/main/Main.tscn"`, suivre la section 7
ci-dessus intégralement. `mcp__godot-mcp__get_editor_logs` après chaque étape pour confirmer
l'absence d'erreur. `mcp__godot-mcp__stop_project` une fois terminé.

- [ ] **Step 3: Commit**

```bash
git add GUIDE_TEST.md
git commit -m "docs: add BaseMap manual playtest section to GUIDE_TEST.md"
```
