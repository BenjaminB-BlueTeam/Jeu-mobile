# T3 — Construction & économie (champs, nouveaux bâtiments, palier visuel) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship T3 of `docs/superpowers/specs/2026-07-23-t3-construction-champs-design.md` — an OGame-style
field cap (backend counter only, no grid UI), 4 new buildings (Advanced Reactor, Auxiliary
Generator, Engineering Corps, Land Clearing), and a level-tier visual progression system on
`BuildingNode`.

**Architecture:** All new mechanics live in `GameState.gd` (the prototype's single source of
gameplay logic, per file header). UI changes are confined to `BuildingNode.gd` (unbuilt state +
visual tiering) and `BuildingDetailPanel.gd` (Build vs Upgrade label, field-cap error message).
`Base.tscn` gains 4 new `Button` tiles wired the same way as the 6 existing ones — no scene script
changes needed since `BaseController._ready()` already wires any `Button` child generically.

**Tech Stack:** Godot 4 / GDScript, JSON config in `design/config/`, JSON i18n in
`design/i18n/` (source of truth) + `client/i18n/` (runtime copy actually loaded by `I18n.gd`).

## Global Constraints

- Serveur autoritaire / lazy-eval / logique en JSON (CLAUDE.md §Règles d'architecture) — n/a ici
  (prototype jetable client-only, cf. `GameState.gd` file header), mais on garde le style
  lazy-eval existant (projection depuis timestamp) et les formules dans `design/config/*.json`.
- Aucune string en dur : toute nouvelle clé i18n va dans `design/i18n/en.json` (canonique) +
  `fr.json`, **et** dans `client/i18n/en.json` + `fr.json` (copie réellement chargée à l'exécution
  par `I18n.gd:_load_locale`, `res://i18n/%s.json`).
- Pas de framework de test GDScript dans ce repo. Vérification par : (a) scripts d'assertion
  ad-hoc via `mcp__godot-mcp__execute_editor_script` (multi-ligne, `assert`/boucles -- **pas**
  `execute_script`, qui n'évalue qu'une expression simple), exécutés **après** avoir lancé le jeu
  avec `mcp__godot-mcp__run_project` (les autoloads `GameState`/`GameData`/etc. sous `/root/` ne
  sont instanciés que pendant l'exécution, pas dans l'éditeur au repos) -- utiliser
  `_custom_print(...)` (pas `print()`) pour récupérer la sortie dans la réponse de l'outil ; et
  (b) playtest manuel via ce même `run_project` + nouvelle section `GUIDE_TEST.md`.
- GDScript du repo indente avec des tabulations (pas des espaces) — respecter le style existant
  dans tous les blocs de code ci-dessous.

---

### Task 1: Config — champs, 4 nouveaux bâtiments, clés i18n

**Files:**
- Modify: `design/config/global.json`
- Modify: `design/config/buildings.json`
- Modify: `design/i18n/en.json`
- Modify: `design/i18n/fr.json`
- Modify: `client/i18n/en.json`
- Modify: `client/i18n/fr.json`

**Interfaces:**
- Produces: clés de config lues par `GameState.gd`/`GameData.gd` dans les tâches suivantes —
  `GameData.global_cfg["base_fields"]`, `GameData.buildings_cfg["advanced_reactor"]` (et les 3
  autres), chacune avec `base_cost`, `cost_factor`, et selon le bâtiment `energy_production`,
  `fuel_consumption`, ou `fields_per_clearing`.
- Produces: clés i18n `building_advanced_reactor`, `building_auxiliary_generator`,
  `building_engineering_corps`, `building_land_clearing`, `ui_build`, `ui_insufficient_fields`,
  consommées par `BuildingNode.gd`/`BuildingDetailPanel.gd` (tâches 3-4).

- [ ] **Step 1: Ajouter `base_fields` à `global.json`**

Fichier complet attendu :

```json
{
  "_comment": "PROTOTYPE prototype-core-loop : speed_factor accéléré pour sentir la boucle en quelques minutes de test. Formules identiques au compendium (design/docs/compendium-mecaniques-ogame.md), seule l'échelle temporelle change. Pas la config finale serveur-autoritaire (voir design/config sur la branche phase-1-economy pour celle-ci).",
  "speed_factor": 20.0,
  "build_time_divisor": 2500,
  "production_growth": 1.1,
  "loot_rate_inactive": 0.75,
  "base_fields": 8
}
```

- [ ] **Step 2: Ajouter les 4 bâtiments à `buildings.json`**

Ajouter ces 4 entrées à la fin de l'objet JSON (après `vehicle_factory`, avant la `}` finale — ne
pas oublier la virgule après l'entrée `vehicle_factory` existante) :

```json
  "advanced_reactor": {
    "name_key": "building_advanced_reactor",
    "base_cost": { "steel": 380, "components": 420 },
    "cost_factor": 1.68,
    "energy_production": { "coef": 45 },
    "fuel_consumption": { "coef": 4 },
    "_note": "T3 energy source. Consumes fuel as a flux (see plan-dev-base-perso-v1.md §3): fuel_consumption modeled as a negative rate on fuel, floored at 0, does not cascade back into the energy balance (v1 simplification, noted limitation)."
  },
  "auxiliary_generator": {
    "name_key": "building_auxiliary_generator",
    "base_cost": { "steel": 50, "components": 20 },
    "cost_factor": 1.4,
    "energy_production": { "coef": 12 },
    "_note": "Cheap early energy top-up, lower yield than Power Plant/Advanced Reactor."
  },
  "engineering_corps": {
    "name_key": "building_engineering_corps",
    "base_cost": { "steel": 300, "components": 150 },
    "cost_factor": 1.6,
    "produces": null,
    "_note": "No resource production. Reduces build-queue time only (see GameState.get_build_time_seconds): divisor (1 + level). Does not affect unit production time (v1 scope)."
  },
  "land_clearing": {
    "name_key": "building_land_clearing",
    "base_cost": { "steel": 500, "components": 300 },
    "cost_factor": 1.9,
    "fields_per_clearing": 2,
    "produces": null,
    "_note": "Unlocks additional base fields (see GameState.get_max_fields). Renamed Terraformer, cf. univers-du-jeu.md."
  }
```

- [ ] **Step 3: Ajouter les clés i18n dans les 4 fichiers**

`design/i18n/en.json` — insérer après `"building_vehicle_factory": "Vehicle Factory",` (ligne 11) :

```json
  "building_headquarters": "Headquarters",
  "building_storage_depot": "Storage Depot",
  "building_advanced_reactor": "Advanced Reactor",
  "building_auxiliary_generator": "Auxiliary Generator",
  "building_engineering_corps": "Engineering Corps",
  "building_land_clearing": "Land Clearing",
```

Note : `building_headquarters` et `building_storage_depot` manquent aujourd'hui dans
`design/i18n/en.json` alors qu'elles existent déjà dans `client/i18n/en.json` (drift pré-existant
entre les deux copies) — on les resynchronise au passage puisqu'on touche ce fichier de toute
façon.

Puis, dans la liste des clés `ui_*` de ce même fichier, ajouter après `"ui_level_abbr": "Lv",` :

```json
  "ui_build": "Build",
```

Et après `"ui_insufficient_resources": "Insufficient resources",` :

```json
  "ui_insufficient_fields": "Insufficient fields",
```

`design/i18n/fr.json` — mêmes emplacements, équivalents FR :

```json
  "building_headquarters": "Quartier général",
  "building_storage_depot": "Dépôts de stockage",
  "building_advanced_reactor": "Réacteur avancé",
  "building_auxiliary_generator": "Générateur auxiliaire",
  "building_engineering_corps": "Corps du génie",
  "building_land_clearing": "Terrassement",
```

```json
  "ui_build": "Construire",
```

```json
  "ui_insufficient_fields": "Cases insuffisantes",
```

`client/i18n/en.json` — ce fichier a déjà `building_headquarters`/`building_storage_depot`/
`ui_rate_per_hour` ; ajouter seulement les clés réellement nouvelles, mêmes valeurs que ci-dessus :
`building_advanced_reactor`, `building_auxiliary_generator`, `building_engineering_corps`,
`building_land_clearing`, `ui_build`, `ui_insufficient_fields`.

`client/i18n/fr.json` — pareil, avec les valeurs FR ci-dessus.

- [ ] **Step 4: Vérifier que les 4 fichiers i18n et les 2 fichiers de config restent du JSON valide**

Run: `python -m json.tool design/config/global.json && python -m json.tool design/config/buildings.json && python -m json.tool design/i18n/en.json && python -m json.tool design/i18n/fr.json && python -m json.tool client/i18n/en.json && python -m json.tool client/i18n/fr.json`

Expected: chaque commande réimprime le JSON reformaté sans erreur (`Expecting ',' delimiter` ou
`Expecting property name` signale une virgule oubliée/en trop — l'erreur la plus probable en
éditant ces fichiers à la main).

- [ ] **Step 5: Commit**

```bash
git add design/config/global.json design/config/buildings.json design/i18n/en.json design/i18n/fr.json client/i18n/en.json client/i18n/fr.json
git commit -m "feat(config): add T3 buildings, base_fields, and related i18n keys"
```

---

### Task 2: `GameState.gd` — champs, carburant du réacteur, temps réduit par Engineering Corps

**Files:**
- Modify: `client/scripts/autoload/GameState.gd:32-39` (dict `buildings`)
- Modify: `client/scripts/autoload/GameState.gd:146-158` (`get_current_resources`)
- Modify: `client/scripts/autoload/GameState.gd:193-194` (`get_build_time_seconds`)
- Modify: `client/scripts/autoload/GameState.gd:196-218` (`start_building`)
- Modify: `client/scripts/autoload/GameState.gd` (nouvelle section, après `get_storage_capacity`)

**Interfaces:**
- Consumes: `GameData.global_cfg["base_fields"]`, `GameData.buildings_cfg["land_clearing"]["fields_per_clearing"]`,
  `GameData.buildings_cfg["advanced_reactor"]["fuel_consumption"]["coef"]` (Task 1).
- Produces: `GameState.get_max_fields() -> int`, `GameState.get_used_fields() -> int`,
  consommées par `BuildingDetailPanel.gd` (Task 3). `buildings` dict contient désormais
  `advanced_reactor`, `auxiliary_generator`, `engineering_corps`, `land_clearing` à `level: 0`.

- [ ] **Step 1: Étendre le dict `buildings` par défaut**

Remplacer (ligne 32-39) :

```gdscript
var buildings: Dictionary = {
	"steel_mine": {"level": 1},
	"component_workshop": {"level": 1},
	"fuel_refinery": {"level": 1},
	"power_plant": {"level": 1},
	"vehicle_factory": {"level": 1},
	"storage_depot": {"level": 1},
}
```

par :

```gdscript
var buildings: Dictionary = {
	"steel_mine": {"level": 1},
	"component_workshop": {"level": 1},
	"fuel_refinery": {"level": 1},
	"power_plant": {"level": 1},
	"vehicle_factory": {"level": 1},
	"storage_depot": {"level": 1},
	"advanced_reactor": {"level": 0},
	"auxiliary_generator": {"level": 0},
	"engineering_corps": {"level": 0},
	"land_clearing": {"level": 0},
}
```

(`_apply_save` ligne 66-71 ne change pas : elle merge déjà les niveaux sauvegardés uniquement pour
les clés qui existent dans ce dict par défaut, donc les vieux saves sans ces 4 bâtiments les
laissent simplement à `level: 0`.)

- [ ] **Step 2: Ajouter la section champs, juste après `get_storage_capacity` (ligne 134)**

```gdscript

## ---- Fields (OGame-style build cap) ----
## A pure numeric counter, mirroring the OGame planet field count: it caps
## how many DISTINCT buildings can exist (level >= 1), not a spatial grid --
## see docs/superpowers/specs/2026-07-23-t3-construction-champs-design.md §1.
## Levelling up an already-built building never consumes a new field.

func get_max_fields() -> int:
	var base: int = GameData.global_cfg["base_fields"]
	var per_level: float = GameData.buildings_cfg.get("land_clearing", {}).get("fields_per_clearing", 0)
	var level: int = buildings.get("land_clearing", {}).get("level", 0)
	return base + int(per_level * level)

func get_used_fields() -> int:
	var used := 0
	for building_id in buildings:
		if buildings[building_id]["level"] >= 1:
			used += 1
	return used
```

- [ ] **Step 3: Ajouter la consommation de carburant du réacteur avancé**

Ajouter cette fonction privée juste avant `get_current_resources` (ligne 144) :

```gdscript
## Sums fuel_consumption across all built buildings that declare it (currently
## only advanced_reactor). Same exponential shape as production/consumption
## elsewhere in this file.
func _fuel_consumption_rate_per_hour() -> float:
	var consumption := 0.0
	var growth: float = GameData.global_cfg["production_growth"]
	var speed: float = GameData.global_cfg["speed_factor"]
	for building_id in buildings:
		var cfg: Dictionary = GameData.buildings_cfg.get(building_id, {})
		var level: int = buildings[building_id]["level"]
		if level <= 0 or not cfg.has("fuel_consumption"):
			continue
		consumption += cfg["fuel_consumption"]["coef"] * level * pow(growth, level) * speed
	return consumption
```

Puis remplacer le corps de `get_current_resources` (ligne 146-158) :

```gdscript
func get_current_resources(as_of: int = -1) -> Dictionary:
	var now: int = as_of if as_of >= 0 else Time.get_unix_time_from_system()
	var elapsed_hours: float = max(0.0, (now - resources_last_collected_at) / 3600.0)
	var cap: float = get_storage_capacity()
	var projected := {}
	for key in RESOURCE_KEYS:
		var building_id := ""
		for b in BUILDING_TO_RESOURCE:
			if BUILDING_TO_RESOURCE[b] == key:
				building_id = b
		var rate: float = _production_rate_per_hour(building_id) if building_id != "" else 0.0
		if key == "fuel":
			rate -= _fuel_consumption_rate_per_hour()
		var value: float = resources[key] + rate * elapsed_hours
		if key == "fuel":
			value = max(0.0, value)
		projected[key] = min(value, cap)
	return projected
```

- [ ] **Step 4: Engineering Corps réduit le temps de construction**

Remplacer (ligne 193-194) :

```gdscript
func get_build_time_seconds(building_id: String) -> float:
	return _time_from_cost_seconds(get_building_cost(building_id))
```

par :

```gdscript
func get_build_time_seconds(building_id: String) -> float:
	var engineering_level: int = buildings.get("engineering_corps", {}).get("level", 0)
	return _time_from_cost_seconds(get_building_cost(building_id)) / (1 + engineering_level)
```

- [ ] **Step 5: Bloquer `start_building` quand les champs sont pleins (level 0 uniquement)**

Dans `start_building` (ligne 196), remplacer :

```gdscript
func start_building(building_id: String) -> bool:
	_resolve_build_queue()
	if build_queue["active"]:
		return false
	var cost := get_building_cost(building_id)
	if not can_afford(cost):
		return false
```

par :

```gdscript
func start_building(building_id: String) -> bool:
	_resolve_build_queue()
	if build_queue["active"]:
		return false
	if buildings[building_id]["level"] == 0 and get_used_fields() >= get_max_fields():
		return false
	var cost := get_building_cost(building_id)
	if not can_afford(cost):
		return false
```

- [ ] **Step 6: Vérifier avec un script ad-hoc dans le projet en cours d'exécution**

Lancer d'abord le jeu avec `mcp__godot-mcp__run_project` (les autoloads ne sont accessibles via
`/root/` qu'une fois le projet en cours d'exécution). Puis `mcp__godot-mcp__execute_editor_script`
avec ce code, qui exerce les nouvelles fonctions directement sur l'autoload `GameState` :

```gdscript
var errors := PackedStringArray()
if GameState.get_used_fields() != 6:
	errors.append("used_fields expected 6, got %d" % GameState.get_used_fields())
if GameState.get_max_fields() != 8:
	errors.append("max_fields expected 8, got %d" % GameState.get_max_fields())
GameState.buildings["land_clearing"]["level"] = 1
if GameState.get_max_fields() != 10:
	errors.append("max_fields after land_clearing L1 expected 10, got %d" % GameState.get_max_fields())
GameState.buildings["engineering_corps"]["level"] = 1
var t0 = GameState.get_build_time_seconds("steel_mine")
GameState.buildings["engineering_corps"]["level"] = 0
var t1 = GameState.get_build_time_seconds("steel_mine")
if t0 >= t1:
	errors.append("engineering_corps should shorten build time: t0=%f t1=%f" % [t0, t1])
GameState.buildings["land_clearing"]["level"] = 0
if errors.is_empty():
	_custom_print("GameState T3 checks OK")
else:
	_custom_print("FAILURES: " + ", ".join(errors))
```

(`GameState` est référencé directement comme singleton global, comme partout ailleurs dans le
codebase -- pas besoin de `get_node`, cf. `GameData.global_cfg` utilisé tel quel dans
`GameState.gd`.)

Expected: la réponse de l'outil affiche `"GameState T3 checks OK"`. Si elle affiche des
`FAILURES: ...`, corriger le code de `GameState.gd` avant de continuer. Ensuite
`mcp__godot-mcp__stop_project` pour repartir d'un état propre avant les tâches suivantes.

- [ ] **Step 7: Commit**

```bash
git add client/scripts/autoload/GameState.gd
git commit -m "feat(client): T3 fields cap, reactor fuel drain, engineering corps build-time bonus"
```

---

### Task 3: `BuildingDetailPanel.gd` — Construire vs Améliorer, message champs insuffisants

**Files:**
- Modify: `client/scripts/ui/BuildingDetailPanel.gd`

**Interfaces:**
- Consumes: `GameState.get_used_fields()`, `GameState.get_max_fields()`, `GameState.buildings`,
  `GameState.start_building()` (toutes déjà publiques), clés i18n `ui_build`/`ui_upgrade`/
  `ui_insufficient_fields` (Task 1).
- Produces: aucun symbole nouveau consommé ailleurs (fichier terminal de la chaîne UI).

- [ ] **Step 1: Déplacer le libellé du bouton dans `open_for` (il doit varier selon le niveau)**

Remplacer le fichier entier par :

```gdscript
extends PopupPanel
## Building upgrade panel: current -> next level, cost, duration. Confirm
## delegates entirely to GameState.start_building -- cost/time shown here are
## read from GameState, never computed in this script.

var _building_id: String = ""

@onready var _title_label: Label = $VBoxContainer/TitleLabel
@onready var _cost_label: Label = $VBoxContainer/CostLabel
@onready var _time_label: Label = $VBoxContainer/TimeLabel
@onready var _confirm_button: Button = $VBoxContainer/ConfirmButton
@onready var _status_label: Label = $VBoxContainer/StatusLabel

func _ready() -> void:
	_confirm_button.pressed.connect(_on_confirm_pressed)

func open_for(building_id: String) -> void:
	_building_id = building_id
	var level: int = GameState.buildings[building_id]["level"]
	_confirm_button.text = I18n.t("ui_build") if level == 0 else I18n.t("ui_upgrade")
	_title_label.text = "%s (%s %d -> %d)" % [I18n.t("building_" + building_id), I18n.t("ui_level_abbr"), level, level + 1]

	var cost := GameState.get_building_cost(building_id)
	var parts := PackedStringArray()
	for res in cost:
		parts.append("%s %d" % [I18n.t("res_" + res), int(ceil(cost[res]))])
	_cost_label.text = ", ".join(parts)

	_time_label.text = "%ds" % int(ceil(GameState.get_build_time_seconds(building_id)))
	_status_label.text = ""
	popup_centered()

func _on_confirm_pressed() -> void:
	if GameState.build_queue["active"]:
		_status_label.text = I18n.t("ui_queue_busy")
		return
	var level: int = GameState.buildings[_building_id]["level"]
	if level == 0 and GameState.get_used_fields() >= GameState.get_max_fields():
		_status_label.text = I18n.t("ui_insufficient_fields")
		return
	if not GameState.start_building(_building_id):
		_status_label.text = I18n.t("ui_insufficient_resources")
		return
	hide()
```

- [ ] **Step 2: Vérifier manuellement dans l'éditeur**

Avec le projet ouvert (`mcp__godot-mcp__run_project`), taper la tuile Land Clearing (encore à
level 0 après Task 4/5) : le bouton doit afficher "Construire" et non "Améliorer". Taper une tuile
déjà construite (ex. Steel Mine) : le bouton doit toujours afficher "Améliorer". Consulter
`mcp__godot-mcp__get_editor_logs` (source `runtime`) pour toute erreur de script au lancement.

- [ ] **Step 3: Commit**

```bash
git add client/scripts/ui/BuildingDetailPanel.gd
git commit -m "feat(client): distinguish Build vs Upgrade in BuildingDetailPanel, add fields error"
```

---

### Task 4: `BuildingNode.gd` — état "non construit" + palier visuel

**Files:**
- Modify: `client/scripts/base/BuildingNode.gd`

**Interfaces:**
- Consumes: `GameState.buildings[building_id]["level"]`, `I18n.t("ui_build")`.
- Produces: aucun symbole nouveau consommé ailleurs (le comportement de `_refresh()` est
  entièrement interne à ce nœud, déclenché par le signal `GameState.state_changed` déjà câblé).

- [ ] **Step 1: Remplacer le fichier entier**

```gdscript
extends Button
## One tappable building tile on the Base grid. Shows the building sprite
## (Kenney Tiny Battle, CC0) in a colored panel with a name/level label below.
## Pure display -- costs and timers live in GameState, never computed here.
##
## Two extra display states on top of the base T1/T2 look:
## - level == 0 ("unbuilt"): dimmed placeholder tile, "Construire" label, no
##   sprite tint, no rank badge. Tapping it still opens BuildingDetailPanel,
##   which offers the "Build" (level 0 -> 1) flow.
## - level >= 1: a visual "tier" (1 + floor((level-1)/5), i.e. one step every
##   5 levels) brightens the border and icon and adds a chevron rank badge,
##   purely cosmetic, no new PNG assets (see docs/superpowers/specs/
##   2026-07-23-t3-construction-champs-design.md §4).

@export var building_id: String = ""
@export var accent: Color = Color(0.5, 0.5, 0.5)
@export var sprite: Texture2D

signal building_tapped(building_id: String)

var _label: Label
var _rank_label: Label
var _icon: TextureRect

func _ready() -> void:
	text = ""
	_build_children()
	pressed.connect(func() -> void: building_tapped.emit(building_id))
	GameState.state_changed.connect(_refresh)
	_refresh()

func _build_children() -> void:
	if sprite:
		_icon = TextureRect.new()
		_icon.texture = sprite
		_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		_icon.offset_top = 6
		_icon.offset_bottom = -32
		add_child(_icon)

	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_label.offset_top = -30
	_label.offset_bottom = -2
	_label.add_theme_color_override("font_color", Color(0.97, 0.97, 0.94))
	_label.add_theme_font_size_override("font_size", 18)
	add_child(_label)

	_rank_label = Label.new()
	_rank_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_rank_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_rank_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_rank_label.offset_left = -80
	_rank_label.offset_top = 4
	_rank_label.offset_right = -6
	_rank_label.offset_bottom = 24
	_rank_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.4, 1))
	_rank_label.add_theme_font_size_override("font_size", 14)
	add_child(_rank_label)

func _tile_box(fill: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border_color
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(8)
	return box

## tier 1 = levels 1-5, tier 2 = levels 6-10, etc. Border/icon brighten with
## tier; Godot 4's StyleBoxFlat has no dashed-border support, so the "unbuilt"
## state (see _apply_unbuilt_style) uses a thin translucent border instead of
## a dashed one to read as "not here yet".
func _apply_built_style(tier: int) -> void:
	var lighten: float = min(0.12 * (tier - 1), 0.5)
	var border_color: Color = accent.lerp(Color.WHITE, lighten)
	var border_width: int = 3 + (tier - 1) * 2
	add_theme_stylebox_override("normal", _tile_box(accent.darkened(0.45), border_color, border_width))
	add_theme_stylebox_override("hover", _tile_box(accent.darkened(0.25), border_color, border_width))
	add_theme_stylebox_override("pressed", _tile_box(accent.darkened(0.1), border_color, border_width))
	if _icon:
		_icon.modulate = Color.WHITE.lerp(Color(0.85, 0.92, 1.0), lighten)

func _apply_unbuilt_style() -> void:
	var box := _tile_box(Color(0.15, 0.15, 0.15, 0.35), Color(0.6, 0.6, 0.6, 0.6), 2)
	add_theme_stylebox_override("normal", box)
	add_theme_stylebox_override("hover", box)
	add_theme_stylebox_override("pressed", box)
	if _icon:
		_icon.modulate = Color(1, 1, 1, 0.25)

func _refresh() -> void:
	if building_id == "" or not GameState.buildings.has(building_id) or _label == null:
		return
	var level: int = GameState.buildings[building_id]["level"]
	if level <= 0:
		_apply_unbuilt_style()
		_label.text = I18n.t("ui_build")
		_rank_label.text = ""
		return
	var tier: int = 1 + int(floor(float(level - 1) / 5.0))
	_apply_built_style(tier)
	_label.text = "%s  %s %d" % [I18n.t("building_" + building_id), I18n.t("ui_level_abbr"), level]
	_rank_label.text = "▲".repeat(tier - 1)
```

- [ ] **Step 2: Vérifier avec un script ad-hoc**

Lancer le jeu avec `mcp__godot-mcp__run_project` (scène par défaut, qui affiche `Base.tscn` via
`Main.gd`), puis `mcp__godot-mcp__execute_editor_script` :

```gdscript
GameState.buildings["steel_mine"]["level"] = 6
GameState.state_changed.emit()
_custom_print("steel_mine set to level 6, tier should now be 2 (chevron + brighter border)")
```

Expected: pas d'erreur dans `get_editor_logs` (source `runtime`). Confirmer visuellement que la
tuile Steel Mine a maintenant une bordure plus épaisse/claire et un chevron `▲` par rapport à son
apparence au niveau 1 (tier 1, sans chevron), et que Land Clearing (level 0) apparaît comme une
tuile grisée avec le texte "Construire". `mcp__godot-mcp__stop_project` une fois confirmé (ne pas
laisser cet état de test se sauvegarder).

- [ ] **Step 3: Commit**

```bash
git add client/scripts/base/BuildingNode.gd
git commit -m "feat(client): unbuilt tile state + level-tier visual progression"
```

---

### Task 5: `Base.tscn` — ajouter les 4 nouvelles tuiles

**Files:**
- Modify: `client/scenes/base/Base.tscn`

**Interfaces:**
- Consumes: `BuildingNode.gd` (script id `6` dans ce fichier, Task 4), aucun nouveau sprite (pas
  d'assets PNG pour ces 4 bâtiments dans ce prototype, cf. spec §6 — les tuiles s'affichent sans
  icône, juste couleur + texte, comme le reste du proto avant l'intégration Kenney).
- Produces: 4 nouveaux `Button` nommés `AdvancedReactor`, `AuxiliaryGenerator`,
  `EngineeringCorps`, `LandClearing` sous `BuildingsLayer` — `BaseController._ready()` les détecte
  et les câble automatiquement (boucle générique existante sur les enfants de `BuildingsLayer`,
  aucune modification de `BaseController.gd` nécessaire).

- [ ] **Step 1: Agrandir le panneau `Compound` pour loger 2 rangées de tuiles supplémentaires**

Remplacer (ligne 54-59) :

```
[node name="Compound" type="Panel" parent="."]
offset_left = 24.0
offset_top = 300.0
offset_right = 696.0
offset_bottom = 900.0
theme_override_styles/panel = SubResource("compound_box")
```

par :

```
[node name="Compound" type="Panel" parent="."]
offset_left = 24.0
offset_top = 300.0
offset_right = 696.0
offset_bottom = 980.0
theme_override_styles/panel = SubResource("compound_box")
```

- [ ] **Step 2: Ajouter les 4 tuiles après `StorageDepot` (après la ligne 142), avant `CommanderSprite`**

```
[node name="AdvancedReactor" type="Button" parent="BuildingsLayer"]
position = Vector2(40, 720)
custom_minimum_size = Vector2(300, 110)
size = Vector2(300, 110)
script = ExtResource("6")
building_id = "advanced_reactor"
accent = Color(0.8, 0.35, 0.2, 1)

[node name="AuxiliaryGenerator" type="Button" parent="BuildingsLayer"]
position = Vector2(380, 720)
custom_minimum_size = Vector2(300, 110)
size = Vector2(300, 110)
script = ExtResource("6")
building_id = "auxiliary_generator"
accent = Color(0.7, 0.75, 0.45, 1)

[node name="EngineeringCorps" type="Button" parent="BuildingsLayer"]
position = Vector2(40, 850)
custom_minimum_size = Vector2(300, 110)
size = Vector2(300, 110)
script = ExtResource("6")
building_id = "engineering_corps"
accent = Color(0.3, 0.6, 0.6, 1)

[node name="LandClearing" type="Button" parent="BuildingsLayer"]
position = Vector2(380, 850)
custom_minimum_size = Vector2(300, 110)
size = Vector2(300, 110)
script = ExtResource("6")
building_id = "land_clearing"
accent = Color(0.55, 0.42, 0.28, 1)
```

(Les 4 nouveaux `Button` n'ont pas de propriété `sprite` — `@export var sprite: Texture2D` reste
`null`, ce que `BuildingNode._build_children()` gère déjà via `if sprite:`.)

- [ ] **Step 3: Vérifier en éditeur**

`mcp__godot-mcp__open_scene` sur `res://scenes/base/Base.tscn` puis
`mcp__godot-mcp__get_scene_tree` : confirmer que `BuildingsLayer` a bien 10 enfants `Button`
(6 existants + 4 nouveaux) plus `CommanderSprite`. Puis `mcp__godot-mcp__run_project` : les 4
nouvelles tuiles doivent apparaître grisées avec "Construire", en dessous des 6 existantes, sans
chevaucher `MapButton` (y=1180). Taper chacune ouvre `BuildingDetailPanel` avec le bouton
"Construire".

- [ ] **Step 4: Commit**

```bash
git add client/scenes/base/Base.tscn
git commit -m "feat(client): wire the 4 T3 buildings onto the Base scene grid"
```

---

### Task 6: Playtest manuel complet + `GUIDE_TEST.md`

**Files:**
- Modify: `GUIDE_TEST.md`

**Interfaces:**
- Consumes: l'ensemble des Tasks 1-5 (comportement de bout en bout).
- Produces: rien de consommé par du code — dernière étape de vérification humaine du plan.

- [ ] **Step 1: Ajouter la section 6 à `GUIDE_TEST.md`, après la section 5 existante**

```markdown
### 6. Construction de nouveaux bâtiments (T3)

Au lancement, 4 nouvelles tuiles apparaissent en bas de la Compound, grisées avec le texte
"Construire" : Advanced Reactor, Auxiliary Generator, Engineering Corps, Land Clearing.

- Taper une tuile grisée → panneau de détail avec bouton "Construire" (pas "Améliorer") et un coût
  de niveau 0→1. Confirmer débite les ressources, lance le timer (même file que les améliorations
  — un seul slot de construction). À la fin, la tuile passe en état "construit" (niveau 1, sprite
  plein/couleur pleine).
- Construire 3 bâtiments jamais posés (en plus des 6 déjà là) → un 4e échoue avec le toast/message
  "Cases insuffisantes" tant que Land Clearing n'a pas été construit et monté (8 champs de base,
  6 déjà pris par les bâtiments existants → seulement 2 places libres avant Land Clearing).
- Construire puis monter Land Clearing d'un niveau → le plafond de champs augmente (+2 par
  niveau), un bâtiment auparavant bloqué par "Cases insuffisantes" devient constructible.
- Construire Engineering Corps → le temps affiché pour une amélioration suivante (ex. Steel Mine)
  diminue visiblement par rapport à avant sa construction.
- Construire Advanced Reactor puis observer la barre de Carburant (haut d'écran) : son taux de
  montée doit baisser (le réacteur consomme du carburant en flux), sans jamais passer sous 0.
- Faire monter un bâtiment existant (ex. Steel Mine) au niveau 6 en accéléré (`speed_factor`) :
  la tuile doit changer d'aspect (bordure plus épaisse/claire, un chevron ▲ apparaît à côté du
  niveau) par rapport à son apparence aux niveaux 1-5.
```

- [ ] **Step 2: Playtest manuel complet via godot-mcp**

`mcp__godot-mcp__run_project`, puis suivre le script de la section 6 ci-dessus intégralement
(construire les 4 bâtiments, vérifier le blocage de champs, vérifier Land Clearing qui débloque,
vérifier Engineering Corps qui accélère, vérifier la baisse de carburant avec Advanced Reactor,
vérifier le palier visuel). Utiliser `mcp__godot-mcp__get_editor_logs` (source `runtime`) après
chaque étape pour confirmer l'absence d'erreur/warning GDScript. `mcp__godot-mcp__stop_project`
une fois la vérification terminée.

Expected: tous les points de la section 6 se comportent comme décrit, aucune erreur dans les logs
runtime.

- [ ] **Step 3: Commit**

```bash
git add GUIDE_TEST.md
git commit -m "docs: add T3 manual playtest section to GUIDE_TEST.md"
```
