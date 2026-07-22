-- Takes ONLY p_player_id (derived by the Edge Function from the verified JWT).
-- The base is resolved internally so a caller can never reference another
-- player's base_id (IDOR/confused deputy) -- see fn_get_base_state comment.
create or replace function fn_start_building(p_player_id uuid, p_building_type text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_base_id uuid;
  v_cfg jsonb;
  v_building_cfg jsonb;
  v_speed_factor numeric;
  v_build_time_divisor numeric;
  v_current_level int;
  v_cost_steel numeric; v_cost_components numeric; v_cost_fuel numeric;
  v_proj record;
  v_build_hours numeric;
  v_completed_at timestamptz;
begin
  select id into v_base_id from bases where player_id = p_player_id for update;
  if not found then
    raise exception 'base_not_found';
  end if;

  perform fn_resolve_building_queue(v_base_id);

  if exists (select 1 from building_queue where base_id = v_base_id) then
    raise exception 'queue_full';
  end if;

  select data into v_cfg from game_config where category = 'buildings' and key = 'all';
  v_building_cfg := v_cfg->'buildings'->p_building_type;
  if v_building_cfg is null then
    raise exception 'unknown_building_type';
  end if;

  if not fn_check_requirements(v_base_id, p_building_type) then
    raise exception 'requirements_not_met';
  end if;

  select coalesce(level, 0) into v_current_level
    from buildings where base_id = v_base_id and building_type = p_building_type;
  v_current_level := coalesce(v_current_level, 0);

  v_cost_steel := (v_building_cfg->'base_cost'->>'steel')::numeric * power((v_building_cfg->>'cost_factor')::numeric, v_current_level);
  v_cost_components := (v_building_cfg->'base_cost'->>'components')::numeric * power((v_building_cfg->>'cost_factor')::numeric, v_current_level);
  v_cost_fuel := (v_building_cfg->'base_cost'->>'fuel')::numeric * power((v_building_cfg->>'cost_factor')::numeric, v_current_level);

  select * into v_proj from fn_project_resources(v_base_id, now());
  if v_proj.steel < v_cost_steel or v_proj.components < v_cost_components or v_proj.fuel < v_cost_fuel then
    raise exception 'insufficient_resources';
  end if;

  v_speed_factor := (v_cfg->'global'->>'speed_factor')::numeric;
  v_build_time_divisor := (v_cfg->'global'->>'build_time_divisor')::numeric;
  v_build_hours := (v_cost_steel + v_cost_components) / (v_build_time_divisor * v_speed_factor);
  v_completed_at := now() + (v_build_hours * interval '1 hour');

  update bases
    set resources_steel = v_proj.steel - v_cost_steel,
        resources_components = v_proj.components - v_cost_components,
        resources_fuel = v_proj.fuel - v_cost_fuel,
        last_collected_at = now()
    where id = v_base_id;

  insert into building_queue (base_id, player_id, building_type, target_level, started_at, completed_at)
    values (v_base_id, p_player_id, p_building_type, v_current_level + 1, now(), v_completed_at);

  return fn_get_base_state(p_player_id);
end;
$$;
