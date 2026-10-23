extends SceneTree
## After scripts/export_web.sh, open each secondary pack with Godot.
## Usage: godot --headless --path . --script res://scripts/check_exported_packs.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var manifest_path := "res://export/packs.json"
	if not FileAccess.file_exists(manifest_path):
		push_error("[pack-check] missing %s" % manifest_path)
		quit(1)
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if typeof(data) != TYPE_DICTIONARY or typeof(data.get("packs", null)) != TYPE_ARRAY:
		push_error("[pack-check] bad manifest")
		quit(1)
		return
	var root := ProjectSettings.globalize_path("res://")
	var failed := false
	for entry in data["packs"]:
		if typeof(entry) != TYPE_DICTIONARY:
			push_error("[pack-check] bad entry")
			failed = true
			continue
		var rel := str(entry.get("file", ""))
		var abs_path := root.path_join("build/web").path_join(rel)
		if not FileAccess.file_exists(abs_path):
			push_error("[pack-check] missing %s" % abs_path)
			failed = true
			continue
		var opened := ProjectSettings.load_resource_pack(abs_path, false)
		print("[pack-check] load %s -> %s" % [abs_path, opened])
		if not opened:
			failed = true
			continue
		var probe := str(entry.get("probe", ""))
		if probe.is_empty():
			continue
		if not ResourceLoader.exists(probe):
			push_error("[pack-check] probe missing %s" % probe)
			failed = true
			continue
		var res: Resource = load(probe)
		if res == null:
			push_error("[pack-check] probe failed to load %s" % probe)
			failed = true
		else:
			print("[pack-check] probe %s OK" % probe)
	if failed:
		quit(1)
	else:
		print("[pack-check] PASS")
		quit(0)
