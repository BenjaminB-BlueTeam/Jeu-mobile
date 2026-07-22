# Document d'univers — "Iron Front" (titre de travail)

**Version 0.1 — 21/07/2026 — Ben**
*Compagnon de : `concept-jeu-ogame-like.md` (v0.2) et `compendium-mecaniques-ogame.md` (v1.2)*

---

## 1. Principes de nommage & localisation

- **Langue canonique de développement : anglais** (clés i18n, code, assets). Tous les noms ci-dessous sont donnés **EN / FR**.
- **Localisation cible : les langues servies par OGame** (~30 communautés) : DE, EN, FR, ES, PT, IT, PL, TR, NL, RU, CZ, SK, HU, RO, GR, BA/HR/SI, SE, DK, NO, FI, AR (MENA), MX/AR (LATAM), BR, TW, JP, KR, US… → au lancement on couvre **EN + FR**, puis DE/ES/PT/PL/TR en priorité (les plus grosses communautés OGame).
- Règle pratique : fichiers de traduction JSON par langue dès le premier commit (`/design/i18n/en.json`, `fr.json`), aucun texte en dur.

## 2. Titre (candidats — à trancher plus tard, vérifier disponibilité stores/marques)

- **Iron Front** (titre de travail)
- Steel Horizon / Warfront Rising / Ironfall / Front Line: Legacy
- Critères : court, lisible en icône, évocateur guerre moderne, dispo sur les stores et en nom de domaine.
- ⚠️ "Iron Front" et "Ironfall" existent déjà comme jeux (PC / 3DS) → le titre final sera probablement à inventer.

## 3. Pitch narratif (lore)

Le continent d'**Averon** sort d'une guerre mondiale qui a effondré les anciens États. Des centaines de **Commandants** indépendants — anciens officiers, ingénieurs, seigneurs de guerre charismatiques — se partagent les ruines et rebâtissent des bases fortifiées sur les décombres. Les ressources sont rares, les alliances fragiles, et les radars ne dorment jamais.

Le joueur est l'un de ces Commandants : il fonde sa base, reconstruit une armée, et se taille un territoire dans un monde où **tout le monde peut piller tout le monde** — mais où la diplomatie vaut parfois plus qu'une colonne de chars.

**Ton** : sérieux avec légèreté, à la Advance Wars — la guerre est crédible (logistique, carburant, épaves), mais les Commandants sont hauts en couleur, expressifs, avec des répliques qui claquent. Pas de gore, pas de réalisme sombre : des véhicules qui explosent en "pop" satisfaisant, des soldats cartoon jamais montrés mourant.

## 4. Factions (cosmétiques uniquement)

Identité visuelle + lore, **zéro impact gameplay** (les bonus passent par les Doctrines). Choisies à la création du Héros, changeables en monnaie virtuelle.

| Faction | Palette | Identité | Style véhicules |
|---|---|---|---|
| **Ashen Legion / Légion des Cendres** | Rouge/noir | Héritiers de l'ancienne armée impériale, discipline et acier | Anguleux, rivetés, lourds |
| **Azure Pact / Pacte d'Azur** | Bleu/blanc | Coalition de cités côtières, technologie et précision | Épurés, modernes, drones |
| **Verdant Union / Union Verdoyante** | Vert/brun | Républiques agraires militarisées, robustesse et nombre | Camouflage, pratiques, soudés |
| **Golden Syndicate / Syndicat Doré** | Or/gris | Marchands-mercenaires, la guerre est un business | Chromés, ostentatoires |

## 5. Ressources

| Rôle OGame | EN | FR | Flavor |
|---|---|---|---|
| Métal | **Steel** | **Acier** | Récupéré des ruines et des mines à ciel ouvert |
| Cristal | **Components** | **Composants** | Électronique, optiques, alliages rares |
| Deutérium | **Fuel** | **Carburant** | Raffiné ; carburant des armées ET monnaie de référence (ratio 3:2:1) |
| Énergie | **Power** | **Énergie** | Réseau électrique de la base |
| Matière noire | **Gold Ingots** | **Lingots** | Monnaie premium |

## 6. Bâtiments de la base

| OGame | EN | FR |
|---|---|---|
| Mine de métal | Steel Mine | Mine d'acier |
| Mine de cristal | Component Workshop | Atelier de composants |
| Synthétiseur de deutérium | Fuel Refinery | Raffinerie de carburant |
| Centrale solaire | Power Plant | Centrale électrique |
| Réacteur à fusion | Advanced Reactor | Réacteur avancé |
| Satellite solaire | Auxiliary Generator | Générateur d'appoint |
| Hangars (×3) | Storage Depots | Dépôts de stockage |
| Usine de robots | Engineering Corps | Corps du génie |
| Usine de nanites | Automated Yard | Chantier automatisé |
| Chantier spatial | Vehicle Factory | Usine de véhicules |
| Laboratoire | Research Center | Centre de recherche |
| Silo de missiles | Missile Silo | Silo de missiles |
| Terraformeur | Land Clearing | Terrassement |
| Dépôt d'alliance | Allied Logistics Post | Poste logistique allié |
| — (QG, hub visuel du Héros) | Headquarters (HQ) | Quartier général (QG) |

**Bunker (la "lune")** : Underground Complex / **Complexe souterrain** — avec Base souterraine (Lunar Base), **Station radar** (Sensor Phalanx → Long-Range Radar) et **Gare souterraine** (Jump Gate → Underground Railway).

## 7. Unités (les "vaisseaux")

| OGame | EN | FR | Rôle |
|---|---|---|---|
| Petit transporteur | Supply Truck | Camion de ravitaillement | Fret léger, rapide |
| Grand transporteur | Heavy Convoy | Convoi lourd | Fret massif |
| Chasseur léger | Recon Buggy | Buggy de reconnaissance | Chair à canon, pas cher |
| Chasseur lourd | Light Tank | Char léger | Anti-buggy |
| Croiseur | Battle Tank | Char de combat | Rapid fire sur les légers |
| Vaisseau de bataille | Heavy Tank | Char lourd | Colonne vertébrale |
| Traqueur | Rocket Artillery | Artillerie à roquettes | Anti-char coût-efficace |
| Bombardier | Siege Howitzer | Obusier de siège | Casse les défenses |
| Destructeur | Gunship | Hélicoptère de combat | Endgame, polyvalent |
| Étoile de la mort (RIP) | Land Fortress "Behemoth" | Forteresse terrestre « Béhémoth » | Unité colossale, détruit les Complexes souterrains |
| Recycleur | Salvage Rig | Dépanneuse | Récupère les épaves |
| Sonde d'espionnage | Scout Drone | Drone de reconnaissance | Espionnage, fret 10 |
| Vaisseau de colonisation | Pioneer Convoy | Convoi pionnier | Fonde un avant-poste |
| Éclaireur (Pathfinder) | Ranger Squad | Escouade de rangers | Expéditions ×2, récolte en zone sauvage |

## 8. Défenses

| OGame | EN | FR |
|---|---|---|
| Lanceur de missiles | MG Nest | Nid de mitrailleuses |
| Artillerie laser légère | AA Gun | Canon anti-aérien (⚠️ garde-fou anti-drones, accessible tôt) |
| Artillerie laser lourde | Heavy AA Battery | Batterie AA lourde |
| Canon de Gauss | Railgun Emplacement | Casemate à canon électrique |
| Artillerie à ions | EMP Tower | Tour EMP |
| Lanceur de plasma | Heavy Cannon "Bastion" | Canon lourd « Bastion » |
| Petite coupole | Shield Generator | Générateur de bouclier |
| Grande coupole | Fortress Shield | Bouclier de forteresse |
| Missile d'interception | Interceptor Missile | Missile intercepteur |
| MIP | Ballistic Missile | Missile balistique |

## 9. Technologies (arbre de recherche)

Espionnage → **Signals Intelligence / Renseignement** ; Ordinateur → **Command Network / Réseau de commandement** (+slots de convois) ; Armes → **Ballistics / Balistique** ; Bouclier → **Defensive Systems / Systèmes défensifs** ; Blindage → **Armor Plating / Blindage** ; Énergie → **Energy Tech / Technologie énergétique** ; Combustion → **Diesel Engines / Moteurs diesel** ; Impulsion → **Turbine Engines / Turbines** ; Hyperespace (moteur) → **Maglev Transport / Sustentation magnétique** ; Hyperespace (techno) → **Advanced Logistics / Logistique avancée** ; Laser → **Targeting Optics / Optiques de visée** ; Ions → **EMP Tech / Technologie EMP** ; Plasma → **Heavy Ordnance / Artillerie lourde** (bonus production) ; Astrophysique → **Cartography / Cartographie** (avant-postes + expéditions) ; Graviton → **Megastructures / Mégastructures** (débloque le Béhémoth) ; Réseau de recherche → **Research Coalition / Coalition scientifique**.

## 10. La carte-monde

- Galaxie → **Region / Région** ; Système solaire → **Sector / Secteur** (15 emplacements de base + 1 **zone sauvage** en position 16 pour les expéditions) ; Position de planète → **Zone**.
- Biomes par position (transpose température/taille OGame) : zones 1-3 **désert** (+énergie solaire), 6-10 **plaines/collines** (+acier, grandes bases), 13-15 **toundra** (+carburant, bases petites).
- Champ de débris → **Wreckage Field / Champ d'épaves**. Expédition → **Expedition / Expédition en zone sauvage**.

## 11. Le Héros / Commandant

- Création : visage (banque de portraits style AW), tenue, emblème, couleur (nuancier de la faction), nom.
- Progression cosmétique : tenues, animations d'idle, poses de victoire (RC gagné), skins de QG, portraits animés.
- Vie dans la base : trajets en jeep entre bâtiments selon la file d'actions, animations contextuelles (chantier, revue des troupes, alerte). Voir compendium §7.
- **Doctrines** (ex-classes) : **Industrial / Industrielle**, **Assault / Offensive**, **Expedition / Exploration**.
- **État-major** (ex-officiers) : Chief of Staff (Commandant), Logistics Officer (Amiral), Chief Engineer (Ingénieur), Chief Geologist (Géologue), Head Scientist (Technocrate).

## 12. Écriture & voix (guidelines)

- Répliques courtes et percutantes des Commandants PNJ (tutoriel, événements) ; humour par le caractère, jamais par la parodie.
- Rapports de combat rédigés comme des dépêches militaires (« 04:12 — Le convoi de ravitaillement est tombé dans une embuscade au secteur 4:117 »).
- Interdits : gore, références réelles (pays, conflits, armées existants), armes chimiques/nucléaires nommées comme telles (le missile balistique reste générique).

## 13. À trancher plus tard

- Titre définitif (vérif marques + stores + domaine).
- Noms/portraits des 4 Commandants PNJ emblématiques (un par faction, mentors du tutoriel).
- Direction audio (thèmes par faction ?).
