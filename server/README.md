# Iron Front — server

Supabase project (Postgres + Edge Functions). Serveur autoritaire : voir `/CLAUDE.md` pour les règles d'architecture.

## Prérequis

- [Supabase CLI](https://supabase.com/docs/guides/cli) installée (`npm i -g supabase` ou via Scoop/Homebrew).
- Docker Desktop en cours d'exécution (requis par `supabase start`).

## Développement local

```bash
cd server
supabase start                    # démarre Postgres/Auth/Studio/Edge Runtime en local (Docker)
supabase db reset                 # (ré)applique toutes les migrations depuis zéro
supabase functions serve get-base-state --env-file .env.local
supabase functions serve start-building --env-file .env.local
supabase functions serve start-research --env-file .env.local
```

Studio local : http://localhost:54323 (voir `supabase/config.toml` pour les ports).

## Nouvelle migration

```bash
supabase migration new <nom_descriptif>
```

Puis éditer le fichier généré sous `supabase/migrations/`.

## Synchronisation `design/config/*.json` → `game_config`

`design/config/buildings.json` et `research.json` restent la **source de vérité éditable**.
La table `game_config` en est un miroir, synchronisé **manuellement** (Phase 1) :

1. Éditer le JSON dans `/design/config/`.
2. Copier le contenu mis à jour dans une nouvelle migration `insert ... on conflict (category, key) do update set data = excluded.data, version = excluded.version` (incrémenter `version`).
3. `supabase migration new sync_game_config_vN` puis `supabase db reset` en local pour vérifier.

Pas d'automatisation en Phase 1 (config stable, peu de changements attendus) — à revoir si la balance devient volatile (voir plan Phase 1, section "reste à faire").

## Déploiement

```bash
supabase link --project-ref <ref-du-projet>
supabase db push                  # applique les migrations sur le projet distant
supabase functions deploy get-base-state
supabase functions deploy start-building
supabase functions deploy start-research
```

## Notes

- Aucune logique de gameplay dans les Edge Functions : elles vérifient le JWT (`auth.getUser()`), résolvent la base du joueur, puis délèguent tout le calcul aux fonctions SQL (`fn_get_base_state`, `fn_start_building`, `fn_start_research`).
- Les fonctions SQL de calcul sont `SECURITY DEFINER` et leur `EXECUTE` est révoqué pour `authenticated`/`anon` — seul `service_role` (utilisé par les Edge Functions) peut les appeler. Le client ne doit jamais recevoir la clé `service_role`.
- Auth Phase 1 : anonyme (`enable_anonymous_sign_ins = true`). Un trigger (`on_auth_user_created`) crée automatiquement `players` + `bases` (HQ niveau 1) à la création du compte.
