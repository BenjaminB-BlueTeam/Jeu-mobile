-- Row Level Security: owner-only reads. All writes go through SECURITY DEFINER
-- functions granted to service_role only (see grants_and_revokes migration) --
-- authenticated/anon never get INSERT/UPDATE/DELETE policies on these tables.

alter table players enable row level security;
alter table bases enable row level security;
alter table buildings enable row level security;
alter table building_queue enable row level security;
alter table research enable row level security;
alter table research_queue enable row level security;
alter table game_config enable row level security;

create policy "own_players" on players
  for select using ((select auth.uid()) = id);

create policy "own_bases" on bases
  for select using ((select auth.uid()) = player_id);

create policy "own_buildings" on buildings
  for select using ((select auth.uid()) = player_id);

create policy "own_building_queue" on building_queue
  for select using ((select auth.uid()) = player_id);

create policy "own_research" on research
  for select using ((select auth.uid()) = player_id);

create policy "own_research_queue" on research_queue
  for select using ((select auth.uid()) = player_id);

create policy "public_read_game_config" on game_config
  for select using (true);
