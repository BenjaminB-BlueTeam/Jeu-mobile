# T3 — Construction & économie (champs, nouveaux bâtiments, palier visuel)

**Version 0.1 — 23/07/2026 — Ben & Claude**
*Compagnon de : `design/docs/plan-dev-base-perso-v1.md` §2.3-2.4 & §4 (T3), `design/docs/gameplay-flow.md` §4*

Prototype jetable `prototype-core-loop` (cf. `CLAUDE.md`, `GUIDE_TEST.md`). T1 (énergie-flux) et T2
(plafonds de stockage) sont déjà en place et jouables. Cette tranche T3 ajoute 4 bâtiments, un
plafond de champs façon OGame, et un palier visuel de progression.

---

## 1. Champs (fields) — compteur backend, sans impact visuel de grille

Transposition directe du champ de planète OGame : un nombre qui borne le nombre de bâtiments
posés, **pas** une grille spatiale de cases tappables. Aucun changement de layout côté écran Base
pour cette mécanique — c'est un garde-fou numérique, comme sur OGame où le total de champs est un
simple chiffre dans la vue planète.

- `GameState.get_max_fields() -> int` = `base_fields + land_clearing_level × fields_per_clearing`.
  - `base_fields = 8` (nouvelle clé dans `design/config/global.json`).
  - `fields_per_clearing = 2` (clé `land_clearing.fields_per_clearing` dans `buildings.json`, cf. §3).
- `GameState.get_used_fields() -> int` = nombre de bâtiments dans `GameState.buildings` avec
  `level >= 1`. Un bâtiment consomme exactement 1 champ **quel que soit son niveau** (comme OGame :
  seule la présence compte, pas le niveau).
- `start_building(building_id)` vérifie le plafond **uniquement quand `buildings[building_id].level == 0`**
  (première construction). Une amélioration d'un bâtiment déjà posé (level ≥ 1 → level+1) ne
  consomme pas de nouveau champ et n'est jamais bloquée par ce plafond.
- Si `get_used_fields() >= get_max_fields()` au moment de construire un bâtiment à level 0 :
  `start_building` retourne `false` sans rien débiter ; l'UI affiche un toast
  `"Cases insuffisantes"` (clé i18n `ui_insufficient_fields`, même préfixe que
  `ui_insufficient_resources` déjà utilisée par `BuildingDetailPanel.gd`), comme prévu par
  `gameplay-flow.md` §4 / `plan-dev-base-perso-v1.md` §2.4.

## 2. Bâtiments à level 0 = "non construits", visibles comme tuiles vides

Aujourd'hui `GameState.buildings` ne contient que les bâtiments déjà posés (level ≥ 1). Cette
tranche ajoute les 4 nouveaux bâtiments à `buildings` dès le démarrage, avec `level: 0` :

```gdscript
"advanced_reactor": {"level": 0},
"auxiliary_generator": {"level": 0},
"engineering_corps": {"level": 0},
"land_clearing": {"level": 0},
```

`Base.tscn` gagne 4 nouvelles tuiles `Button` (même pattern que les 6 existantes — pas de
génération procédurale de grille, cf. décision de cadrage : le nombre de champs n'a **aucun**
impact visuel, donc pas besoin d'une grille dynamique). Chaque tuile est câblée à son
`building_id` comme les tuiles actuelles.

`BuildingNode.gd` gagne un état "non construit" :
- Si `level == 0` : contour pointillé/grisé, pas de sprite plein (icône assombrie à faible alpha
  ou masquée), label = `"ui_build"` ("Construire") au lieu du nom + niveau. Pas de badge de
  palier (§4) tant que level = 0.
- Tap sur une tuile `level == 0` ouvre le même `BuildingDetailPanel` que les tuiles existantes.

`BuildingDetailPanel.gd` gagne une distinction déjà partiellement présente dans le flow cible
(`gameplay-flow.md` §2.2). Le bouton de confirmation (`_confirm_button.text`, aujourd'hui figé sur
`I18n.t("ui_upgrade")` dans `_ready()`) doit être recalculé dans `open_for()` selon le niveau :
- `level == 0` → bouton libellé `"ui_build"` ("Construire"), coût/durée = ceux du passage
  level 0 → 1 (même formule `get_building_cost`/`get_build_time_seconds`, qui fonctionnent déjà
  pour n'importe quel niveau de départ).
- `level >= 1` → comportement actuel inchangé, bouton `"ui_upgrade"` ("Améliorer" — clé existante,
  aucun renommage nécessaire).
- Si `start_building` échoue à cause du plafond de champs (level == 0 uniquement), afficher
  `I18n.t("ui_insufficient_fields")` dans `_status_label` au lieu du texte générique actuel
  (aujourd'hui `_on_confirm_pressed` ne distingue pas la cause d'échec, cf. `ui_insufficient_resources`
  ligne 38 — il faudra que `start_building`/l'appelant distingue "champs pleins" de "ressources
  insuffisantes", par ex. en checkant `get_used_fields() >= get_max_fields()` avant d'appeler
  `start_building` pour choisir le bon message).

## 3. Les 4 nouveaux bâtiments — config (`design/config/buildings.json`)

Mêmes formes que les entrées existantes (`base_cost`, `cost_factor` en `steel`/`components`,
formule exponentielle `base × factor^(L-1)` identique au reste du fichier) :

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

`design/config/global.json` gagne `"base_fields": 8`.

### Formules dans `GameState.gd`

- `energy_production`/`energy_consumption` des 4 nouveaux bâtiments s'intègrent **sans changement
  de code** dans `get_energy_report()`, qui itère déjà `GameData.buildings_cfg` génériquement par
  clé `energy_production`/`energy_consumption` (cf. code actuel, lignes 92-108).
- `fuel_consumption` d'`advanced_reactor` est un cas nouveau : ajouter dans la boucle de projection
  des ressources (`get_current_resources`) un rate négatif sur `fuel` égal à
  `coef × level × growth^level` (même formule que les autres, signe négatif), **plafonné à 0** pour
  le stock projeté de carburant (cf. plan §3, imprécision assumée : pas de cascade retour sur le
  bilan énergie si le carburant tombe à 0).
- `get_build_time_seconds(building_id)` divise le résultat actuel de `_time_from_cost_seconds` par
  `(1 + engineering_corps_level)`. `engineering_corps_level` lu directement dans
  `GameState.buildings["engineering_corps"]["level"]` (0 si pas construit → diviseur 1, aucun
  effet, cohérent).
- `get_max_fields()` / `get_used_fields()` : nouvelles fonctions pures, même style que
  `get_storage_capacity()`.

## 4. Palier visuel de progression (nouveau, ajouté à la demande — pas dans le plan initial)

Objectif : rendre visible qu'un bâtiment "s'est amélioré" au-delà du simple chiffre de niveau,
**sans produire de nouveaux assets** (cohérent avec l'esprit "placeholders" du plan v1).

- `tier = 1 + floor((level - 1) / 5)` pour `level >= 1` (niveaux 1-5 = palier 1, 6-10 = palier 2,
  etc.). `tier = 0` (aucun effet) pour `level == 0` (tuile non construite, cf. §2).
- Par palier, dans `BuildingNode._apply_style()` / `_refresh()` :
  - Bordure : épaisseur `3 + (tier - 1) * 2`, couleur éclaircie vers le blanc
    (`accent.lerp(Color.WHITE, min(0.12 * (tier - 1), 0.5))`) — effet "renforcé/métallique" croissant.
  - Icône (`TextureRect` du sprite) : `modulate` légèrement éclairci avec le tier, même formule de
    lerp, pour suggérer un aspect plus poli/moderne sans changer le PNG source.
  - Badge de rang : un `Label` supplémentaire affichant `"▲".repeat(tier - 1)` (0 chevron au tier 1,
    1 au tier 2, etc.) à côté du niveau — thème militaire cohérent avec le Commandant/Advance Wars.
- Pure présentation : aucune clé JSON, aucun impact sur les formules de coût/prod/temps. Vit
  entièrement dans `BuildingNode.gd`.

## 5. i18n

Nouvelles clés (EN canonique + FR), dans `design/i18n/en.json` + `fr.json` :
- `building_advanced_reactor`, `building_auxiliary_generator`, `building_engineering_corps`,
  `building_land_clearing`
- `ui_build` ("Build" / "Construire") — `ui_upgrade` existe déjà, aucun changement.
- `ui_insufficient_fields` ("Insufficient fields" / "Cases insuffisantes")

## 6. Hors scope de cette tranche (noté, pas oublié)

- Grille spatiale de cases tappables (le plan initial §2.4 l'évoquait ; remplacé par le compteur
  backend pur, décision actée dans ce document — cf. §1).
- Recherche (`research_center`, T4) — tranche suivante.
- Cascade exacte énergie ↔ carburant (réacteur qui s'arrête si le carburant tombe à 0) — imprécision
  assumée, cf. plan §3, résolue au portage serveur.
- Nouveaux assets graphiques (Higgsfield) pour les 4 bâtiments — sprites/couleurs/glyphes
  programmatiques uniquement pour ce feel-test, comme le reste du proto.

## 7. Vérification

Pas de framework de test GDScript dans le repo (prototype jetable, cf. `CLAUDE.md`) : vérification
par playtest manuel, section ajoutée à `GUIDE_TEST.md` (nouveau §6 "Construction de nouveaux
bâtiments (T3)") couvrant : tuile vide → panneau "Construire" → construction → tuile pleine avec
niveau 1 ; plafond de champs atteint → toast "Cases insuffisantes" ; Land Clearing relève le
plafond ; Engineering Corps réduit visiblement le temps de construction ; palier visuel change au
niveau 6 d'un bâtiment existant (ex. Steel Mine monté rapidement via `speed_factor`).
