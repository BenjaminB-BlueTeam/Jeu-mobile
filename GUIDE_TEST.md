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

### 6. Construction de nouveaux bâtiments (T3)

Au lancement, 4 nouvelles tuiles apparaissent en bas de la Compound, grisées avec le texte
"Construire" : Advanced Reactor, Auxiliary Generator, Engineering Corps, Land Clearing.

- Taper une tuile grisée → panneau de détail avec bouton "Construire" (pas "Améliorer") et un coût
  de niveau 0→1. Confirmer débite les ressources, lance le timer (même file que les améliorations
  — un seul slot de construction). À la fin, la tuile passe en état "construit" (niveau 1, sprite
  plein/couleur pleine).
- Construire 2 des bâtiments suivants (peu importe l'ordre, mais **pas encore Land Clearing**) :
  Advanced Reactor, Auxiliary Generator, Engineering Corps. 8 champs de base, 6 déjà pris par les
  bâtiments existants → seulement 2 places libres, donc ces 2 constructions remplissent le
  compteur de champs (8/8).
- Tenter de construire le 3e bâtiment restant parmi ces trois → échoue avec le toast/message
  "Cases insuffisantes". Tenter aussi Land Clearing à ce stade → échoue exactement de la même
  façon (le plafond de champs s'applique uniformément à toutes les constructions, y compris à
  Land Clearing lui-même — aucun passe-droit).
  ⚠️ **Ceci est voulu, pas un bug** : si les 2 places libres sont consommées par autre chose que
  Land Clearing avant qu'il soit construit, Land Clearing devient **définitivement** impossible à
  construire dans cette sauvegarde (il lui faut un champ libre pour être posé, mais lui seul peut
  en créer de nouveaux). C'est l'équivalent du piège du Terraformer dans OGame : à construire tôt,
  sous peine de rester bloqué. Pour vérifier que Land Clearing lève bien le plafond (point
  suivant), il faut donc repartir sur une sauvegarde neuve — supprimer le fichier de sauvegarde
  (`user://savegame.json`, cf. `SaveManager.gd`; sous Windows via l'éditeur cela correspond à
  `%APPDATA%\Godot\app_userdata\Iron Front — Core Loop Prototype\savegame.json`) — et construire
  Land Clearing en premier, avant les deux autres bâtiments T3.
- Sur une sauvegarde neuve où Land Clearing est construit avant les deux autres : le monter d'un
  niveau → le plafond de champs augmente (+2 par niveau), un bâtiment auparavant bloqué par
  "Cases insuffisantes" devient constructible.
- Construire Engineering Corps → le temps affiché pour une amélioration suivante (ex. Steel Mine)
  diminue visiblement par rapport à avant sa construction.
- Construire Advanced Reactor puis observer la barre de Carburant (haut d'écran) : son taux de
  montée doit baisser (le réacteur consomme du carburant en flux), sans jamais passer sous 0.
- Faire monter un bâtiment existant (ex. Steel Mine) au niveau 6 en accéléré (`speed_factor`) :
  la tuile doit changer d'aspect (bordure plus épaisse/claire, un chevron ▲ apparaît à côté du
  niveau) par rapport à son apparence aux niveaux 1-5.

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
