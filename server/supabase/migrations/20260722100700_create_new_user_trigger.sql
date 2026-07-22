-- Onboarding: any new auth.users row (including anonymous sign-ins) gets a
-- player, a home base with starter resources, and an HQ at level 1.
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_base_id uuid;
begin
  insert into players (id) values (new.id);

  insert into bases (player_id) values (new.id) returning id into v_base_id;

  insert into buildings (base_id, player_id, building_type, level)
    values (v_base_id, new.id, 'headquarters', 1);

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();
