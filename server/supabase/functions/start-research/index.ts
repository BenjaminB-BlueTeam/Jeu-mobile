import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "missing_authorization" }), { status: 401 });
  }

  let research_code: string | undefined;
  try {
    ({ research_code } = await req.json());
  } catch {
    return new Response(JSON.stringify({ error: "invalid_body" }), { status: 400 });
  }
  if (!research_code) {
    return new Response(JSON.stringify({ error: "missing_research_code" }), { status: 400 });
  }

  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error: userError } = await userClient.auth.getUser();
  if (userError || !user) {
    return new Response(JSON.stringify({ error: "invalid_session" }), { status: 401 });
  }

  const serviceClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  const { data: base, error: baseError } = await serviceClient
    .from("bases")
    .select("id")
    .eq("player_id", user.id)
    .single();
  if (baseError || !base) {
    return new Response(JSON.stringify({ error: "base_not_found" }), { status: 404 });
  }

  const { data, error } = await serviceClient.rpc("fn_start_research", {
    p_player_id: user.id,
    p_base_id: base.id,
    p_research_code: research_code,
  });
  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 400 });
  }

  return new Response(JSON.stringify(data), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
