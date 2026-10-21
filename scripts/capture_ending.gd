extends SceneTree
## Capture movie-credits ending → shots/06_ending_credits.png
## Usage: godot --path <project> --script res://scripts/capture_ending.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs = root.get_node_or_null("GameState")
	if gs == null:
		printerr("[ending-shot] GameState missing")
		quit(1)
		return

	gs.begin_new_game()
	# Doctor-leaning sample stats
	gs.year = 13
	gs.season = 0
	gs.months_played = 144
	gs.charm = 58
	gs.morals = 72
	gs.social = 55
	gs.stamina = 62
	gs.academia = 88
	gs.mood = 68
	gs.cash = 12400
	gs.is_game_over = true
	gs.final_ending = {
		"id": "doctor",
		"name": "社區診所的白袍",
		"priority": 90,
		"summary": "她通過考試，回到小鎮診所實習。街坊叫她「小醫生」，你坐在候診椅上，驕傲得說不出話。",
	}
	gs.state_changed.emit()

	var err := change_scene_to_file("res://scenes/ending.tscn")
	if err != OK:
		printerr("[ending-shot] failed to load ending: ", err)
		quit(1)
		return

	await process_frame
	await process_frame
	await process_frame
	await create_timer(1.0).timeout

	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		printerr("[ending-shot] no image")
		quit(1)
		return
	var out := ProjectSettings.globalize_path("res://shots/06_ending_credits.png")
	img.save_png(out)
	print("[ending-shot] ", out, " ", img.get_width(), "x", img.get_height())
	quit(0)
