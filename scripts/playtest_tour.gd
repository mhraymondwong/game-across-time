extends SceneTree
## Full playtest tour: capture each major screen → shots/playtest/
## Usage: DISPLAY=:22 or xvfb-run -a godot --path . --script res://scripts/playtest_tour.gd

const OUT := "res://shots/playtest"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs = root.get_node_or_null("GameState")
	if gs == null:
		printerr("[playtest] GameState missing")
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	# 01 Title
	await _goto("res://scenes/title.tscn")
	await _shot("01_title.png")

	# 02 Hub Y1 spring (drawer open default)
	gs.begin_new_game()
	await _goto("res://scenes/home_hub.tscn")
	await _shot("02_hub_y1_spring.png")

	# 03 Hub with full season schedule
	gs.set_schedule_slot(0, "study_library")
	gs.set_schedule_slot(1, "rest_park")
	gs.set_schedule_slot(2, "virtue_chores")
	gs.state_changed.emit()
	await process_frame
	await process_frame
	await _shot("03_hub_scheduled.png")

	# 04 Season result (resolve season)
	var _res: Dictionary = gs.resolve_season()
	await _goto("res://scenes/season_result.tscn")
	await _shot("04_season_result.png")

	# Advance to winter end of year → year review path sample
	# Build year review for year 3 (mid growth)
	gs.begin_new_game()
	gs.year = 3
	gs.season = 3
	gs.months_played = 3 * 12
	gs.charm = 50
	gs.morals = 55
	gs.social = 48
	gs.stamina = 60
	gs.academia = 45
	gs.mood = 65
	gs.cash = 9200
	gs.year_start_stats = {
		"charm": 40, "morals": 45, "social": 40, "stamina": 52,
		"academia": 35, "mood": 58, "cash": 8500,
	}
	gs.year_activity_names = ["圖書館讀書", "公園散步", "家務", "才藝課"]
	gs.year_event_titles = ["春日散步", "夏日海邊", "秋日山上"]
	gs.last_year_review = gs.build_year_review()
	gs.year = 4
	gs.pending_ending_after_review = false
	await _goto("res://scenes/year_review.tscn")
	await _shot("05_year_review.png")

	# 06 Hub mid-game wardrobe (year 7 summer → stage ~3)
	gs.begin_new_game()
	gs.year = 7
	gs.season = 1  # summer
	gs.months_played = 6 * 12 + 3
	gs.charm = 58
	gs.morals = 60
	gs.social = 55
	gs.stamina = 62
	gs.academia = 52
	gs.mood = 70
	gs.cash = 11000
	await _goto("res://scenes/home_hub.tscn")
	await _shot("06_hub_y7_summer.png")

	# 07 Ending credits
	gs.begin_new_game()
	gs.year = 13
	gs.season = 0
	gs.months_played = 216
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
	await _goto("res://scenes/ending.tscn")
	await _shot("07_ending.png")

	# 08 Late hub winter Y11
	gs.begin_new_game()
	gs.year = 11
	gs.season = 3
	gs.months_played = 10 * 12 + 9
	gs.charm = 70
	gs.morals = 65
	gs.social = 68
	gs.stamina = 55
	gs.academia = 72
	gs.mood = 60
	gs.cash = 15000
	await _goto("res://scenes/home_hub.tscn")
	await _shot("08_hub_y11_winter.png")

	print("[playtest] ALL SHOTS DONE")
	quit(0)


func _goto(path: String) -> void:
	var err := change_scene_to_file(path)
	if err != OK:
		printerr("[playtest] failed scene ", path, " err=", err)
	await process_frame
	await process_frame
	await process_frame
	await create_timer(0.85).timeout


func _shot(name: String) -> void:
	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		printerr("[playtest] no image for ", name)
		return
	var out := ProjectSettings.globalize_path("%s/%s" % [OUT, name])
	img.save_png(out)
	print("[playtest] ", out, " ", img.get_width(), "x", img.get_height())
