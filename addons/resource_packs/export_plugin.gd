@tool
extends EditorExportPlugin
## Keeps res:// paths owned by export/packs.json out of the main Web pack,
## and writes only that pack's paths into a secondary --export-pack.
##
## Role comes from RESOURCE_PACK_ROLE (scripts/export_web.sh) or the preset
## option resource_packs/role. "main" excludes every listed prefix. Any other
## role keeps only that pack's prefixes.


const MANIFEST := "res://export/packs.json"

var _prefixes_by_id: Dictionary = {}
var _role: String = ""
var _kept: int = 0
var _skipped: int = 0


func _get_name() -> String:
	# Sort before the built-in GDScript exporter. Otherwise that plugin compiles
	# every script into the pack before skip() can drop it.
	return "0ResourcePacks"


func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform != null


func _get_export_options(platform: EditorExportPlatform) -> Array[Dictionary]:
	if platform == null:
		return []
	return [
		{
			"option": {
				"name": "resource_packs/role",
				"type": TYPE_STRING,
				"hint": PROPERTY_HINT_PLACEHOLDER_TEXT,
				"hint_string": "main, or a pack id from export/packs.json",
			},
			"default_value": "main",
		}
	]


func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	_kept = 0
	_skipped = 0
	_prefixes_by_id = {}
	_role = _resolve_role()
	var parsed: Variant = _read_manifest()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[packs] export manifest missing or invalid (%s)" % MANIFEST)
	else:
		var packs: Variant = parsed.get("packs", [])
		if typeof(packs) == TYPE_ARRAY:
			for entry in packs:
				if typeof(entry) != TYPE_DICTIONARY:
					continue
				var id := str(entry.get("id", "")).strip_edges()
				var includes: Variant = entry.get("include", [])
				if id.is_empty() or typeof(includes) != TYPE_ARRAY:
					continue
				var prefixes: Array[String] = []
				for item in includes:
					var prefix := str(item).strip_edges()
					if not prefix.is_empty():
						prefixes.append(prefix)
				_prefixes_by_id[id] = prefixes
	if _role != "main" and not _prefixes_by_id.has(_role):
		push_error("[packs] RESOURCE_PACK_ROLE '%s' is not an id in %s" % [_role, MANIFEST])
	print("[packs] export begin role=%s output=%s" % [_role, path])


func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	var owner := _owner_of(path)
	var keep := owner.is_empty() if _role == "main" else owner == _role
	if keep:
		_kept += 1
	else:
		_skipped += 1
		skip()


func _export_end() -> void:
	print("[packs] export end role=%s kept=%d skipped=%d" % [_role, _kept, _skipped])
	if _role != "main" and _kept == 0:
		push_error("[packs] pack role '%s' kept no files" % _role)


func _resolve_role() -> String:
	var env := OS.get_environment("RESOURCE_PACK_ROLE").strip_edges()
	if not env.is_empty():
		return env
	var opt := str(get_option("resource_packs/role")).strip_edges()
	if not opt.is_empty():
		return opt
	return "main"


func _owner_of(path: String) -> String:
	var norm := path.replace("\\", "/")
	for id in _prefixes_by_id.keys():
		var prefixes: Array = _prefixes_by_id[id]
		for prefix in prefixes:
			if _matches_prefix(norm, str(prefix)):
				return str(id)
	return ""


func _matches_prefix(path: String, prefix: String) -> bool:
	var pattern := prefix.replace("\\", "/")
	if pattern.ends_with("*"):
		pattern = pattern.substr(0, pattern.rfind("*"))
	if pattern.ends_with("/"):
		return path.begins_with(pattern)
	return path == pattern or path.begins_with(pattern + "/")


func _read_manifest() -> Variant:
	if not FileAccess.file_exists(MANIFEST):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
