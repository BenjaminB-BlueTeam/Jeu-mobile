# Guide de test — prototype `prototype-core-loop`

Prototype **jetable**, hors-ligne, mono-joueur : toute la logique (production, coûts, timers,
raid) tourne côté client en GDScript, à l'opposé de l'architecture finale serveur-autoritaire
(voir `CLAUDE.md`). Objectif : sentir la boucle de base, pas valider une archi.

## Lancer le prototype

1. Ouvrir Godot 4.3+ (ou plus récent compatible).
2. "Importer", sélectionner `client/project.godot`.
3. F5 (ou bouton Play) — lance `scenes/main/Main.tscn`.

⚠️ Doit être lancé **depuis l'éditeur** (ou un run source), pas depuis un export : la config
JSON est lue via `res://../design/config/*.json` (chemin relatif au dossier `client/`), qui ne
résout pas dans un export mobile. Pas d'export prévu pour ce feel-test.

## Ce qu'il faut sentir

Échelle de temps accélérée (`design/config/global.json` → `speed_factor: 20.0`) pour que la
boucle se sente en quelques minutes plutôt qu'en heures. Ajustable sans recompiler.

### 1. Ressources qui montent

À l'écran Base, regarder la barre du haut (Acier/Composants/Carburant/Énergie) quelques
secondes : les valeurs doivent monter en continu, sans à-coups perceptibles (recalcul toutes les
0,5 s à partir d'un timestamp — voir `GameState.gd`).

### 2. Améliorer un bâtiment

Taper la Mine d'acier → panneau coût/durée → "Améliorer". Vérifier :
- Les ressources sont débitées immédiatement.
- Le Commandant (rectangle doré "CMD") se déplace vers le bâtiment.
- Un texte de file apparaît sous la barre de ressources avec un compte à rebours.
- Taper un autre bâtiment producteur pendant que la file est occupée → message "File occupée"
  (1 seul slot de construction, comme prévu — cf. `design/docs/gameplay-flow.md` §4).
- À la fin du timer, le niveau affiché sur le bâtiment monte et le taux de production augmente
  (la pente de la barre de ressources s'accentue).

### 3. Produire une unité (file indépendante)

Taper l'Usine de véhicules → panneau différent (production, pas amélioration) → choisir une
quantité → "Produire". Vérifier que cette file tourne **en parallèle** d'une construction en
cours (les deux timers avancent indépendamment).

### 4. Raid sur la Carte

Une fois au moins 1 Buggy de reconnaissance produit : bouton "World Map" en bas de l'écran Base
→ taper une base marquée comme inactive (les seules ciblables) → choisir une quantité → "Envoyer
le raid". Vérifier :
- Taper une base "active" affiche un toast "Non ciblable dans ce prototype" (pas d'erreur).
- Le temps de trajet est affiché avant confirmation.
- Après le retour (timer visible sous la barre de ressources, écran Base), un toast apparaît :
  "Convoi rentré : +X [ressource]", les ressources sont créditées une seule fois.

### 5. Persistance entre sessions

Lancer une construction ou un raid, **fermer la fenêtre du jeu** (pas juste minimiser) avant la
fin du timer, puis relancer (F5). Vérifier qu'à la réouverture, l'état reflète le temps réellement
écoulé : si le timer était fini entre-temps, la construction/le raid doit s'être résolu tout seul
(niveau monté / butin crédité) sans duplication.

## Limites connues (assumées, pas des bugs)

- Pas d'onboarding codé (Commandant par défaut au lancement) — décrit dans
  `design/docs/gameplay-flow.md` §1 seulement.
- Pas de recherche, pas de rapport de combat dédié, pas d'alliance — hors scope de ce prototype.
- Pas d'attaque adverse : le fleet save (mécanique n°1 du jeu final) n'est pas simulé ici.
- Usine de véhicules : le niveau affiché n'a aucun effet mécanique (décoratif, cf.
  `design/config/buildings.json`).
- 1 seul convoi de raid actif à la fois, un seul timer aller-retour global (pas de distinction
  aller/retour séparée).
- Commandant = rectangle coloré + label "CMD" (aucun asset fourni/généré pour cette tâche).
