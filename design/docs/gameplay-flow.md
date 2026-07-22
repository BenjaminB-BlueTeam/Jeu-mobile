# Flow de jeu — Iron Front

**Version 0.1 — 22/07/2026 — Ben & Claude**
*Compagnon de : `concept-jeu-ogame-like.md`, `compendium-mecaniques-ogame.md`, `univers-du-jeu.md`*

---

## 0. Périmètre de ce document

Ce document décrit la cible complète du jeu. Une partie seulement est implémentée dans le
prototype jouable de la branche `prototype-core-loop` (hors-ligne, jetable, cf. `GUIDE_TEST.md`).

| Élément | Documenté ici | Codé dans le prototype |
|---|---|---|
| Base (bâtiments, ressources) | Oui | Oui |
| Détail bâtiment (amélioration) | Oui | Oui |
| Carte-monde (secteurs, raid) | Oui | Oui (simplifié) |
| Production d'unités | Oui | Oui |
| Persistance locale | Oui | Oui |
| Onboarding (création du Commandant) | Oui | Non — Commandant par défaut au lancement |
| Recherche | Oui | Non — hors scope du feel-test |
| Rapport de combat (écran dédié) | Oui | Non — remplacé par un toast texte |
| Alliance | Oui | Non |
| Fleet save / attaque adverse | Oui (mécanique cible) | Non — pas d'adversaire simulé |
| 2e file de construction ("ingénieur", premium) | Oui | Non — pas de monétisation dans un jetable |

---

## 1. Onboarding — premier lancement

Écran de création du Commandant (cf. univers §11), avant tout accès à la Base :

1. **Nom** du Commandant (champ texte, valeur par défaut proposée).
2. **Visage** : galerie de portraits (style Advance Wars, banque de ~6 visages).
3. **Tenue** : 3-4 options cosmétiques.
4. **Emblème** : grille de blasons.
5. **Couleur d'accent** : nuancier (indépendant de la faction).
6. **Faction** : cosmétique uniquement, aucun bonus gameplay (règle actée CLAUDE.md) — Ashen
   Legion / Azure Pact / Verdant Union / Golden Syndicate.

Puis **3 actions guidées**, une bulle + surbrillance à la fois, l'écran reste bloqué sur l'étape
en cours (skippable après une première complétion) :

1. **Améliorer la Mine d'acier** (niveau 1→2) : introduit le panneau de détail bâtiment, le coût,
   la file de construction à 1 slot, le déplacement du Commandant vers le bâtiment.
2. **Lancer la production d'un Buggy de reconnaissance** à l'Usine de véhicules : introduit la
   file de production d'unités, indépendante de la file de construction.
3. **Envoyer ce Buggy en raid** sur une base inactive proche sur la Carte-monde : introduit
   l'écran Carte, la sélection de cible, le temps de trajet, le retour avec butin.

À l'issue des 3 actions, l'onboarding se termine, le joueur a une vue complète de la boucle.

---

## 2. Les 5 écrans

### 2.1 Base *(codé)*

**Vue** : plan 2D vue de dessus, quelques bâtiments disposés sur une grille simple (Mine d'acier,
Atelier de composants, Raffinerie de carburant, Centrale électrique, Usine de véhicules), le
Commandant visible sur le terrain. Barre de ressources fixe en haut (Acier / Composants /
Carburant / Énergie), qui monte en continu.

**Actions** : taper un bâtiment ouvre le panneau de détail. Bouton d'accès à la Carte-monde
(coin de l'écran). Indicateur de file de construction en cours (icône + minuteur) si un slot est
occupé.

**Boutons clés** : bâtiments tappables, bouton "Carte", badge de file active.

### 2.2 Détail bâtiment *(codé)*

**Vue** : popup — nom du bâtiment, niveau actuel → niveau suivant, coût (par ressource, grisé si
insuffisant), durée de construction, description courte (flavor, cf. univers).

**Actions** : bouton "Améliorer" (débite les ressources, occupe le slot de file, ferme le popup,
lance le timer et l'animation du Commandant) ; si le slot de construction est déjà occupé, message
"File occupée" (pas de 2e slot gratuit — cf. §4).

**Boutons clés** : Améliorer, Fermer.

### 2.3 Carte-monde *(codé, simplifié)*

**Vue** : grille de secteurs. Le secteur du joueur au centre, quelques bases voisines : certaines
**inactives** (fermes pillables, seules ciblables dans le prototype), d'autres **actives**
(affichées mais non ciblables dans le prototype — cible finale : raid/espionnage complet).

**Actions** : sélectionner une base inactive ouvre le panneau de raid — choix des unités
disponibles à envoyer, temps de trajet affiché, confirmation lance le convoi (visible sur la
carte le temps du trajet). Au retour : butin crédité + toast "Convoi rentré : +X Acier".

**Boutons clés** : sélection de secteur, "Envoyer le raid", retour à la Base.

### 2.4 Rapport de combat *(documenté seulement)*

**Cible finale** : écran dédié listant, par vague, les pertes des deux camps, le butin détaillé,
le champ d'épaves généré (cf. compendium §3.2), rédigé comme une dépêche militaire (cf. univers
§12, ex. « 04:12 — Le convoi de ravitaillement est tombé dans une embuscade au secteur 4:117 »).
Dans le prototype, ce rapport est remplacé par un simple toast texte (pas de combat réel simulé,
seulement du pillage sur bases inactives sans opposition).

### 2.5 Alliance *(documenté seulement)*

**Cible finale** : liste des membres, chat, stationnement défensif (ACS Defend, cf. compendium
§4.4), déclarations de guerre (levée de la limite de bash, §3.13), PNA/pactes. Absent du
prototype (pas de multijoueur dans un feel-test hors-ligne).

---

## 3. Boucle cœur

```
   ┌─────────────────────────────────────────────────────────────────┐
   │                                                                   │
   ▼                                                                   │
ACCUMULER  →  DÉCIDER  →  ENVOYER UNE ARMÉE  →  RISQUE NOCTURNE  →  COLLECTER
(passif,      (améliorer /   (raid/mission,       (fleet save —       (lecture
lazy-eval)     rechercher /   temps de trajet       CIBLE FINALE,       lazy-eval,
               produire)      visible par la        non simulée         retour de
                              cible)                dans ce proto :     convoi,
                                                     pas d'attaque       butin)
                                                     adverse ici)
```

- **Accumuler** : les ressources montent en continu, hors ligne comme en jeu (lazy evaluation —
  cœur d'OGame, cf. compendium §1). Le joueur n'a rien à faire pour que ça avance.
- **Décider** : améliorer un bâtiment, lancer une recherche (cible finale), produire des unités —
  trois files indépendantes (§4).
- **Envoyer une armée** : chaque mission a un temps de trajet visible par la cible (mécanique
  signature à conserver, cf. concept §4) — fenêtre de vulnérabilité, interception, timing.
- **Gérer le risque nocturne (fleet save)** : cible finale — cf. compendium §4.1, tout mouvement
  rend l'armée + les ressources embarquées intouchables ; c'est LA mécanique n°1 du jeu final.
  Le prototype ne simule aucune attaque adverse, donc ce risque n'est pas ressenti ici — seule la
  mécanique de temps de trajet (aller-retour) est testée.
- **Collecter** : au retour du convoi, butin ajouté aux ressources ; la lecture lazy-eval reflète
  aussi la production accumulée pendant l'absence.
- **Recommencer** : la boucle s'auto-alimente, avec des paliers de plus en plus longs (croissance
  exponentielle des coûts).

---

## 4. Modèle de construction (décision actée, à implémenter tel quel)

**File façon OGame, PAS d'ouvriers façon Clash of Clans.** Une file = une chose à la fois ; on ne
paie pas pour paralléliser des unités de travail, on paie pour une 2e file entière.

- **1 slot de construction gratuit** : le Héros/Commandant construit une chose à la fois (le
  Commandant se déplace physiquement au bâtiment, animation de chantier — cf. compendium §7,
  univers §11).
- **2e slot de construction = premium** ("ingénieur" recruté, cf. état-major compendium §7) —
  confort payant, jamais un item qui accélère au-delà du raisonnable ni un item pay-to-win (ligne
  rouge CLAUDE.md). Non implémenté dans le prototype (pas de vraie monétisation en offline).
- **Recherche** : file **indépendante** de la construction, son propre slot (1 gratuit). Non codée
  dans le prototype (hors des 6 points du feel-test), juste esquissée ici pour cohérence.
- **Production d'unités** : file **indépendante**, son propre slot par usine (Usine de véhicules).
  C'est la file testée dans le prototype aux côtés de la construction — les deux peuvent tourner
  **en parallèle** puisque ce sont deux files distinctes.

Chaque file a ses propres formules de coût/durée (même forme exponentielle, cf. compendium §1),
mais son propre minuteur et son propre slot — jamais de queue partagée entre construction,
recherche et production.
