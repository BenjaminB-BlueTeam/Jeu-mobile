import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "missing_authorization" }), { status: 401 });
  }

  let building_type: string | undefined;
  try {
    ({ building_type } = await req.json());
  } catch {
    return new Response(JSON.stringify({ error: "invalid_body" }), { status: 400 });
  }
  if (!building_type) {
    return new Response(JSON.stringify({ error: "missing_building_type" }), { status: 400 });
  }

  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error: userError } = await userClient.auth.getUser();
  if (userError || !user) {
    return new Response(JSON.stringify({ error: "invalid_session" }), { status: 401 });
  }

  const serviceClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  // p_player_id comes from the verified JWT (user.id), never from client input:
  // the RPC resolves the caller's own base internally (see migration comments).
  const { data, error } = await serviceClient.rpc("fn_start_building", {
    p_player_id: user.id,
    p_building_type: building_type,
  });
  if (error) {
    const status = error.message === "base_not_found" ? 404 : 400;
    return new Response(JSON.stringify({ error: error.message }), { status });
  }

  return new Response(JSON.stringify(data), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
