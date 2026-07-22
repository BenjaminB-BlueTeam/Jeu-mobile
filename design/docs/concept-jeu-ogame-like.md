# Concept — Jeu mobile stratégie persistante (OGame × Base Building)

**Version 0.2 — 21/07/2026 — Ben**
*Document compagnon : `compendium-mecaniques-ogame.md` (mécaniques détaillées + décisions design actées)*

---

## 1. Pitch

Un jeu de stratégie mobile en monde persistant : chaque joueur développe **une base visuelle** (style Age of Empires / Whiteout Survival) posée sur une **carte-monde partagée** avec des milliers d'autres joueurs, des alliances, du raid et du commerce. Les mécaniques profondes viennent d'OGame (économie de ressources en temps réel, files de construction, recherche, flottes/armées en transit, rapports de combat), l'habillage et l'accessibilité viennent des 4X mobiles modernes.

**Le pari :** garder la profondeur et la tension d'OGame (on peut te raider pendant que tu dors) dans un format mobile lisible, avec des sessions de 5-10 min.

---

## 2. Univers (TRANCHÉ)

**Guerre moderne dans un monde "fantasy militaire"** : véhicules terrestres (chars, artillerie, convois, hélicos, drones) à la place des vaisseaux OGame. Référence visuelle : **Advance Wars: Dark Conflict** — proportions chibi-militaires, palettes franches, unités très lisibles, commandants charismatiques. ⚠️ On s'inspire du *style* uniquement : aucun asset, personnage ou nom repris (IP Nintendo/Intelligent Systems).

Table de transposition complète (planète→base, lune→bunker, flotte→bataillon, phalange→radar, etc.) : voir compendium §0.

## 2bis. Le Héros / Commandant (signature du jeu)

- **Customisation dès l'onboarding** (visage, tenue, emblème, couleur de faction), extensible en monnaie virtuelle (tenues, animations, skins de QG).
- **Il incarne l'UI** : le joueur le voit se déplacer dans la base selon ses actions — jeep vers la mine qu'on améliore, entrée au centre de recherche, revue des troupes devant l'usine, sprint au poste de commandement en cas d'attaque. Purement cosmétique côté client (le héros "joue" la file d'événements serveur) → zéro impact sur l'architecture autoritaire.
- Rôle gameplay : porte les **Doctrines** (ex-classes OGame) et l'**État-major** (ex-officiers). Jamais de stats de combat pay-to-win. Détail : compendium §7.

---

## 3. Core loop

```
Collecter ressources → Construire/améliorer la base (visuel) → Débloquer recherches
→ Produire unités → Envoyer missions sur la carte-monde (récolte, raid, expédition)
→ Rapports de combat / butin → Réinvestir → (boucle sociale : alliance, entraide, guerres)
```

- **Court terme (session 5 min)** : relancer files de construction, collecter, lancer une mission.
- **Moyen terme (jour/semaine)** : paliers de bâtiment HQ, événements, raids coordonnés.
- **Long terme (saison)** : guerres d'alliances, contrôle de zones de la carte, classements, reset saisonnier partiel.

## 4. Mécaniques OGame transposées

- **3 ressources + 1 énergie** : production continue même hors ligne (le cœur d'OGame).
- **Files de construction en temps réel** : les durées croissent, accélérables (monétisation).
- **Arbre de recherche** qui débloque unités et bonus.
- **Armées en transit** : chaque mission a un temps de trajet visible par la cible → fenêtres de vulnérabilité, interception, timing. C'est LA mécanique signature à conserver.
- **Rapports de combat** détaillés + espionnage.
- **Butin et "champs de débris"** (récupération après bataille) → incite au conflit.
- **Protection débutant + mode vacances** (indispensable pour le retentissement mobile).
- **Colonies/avant-postes multiples** en mid-game.

## 5. Différenciateurs vs OGame / vs Whiteout Survival

1. Base **visuelle et vivante** (vs tableaux HTML d'OGame).
2. Sessions courtes, onboarding guidé, pas de math obligatoire (vs OGame).
3. **Moins pay-to-win** que les 4X actuels : monétisation sur le confort et le cosmétique, saisons pour resserrer les écarts — c'est un vrai argument pour la niche des ex-joueurs OGame déçus des 4X prédateurs.
4. Serveurs/saisons à taille humaine (2-5k joueurs) → les alliances comptent vraiment.

## 6. Réalité du scope (à lire deux fois)

Whiteout Survival, c'est des centaines de personnes et un budget UA colossal. En solo, tu ne rivalises pas sur le contenu ni sur l'acquisition — tu rivalises sur **la niche** (joueurs OGame/Travian nostalgiques, fatigués du pay-to-win) et sur **l'itération rapide**. Conséquences :

- MVP = mécaniques OGame + base visuelle **simple** (grille 2D, pas de héros, pas de gacha, pas d'événements complexes au départ).
- Art : packs d'assets 2D achetés + génération IA retouchée. Pas de 3D.
- Un seul serveur au lancement, communauté Discord dès le premier jour.

## 7. Stack technique (solo + Claude Code)

Ce genre est à 80 % de l'UI et du backend, pas du moteur 3D. Reco :

- **Client : Godot 4** (export iOS/Android, scènes en fichiers texte → très adapté au travail avec Claude Code, gratuit, pas de royalties). La base en 2D top-down sur grille, la carte-monde en tuiles.
- **Backend : autoritaire côté serveur, obligatoire** (jeu multijoueur persistant = tout se calcule sur le serveur, le client ne fait qu'afficher).
  - **Option simple (reco pour le MVP) : Supabase** — Postgres + Edge Functions + Realtime. La production de ressources se calcule à la lecture (lazy evaluation, comme OGame), les combats sont résolus par des fonctions planifiées. Tu as déjà le connecteur Supabase branché ici, bonus.
  - Option "game backend" : Nakama (Heroic Labs) si tu veux du tout-en-un jeu (matchs, chat, guildes) — plus puissant, plus lourd à opérer.
- **Pas de tick global** : comme OGame, tout est calculé à la demande + jobs planifiés pour les arrivées d'armées. Ça scale très bien et c'est simple.

## 8. Monétisation (commercial)

- F2P + achats : accélérations (plafonnées), 2e file de construction, pass de saison, cosmétiques de base.
- **Lignes rouges** : pas d'achat direct de ressources massives ni d'unités → c'est ton positionnement.
- Objectif réaliste solo : quelques milliers de joueurs actifs rentabilisent les serveurs ; la vraie question est la rétention D7/D30, pas le revenu au départ.

## 9. Risques principaux

1. **Multijoueur persistant = complexité serveur** (anti-triche, équilibrage, coûts). Mitigé par l'approche lazy-evaluation + Supabase.
2. **Masse critique** : un monde persistant vide est mort. → lancement en beta fermée Discord, un seul serveur, bots de remplissage au besoin.
3. **Équilibrage** : prévoir dès le départ toutes les formules (production, combat, coûts) dans des tables de config modifiables sans redéploiement.
4. Stores : compte développeur Apple/Google, review, RGPD — prévoir 2-3 semaines admin.

## 10. Roadmap proposée

| Phase | Durée indicative | Contenu |
|---|---|---|
| 0. Game design détaillé | 2-3 sem. | Choix univers, formules économie/combat (tableur), wireframes |
| 1. Prototype économie | 3-4 sem. | Supabase + client Godot minimal : ressources, bâtiments, files, recherche (solo, pas de carte) |
| 2. Monde + combat | 4-6 sem. | Carte-monde, missions, trajets, résolution de combat, rapports, espionnage |
| 3. Social | 3-4 sem. | Alliances, chat, classements, protection débutant |
| 4. Beta fermée | 6-8 sem. | 100-500 joueurs Discord, équilibrage, rétention |
| 5. Soft launch | — | Un pays test, monétisation activée, itération |

## 11. Décisions actées & prochaines étapes

**Décisions design actées** (détail dans le compendium) :
- Univers guerre moderne / fantasy militaire, style visuel type Advance Wars: Dark Conflict (inspiration seulement).
- Héros/Commandant customisable qui incarne l'UI de la base.
- Pas de formes de vie (Lifeforms) ni équivalent — exclu définitivement.
- Drones avec fret de 10 ressources + garde-fou : toute unité anti-air posée détruit les drones en attaque, anti-air accessible très tôt.
- Pillage : 50 % sur actifs, **75 % sur inactifs pour tous**.

**Prochaines étapes** :
1. Doc d'univers : noms des ressources, unités, bâtiments, factions, ambiance.
2. Construire le **modèle économique dans un tableur** (formules de production/coûts/durées OGame-like, en s'appuyant sur les clones open source) — à faire AVANT tout code.
3. Ensuite seulement, premier prompt Claude Code (phase 1).

### Prompt de démarrage Claude Code (phase 1, quand le design sera figé)

```
Initialise un monorepo pour un jeu de stratégie mobile persistant :
- /server : projet Supabase (migrations SQL + edge functions TypeScript).
  Tables : players, bases, buildings, building_queue, resources, research.
  Production de ressources en lazy evaluation : colonne last_collected_at,
  calcul à la lecture via fonction SQL. Files de construction avec
  completed_at, résolues à la demande.
- /client : projet Godot 4 (GDScript), scène unique "Base" : grille 2D,
  placement de bâtiments, panneau ressources mis à jour depuis le serveur,
  file de construction avec timers.
- /design : les formules économiques dans des fichiers JSON de config
  (coûts, durées, production par niveau) partagés entre client et serveur.
Aucune logique de gameplay côté client : le serveur est autoritaire.
```
