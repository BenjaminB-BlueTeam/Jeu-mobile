# Compendium des mécaniques OGame & transposition "Guerre Moderne Fantasy"

**Version 1.0 — 21/07/2026 — Ben**
Recherche croisée : wikis OGame (Fandom, owiki.de, wiki.ogame.org, Sidian), forums officiels Gameforge FR/EN, pages officielles Gameforge, chaînes YouTube FR (@BoobzLaden, @7020Psykose, Sagesse Ogame), clones open source (pr0game, 2Moons, XNova, alaingilbert/ogame). Sources complètes en fin de document.

---

## 0. Univers retenu & direction artistique

**Guerre moderne dans un monde "fantasy militaire"** : véhicules terrestres (chars, artillerie, convois, hélicos) à la place des vaisseaux, factions stylisées, ton légèrement cartoon/exagéré.

**Référence visuelle : Advance Wars: Dark Conflict** (proportions chibi-militaires, palettes franches, unités lisibles, commandants charismatiques). ⚠️ **Attention IP** : on s'inspire du *style* (proportions, lisibilité, ton), on ne reprend NI les assets, NI les personnages, NI les noms — Advance Wars appartient à Nintendo/Intelligent Systems. Un artiste (ou une génération IA bien dirigée) peut produire un style "military toon" original dans cet esprit.

### Table de transposition générale

| OGame | Notre jeu |
|---|---|
| Planète | **Base / Territoire** (base visuelle constructible) |
| Colonie | **Avant-poste** (nouvelle base sur la carte-monde) |
| Lune | **Bunker souterrain** (annexe cachée de la base, gagnée après grosse bataille) |
| Flotte | **Bataillon / Convoi** (colonnes de véhicules visibles sur la carte) |
| Vaisseaux (CLE, croiseur, VB…) | **Véhicules** : jeeps, chars légers/lourds, artillerie, hélicos, lance-missiles |
| Transporteurs (PT/GT) | **Camions / Convois logistiques** |
| Recycleurs | **Dépanneuses / équipes de récupération** |
| Sonde d'espionnage | **Drone de reconnaissance** (fret : 10 ressources) |
| Étoile de la Mort (RIP) | **Bombardier stratégique / canon géant** (unité endgame rare) |
| Champ de débris (CDR) | **Champ d'épaves** (carcasses récupérables sur la carte) |
| Phalange de capteur | **Station radar longue portée** (dans le bunker) |
| Porte de saut | **Réseau ferroviaire souterrain / pont aérien** (transfert instantané bunker↔bunker) |
| MIP / MI | **Missiles balistiques / batteries antimissiles** |
| Expédition (case 16) | **Expédition en zone contaminée / terres sauvages** (bords de carte) |
| Métal / Cristal / Deutérium | 3 ressources (ex. **Acier / Composants / Carburant**) + **Énergie** |
| Matière noire | Monnaie premium (ex. **Or / Lingots**) |
| Mode vacances | **Cessez-le-feu** |
| Officiers | **État-major** (voir §7 Héros) |
| Classes (Collecteur/Général/Découvreur) | **Doctrines** (Industrielle / Offensive / Exploration) |

---

## 1. Économie (le socle OGame)

Formules de référence (extraites des wikis + clones open source — à recaler dans notre tableur) :

- **Production/h des mines** : `30 × L × 1.1^L` (métal), `20 × L × 1.1^L` (cristal), `10 × L × 1.1^L × f(température)` (deutérium — chez nous : raffinerie de carburant, modulée par le type de terrain de la base au lieu de la température).
- **Coûts** : coût niveau L = base × facteur^(L−1) (facteurs 1,5–1,8 ; hangars ×2). Croissance exponentielle = cœur de la progression long-terme.
- **Énergie** : centrales (solaire→**centrale électrique**, fusion→**réacteur**, satellites→**générateurs d'appoint**) ; déficit d'énergie = production réduite proportionnellement.
- **Hangars** : capacité exponentielle ; hangar plein = production stoppée ; les hangars ne protègent PAS du pillage.
- **Temps de construction** : `(coût M+C) / (2500 × (1+robots) × vitesse × 2^nanites)` — chez nous : grues/équipes d'ingénieurs.
- **Valeur d'échange** : ratio officieux **3:2:1** (métal:cristal:deut), 2:1:1 sur serveurs guerriers. À reproduire : une ressource "carburant" rare qui sert de monnaie ET de coût de déplacement.
- **Pillage** : 50 % des ressources posées sur joueurs actifs ; **75 % sur les inactifs pour tout le monde** (décision design — dans OGame ce taux est réservé à la classe Découvreur ; chez nous il est universel pour encourager le nettoyage des fermes). Vagues successives : chaque attaque prend le taux du restant.
- **Le marchand** (échange contre premium), l'import/export (objets contre ressources), boosters temporaires (Kraken/Detroid/Newtron → chez nous : caisses de matériel).

**La "banque" (protection des ressources)** — mécanique centrale :
1. Dépenser avant déconnexion (files longues).
2. **Embarquer les ressources dans le convoi en fleet save** : les ressources en mouvement sont involables. La vraie banque d'OGame = les camions chargés qui roulent la nuit.
3. Corollaire design : le carburant du FS est le "loyer" de la banque.

---

## 2. Espionnage

- **Drones (sondes)** : **fret de 10 unités de ressources** (décision design — comme les univers OGame où les sondes ont du fret ; permet le micro-pillage en masse de drones sur cibles vides, unité la plus rapide du jeu). Niveau de détail du rapport = f(écart de techno espionnage, nombre de drones).
  - ⚖️ **Garde-fou équilibrage (décision actée)** : le "probe raiding" (nuées de drones qui micro-pillent à moindre coût) ne doit pas devenir la stratégie dominante du early game → **toute unité anti-air posée détruit les drones en mission d'attaque**, et l'anti-air de base est accessible très tôt dans l'arbre de construction. Paliers : ressources → défense → unités → bâtiments → recherches. Formule : info = nb sondes + (écart technos)².
- **Contre-espionnage** : probabilité de détection/destruction des drones ∝ nb de drones envoyés, unités présentes, (écart technos)². Compromis risque/info. Le rapport de contre-espionnage révèle l'origine → l'espionné sait qu'il est ciblé.
- **Règles d'or des joueurs** : sonder avant TOUTE attaque, re-sonder dans les dernières secondes avant impact (anti-ninja).
- **Radar (phalange)** : voir §5 — lecture des mouvements, pas des unités posées.

---

## 3. Techniques offensives (le vrai contenu du jeu)

### 3.1 Raid / farming
Piller les faibles et les **inactifs** (statuts i/I après 7/28 jours — les inactifs produisent encore = "fermes", **pillables à 75 %** vs 50 % pour les actifs). Entretien d'une liste de fermes, calcul de fret, frappes aux heures creuses de la cible, vagues dans la limite de bash.

### 3.2 Crash de flotte
Détruire un bataillon posé pour récolter le **champ d'épaves** (~30 % de la valeur des unités détruites des DEUX camps). Rentabilité = épaves + butin − pertes − carburant. Séquence : espionner → simuler → attaquer synchronisé → **dépanneuses envoyées AVANT l'attaque** pour arriver juste après le combat (voler les épaves au défenseur).

### 3.3 Attaque groupée (AG / ACS)
Jusqu'à 5 attaquants fusionnent leurs bataillons en une "union". **Règle des 30 %** : une flotte qui rejoint ne peut pas ralentir l'union de plus de 30 % du temps restant. Butin réparti au prorata du fret. Le **self-ACS** (union avec soi-même) sert à ralentir/re-timer sa propre attaque déjà lancée.

### 3.4 Snipe au retour
Une flotte en vol est intouchable ; à la seconde où elle atterrit, elle est attaquable. Le snipe = faire arriver son attaque **quelques secondes après l'atterrissage du retour** adverse (lu au radar). Timing à 3-4 secondes près chez les experts. Cas : retour d'attaque, de transport, de déploiement, **récolte d'épaves datée par la disparition du champ en vue carte**.

### 3.5 Décalage à la sonde (technique signature FR — tutos Psykose)
Moduler l'heure d'impact d'une attaque DÉJÀ lancée : créer une union (AG) sur son propre vol et y faire entrer un drone envoyé à vitesse réduite → l'impact est **retardé à la seconde près sans rappeler** (dans la limite des 30 %). Usages : coller au retour adverse, fausser l'heure d'impact lue par le défenseur, synchroniser des vagues.

### 3.6 Ninja (piège défensif... utilisé offensivement)
Le défenseur appâte (ressources visibles, défense faible), puis fait atterrir sa vraie armée (rappel de déploiement — invisible au radar —, transfert ferroviaire bunker→bunker, ou renforts alliés en stationnement) **quelques secondes avant l'impact**, trop tard pour un rappel adverse. L'attaquant calibré pour du pillage se fait détruire ; le défenseur ramasse les épaves (et parfois gagne son bunker — "ninja moonshot").

### 3.7 Missiles balistiques (MIP)
Détruisent **définitivement** la défense (pas de reconstruction, pas d'épaves), ignorent les boucliers/coupoles. Prérequis silo ; portée = f(techno propulsion) ; les **antimissiles** (MI) interceptent 1:1 — il faut saturer avant de toucher. Ne comptent pas dans la limite de bash. Usage : "ouvrir" une tortue avant le raid.

### 3.8 Destruction de bunker (destruction de lune)
Mission spéciale des unités endgame (bombardier stratégique). Chance de réussite = `(100 − √diamètre) × √(nb d'unités)` ; chance de perdre les unités = `√diamètre / 2` (jets indépendants). Combat normal AVANT le jet → une défense de bunker dissuade les tentatives discount. **Combo mortel** : détruire le bunker pendant que la flotte adverse est en vol → tous ses mouvements retombent sur la base principale, redevenue lisible au radar → snipe du retour. C'est LE contre du fleet save parfait.

### 3.9 Moonshot (fabrication de bunker)
Un combat générant ≥ ~2M d'épaves donne jusqu'à **20 % de chance** de créer un bunker (1 %/100k d'épaves). Pratique coopérative : un allié envoie ~1667 véhicules légers se faire détruire, on partage les coûts, ~5 essais en moyenne. Aussi : tout gros crash peut "luner" la victime comme le vainqueur.

### 3.10 Traque ("lanx permanent")
Chasse d'une grosse cible : **coloniser un avant-poste près d'elle → s'y faire un bunker (moonshot) → monter le radar → scans répétés** pour cartographier ses habitudes de fleet save jusqu'à la faille (horaire régulier, récolte datée, déploiement visible). Combo avec §3.8 si la cible save bunker→bunker.

### 3.11 La "volante" (jargon FR — tuto Sagesse Ogame #18)
Garder un **véhicule de colonisation en vol** pour poser à la demande un avant-poste jetable près d'une cible : point d'appui hors de portée radar, relais, ou **double attaque** (une attaque visible + une seconde depuis l'avant-poste frais). L'avant-poste est ensuite abandonné.

### 3.12 Blind phalanx (snipe à l'aveugle)
Sniper sans lecture radar : déduire les heures de retour possibles par observation indirecte (disparition d'épaves, étoiles d'activité, heure d'un combat) + énumération des temps de trajet possibles (paliers de vitesse 10-100 %) → ensemble fini d'heures candidates ; le retour d'un déploiement rappelé tombe dans un **intervalle calculable** (outil communautaire : LanxCalc). Punit les joueurs aux horaires réguliers même protégés par bunker.

### 3.13 Règle de bash
Max **6 attaques par base/24 h** (missiles exclus, attaques anéanties exclues). Levée 12 h après une **déclaration de guerre** officielle entre alliances → la diplomatie fait partie du gameplay offensif.

---

## 4. Techniques défensives

### 4.1 Fleet save (FS) — LA mécanique n°1 du jeu
Tout mouvement rend l'armée + les ressources embarquées intouchables. Variantes classées par sûreté :

| Variante | Lisible au radar ? |
|---|---|
| **Déploiement bunker→bunker** | **Invisible de bout en bout** (méthode reine, nécessite 2 bunkers) |
| Bunker→épaves (récolte) | Invisible, MAIS la disparition des épaves date le retour (parade : "shadow waves" de dépanneuses leurres) |
| Bunker→expédition | Invisible ; risque = événements d'expédition |
| Déploiement base→base + **rappel** | Aller visible ; **le retour d'un déploiement rappelé disparaît du radar** (seule méthode sûre sans bunker) |
| Récolte / attaque lente sur inactif depuis une base | Visible → phalangeable → dangereux |
| FS colonisation | Sûr SI aucun slot d'avant-poste libre (sinon largage des ressources !) |

Bonnes pratiques : varier heures/vitesses/destinations (30 min-1 h min.), se reconnecter 1 h avant le retour, ne JAMAIS dormir armée posée.

### 4.2 Défense statique ("tortue")
**Principe cardinal : la défense ne sert qu'à dissuader** — toute défense tombe face à un attaquant déterminé ; son rôle est de rendre le raid non rentable. **Fodder/chair à canon** : masse d'unités bon marché qui absorbe les tirs et le rapid fire, protégeant les grosses pièces (ratios type ~270 lanceurs par tourelle lourde). **Règle des 70 %** : après combat, chaque défense détruite a ~70 % de chance d'être reconstruite gratuitement (85 % avec l'Ingénieur) — SAUF si détruite par missile. Classiquement la défense ne génère pas d'épaves (paramètre d'univers) → détruire une tortue ne rapporte rien, c'est ça qui dissuade. **Les vraies armées ne se protègent jamais derrière une défense** : le FS protège l'armée, la défense protège la production nocturne.

### 4.3 Coupoles, antimissiles, radar défensif
Coupoles (1 petite + 1 grande max/base) : gros bouclier global, ignoré par les missiles balistiques. Stock permanent d'antimissiles obligatoire pour toute tortue. Radar aussi défensif : surveiller les attaquants proches.

### 4.4 Ninja (côté défenseur) et stationnement allié
Voir §3.6. **ACS Defend** : stationner jusqu'à 32 h chez un allié (alliance ou liste d'amis), max 5 défenseurs, les flottes combattent ensemble. Sert au ninja collectif — et attention : attaquer la base hôte pendant un stationnement crashe deux armées d'un coup.

### 4.5 Protections systémiques
**Protection débutant** (ratio de points ~5×), **cessez-le-feu/mode vacances** (48 h min, production stoppée, inattaquable), statuts d'inactivité, système d'honneur (attaquer les "bandits" = butin augmenté ; attaquer trop faible = déshonneur).

### 4.6 Diplomatie
PNA (pactes de non-agression), pactes totaux (défense mutuelle), conventions anti-crash entre gros joueurs. Rien n'est appliqué par le jeu : purement social — et c'est voulu.

---

## 5. Le bunker (la lune) — pivot stratégique

Ce qui fait de la lune LE pivot d'OGame, à préserver absolument dans la transposition :

1. **Invisibilité radar** : tout mouvement partant/arrivant d'un bunker est illisible. Le radar ne scanne que les bases, jamais les bunkers.
2. **Station radar** : portée = (niveau² − 1) secteurs ; coût par scan (5 000 carburant) ; lit tous les vols vers/depuis une base (types + heures exactes) mais PAS les unités posées.
3. **Réseau ferroviaire (porte de saut)** : transfert **instantané** d'unités bunker↔bunker, sans ressources en soute, cooldown ~1 h partagé par les deux bunkers.
4. Le bunker s'obtient par la guerre (épaves des batailles) → boucle vertueuse : le conflit crée l'outil stratégique.
5. Sa destruction (§3.8) est la seule parade au FS parfait → équilibre attaque/défense au sommet.

---

## 6. Expéditions & exploration

- Slots d'expédition = `⌊√(niveau Astrophysique)⌋` (+2 avec la doctrine Exploration). Chez nous : **expéditions vers les terres sauvages** en bord de carte.
- **Points d'expédition** : chaque unité vaut structure/200 ; le gain est **plafonné selon le score du top 1 du serveur** (table de 2 400 à 25 000 points) → taille de flotte optimale = juste atteindre le plafond.
- Résultats (probabilités ~) : ressources 32,5 %, unités gratuites 22 %, rien 18,6 %, premium 9 %, retard 7 %, pirates 5,8 %, aliens 2,6 %, avance 2 %, marchand/objets 0,7 %, **perte totale ("trou noir") 0,33 %**.
- Multiplicateurs : ×2 avec un **éclaireur (Pathfinder)**, ×1,5 doctrine Exploration ; épuisement des zones (rotation nécessaire, ~10 expéditions/jour de régénération).
- Compo type "mineur" : bloc de camions jusqu'au plafond + 1 éclaireur + 1 drone.
- **Graviton / ferme à générateurs** : la techno endgame qui exige 300 000 d'énergie instantanée → construire ~5-8 000 générateurs d'un coup (cible en or pour les ennemis) → débloque l'unité de destruction de bunker.

## 6bis. Colonisation
- Avant-poste supplémentaire à chaque niveau impair d'Astrophysique. Positions de carte différenciées (chez nous : **biomes** — zone désertique = +carburant ? montagne = +acier ? à définir) ; tailles aléatoires → "reroll" de colonies ; stratégies de placement (près des cibles = traque, loin = sécurité).

---

## 7. Le Héros / Commandant (notre ajout signature)

**Création dès l'onboarding** : choix du visage, tenue, emblème, couleur de faction (style Advance Wars : un commandant expressif en buste dans l'UI + un sprite sur la carte de base). Personnalisation étendue achetable en monnaie virtuelle (tenues, animations, skins de QG).

**Le Commandant est la diégèse de l'UI** — il remplace les menus abstraits d'OGame :
- Amélioration d'une mine → le Commandant **se déplace en jeep vers la mine**, animation de chantier.
- Lancement d'une recherche → il entre au centre de recherche.
- Production d'unités → il passe en revue les véhicules devant l'usine.
- Attaque entrante → il court au poste de commandement, sirènes.
- File d'actions = file de déplacements du Héros → le joueur "voit" son plan s'exécuter. (Techniquement : pur cosmétique client, zéro impact serveur — le héros joue la file d'événements.)

**Rôle gameplay (transpose officiers + classes OGame)** :
- **Doctrines** (choix exclusif, changeable contre premium) : Industrielle (+25 % production…), Offensive (+vitesse, −carburant, +2 slots…), Exploration (+2 expéditions, +gains d'expédition… — le butin à 75 % sur inactifs étant universel chez nous, il ne fait pas partie de cette doctrine).
- **État-major** : 5 conseillers recrutables (premium/temps) = les 5 officiers OGame (files supplémentaires, +énergie, +production, −temps de recherche, +espionnage).
- Niveaux du Héros = petits bonus passifs ; JAMAIS de stats de combat pay-to-win directes (ligne rouge du positionnement).

---

## 8. Glossaire (jargon communauté FR à réutiliser/renommer)

FS (fleet save), ghost/ghoster (FS invisible), CDR (champ de ruines), lanx (phalange/radar), snipe, ninja, crash, RC (rapport de combat), renta (rentabilité), moonshot/étoilage, volante (colonie volante), décalage à la sonde, bash, push (interdit), multi (interdit), farm, turtle/bunker, AG/DG (attaques/défenses groupées), écran de phalange (vols leurres pour noyer le vrai retour), RIP/EDLM, uni (serveur), HoF (records de combats).

---

## 9. Décisions design pour NOTRE jeu (synthèse)

**À garder tel quel (cœur OGame)** : économie exponentielle lazy-eval, 50 % de pillage, fleet save et toutes ses variantes, radar/bunker et leurs règles de visibilité, épaves + récupération, ninja, snipe, ACS + règle des 30 %, règle de bash, expéditions plafonnées, protection débutant, reconstruction de défense à 70 %.

**À adapter pour mobile** :
- Timings à la seconde (snipe à 3-4 s) → viables sur mobile MAIS prévoir : confirmations rapides, serveur autoritaire au timestamp, éventuellement fenêtres d'atterrissage de ±quelques secondes affichées.
- Notifications push = le nouveau "être en ligne" (attaque entrante, retour de convoi, radar) — c'est un AVANTAGE du mobile sur l'OGame navigateur.
- Scans radar et rapports : UI mobile dédiée, pas de tableaux bruts.
- Sessions courtes : file d'actions du Héros + planificateur de FS intégré (l'outil que les joueurs OGame bricolent avec des scripts type OGLight — on l'offre nativement).

**À exclure du MVP (v2+)** : missiles balistiques, destruction de bunker, doctrines multiples, système d'honneur, marché entre joueurs.

**Exclu définitivement** : équivalent "formes de vie" (Lifeforms v9) — pas de couche espèces/population/nourriture dans le jeu, ni au lancement ni plus tard.

**Lignes rouges** : pas d'achat direct d'unités/ressources massives ; le premium = confort (état-major, accélérations plafonnées, cosmétiques du Héros).

---

## Sources principales

**Wikis** : [Fandom OGame](https://ogame.fandom.com) (Fleetcrash, Ninja, Bashing, IPM, Destroy, Espionage, Fleetsaving, Formulas, Expedition, Astrophysics), [owiki.de](https://owiki.de) (Sensorphalanx, Expedition, formules), [wiki.ogame.org](http://wiki.ogame.org) (guides ACS, Fleetsaving, Moon), [Sidian OGame Wiki](https://sidian.app/s/ogame-wiki) (missions, fleet-saving, classes).
**Officiel** : [Gameforge — moonshot](https://gameforge.com/en-GB/games/ogame-moon-shot.html), [règles FR](https://gameforge.com/fr-FR/games/ogame-regles.html), boards officiels FR/EN/Origin (guides ACS, IPM, Blind Phalanx "Tactic 15b", tutoriels défense).
**Outils** : [Tools For Ogame](https://toolsforogame.com) (destruction de lune, MIP), [LanxCalc](https://sourceforge.net/projects/lanxcalc/).
**Communauté FR** : chaînes YouTube [Psykose](https://www.youtube.com/@7020Psykose) (décalage à la sonde, OGLight, podcasts serveur), [BoobzLaden](https://www.youtube.com/@BoobzLaden) (tutos débutant 2025, série F2P, classe Explorateur), Sagesse Ogame (série Tuto FR #1-18, dont #18 la Volante), Cyber Radio ; [gamewinner.fr](https://www.gamewinner.fr) (défense, raideur, mode vacances), [aideogame.fr](http://aideogame.fr) (règles bash/push), [pkotte.gitbook.io](https://pkotte.gitbook.io/ogame/) (lunes, diplomatie), glossaires forums (Vocabulaire Ogame, FAQ colonie volante).
**Code source (formules exactes)** : [pr0game](https://codeberg.org/pr0game/pr0game), [2Moons](https://github.com/jkroepke/2Moons), [XNova](https://github.com/xmke/xnova), [alaingilbert/ogame](https://github.com/alaingilbert/ogame) (lib Go, calculs à jour), [OGameX](https://github.com/lanedirt/OGameX), [github.com/topics/ogame](https://github.com/topics/ogame).
