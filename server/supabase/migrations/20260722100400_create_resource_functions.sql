-- Lazy-evaluation core: resources and queues are never touched by a background
-- job. Everything is computed/resolved at read time or right before a write.

create or replace function fn_project_resources(p_base_id uuid, p_as_of timestamptz default now())
returns table (
  steel numeric, components numeric, fuel numeric,
  power_available numeric, power_required numeric, power_ratio numeric
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_base bases%rowtype;
  v_cfg jsonb;
  v_research_cfg jsonb;
  v_growth numeric;
  v_energy_growth numeric;
  v_elapsed_hours numeric;

  v_steel_mine_level int;
  v_workshop_level int;
  v_refinery_level int;
  v_power_plant_level int;
  v_steel_depot_level int;
  v_components_depot_level int;
  v_fuel_depot_level int;

  v_steel_coef numeric; v_components_coef numeric; v_fuel_coef numeric; v_power_coef numeric;
  v_steel_energy_coef numeric; v_components_energy_coef numeric; v_refinery_energy_coef numeric;

  v_steel_cap_base numeric; v_steel_cap_growth numeric;
  v_components_cap_base numeric; v_components_cap_growth numeric;
  v_fuel_cap_base numeric; v_fuel_cap_growth numeric;

  v_research_level int;
  v_research_bonus_per_level numeric;
  v_research_multiplier numeric;

  v_steel_prod_h numeric; v_components_prod_h numeric; v_fuel_prod_h numeric;
  v_power_avail numeric; v_power_req numeric; v_power_ratio numeric;
  v_steel_cap numeric; v_components_cap numeric; v_fuel_cap numeric;
begin
  select * into v_base from bases where id = p_base_id;
  if not found then
    raise exception 'base_not_found';
  end if;

  select data into v_cfg from game_config where category = 'buildings' and key = 'all';
  select data into v_research_cfg from game_config where category = 'research' and key = 'all';

  v_growth := (v_cfg->'global'->>'production_growth')::numeric;
  v_energy_growth := (v_cfg->'global'->>'energy_growth')::numeric;

  select coalesce(level, 0) into v_steel_mine_level from buildings where base_id = p_base_id and building_type = 'steel_mine';
  select coalesce(level, 0) into v_workshop_level from buildings where base_id = p_base_id and building_type = 'component_workshop';
  select coalesce(level, 0) into v_refinery_level from buildings where base_id = p_base_id and building_type = 'fuel_refinery';
  select coalesce(level, 0) into v_power_plant_level from buildings where base_id = p_base_id and building_type = 'power_plant';
  select coalesce(level, 0) into v_steel_depot_level from buildings where base_id = p_base_id and building_type = 'storage_depot_steel';
  select coalesce(level, 0) into v_components_depot_level from buildings where base_id = p_base_id and building_type = 'storage_depot_components';
  select coalesce(level, 0) into v_fuel_depot_level from buildings where base_id = p_base_id and building_type = 'storage_depot_fuel';

  v_steel_coef := (v_cfg->'buildings'->'steel_mine'->'produces'->>'coef')::numeric;
  v_components_coef := (v_cfg->'buildings'->'component_workshop'->'produces'->>'coef')::numeric;
  v_fuel_coef := (v_cfg->'buildings'->'fuel_refinery'->'produces'->>'coef')::numeric;
  v_power_coef := (v_cfg->'buildings'->'power_plant'->'produces'->>'coef')::numeric;

  v_steel_energy_coef := (v_cfg->'buildings'->'steel_mine'->'energy_consumption'->>'coef')::numeric;
  v_components_energy_coef := (v_cfg->'buildings'->'component_workshop'->'energy_consumption'->>'coef')::numeric;
  v_refinery_energy_coef := (v_cfg->'buildings'->'fuel_refinery'->'energy_consumption'->>'coef')::numeric;

  v_steel_cap_base := (v_cfg->'buildings'->'storage_depot_steel'->'storage_capacity'->>'base_capacity')::numeric;
  v_steel_cap_growth := (v_cfg->'buildings'->'storage_depot_steel'->'storage_capacity'->>'growth')::numeric;
  v_components_cap_base := (v_cfg->'buildings'->'storage_depot_components'->'storage_capacity'->>'base_capacity')::numeric;
  v_components_cap_growth := (v_cfg->'buildings'->'storage_depot_components'->'storage_capacity'->>'growth')::numeric;
  v_fuel_cap_base := (v_cfg->'buildings'->'storage_depot_fuel'->'storage_capacity'->>'base_capacity')::numeric;
  v_fuel_cap_growth := (v_cfg->'buildings'->'storage_depot_fuel'->'storage_capacity'->>'growth')::numeric;

  select coalesce(level, 0) into v_research_level
    from research where player_id = v_base.player_id and research_code = 'extraction_efficiency';
  v_research_bonus_per_level := (v_research_cfg->'research'->'extraction_efficiency'->'effect'->>'bonus_per_level')::numeric;
  v_research_multiplier := 1 + coalesce(v_research_level, 0) * v_research_bonus_per_level;

  v_steel_prod_h := case when v_steel_mine_level > 0
    then v_steel_coef * v_steel_mine_level * power(v_growth, v_steel_mine_level) * v_research_multiplier else 0 end;
  v_components_prod_h := case when v_workshop_level > 0
    then v_components_coef * v_workshop_level * power(v_growth, v_workshop_level) else 0 end;
  v_fuel_prod_h := case when v_refinery_level > 0
    then v_fuel_coef * v_refinery_level * power(v_growth, v_refinery_level) else 0 end;

  v_power_avail := case when v_power_plant_level > 0
    then v_power_coef * v_power_plant_level * power(v_growth, v_power_plant_level) else 0 end;
  v_power_req := (case when v_steel_mine_level > 0 then v_steel_energy_coef * v_steel_mine_level * power(v_energy_growth, v_steel_mine_level) else 0 end)
    + (case when v_workshop_level > 0 then v_components_energy_coef * v_workshop_level * power(v_energy_growth, v_workshop_level) else 0 end)
    + (case when v_refinery_level > 0 then v_refinery_energy_coef * v_refinery_level * power(v_energy_growth, v_refinery_level) else 0 end);
  v_power_ratio := case when v_power_req = 0 then 1 else least(1, v_power_avail / v_power_req) end;

  v_elapsed_hours := greatest(0, extract(epoch from (p_as_of - v_base.last_collected_at)) / 3600.0);

  v_steel_cap := v_steel_cap_base * power(v_steel_cap_growth, v_steel_depot_level);
  v_components_cap := v_components_cap_base * power(v_components_cap_growth, v_components_depot_level);
  v_fuel_cap := v_fuel_cap_base * power(v_fuel_cap_growth, v_fuel_depot_level);

  steel := least(v_base.resources_steel + v_steel_prod_h * v_elapsed_hours * v_power_ratio, v_steel_cap);
  components := least(v_base.resources_components + v_components_prod_h * v_elapsed_hours * v_power_ratio, v_components_cap);
  fuel := least(v_base.resources_fuel + v_fuel_prod_h * v_elapsed_hours * v_power_ratio, v_fuel_cap);
  power_available := v_power_avail;
  power_required := v_power_req;
  power_ratio := v_power_ratio;

  return next;
end;
$$;

-- Materializes the building queue if its completed_at has passed. Resources
-- are projected up to completed_at using the OLD level (queue not yet
-- applied), THEN the level is bumped -- never project past completion with
-- the new level already active, or production gets attributed retroactively
-- to a building upgrade that hadn't happened yet.
create or replace function fn_resolve_building_queue(p_base_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_queue building_queue%rowtype;
  v_proj record;
begin
  perform 1 from bases where id = p_base_id for update;

  select * into v_queue from building_queue where base_id = p_base_id;
  if not found or v_queue.completed_at > now() then
    return;
  end if;

  select * into v_proj from fn_project_resources(p_base_id, v_queue.completed_at);

  update bases
    set resources_steel = v_proj.steel,
        resources_components = v_proj.components,
        resources_fuel = v_proj.fuel,
        last_collected_at = v_queue.completed_at
    where id = p_base_id;

  insert into buildings (base_id, player_id, building_type, level)
    values (p_base_id, v_queue.player_id, v_queue.building_type, v_queue.target_level)
    on conflict (base_id, building_type) do update set level = excluded.level;

  delete from building_queue where base_id = p_base_id;
end;
$$;

create or replace function fn_resolve_research_queue(p_player_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_queue research_queue%rowtype;
begin
  select * into v_queue from research_queue where player_id = p_player_id;
  if not found or v_queue.completed_at > now() then
    return;
  end if;

  insert into research (player_id, research_code, level)
    values (p_player_id, v_queue.research_code, v_queue.target_level)
    on conflict (player_id, research_code) do update set level = excluded.level;

  delete from research_queue where player_id = p_player_id;
end;
$$;

-- Full read model consumed by the client. Resolves any due queues first so
-- the returned state always reflects reality as of "now".
create or replace function fn_get_base_state(p_base_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_player_id uuid;
  v_proj record;
  v_result jsonb;
begin
  select player_id into v_player_id from bases where id = p_base_id;
  if not found then
    raise exception 'base_not_found';
  end if;

  perform fn_resolve_building_queue(p_base_id);
  perform fn_resolve_research_queue(v_player_id);

  select * into v_proj from fn_project_resources(p_base_id, now());

  select jsonb_build_object(
    'resources', jsonb_build_object(
      'steel', v_proj.steel,
      'components', v_proj.components,
      'fuel', v_proj.fuel
    ),
    'power', jsonb_build_object(
      'available', v_proj.power_available,
      'required', v_proj.power_required,
      'ratio', v_proj.power_ratio
    ),
    'buildings', coalesce((
      select jsonb_agg(jsonb_build_object('building_type', building_type, 'level', level))
      from buildings where base_id = p_base_id
    ), '[]'::jsonb),
    'building_queue', (
      select jsonb_build_object('building_type', building_type, 'target_level', target_level,
        'started_at', started_at, 'completed_at', completed_at)
      from building_queue where base_id = p_base_id
    ),
    'research', coalesce((
      select jsonb_agg(jsonb_build_object('research_code', research_code, 'level', level))
      from research where player_id = v_player_id
    ), '[]'::jsonb),
    'research_queue', (
      select jsonb_build_object('research_code', research_code, 'target_level', target_level,
        'started_at', started_at, 'completed_at', completed_at)
      from research_queue where player_id = v_player_id
    )
  ) into v_result;

  return v_result;
end;
$$;

create or replace function fn_check_requirements(p_base_id uuid, p_building_type text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cfg jsonb;
  v_requires jsonb;
  v_req_type text;
  v_req_level int;
  v_current_level int;
begin
  select data into v_cfg from game_config where category = 'buildings' and key = 'all';
  v_requires := v_cfg->'buildings'->p_building_type->'requires';

  if v_requires is null or v_requires = '{}'::jsonb then
    return true;
  end if;

  for v_req_type, v_req_level in select key, value::int from jsonb_each_text(v_requires)
  loop
    select coalesce(level, 0) into v_current_level
      from buildings where base_id = p_base_id and building_type = v_req_type;
    if coalesce(v_current_level, 0) < v_req_level then
      return false;
    end if;
  end loop;

  return true;
end;
$$;
