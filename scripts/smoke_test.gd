extends SceneTree
## Headless: play all 144 months, reach an ending, exit 0
## Usage: godot --headless --path <project> --script res://scripts/smoke_test.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("[smoke] 《時光裡的她》 smoke test start")
	var gs: Node = root.get_node_or_null("GameState")
	if gs == null:
		var script: GDScript = load("res://scripts/game_state.gd") as GDScript
		gs = script.new()
		gs.name = "GameState"
		root.add_child(gs)
		print("[smoke] GameState instantiated manually")
	else:
		print("[smoke] GameState autoload found")

	# —— Growth stage table ——
	var stage_ok := true
	var expect_stages := {
		1: 0, 2: 0, 3: 1, 4: 1, 5: 2, 6: 2,
		7: 3, 8: 3, 9: 4, 10: 4, 11: 5, 12: 5,
	}
	for y in expect_stages:
		var got := GameConfig.growth_stage_for_year(y)
		var want: int = expect_stages[y]
		print("[smoke] growth_stage year %d -> %d (expect %d)" % [y, got, want])
		if got != want:
			printerr("[smoke] FAIL: stage mismatch year %d" % y)
			stage_ok = false
	# Boundary asserts requested: years 3,7,9,11
	for y2 in [3, 7, 9, 11]:
		if GameConfig.growth_stage_for_year(y2) != expect_stages[y2]:
			stage_ok = false

	# —— Wardrobe resolver ——
	var wardrobe_ok := true
	for st in range(6):
		for season in range(4):
			var wp := GameConfig.wardrobe_path(st, season)
			if wp == "" or not (ResourceLoader.exists(wp) or FileAccess.file_exists(ProjectSettings.globalize_path(wp))):
				printerr("[smoke] FAIL: wardrobe missing stage=%d season=%d path=%s" % [st, season, wp])
				wardrobe_ok = false
			else:
				print("[smoke] wardrobe s%d season%d -> %s OK" % [st, season, wp])

	# Event media stills exist for beach / mountain
	for mid in ["beach", "mountain"]:
		var sp := GameConfig.event_still_path(mid)
		if sp == "":
			printerr("[smoke] FAIL: missing event still %s" % mid)
			wardrobe_ok = false
		else:
			print("[smoke] event still %s -> %s OK" % [mid, sp])
	for vid in ["event_beach", "event_mountain"]:
		var vp := GameConfig.event_video_path(vid)
		if vp == "":
			print("[smoke] INFO: video %s not present yet (still-only OK)" % vid)
		else:
			print("[smoke] event video %s -> %s OK" % [vid, vp])

	# Special events registered
	var has_beach := false
	var has_mtn := false
	for e in SeasonEvents.EVENTS:
		if e.get("id") == "summer_beach" and e.get("media_still") == "beach":
			has_beach = true
		if e.get("id") == "autumn_mountain" and e.get("media_still") == "mountain":
			has_mtn = true
	if not has_beach or not has_mtn:
		printerr("[smoke] FAIL: special media events missing")
		stage_ok = false
	else:
		print("[smoke] special events summer_beach + autumn_mountain OK")

	# —— Map events cover all 6 places ——
	var map_ok := true
	var covered := MapEvents.place_ids_covered()
	for pid in MapEvents.PLACE_IDS:
		if pid not in covered:
			printerr("[smoke] FAIL: map_events missing place %s" % pid)
			map_ok = false
		else:
			var n := MapEvents.events_for_place(pid).size()
			print("[smoke] map_events %s -> %d events" % [pid, n])
			if n < 3:
				printerr("[smoke] FAIL: place %s has fewer than 3 events" % pid)
				map_ok = false
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var sample := MapEvents.pick_event("park", {}, rng)
	if sample.is_empty() or not sample.has("title"):
		printerr("[smoke] FAIL: pick_event returned empty")
		map_ok = false
	else:
		print("[smoke] pick_event park -> %s OK" % sample.get("title", "?"))

	# —— Save / Load round-trip ——
	var save_ok := true
	gs.begin_new_game()
	gs.year = 3
	gs.season = 2
	gs.charm = 55
	gs.morals = 61
	gs.social = 44
	gs.stamina = 70
	gs.academia = 38
	gs.mood = 72
	gs.cash = 12345
	gs.season_schedule = ["study_library", "rest_park", ""] as Array[String]
	gs.flags["visited_home"] = 2
	gs.flags["home_story_told"] = true
	gs.months_played = 17
	gs.last_activity_names = ["圖書館", "公園散步"] as Array[String]
	gs.last_season_event = {"title": "測試事件", "body": "x"}
	if not gs.save_game(0):
		printerr("[smoke] FAIL: save_game returned false")
		save_ok = false
	else:
		print("[smoke] save_game slot 0 OK")
	gs.begin_new_game()  # wipe
	if gs.year != 1 or gs.charm == 55:
		# begin_new_game should reset; charm starts from config not 55
		pass
	if not gs.load_game(0):
		printerr("[smoke] FAIL: load_game returned false")
		save_ok = false
	else:
		var checks := [
			["year", gs.year, 3],
			["season", gs.season, 2],
			["charm", gs.charm, 55],
			["morals", gs.morals, 61],
			["social", gs.social, 44],
			["stamina", gs.stamina, 70],
			["academia", gs.academia, 38],
			["mood", gs.mood, 72],
			["cash", gs.cash, 12345],
			["months_played", gs.months_played, 17],
		]
		for c in checks:
			if int(c[1]) != int(c[2]):
				printerr("[smoke] FAIL: load %s got %s expect %s" % [c[0], str(c[1]), str(c[2])])
				save_ok = false
		if str(gs.season_schedule[0]) != "study_library":
			printerr("[smoke] FAIL: schedule[0] not restored")
			save_ok = false
		if int(gs.flags.get("visited_home", 0)) != 2:
			printerr("[smoke] FAIL: flags not restored")
			save_ok = false
		if save_ok:
			print("[smoke] load_game restores year/season/stats OK")
	gs.delete_save(0)

	# —— Phase 5: activity unlocks + mood intensity ——
	var act_ok := true
	var new_ids := [
		"culture_reading", "clinic_helper", "shops_market",
		"school_debate", "park_run", "talent_showcase",
	]
	var all_acts: Dictionary = Activities.all()
	for nid in new_ids:
		if not all_acts.has(nid):
			printerr("[smoke] FAIL: missing new activity %s" % nid)
			act_ok = false
		else:
			print("[smoke] activity %s registered OK" % nid)

	gs.begin_new_game()
	gs.mood = 15
	var av_heavy: Dictionary = Activities.availability("work_store", gs)
	var av_rest: Dictionary = Activities.availability("rest_sleep", gs)
	if bool(av_heavy.get("ok", true)):
		printerr("[smoke] FAIL: mood=15 should block work_store")
		act_ok = false
	else:
		print("[smoke] mood=15 blocks work_store: %s" % av_heavy.get("reason", ""))
	if not bool(av_rest.get("ok", false)):
		printerr("[smoke] FAIL: mood=15 rest_sleep should be available")
		act_ok = false
	else:
		print("[smoke] mood=15 rest_sleep available OK")

	gs.mood = 30
	av_heavy = Activities.availability("work_store", gs)
	var av_lib: Dictionary = Activities.availability("study_library", gs)
	if bool(av_heavy.get("ok", true)):
		printerr("[smoke] FAIL: mood=30 should block intensity-2 work_store")
		act_ok = false
	else:
		print("[smoke] mood=30 blocks work_store: %s" % av_heavy.get("reason", ""))
	if not bool(av_lib.get("ok", false)):
		printerr("[smoke] FAIL: mood=30 study_library (intensity 1) should be OK")
		act_ok = false
	else:
		print("[smoke] mood=30 study_library available OK")

	gs.begin_new_game()
	gs.mood = 60
	gs.year = 1
	gs.flags.clear()
	var av_cult: Dictionary = Activities.availability("culture_reading", gs)
	if bool(av_cult.get("ok", true)):
		printerr("[smoke] FAIL: year=1 no visit should lock culture_reading")
		act_ok = false
	else:
		print("[smoke] culture_reading locked without visit: %s" % av_cult.get("reason", ""))
	gs.flags["visited_culture"] = 1
	gs.year = 3
	av_cult = Activities.availability("culture_reading", gs)
	if not bool(av_cult.get("ok", false)):
		printerr("[smoke] FAIL: visited_culture + year=3 should unlock culture_reading (%s)" % av_cult.get("reason", ""))
		act_ok = false
	else:
		print("[smoke] culture_reading unlocked after visit+year OK")

	# —— Phase 6: year-end scrapbook review ——
	var yr_ok := true
	gs.begin_new_game()
	if gs.year_start_stats.is_empty():
		printerr("[smoke] FAIL: year_start_stats empty after begin_new_game")
		yr_ok = false
	else:
		print("[smoke] year_start_stats snapshotted OK")
	# Accumulate fake year data & bump stats
	gs.year_activity_names = ["圖書館讀書", "公園散步", "咖啡店打工"]
	gs.year_event_titles = ["春日櫻花散步", "夏日海邊浪花"]
	gs.charm = int(gs.year_start_stats.get("charm", 35)) + 12
	gs.mood = int(gs.year_start_stats.get("mood", 60)) + 6
	gs.social = int(gs.year_start_stats.get("social", 35)) + 4
	var rev: Dictionary = gs.build_year_review()
	for key in ["year", "age", "stage_label", "deltas", "highlights", "polaroid_band", "summary"]:
		if not rev.has(key):
			printerr("[smoke] FAIL: last_year_review missing key %s" % key)
			yr_ok = false
	var dlt = rev.get("deltas", {})
	if typeof(dlt) != TYPE_DICTIONARY or int(dlt.get("charm", 0)) != 12:
		printerr("[smoke] FAIL: build_year_review charm delta expect 12 got %s" % str(dlt.get("charm", "?")))
		yr_ok = false
	else:
		print("[smoke] build_year_review deltas OK charm+12")
	if str(rev.get("summary", "")) == "":
		printerr("[smoke] FAIL: empty summary")
		yr_ok = false
	else:
		print("[smoke] summary: %s" % rev.get("summary", ""))
	var band := str(rev.get("polaroid_band", ""))
	if band not in ["child", "teen", "young"]:
		printerr("[smoke] FAIL: bad polaroid_band %s" % band)
		yr_ok = false
	else:
		print("[smoke] polaroid_band=%s OK" % band)
	var pp := GameConfig.year_review_polaroid_path(band)
	var ab := GameConfig.year_review_album_bg()
	print("[smoke] album_bg=%s polaroid=%s" % [ab, pp])
	if ab == "":
		printerr("[smoke] FAIL: album_bg missing")
		yr_ok = false
	if pp == "":
		printerr("[smoke] FAIL: polaroid path empty")
		yr_ok = false

	# Winter year 1 → year_review
	gs.begin_new_game()
	gs.year = 1
	gs.season = 3  # winter
	gs.snapshot_year_start()
	gs.charm += 5
	gs.year_activity_names = ["在家好好休息"]
	var next1: String = gs.advance_after_season()
	if next1 != "year_review":
		printerr("[smoke] FAIL: winter y1 advance expect year_review got %s" % next1)
		yr_ok = false
	else:
		print("[smoke] winter y1 → year_review OK (now year=%d)" % gs.year)
	if int(gs.last_year_review.get("year", -1)) != 1:
		printerr("[smoke] FAIL: last_year_review.year expect 1")
		yr_ok = false
	if gs.pending_ending_after_review:
		printerr("[smoke] FAIL: pending_ending should be false after y1")
		yr_ok = false
	var cont1: String = gs.continue_after_year_review()
	if cont1 != "hub":
		printerr("[smoke] FAIL: continue after y1 expect hub got %s" % cont1)
		yr_ok = false
	else:
		print("[smoke] continue_after_year_review → hub OK")

	# Winter year 12 → year_review then ending
	gs.begin_new_game()
	gs.year = 12
	gs.season = 3
	gs.snapshot_year_start()
	gs.year_activity_names = ["才藝發表"]
	var next12: String = gs.advance_after_season()
	if next12 != "year_review":
		printerr("[smoke] FAIL: winter y12 expect year_review got %s" % next12)
		yr_ok = false
	else:
		print("[smoke] winter y12 → year_review OK")
	if not gs.pending_ending_after_review:
		printerr("[smoke] FAIL: pending_ending_after_review should be true")
		yr_ok = false
	else:
		print("[smoke] pending_ending_after_review set OK")
	if int(gs.last_year_review.get("year", -1)) != 12:
		printerr("[smoke] FAIL: review year expect 12")
		yr_ok = false
	var cont12: String = gs.continue_after_year_review()
	if cont12 != "ending":
		printerr("[smoke] FAIL: continue after y12 expect ending got %s" % cont12)
		yr_ok = false
	else:
		print("[smoke] continue_after_year_review → ending OK")
	if not gs.is_game_over:
		printerr("[smoke] FAIL: is_game_over after y12 review continue")
		yr_ok = false


	# —— Phase 7: ending art paths + radar helper ——
	var end_ok := true
	for eid in ["doctor", "ordinary_happy", "burnout", "credits_bg"]:
		var ep := GameConfig.ending_art_path(eid)
		if ep == "" or not (ResourceLoader.exists(ep) or FileAccess.file_exists(ProjectSettings.globalize_path(ep))):
			printerr("[smoke] FAIL: ending_art_path(%s) missing -> %s" % [eid, ep])
			end_ok = false
		else:
			print("[smoke] ending_art %s -> %s OK" % [eid, ep])
	# Unknown id should fall back to ordinary_happy or credits_bg (existing file)
	var fb := GameConfig.ending_art_path("__no_such_ending__")
	if fb == "":
		printerr("[smoke] FAIL: unknown ending id should fallback")
		end_ok = false
	else:
		print("[smoke] ending_art fallback -> %s OK" % fb)
	# StatRadar class loads
	var radar_script: GDScript = load("res://scripts/stat_radar.gd") as GDScript
	if radar_script == null:
		printerr("[smoke] FAIL: cannot load stat_radar.gd")
		end_ok = false
	else:
		var radar_inst = radar_script.new()
		if radar_inst == null:
			printerr("[smoke] FAIL: StatRadar.new() failed")
			end_ok = false
		else:
			radar_inst.set_from_stats({"charm": 80, "morals": 70, "social": 60, "stamina": 50, "academia": 90})
			print("[smoke] StatRadar set_from_stats OK")
			radar_inst.free()


	# —— Phase 8: diary-cover title assets ——
	var title_ok := true
	var cover := "res://assets/title_diary_cover.jpg"
	if not (ResourceLoader.exists(cover) or FileAccess.file_exists(ProjectSettings.globalize_path(cover))):
		printerr("[smoke] FAIL: title_diary_cover.jpg missing")
		title_ok = false
	else:
		print("[smoke] title_diary_cover.jpg OK")
	var title_script: GDScript = load("res://scripts/title.gd") as GDScript
	if title_script == null:
		printerr("[smoke] FAIL: cannot load title.gd")
		title_ok = false
	else:
		print("[smoke] title.gd loads OK")
	var title_scene := "res://scenes/title.tscn"
	if not (ResourceLoader.exists(title_scene) or FileAccess.file_exists(ProjectSettings.globalize_path(title_scene))):
		printerr("[smoke] FAIL: title.tscn missing")
		title_ok = false
	else:
		print("[smoke] title.tscn OK")

	gs.begin_new_game()

	var ids: Array = Activities.ids()
	if ids.is_empty():
		printerr("[smoke] FAIL: no activities")
		quit(1)
		return

	var picker := func(month_index: int, state: Node) -> String:
		if int(state.mood) < 30 or int(state.stamina) < 25:
			return "rest_sleep"
		if int(state.cash) < 1000:
			if Activities.is_available("work_cafe", state):
				return "work_cafe"
			if Activities.is_available("virtue_chores", state):
				return "virtue_chores"
			return "rest_sleep"
		var pick: String = ids[month_index % ids.size()]
		if not Activities.is_available(pick, state):
			return "rest_park"
		return pick

	var ending: Dictionary = gs.run_full_auto(picker)
	var months: int = gs.months_played
	var expected: int = GameConfig.TOTAL_MONTHS

	print("[smoke] months_played=%d (expect %d)" % [months, expected])
	print("[smoke] final year=%d season=%d" % [gs.year, gs.season])
	print("[smoke] stats charm=%d morals=%d social=%d stamina=%d academia=%d cash=%d mood=%d" % [
		gs.charm, gs.morals, gs.social, gs.stamina, gs.academia, gs.cash, gs.mood
	])
	print("[smoke] ending id=%s name=%s" % [ending.get("id", "?"), ending.get("name", "?")])

	var ev: Dictionary = gs.last_season_event
	print("[smoke] last_season_event=%s" % str(ev.get("title", "(none)")))

	var ok := stage_ok and wardrobe_ok and map_ok and save_ok and act_ok and yr_ok and end_ok and title_ok
	if months != expected:
		printerr("[smoke] FAIL: months_played != %d" % expected)
		ok = false
	if not gs.is_game_over:
		printerr("[smoke] FAIL: game not over")
		ok = false
	if ending.is_empty() or not ending.has("id"):
		printerr("[smoke] FAIL: no ending")
		ok = false
	if ev.is_empty() or not ev.has("title"):
		printerr("[smoke] FAIL: no last_season_event after playthrough")
		ok = false

	if ok:
		print("[smoke] PASS")
		quit(0)
	else:
		print("[smoke] FAIL")
		quit(1)
