# Iron Front (titre de travail)

Jeu mobile de stratégie persistante : mécaniques OGame transposées dans un univers de guerre moderne "fantasy militaire" (style visuel inspiré d'Advance Wars), avec base visuelle, carte-monde partagée, alliances et Héros/Commandant customisable.

## Structure du monorepo

- `design/docs/` — documents de game design (concept, compendium des mécaniques, univers)
- `design/i18n/` — fichiers de traduction (EN canonique, FR au lancement)
- `design/config/` — formules d'équilibrage en JSON (partagées client/serveur)
- `design/equilibrage-iron-front.xlsx` — tableur d'équilibrage (à déposer ici)
- `server/` — (à venir) projet Supabase : migrations SQL + edge functions TypeScript
- `client/` — (à venir) projet Godot 4 (GDScript)

## Stack (validée par recherche approfondie, juillet 2026)

- **Client** : Godot 4 (2D, export iOS/Android) — fichiers texte adaptés au dev avec Claude Code
- **Backend** : Supabase (Postgres, Edge Functions, Realtime) — serveur autoritaire, lazy evaluation
- Montée en charge : lazy-eval (calcul à la lecture, pas de tick global) → scale nativement ; brique temps réel dédiée ajoutée seulement si le chat live devient un goulot

## Documents de référence

1. [Concept](design/docs/concept-jeu-ogame-like.md) — vision, core loop, roadmap
2. [Compendium des mécaniques](design/docs/compendium-mecaniques-ogame.md) — mécaniques OGame + décisions design
3. [Univers](design/docs/univers-du-jeu.md) — lore, noms EN/FR, factions
