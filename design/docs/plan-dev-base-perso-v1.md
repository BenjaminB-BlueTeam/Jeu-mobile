# Plan de dev — Base perso v1 (prototype)

**Version 0.1 — 22/07/2026 — Ben & Claude**
*Compagnon de : `gameplay-flow.md` §2.1-2.2, `univers-du-jeu.md` §5-6, `compendium-mecaniques-ogame.md` §1*

---

## 0. Décisions de cadrage (actées)

- **Fondation : le prototype client jetable** (branche `prototype-core-loop`, logique en GDScript
  local). But = valider le FEEL et le contenu de la base vite et gratuitement. Ce code sera jeté
  au passage serveur-autoritaire (cf. `CLAUDE.md` racine). Le prototype sert de **spec vivante**
  du futur backend.
- **Périmètre v1 : base perso uniquement.** Carte-monde / raid / social / monétisation = hors
  scope de ce plan (le raid existant reste en place, on n'y touche pas).
- **Assets : placeholders programmatiques** (formes / couleurs / glyphes dessinés dans Godot).
  Moche assumé. Zéro crédit Higgsfield tant que le feel n'est pas validé.

---

## 1. Bâtiments de la base v1 (~11)

Noms i18n canoniques : cf. `univers-du-jeu.md` §6. Tous préexistants sur la grille jusqu'à T3
(où l'on introduit la construction de nouveaux bâtiments sur cases vides).

| Bâtiment (EN / clé) | Rôle mécanique | Introduit en |
|---|---|---|
| Steel Mine `steel_mine` | Produit acier, **consomme énergie** | existant (T1) |
| Component Workshop `component_workshop` | Produit composants, **consomme énergie** | existant (T1) |
| Fuel Refinery `fuel_refinery` | Produit carburant, **consomme énergie** | existant (T1) |
| Power Plant `power_plant` | **Produit énergie** (flux) | existant (T1, réinterprété) |
| Vehicle Factory `vehicle_factory` | Produit unités (file indépendante) | existant |
| Headquarters `headquarters` | Hub visuel du Commandant, décoratif | T1 |
| Storage Depot `storage_depot` | **Plafond de capacité** des 3 ressources | T2 |
| Advanced Reactor `advanced_reactor` | +énergie, **consomme carburant** | T3 |
| Auxiliary Generator `auxiliary_generator` | +énergie, coût faible | T3 |
| Engineering Corps `engineering_corps` | **Réduit le temps de construction** | T3 |
| Land Clearing `land_clearing` | **Débloque des cases** (limite de bâtiments) | T3 |
| Research Center `research_center` | Active la file de recherche | T4 |

---

## 2. Mécaniques v1 (formules)

Toutes les formules vivent dans `design/config/*.json` (règle CLAUDE.md §4). Croissance
exponentielle par niveau `coef × L × growth^L` (growth = 1.1), coût `base × factor^(L-1)`.

### 2.1 Énergie = flux (T1) — répare la mécanique creuse actuelle

Aujourd'hui `power` est un stock qui monte sans effet. On le remplace par un **flux instantané** :

- `power` **sort** des ressources stockées (`RESOURCE_KEYS = [steel, components, fuel]`).
- Chaque producteur (mine/atelier/raffinerie) a une `energy_consumption` = `base × L × 1.1^L`.
- Chaque source d'énergie (centrale, réacteur, générateur) a une `energy_production` = `coef × L × 1.1^L`.
- `balance = Σ production − Σ consommation`.
- `production_factor = 1.0 si balance ≥ 0, sinon clamp(Σprod / Σcons, 0, 1)`.
- Le facteur multiplie la prod d'acier / composants / carburant dans le projeté lazy-eval.
- Barre : `Énergie : +120` (vert) ou `Énergie : −30 ⚠` (rouge) au lieu d'un compteur qui monte.

### 2.2 Plafonds de stockage (T2)

- `storage_depot` niveau L → `capacity = base_capacity × storage_growth^L`, **partagée** par les
  3 ressources (simplification v1 ; OGame a un hangar par ressource — noté pour le port serveur).
- `get_current_resources` clampe chaque ressource projetée à `min(projeté, capacity)`.
- Barre affiche `courant / max` ; passe en rouge à plein (prod effectivement stoppée).
- `base_capacity` choisi pour ne pas capper dès les premières minutes.

### 2.3 Réduction du temps de construction (T3)

- `engineering_corps` niveau L → facteur `(1 + L)` au dénominateur du temps de construction :
  `temps = base_time / (1 + engineering_corps_level)`. Touche la file construction, pas la prod
  d'unités (v1).

### 2.4 Construction de nouveaux bâtiments + limite de cases (T3)

Change le modèle « tout préplacé » : la grille a des **cases vides**. Taper une case vide ouvre
un menu « Construire » (choix parmi les bâtiments non encore posés).

- `max_fields = base_fields + land_clearing_level × fields_per_clearing`.
- Nombre de bâtiments posés ≤ `max_fields` ; sinon message « Cases insuffisantes ».
- Construire consomme ressources + occupe **la file de construction** (même slot unique que l'upgrade).

### 2.5 Recherche (T4)

- `research_center` (niveau ≥ 1) active une **3e file indépendante** (son propre slot, son timer).
- 2-3 technos early qui touchent la base :
  - **Energy Tech** `tech_energy` — `+8 % × niveau` de production d'énergie.
  - **Heavy Ordnance** `tech_ordnance` — `+5 % × niveau` de production des mines (bonus OGame plasma).
  - (optionnel) **Research Coalition** `tech_coalition` — `−X %` temps de recherche.
- Effets câblés dans les formules de prod / énergie via un multiplicateur de techno.

---

## 3. Détail réacteur / carburant (précision lazy-eval)

`advanced_reactor` consomme du carburant (`fuel_consumption = coef × L × 1.1^L`), modélisé comme
un **taux négatif** sur le carburant. Le projeté est **planché à 0** (`max(0, projeté)`). Imprécision
assumée : quand le stock de carburant est vide, le réacteur reste compté dans le bilan énergie
(pas de cascade prod→énergie→prod). Acceptable pour un feel-test ; le port serveur résoudra ça en SQL.

---

## 4. Découpage en tranches (chacune visualisable, commit local par tranche)

- **T1 — Énergie flux + refonte visuelle.** Retire `power` du stock, implémente le flux + facteur,
  barre ressources avec taux de prod et bilan énergie. Refonte visuelle : sol tuilé, bâtiments
  redessinés (forme + glyphe + couleur par métier + niveau), Commandant moins moche, QG posé.
  → **premier vrai visuel jouable.**
- **T2 — Plafonds de stockage.** `storage_depot`, cap partagé, barre `cur/max`, prod stoppée à plein.
- **T3 — Construction + éco.** Cases vides + menu Construire + `land_clearing`/limite de cases ;
  `advanced_reactor`, `auxiliary_generator`, `engineering_corps` (temps). → **feel base-building.**
- **T4 — Recherche.** `research_center`, 3e file, 2-3 technos câblées sur prod/énergie.

---

## 5. Hors scope v1 (noté, pas oublié)

- Carte-monde / raid / combat / social (le raid actuel reste tel quel).
- Onboarding / création du Commandant, doctrines, état-major.
- Hangars séparés par ressource, cascade énergie exacte, réacteur endgame.
- Tout asset non-programmatique (Higgsfield) — après validation du feel.
- Le port serveur-autoritaire (Supabase) — ce prototype en sera la spec.

---

## 6. Invariants respectés (règles CLAUDE.md)

- Toute la logique reste dans `GameState.gd` ; l'UI ne fait qu'afficher (jamais de calcul de coût/temps/prod côté vue).
- Toutes les formules restent dans `design/config/*.json`, modifiables sans recompiler.
- i18n : aucune string en dur, clés EN canoniques dans `en.json` + `fr.json`.
- Lazy-eval conservé (projection depuis timestamp, flush avant changement de taux / dépense / save).
