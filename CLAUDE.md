# Iron Front — Conventions projet

## Contexte

Jeu mobile de stratégie persistante type OGame (univers guerre moderne fantasy, style Advance Wars). Développeur solo (Ben). Lire `design/docs/` avant toute implémentation gameplay :
- `concept-jeu-ogame-like.md` — vision, scope, roadmap
- `compendium-mecaniques-ogame.md` — LA référence des mécaniques et décisions design actées
- `univers-du-jeu.md` — nommage EN/FR de toutes les entités

## Stack

- Client : Godot 4 (GDScript), scènes `.tscn` texte, export iOS/Android.
- Backend : Supabase (Postgres + Edge Functions + Realtime), serveur autoritaire.

## Règles d'architecture (non négociables)

1. **Serveur autoritaire** : aucune logique de gameplay côté client. Le client Godot affiche, le serveur calcule. Le client n'envoie que des commandes, jamais des changements d'état.
2. **Lazy evaluation** : production de ressources calculée à la lecture (`last_collected_at`), files résolues à la demande (`completed_at`), pas de tick global. C'est ce qui fait scaler le jeu à 50k joueurs.
3. **Calcul lourd en SQL/Postgres**, pas en Edge Functions (cold starts). Les Edge Functions orchestrent seulement.
4. **Formules d'équilibrage dans `/design/config/*.json`** : coûts, durées, production par niveau — partagés client/serveur, modifiables sans redéploiement. Source de vérité : `design/equilibrage-iron-front.xlsx`.
5. **i18n dès le départ** : aucun texte en dur ; clés anglaises canoniques, `design/i18n/en.json` + `fr.json`.

## Décisions design actées (ne pas remettre en cause sans demander)

- Pas de formes de vie (Lifeforms) ni équivalent, définitivement.
- Drones : fret de 10 ressources ; toute unité anti-air posée les détruit en attaque (garde-fou early game).
- Pillage : 50 % sur actifs, 75 % sur inactifs (universel).
- Monétisation : confort et cosmétique uniquement, jamais d'achat direct d'unités/ressources massives.
- Le Héros/Commandant est purement cosmétique côté client (il "joue" la file d'événements serveur).
- Factions : cosmétiques uniquement (bonus gameplay via les Doctrines).

## Conventions

- Langue du code et des commits : anglais. Docs de design : français.
- Migrations SQL versionnées ; edge functions TypeScript.
