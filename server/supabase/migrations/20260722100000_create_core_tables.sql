-- Core gameplay tables for Phase 1 (economy prototype).
-- One base per player in Phase 1 (unique constraint on bases.player_id);
-- lifted in Phase 2 when colonization introduces multi-base play.

create table players (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null default 'Commander',
  created_at timestamptz not null default now()
);

create table bases (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references players(id) on delete cascade,
  name text not null default 'Home Base',
  resources_steel numeric(14,2) not null default 500,
  resources_components numeric(14,2) not null default 0,
  resources_fuel numeric(14,2) not null default 0,
  last_collected_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (player_id)
);

create table buildings (
  id uuid primary key default gen_random_uuid(),
  base_id uuid not null references bases(id) on delete cascade,
  player_id uuid not null references players(id) on delete cascade,
  building_type text not null,
  level int not null default 0,
  unique (base_id, building_type)
);

create table building_queue (
  id uuid primary key default gen_random_uuid(),
  base_id uuid not null references bases(id) on delete cascade,
  player_id uuid not null references players(id) on delete cascade,
  building_type text not null,
  target_level int not null,
  started_at timestamptz not null default now(),
  completed_at timestamptz not null,
  unique (base_id)
);

create table research (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references players(id) on delete cascade,
  research_code text not null,
  level int not null default 0,
  unique (player_id, research_code)
);

create table research_queue (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references players(id) on delete cascade,
  base_id uuid not null references bases(id) on delete cascade,
  research_code text not null,
  target_level int not null,
  started_at timestamptz not null default now(),
  completed_at timestamptz not null,
  unique (player_id)
);

create index idx_bases_player_id on bases(player_id);
create index idx_buildings_base_id on buildings(base_id);
create index idx_building_queue_base_id on building_queue(base_id);
create index idx_research_player_id on research(player_id);
