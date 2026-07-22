create or replace function fn_start_research(p_player_id uuid, p_base_id uuid, p_research_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cfg jsonb;
  v_research_cfg jsonb;
  v_current_level int;
  v_cost_steel numeric; v_cost_components numeric; v_cost_fuel numeric;
  v_proj record;
begin
  perform fn_resolve_research_queue(p_player_id);

  if exists (select 1 from research_queue where player_id = p_player_id) then
    raise exception 'queue_full';
  end if;

  select data into v_research_cfg from game_config where category = 'research' and key = 'all';
  v_cfg := v_research_cfg->'research'->p_research_code;
  if v_cfg is null then
    raise exception 'unknown_research_code';
  end if;

  if not fn_check_requirements(p_base_id, 'headquarters') then
    raise exception 'requirements_not_met';
  end if;

  select coalesce(level, 0) into v_current_level
    from research where player_id = p_player_id and research_code = p_research_code;
  v_current_level := coalesce(v_current_level, 0);

  v_cost_steel := (v_cfg->'base_cost'->>'steel')::numeric * power((v_cfg->>'cost_factor')::numeric, v_current_level);
  v_cost_components := (v_cfg->'base_cost'->>'components')::numeric * power((v_cfg->>'cost_factor')::numeric, v_current_level);
  v_cost_fuel := (v_cfg->'base_cost'->>'fuel')::numeric * power((v_cfg->>'cost_factor')::numeric, v_current_level);

  select * into v_proj from fn_project_resources(p_base_id, now());
  if v_proj.steel < v_cost_steel or v_proj.components < v_cost_components or v_proj.fuel < v_cost_fuel then
    raise exception 'insufficient_resources';
  end if;

  update bases
    set resources_steel = v_proj.steel - v_cost_steel,
        resources_components = v_proj.components - v_cost_components,
        resources_fuel = v_proj.fuel - v_cost_fuel,
        last_collected_at = now()
    where id = p_base_id;

  -- Research build time reuses the same time formula as buildings (steel+components
  -- cost / divisor), consistent with fn_start_building.
  insert into research_queue (player_id, base_id, research_code, target_level, started_at, completed_at)
  values (
    p_player_id, p_base_id, p_research_code, v_current_level + 1, now(),
    now() + (
      (v_cost_steel + v_cost_components)
      / ((select (data->'global'->>'build_time_divisor')::numeric from game_config where category = 'buildings' and key = 'all')
         * (select (data->'global'->>'speed_factor')::numeric from game_config where category = 'buildings' and key = 'all'))
    ) * interval '1 hour'
  );

  return fn_get_base_state(p_base_id);
end;
$$;
