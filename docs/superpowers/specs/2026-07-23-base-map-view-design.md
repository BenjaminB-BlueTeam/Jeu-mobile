# Vue Base — carte 2D top-down ¾ à slots fixes (BaseMap)

**Version 0.1 — 23/07/2026 — Ben & Claude**
*Remplace la liste verticale de tuiles (T1-T3, `Base.tscn`/`BaseController.gd`/`BuildingNode.gd`)
par une vraie carte explorable, réutilisable pour le multi-bases futur. Purement client — aucune
donnée de position côté serveur (cf. `CLAUDE.md` §Règles d'architecture).*

---

## 0. Décisions de cadrage (actées pendant le brainstorm)

- **Remplacement complet** : `Base.tscn`, `BaseController.gd`, `BuildingNode.gd` sont supprimés une
  fois `BaseMap` fonctionnel — pas de coexistence, pas de code mort.
- **AssetResolver devient un autoload** : seule source de vérité pour la résolution de sprite
  (bâtiments *et* sol), reprenant la logique déjà validée dans `BuildingNode.gd` (commit `f2cf43f`,
  qui disparaît avec le remplacement).
- **Slots = `Area2D`**, pas `Control` : la caméra doit pan/zoom (`Camera2D`), qui ne transforme que
  l'espace `Node2D`. Toute la carte (sol, chemins, décor, bâtiments) vit en `Node2D`.
- **TileSet créé from scratch** : aucun n'existe dans le projet (le sol actuel T1-T3 est un
  `TextureRect` en mode `TILE`, pas une vraie `TileMap`).
- **Layout dessiné maintenant**, coordonnées exactes validées par script anti-chevauchement à
  l'implémentation (pas de référence visuelle disponible : `design/da/` est vide pour l'instant).
- **Pas de sélecteur multi-bases visible** pour cette tranche — seulement l'API (`base_id` en
  paramètre de la scène). Simplification actée par rapport à la demande initiale, un vrai sélecteur
  UI attendra qu'il y ait réellement plusieurs bases à choisir.
- **HQ = un slot comme les autres** (3x3, pas de traitement visuel spécial type panneau doré).

---

## 1. `design/config/base_layout.json` — layout unique, partagé par toutes les bases

Grille logique **12 x 16 tiles** (1 tile = 128px) → monde de **1536 x 2048 px**. Layout organique :
zones groupées en "quartiers" de tailles/espacements variables (pas une grille uniforme), reliées
par des chemins, avec des vides pour la lisibilité.

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

- Slots `11-20` : réservés, sans assignation (futurs bâtiments T4+, ex. `research_center`).
- `defense_slots` : réservés, sans assignation (aucune unité de défense n'existe encore dans
  `units.json`/`buildings.json`) — rendus comme terrain vide, non-interactifs, pour cette tranche.
- **Déjà validé** : les coordonnées ci-dessus ont été passées dans un script anti-chevauchement
  pendant le brainstorm (2 conflits trouvés — slot 18 chevauchait le HQ, slot 13 chevauchait le
  slot 16 — corrigés ; 29 rectangles au total, tous distincts et dans les bornes 12x16). Le même
  script (Python, cf. plan d'implémentation) est livré dans le repo pour valider tout futur ajustement
  du layout sans avoir à relancer Godot.
- Le mapping `assignments` est **cosmétique uniquement** : changer quel bâtiment occupe quel slot
  ne change rien au gameplay (mêmes formules, même `GameState.buildings`). Il est identique pour
  toutes les bases (pas de personnalisation par base dans cette tranche).

## 2. `AssetResolver` (nouvel autoload)

Remplace la logique aujourd'hui locale à `BuildingNode.gd` (qui disparaît). Un seul point d'entrée
pour toute résolution de sprite, même principe de fallback en cascade partout :

```gdscript
# get_building_texture(building_id: String, level: int) -> Texture2D
# tier = clamp(floor(level / levels_per_tier) + 1, 1, max_tier)
#   (levels_per_tier/max_tier_level lus depuis buildings.json[building_id].visual_tier,
#   défaut 10/40 -- identique à la formule déjà validée dans BuildingNode.gd)
# Fallback : bld_<id>_t<tier>.png -> ... -> bld_<id>_t1.png -> bld_<id>.png -> null

# get_ground_texture(biome: String, variant_seed: int) -> Texture2D
# Fallback : ground_<biome>_<1 + variant_seed % 3>.png -> grass.png (Kenney placeholder)
```

> **Déviation à l'implémentation (Task 3)** : `get_ground_texture()` a finalement été abandonné,
> le sol n'a jamais eu besoin de résolution de texture à l'exécution. La variation visuelle du sol
> est entièrement bakée dans les 4 tuiles alternatives du `TileSet` construit à la préparation des
> assets ; `BaseMap._build_ground()` choisit juste un index d'alternative (seedé par tuile) parmi
> ces 4, sans passer par `AssetResolver` ni appliquer de `modulate` à l'exécution.

- `variant_seed` est dérivé du `base_id` + de la position de la tuile (ex.
  `hash(str(base_id) + "_" + str(tile_x) + "_" + str(tile_y)) % 3`), pour que chaque base ait un sol
  légèrement différent mais **stable** (même sol à chaque rechargement de la même base).
- Tant qu'un seul tile de sol existe (`grass.png`), la variation visuelle vient d'une légère teinte
  aléatoire (`modulate`, seedée pareil) appliquée par `BaseMap` à chaque cellule — pas de l'asset
  lui-même. Une fois `ground_plains_1/2/3.png` livrés, la teinte disparaît naturellement (l'asset
  réel prend le dessus via le fallback).

## 3. Scène `BaseMap` (`client/scenes/base/BaseMap.tscn` + `base_map.gd`)

**Racine** `Node2D`, paramètres d'entrée `base_id: String` et `biome: String` (défaut `"plains"`).

**Couches (`Node2D` enfants, dans l'ordre de dessin)** :
1. `GroundLayer` (`TileMapLayer`) — un `TileSet` minimal créé pour ce projet, une seule tuile
   source (`grass.png`) au démarrage ; case par case, texture + teinte résolues via
   `AssetResolver.get_ground_texture(biome, variant_seed)`.
2. `PathsLayer` (`Line2D` ou `TileMapLayer` selon ce qui rend le mieux à l'implémentation) — chemins
   organiques reliant HQ ↔ quartiers ↔ slots, tracés à partir des coordonnées du layout (pas de
   config séparée : dérivés géométriquement des positions de slots).
3. `DecorLayer` (`Node2D`) — sprites de décor (`tree.png`, `grass_flowers.png`) placés à des
   positions procédurales seedées par `base_id` (même logique de stabilité que le sol), en évitant
   les zones occupées par HQ/slots/chemins.
4. `BuildingsLayer` (`Node2D`) — un `Area2D` + `CollisionShape2D` (rectangle, taille = `size × 128px`)
   par slot défini dans `base_layout.json` (HQ inclus). Sprite résolu via
   `AssetResolver.get_building_texture()` si le `building_id` assigné a `level > 0`, sinon sprite
   `slot_empty` (placeholder : `ColorRect #7A8450` tant que l'asset n'existe pas). Niveau affiché en
   `Label` badge, comme l'actuel `BuildingNode`. Slots sans assignation (10 slots 2x2 + 8 defense
   slots) : rendus comme terrain vide, non-interactifs. `CommanderSprite` (cf. §5) vit comme sibling
   de `BuildingsLayer`, positions alimentées par les centres des `Area2D`.

**Interaction** :
- Chaque `Area2D` assigné émet `slot_clicked(building_id: String)` sur clic/tap (`input_event`).
- `base_map.gd` connecte ce signal : bâtiments `UNIT_BUILDINGS` (`vehicle_factory`) → ouvre
  `UnitProductionPanel` ; les autres → `BuildingDetailPanel.open_for(building_id)`. Logique identique
  à l'actuel `BaseController._on_building_tapped`, juste rebranchée depuis les signaux `Area2D` au
  lieu des signaux `Button`.
- `ResourceBar`/`QueuePanel`/`BuildingDetailPanel`/`UnitProductionPanel` restent des overlays
  `CanvasLayer` (donc non affectés par la caméra du monde), rehébergés sous `BaseMap` exactement
  comme ils l'étaient sous `Base`.

**Caméra** : `Camera2D`, enfant de `BaseMap`.
- Pan : drag (souris) / touch-drag (mobile), calculé en `_unhandled_input` sur les événements
  `InputEventScreenDrag`/`InputEventMouseMotion` avec bouton maintenu.
- Zoom : molette (desktop) / pinch (mobile, `InputEventMagnifyGesture`), bornes min/max raisonnables
  (le monde 1536×2048 doit rester entièrement visible au zoom minimal, le détail d'un slot 2x2 lisible
  au zoom maximal).
- `limit_left/right/top/bottom` bornés à `0`/`grid_size.w × 128`/`0`/`grid_size.h × 128` — impossible
  de scroller hors de la carte.

**Biome** : paramètre de scène, seul `"plains"` fonctionne réellement (résout vers `grass.png` via le
fallback) ; `"desert"`/`"tundra"` acceptés en paramètre mais retombent sur le même fallback tant que
leurs assets n'existent pas — pas de branchement logique différent à écrire maintenant, le fallback
générique de `AssetResolver.get_ground_texture` couvre déjà ce cas.

## 4. Multi-bases (API seulement, pas d'UI cette tranche)

- `BaseMap` prend `base_id`/`biome` en paramètre (utilisés pour le seed de variation et le choix de
  biome) — l'API est prête pour plusieurs bases dès maintenant.
- Pas de sélecteur visible tant qu'il n'y a qu'une base. Une petite liste mock locale (une entrée,
  `{ "base_id": "base_local_1", "name": "Base principale", "biome": "plains" }`) vit dans
  `GameState.gd` ou un fichier dédié minimal — juste assez pour instancier `BaseMap` avec de vrais
  paramètres plutôt que des valeurs en dur.
- `# TODO(server): remplacer par la liste des bases du joueur depuis Supabase (table `bases`,
  RLS par joueur) une fois le backend en place.` — commentaire explicite à l'endroit du mock.

## 5. Migration depuis l'ancienne vue Base

- Supprimer `client/scenes/base/Base.tscn`, `client/scripts/base/BaseController.gd`,
  `client/scripts/base/BuildingNode.gd`.
- **`CommanderSprite.gd` est conservé** (feature cosmétique actée, `CLAUDE.md` §Décisions design :
  "Le Héros/Commandant est purement cosmétique côté client"), adapté aux nouvelles coordonnées :
  - `set_building_positions(positions: Dictionary)` reçoit désormais le **centre** de chaque slot
    (`Area2D.global_position`, l'origine naturelle d'un `Area2D` avec `CollisionShape2D` centrée)
    au lieu d'un coin + offset fixe.
  - `BUILDING_CENTER_OFFSET` (calibré pour les anciennes tuiles 300x110) est retiré ;
    `_on_move_requested` utilise directement `_building_positions[building_id]` comme cible, sans
    offset additionnel, puisque `BaseMap` fournit déjà des centres.
  - `BaseMap._ready()` construit ce dict à partir des `Area2D` de `BuildingsLayer` (même rôle que
    l'actuel `BaseController._ready()` qui le construit à partir des `Button`).
- `Main.gd` pointe `_base` vers `BaseMap.tscn` au lieu de `Base.tscn` ; le signal `map_requested`
  (bascule vers `WorldMap`) et `set_active()` restent identiques dans leur contrat.
- `WorldMapController`'s `base_requested` continue de fonctionner sans changement (il ne connaît
  que le contrat `set_active`/signal, pas les détails internes de la scène Base).

## 6. Fallbacks (le projet doit tourner immédiatement, sans aucun nouvel asset)

- Sol : `grass.png` (Kenney, déjà présent) via `AssetResolver.get_ground_texture`.
- Bâtiments : sprites `bld_*.png` déjà présents pour les 6 bâtiments T1/T2 ; `slot_empty` en
  `ColorRect #7A8450` tant qu'aucun asset dédié n'existe.
- Décor : `tree.png`/`grass_flowers.png` (déjà présents).
- Chemins : tracé procédural simple (`Line2D`, couleur terre `#8C6B4F` cf. DA §4) tant qu'aucun
  asset de chemin texturé n'existe.

## 7. Vérification

Pas de framework de test (cf. `CLAUDE.md`/`GameState.gd`). Vérification par :
- Script de validation du layout (anti-chevauchement, dans les bornes) — voir §1.
- Playtest manuel via `GUIDE_TEST.md` (nouvelle section à écrire à l'implémentation) : la carte
  s'affiche, pan/zoom fonctionnent et restent bornés, chaque slot assigné ouvre le bon panneau,
  Vehicle Factory ouvre bien `UnitProductionPanel`, les slots non-assignés ne réagissent pas au tap,
  le sol/décor sont visuellement stables entre deux rechargements de la même base.
- Vérification runtime ad-hoc via godot-mcp (`run_project` avec `scene_path` explicite +
  `get_editor_logs`), même méthodologie que T3 (cf. mémoire de session : pas d'
  `execute_editor_script` contre une instance déjà lancée, code temporaire dans un fichier réellement
  chargé par le projet).

## 8. Assets attendus (liste pour génération, chemins exacts)

Tous en PNG, fond transparent (sauf sol, sans fond nécessaire), cf. `direction-artistique.md` pour
le style et le prompt template (§10).

**Sol** (`client/assets/tiles/`) :
- `ground_plains_1.png`, `ground_plains_2.png`, `ground_plains_3.png` (variations olive #7A8450)
- `ground_desert_1.png`, `ground_desert_2.png`, `ground_desert_3.png` (futur, sable #C7A876)
- `ground_tundra_1.png`, `ground_tundra_2.png`, `ground_tundra_3.png` (futur, beige froid #B0A88E)

**Chemins** (`client/assets/tiles/`) :
- `path_straight.png`, `path_corner.png`, `path_junction.png` (brun chaud #8C6B4F, bords irréguliers,
  cf. DA §5) — optionnel pour cette tranche (fallback `Line2D` déjà fonctionnel).

**Slot vide** (`client/assets/tiles/`) :
- `slot_empty_2x2.png`, `slot_empty_1x1.png` (silhouette pointillée/vide, cf. DA §2 "contour doux")

**Décor** (`client/assets/tiles/`) :
- `decor_tree_1.png`, `decor_tree_2.png` (déjà en partie couvert par `tree.png` existant)
- `decor_bush.png`, `decor_rock.png`, `decor_grass_tuft.png`

**Bâtiments par palier** (`client/assets/tiles/`, cf. DA §12, un jeu de 5 par bâtiment) :
- `bld_headquarters_t1.png` … `_t5.png`
- `bld_steel_mine_t1.png` … `_t5.png`
- `bld_component_workshop_t1.png` … `_t5.png`
- `bld_fuel_refinery_t1.png` … `_t5.png`
- `bld_power_plant_t1.png` … `_t5.png`
- `bld_storage_depot_t1.png` … `_t5.png`
- `bld_vehicle_factory_t1.png` … `_t5.png`
- `bld_advanced_reactor_t1.png` … `_t5.png`
- `bld_auxiliary_generator_t1.png` … `_t5.png`
- `bld_engineering_corps_t1.png` … `_t5.png`
- `bld_land_clearing_t1.png` … `_t5.png`

Tout fichier absent retombe automatiquement sur le tier inférieur puis sur le fichier sans suffixe
puis sur le placeholder `ColorRect` — génération progressive possible, aucun code à retoucher.
