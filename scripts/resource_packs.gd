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


## Godot 4.7 can load a .pck but cannot unload one. Web still downloads every
## pack at the splash (see export/web_shell.html). After a year changes, drop
## cached textures from age bands and adult years the diary is no longer showing.
## The current year and the previous year stay, so 「長高了」 can still compare them.
func release_stale_year_art(current_year: int) -> int:
	var released := 0
	var keep_year := {
		current_year: true,
		maxi(1, current_year - 1): true,
	}
	for y in range(GameConfig.ADULT_START_YEAR, GameConfig.TOTAL_YEARS + 1):
		if keep_year.has(y):
			continue
		for season_key in GameConfig.SEASON_KEYS:
			for folder in ["res://assets/adulthood/", "res://assets/wardrobe/"]:
				for ext in ["png", "jpg"]:
					var plate := "%sadult_y%d_%s.%s" % [folder, y, season_key, ext]
					if _release_cached(plate):
						released += 1
	var keep_band := {
		AgeLooks.band_for_year(current_year): true,
		AgeLooks.band_for_year(maxi(1, current_year - 1)): true,
	}
	for band in AgeLooks.BANDS:
		if keep_band.has(band):
			continue
		for stem in [
			"res://assets/family/daughter_%s" % band,
			"res://assets/family/mom_%s_cutout" % band,
			"res://assets/family/mom_%s_bust" % band,
			"res://assets/family/dad_%s" % band,
			"res://assets/family/family_%s" % band,
		]:
			for ext in ["png", "jpg"]:
				if _release_cached("%s.%s" % [stem, ext]):
					released += 1
	if released > 0:
		print("[packs] released %d stale year textures (year %d)" % [released, current_year])
	return released


func _release_cached(path: String) -> bool:
	if path == "" or not ResourceLoader.has_cached(path):
		return false
	var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
	if res == null:
		return false
	if res.resource_path == path:
		res.take_over_path("")
	return not ResourceLoader.has_cached(path)
