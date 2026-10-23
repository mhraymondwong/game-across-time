extends Node
## Loads extra .pck files from res://export/packs.json before the main scene.
##
## Web: export/web_shell.html downloads each pack into the engine filesystem
## (virtual path /packs/....pck) while the diary splash is still up. This
## autoload then calls ProjectSettings.load_resource_pack before title.tscn.
## Editor and headless project runs already have those resources on res://,
## so a missing .pck is fine when the probe file exists.


const MANIFEST_PATH := "res://export/packs.json"

var loaded_files: PackedStringArray = PackedStringArray()
var satisfied_ids: PackedStringArray = PackedStringArray()
var failed_ids: PackedStringArray = PackedStringArray()
var manifest_error: String = ""


func _init() -> void:
	_load_packs()


func ensure_ready() -> bool:
	return manifest_error.is_empty() and failed_ids.is_empty()


func status_line() -> String:
	if not manifest_error.is_empty():
		return "error=%s" % manifest_error
	return "loaded=%s present=%s failed=%s" % [loaded_files, satisfied_ids, failed_ids]


func _load_packs() -> void:
	var data: Variant = _read_manifest()
	if data == null:
		manifest_error = "missing or unreadable manifest"
		push_error("[packs] " + manifest_error)
		return
	if typeof(data) != TYPE_DICTIONARY:
		manifest_error = "manifest is not an object"
		push_error("[packs] " + manifest_error)
		return
	var packs: Variant = data.get("packs", [])
	if typeof(packs) != TYPE_ARRAY:
		manifest_error = "manifest packs is not an array"
		push_error("[packs] " + manifest_error)
		return
	for entry in packs:
		_load_entry(entry)


func _load_entry(entry: Variant) -> void:
	if typeof(entry) != TYPE_DICTIONARY:
		failed_ids.append("?")
		push_error("[packs] pack entry is not an object")
		return
	var id := str(entry.get("id", "")).strip_edges()
	var file := str(entry.get("file", "")).strip_edges()
	var probe := str(entry.get("probe", "")).strip_edges()
	if id.is_empty() or file.is_empty():
		failed_ids.append(id if not id.is_empty() else "?")
		push_error("[packs] pack entry missing id or file")
		return
	if _try_load_file(file):
		if not probe.is_empty() and not _probe_exists(probe):
			failed_ids.append(id)
			push_error("[packs] loaded %s but probe missing: %s" % [file, probe])
			return
		satisfied_ids.append(id)
		print("[packs] loaded %s (%s)" % [id, file])
		return
	if not probe.is_empty() and _probe_exists(probe):
		satisfied_ids.append(id)
		print("[packs] %s already present (%s)" % [id, probe])
		return
	failed_ids.append(id)
	push_error("[packs] missing %s (%s)" % [id, file])


func _try_load_file(rel: String) -> bool:
	var clean := rel.replace("\\", "/").trim_prefix("/")
	if clean.is_empty() or clean.contains(".."):
		return false
	var candidates: PackedStringArray = PackedStringArray()
	candidates.append("/" + clean)
	candidates.append(clean)
	var exe_dir := OS.get_executable_path().get_base_dir()
	if not exe_dir.is_empty():
		candidates.append(exe_dir.path_join(clean))
	for path in candidates:
		if not FileAccess.file_exists(path):
			continue
		if ProjectSettings.load_resource_pack(path, false):
			loaded_files.append(path)
			return true
		push_warning("[packs] found %s but load_resource_pack failed" % path)
	return false


func _probe_exists(probe: String) -> bool:
	if ResourceLoader.exists(probe):
		return true
	return FileAccess.file_exists(probe)


func _read_manifest() -> Variant:
	var text := _read_text(MANIFEST_PATH)
	if text.is_empty():
		# Web shell also writes the fetched packs.json onto the virtual FS.
		text = _read_text("/packs.json")
	if text.is_empty():
		text = _read_text("packs.json")
	if text.is_empty():
		return null
	return JSON.parse_string(text)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)
