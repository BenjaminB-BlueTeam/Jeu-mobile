-- Mirror of design/config/*.json, the versioned source of truth for balancing.
-- Re-run a new migration with updated seed data whenever the JSON files change
-- (see server/README.md for the manual sync process).

create table game_config (
  category text not null,
  key text not null,
  data jsonb not null,
  version int not null default 1,
  updated_at timestamptz not null default now(),
  primary key (category, key)
);
