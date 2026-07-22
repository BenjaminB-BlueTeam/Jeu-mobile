extends Node
## Loads client/i18n/<locale>.json and exposes I18n.t(key). No hardcoded
## strings anywhere else in the client (CLAUDE.md i18n rule applies even to
## this throwaway prototype).

var locale: String = "fr"
var _translations: Dictionary = {}

func _ready() -> void:
	_load_locale(locale)

func _load_locale(new_locale: String) -> void:
	var path := "res://i18n/%s.json" % new_locale
	if not FileAccess.file_exists(path):
		push_error("Missing i18n file: %s" % path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	_translations = JSON.parse_string(file.get_as_text())
	locale = new_locale

func t(key: String, params: Dictionary = {}) -> String:
	var text: String = _translations.get(key, key)
	for param_key in params:
		text = text.replace("{%s}" % param_key, str(params[param_key]))
	return text
