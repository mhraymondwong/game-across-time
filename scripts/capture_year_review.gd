extends SceneTree
## Headless / xvfb: load year_review with fake last_year_review → shots/05_year_review.png


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs = root.get_node_or_null("GameState")
	if gs == null:
		printerr("[year-review-shot] GameState missing")
		quit(1)
		return
	gs.begin_new_game()
	gs.year = 5
	gs.season = 0
	gs.charm = 48
	gs.morals = 52
	gs.social = 44
	gs.stamina = 58
	gs.academia = 40
	gs.mood = 70
	gs.cash = 9500
	gs.year_start_stats = {
		"charm": 35, "morals": 40, "social": 35, "stamina": 50,
		"academia": 30, "mood": 60, "cash": 8000,
	}
	gs.year_activity_names = ["圖書館讀書", "公園散步", "咖啡店打工", "才藝課"]
	gs.year_event_titles = ["春日櫻花散步", "夏日海邊浪花", "秋日山上紅葉"]
	# Build as if reviewing completed year 4 while year is still 4
	gs.year = 4
	gs.last_year_review = gs.build_year_review()
	gs.year = 5
	gs.pending_ending_after_review = false
	change_scene_to_file("res://scenes/year_review.tscn")
	await process_frame
	await process_frame
	await process_frame
	await create_timer(0.9).timeout
	var img: Image = root.get_viewport().get_texture().get_image()
	var out := ProjectSettings.globalize_path("res://shots/05_year_review.png")
	img.save_png(out)
	print("[year-review-shot] ", out, " ", img.get_width(), "x", img.get_height())
	quit(0)
