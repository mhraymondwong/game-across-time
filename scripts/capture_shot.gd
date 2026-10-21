extends SceneTree
## Capture wardrobe + event media screenshot -> shots/04_wardrobe_event.png
## Usage: godot --path <project> --script res://scripts/capture_shot.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs = root.get_node_or_null("GameState")
	if gs:
		gs.begin_new_game()
		# Year 5 summer → growth stage 2, summer wardrobe (fallback spring for s2)
		gs.year = 5
		gs.season = 1
		gs.last_deltas = {
			"charm": 2, "morals": 0, "social": 2, "stamina": 1,
			"academia": 0, "mood": 6, "cash": -350,
			"activities": ["公園散步", "才藝課", "休息"],
		}
		# Force beach special event with media
		gs.last_season_event = {
			"id": "summer_beach",
			"title": "夏天去海灘",
			"body": "週末驅車到近郊海灘。陽光、浪聲與防曬乳的味道——她在沙上寫下你們的名字。",
			"sticker": "summer",
			"media_still": "beach",
			"media_video": "event_beach",
			"deltas": {"mood": 6, "stamina": 2, "charm": 2, "social": 2, "cash": -350},
		}
		gs.state_changed.emit()

	var err := change_scene_to_file("res://scenes/season_result.tscn")
	if err != OK:
		printerr("[shot] failed to load season_result: ", err)
		quit(1)
		return
	await process_frame
	await process_frame
	await process_frame
	await create_timer(0.6).timeout

	# Dismiss media overlay so result card + still thumbnail are visible, then
	# also grab one frame with overlay by re-showing? Prefer overlay with beach still.
	# Media layer starts visible — capture that (beach still fullscreen).
	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		printerr("[shot] no image")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://shots")
	var path := "res://shots/04_wardrobe_event.png"
	var abs_path := ProjectSettings.globalize_path(path)
	var save_err := img.save_png(abs_path)

	# Also capture home_hub wardrobe for stage 2 summer
	if gs:
		gs.year = 5
		gs.season = 1
	change_scene_to_file("res://scenes/home_hub.tscn")
	await process_frame
	await process_frame
	await create_timer(0.5).timeout
	var img2: Image = root.get_viewport().get_texture().get_image()
	if img2:
		img2.save_png(ProjectSettings.globalize_path("res://shots/04b_wardrobe_hub.png"))

	var stage := GameConfig.growth_stage_for_year(5)
	var wp := GameConfig.wardrobe_path_for_year_season(5, 1)
	print("[shot] saved ", abs_path, " err=", save_err,
		" stage=", stage, " wardrobe=", wp)
	quit(0 if save_err == OK else 1)
