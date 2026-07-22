extends Node
## Thin HTTP wrapper around Supabase Auth + Edge Functions. Holds the session
## token; contains zero gameplay logic (CLAUDE.md rule #1) — every call is
## forwarded to a server Edge Function, never a direct RPC/table write.

const SUPABASE_URL := "http://127.0.0.1:54321"
const SUPABASE_ANON_KEY := "REPLACE_WITH_LOCAL_ANON_KEY" # from `supabase status`

var access_token: String = ""
var user_id: String = ""

signal auth_ready

func _ready() -> void:
	_sign_in_anonymously()

func _sign_in_anonymously() -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_signup_completed.bind(http))
	var headers := [
		"apikey: %s" % SUPABASE_ANON_KEY,
		"Content-Type: application/json",
	]
	# Anonymous sign-in: GoTrue creates an anonymous user via POST /auth/v1/signup
	# with an empty body when enable_anonymous_sign_ins is true (server/supabase/config.toml).
	# Verify this endpoint against your installed Supabase CLI version if auth fails.
	http.request(SUPABASE_URL + "/auth/v1/signup", headers, HTTPClient.METHOD_POST, "{}")

func _on_signup_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	if response_code != 200:
		push_error("Supabase anonymous sign-in failed (%d): %s" % [response_code, body.get_string_from_utf8()])
		return
	var parsed: Dictionary = JSON.parse_string(body.get_string_from_utf8())
	access_token = parsed.get("access_token", "")
	user_id = parsed.get("user", {}).get("id", "")
	auth_ready.emit()

## Calls an Edge Function by name with a JSON payload. `callback` receives
## (response_code: int, parsed_body: Variant).
func call_function(function_name: String, payload: Dictionary, callback: Callable) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
		http.queue_free()
		var parsed = JSON.parse_string(body.get_string_from_utf8())
		callback.call(response_code, parsed)
	)
	var headers := [
		"apikey: %s" % SUPABASE_ANON_KEY,
		"Authorization: Bearer %s" % access_token,
		"Content-Type: application/json",
	]
	http.request(SUPABASE_URL + "/functions/v1/" + function_name, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
