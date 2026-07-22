-- The client never calls these RPCs directly: only the service_role used by
-- Edge Functions may execute them. authenticated/anon only get the SELECT
-- policies granted in enable_rls_policies.sql.

revoke execute on function fn_get_base_state(uuid) from authenticated, anon;
revoke execute on function fn_start_building(uuid, text) from authenticated, anon;
revoke execute on function fn_start_research(uuid, text) from authenticated, anon;
revoke execute on function fn_resolve_building_queue(uuid) from authenticated, anon;
revoke execute on function fn_resolve_research_queue(uuid) from authenticated, anon;
revoke execute on function fn_project_resources(uuid, timestamptz) from authenticated, anon;
revoke execute on function fn_check_requirements(uuid, text) from authenticated, anon;

grant execute on function fn_get_base_state(uuid) to service_role;
grant execute on function fn_start_building(uuid, text) to service_role;
grant execute on function fn_start_research(uuid, text) to service_role;
