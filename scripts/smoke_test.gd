extends SceneTree
## Headless: play all 216 months, reach an ending, exit 0
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

	var packs_ok := true
	var pack_node := root.get_node_or_null("ResourcePacks")
	if pack_node == null:
		printerr("[smoke] FAIL: ResourcePacks autoload missing")
		packs_ok = false
	elif not pack_node.ensure_ready():
		printerr("[smoke] FAIL: resource packs %s" % pack_node.status_line())
		packs_ok = false
	else:
		print("[smoke] resource packs %s" % pack_node.status_line())

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
		"school_library_helper", "virtue_recycle", "school_garden",
		"school_class_helper", "festival_helper", "family_bento",
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

	# Age 9 (year 4) cannot take paid part-time work; early helpers can.
	gs.begin_new_game()
	gs.mood = 80
	gs.year = 4
	gs.academia = 80
	gs.morals = 80
	gs.stamina = 80
	gs.charm = 80
	gs.cash = 8000
	gs.flags["visited_school"] = 1
	gs.flags["visited_shops"] = 1
	gs.flags["visited_clinic"] = 1
	var cafe_year := int(all_acts["work_cafe"].get("min_year", 0))
	var store_year := int(all_acts["work_store"].get("min_year", 0))
	var tutor_year := int(all_acts["work_tutor"].get("min_year", 0))
	if cafe_year != 10 or store_year != 11 or tutor_year != 11:
		printerr("[smoke] FAIL: paid work min_year expected cafe 10 / store 11 / tutor 11")
		act_ok = false
	if str(all_acts["clinic_helper"].get("category", "")) != "品格":
		printerr("[smoke] FAIL: clinic_helper should stay 品格")
		act_ok = false
	for paid in ["work_cafe", "work_store", "work_tutor"]:
		var av_paid: Dictionary = Activities.availability(paid, gs)
		if bool(av_paid.get("ok", true)):
			printerr("[smoke] FAIL: year 4 (age 9) should lock %s" % paid)
			act_ok = false
		else:
			print("[smoke] year 4 locks %s: %s" % [paid, av_paid.get("reason", "")])
	var kid_ids := [
		"school_library_helper", "virtue_recycle", "school_garden",
		"school_class_helper", "festival_helper", "family_bento", "shops_market",
	]
	for kid in kid_ids:
		var kdef: Dictionary = all_acts[kid]
		if str(kdef.get("category", "")) == "打工":
			printerr("[smoke] FAIL: %s should not be category 打工" % kid)
			act_ok = false
		if int(kdef.get("cash", 0)) > 400 or int(kdef.get("cash", 0)) < 0:
			printerr("[smoke] FAIL: %s cash %s outside 0–400" % [kid, str(kdef.get("cash", 0))])
			act_ok = false
		if Activities.intensity_of(kdef) > 1:
			printerr("[smoke] FAIL: %s intensity should be 0–1" % kid)
			act_ok = false
		if str(kdef.get("name", "")) == "" or str(kdef.get("desc", "")) == "":
			printerr("[smoke] FAIL: %s missing zh name/desc" % kid)
			act_ok = false
		var av_kid: Dictionary = Activities.availability(kid, gs)
		if not bool(av_kid.get("ok", false)):
			printerr("[smoke] FAIL: year 4 should allow %s (%s)" % [kid, av_kid.get("reason", "")])
			act_ok = false
		else:
			print("[smoke] year 4 allows %s OK" % kid)
	gs.year = 1
	gs.flags.clear()
	var av_recycle: Dictionary = Activities.availability("virtue_recycle", gs)
	var av_bento: Dictionary = Activities.availability("family_bento", gs)
	var av_garden: Dictionary = Activities.availability("school_garden", gs)
	if not bool(av_recycle.get("ok", false)) or not bool(av_bento.get("ok", false)):
		printerr("[smoke] FAIL: year 1 should allow recycle/bento without a visit")
		act_ok = false
	elif bool(av_garden.get("ok", true)):
		printerr("[smoke] FAIL: year 1 school_garden should wait for a school visit")
		act_ok = false
	else:
		print("[smoke] year 1 recycle/bento open, garden waits for school OK")
	gs.flags["visited_school"] = 1
	gs.flags["visited_shops"] = 1
	gs.flags["visited_clinic"] = 1
	gs.year = 10
	var av_cafe: Dictionary = Activities.availability("work_cafe", gs)
	var av_store10: Dictionary = Activities.availability("work_store", gs)
	var av_tutor10: Dictionary = Activities.availability("work_tutor", gs)
	if not bool(av_cafe.get("ok", false)):
		printerr("[smoke] FAIL: year 10 should unlock work_cafe (%s)" % av_cafe.get("reason", ""))
		act_ok = false
	elif bool(av_store10.get("ok", true)) or bool(av_tutor10.get("ok", true)):
		printerr("[smoke] FAIL: year 10 should still lock store/tutor")
		act_ok = false
	else:
		print("[smoke] year 10 unlocks cafe, locks store/tutor OK")
	gs.year = 11
	var av_store: Dictionary = Activities.availability("work_store", gs)
	var av_tutor: Dictionary = Activities.availability("work_tutor", gs)
	if not bool(av_store.get("ok", false)) or not bool(av_tutor.get("ok", false)):
		printerr("[smoke] FAIL: year 11 should unlock store (%s) and tutor (%s)" % [
			av_store.get("reason", ""), av_tutor.get("reason", "")
		])
		act_ok = false
	else:
		print("[smoke] year 11 unlocks work_store and work_tutor OK")

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

	# Winter year 12 → year_review, then the first adult year (ending waits for year 18)
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
	if gs.pending_ending_after_review:
		printerr("[smoke] FAIL: pending_ending should stay false after y12")
		yr_ok = false
	elif int(gs.year) != 13:
		printerr("[smoke] FAIL: after y12 winter expect year 13 got %d" % gs.year)
		yr_ok = false
	elif str(gs.last_year_review.get("stage_label", "")) != "青年":
		printerr("[smoke] FAIL: y12 stage_label expect 青年 got %s" % str(gs.last_year_review.get("stage_label", "")))
		yr_ok = false
	else:
		print("[smoke] y12 continues into adulthood OK")
	if int(gs.last_year_review.get("year", -1)) != 12:
		printerr("[smoke] FAIL: review year expect 12")
		yr_ok = false
	var cont12: String = gs.continue_after_year_review()
	if cont12 != "hub":
		printerr("[smoke] FAIL: continue after y12 expect hub got %s" % cont12)
		yr_ok = false
	elif gs.is_game_over:
		printerr("[smoke] FAIL: game should still be running after y12")
		yr_ok = false
	else:
		print("[smoke] continue_after_year_review y12 → hub OK")

	# Winter year 18 → year_review then ending
	gs.begin_new_game()
	gs.year = 18
	gs.season = 3
	gs.snapshot_year_start()
	gs.adult_job = "shop_staff"
	gs.year_activity_names = ["黃昏散步"]
	var next18: String = gs.advance_after_season()
	if next18 != "year_review":
		printerr("[smoke] FAIL: winter y18 expect year_review got %s" % next18)
		yr_ok = false
	elif not gs.pending_ending_after_review:
		printerr("[smoke] FAIL: pending_ending_after_review should be true at end of y18")
		yr_ok = false
	elif int(gs.last_year_review.get("year", -1)) != 18:
		printerr("[smoke] FAIL: review year expect 18")
		yr_ok = false
	elif str(gs.last_year_review.get("stage_label", "")) != "成年":
		printerr("[smoke] FAIL: y18 stage_label expect 成年 got %s" % str(gs.last_year_review.get("stage_label", "")))
		yr_ok = false
	else:
		print("[smoke] winter y18 → year_review, pending ending OK")
	var cont18: String = gs.continue_after_year_review()
	if cont18 != "ending":
		printerr("[smoke] FAIL: continue after y18 expect ending got %s" % cont18)
		yr_ok = false
	elif not gs.is_game_over:
		printerr("[smoke] FAIL: is_game_over after y18 review continue")
		yr_ok = false
	else:
		print("[smoke] continue_after_year_review y18 → ending OK")


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

	# —— Phase 9: vignettes, NPC affinity, album, save slots, tutorial flag ——
	var phase9_ok := true
	gs.begin_new_game()
	for aid in Activities.ids():
		var vig: Dictionary = ActivityScenes.get_vignette(str(aid), 0)
		if str(vig.get("title", "")) == "" or str(vig.get("body", "")).length() < 12:
			printerr("[smoke] FAIL vignette text for %s" % str(aid))
			phase9_ok = false
	gs.season_schedule = ["social_friends", "rest_park", "virtue_chores"] as Array[String]
	gs.resolve_season()
	if gs.last_vignettes.size() != 3:
		printerr("[smoke] FAIL last_vignettes size %s" % str(gs.last_vignettes.size()))
		phase9_ok = false
	else:
		print("[smoke] last_vignettes x3 OK")
	var saw_friend := false
	for entry in gs.album:
		if str(entry.get("title", "")) == "週末的同學":
			saw_friend = true
	if not saw_friend:
		printerr("[smoke] FAIL notable vignette missing from album")
		phase9_ok = false
	else:
		print("[smoke] notable vignette in album OK")
	if int(gs.npc_affinity.get("lin_xiaoqing", 0)) < 23:
		printerr("[smoke] FAIL lin affinity after social_friends")
		phase9_ok = false
	else:
		print("[smoke] lin affinity %s OK" % str(gs.npc_affinity.get("lin_xiaoqing", 0)))

	gs.begin_new_game()
	var map_rng := RandomNumberGenerator.new()
	map_rng.seed = 3
	var ev1: Dictionary = gs.trigger_place_event("home", map_rng, true, true)
	var ev2: Dictionary = gs.trigger_place_event("home", map_rng, true, true)
	if bool(ev1.get("skipped", true)) or not bool(ev2.get("skipped", false)):
		printerr("[smoke] FAIL map once-per-place cooldown")
		phase9_ok = false
	elif int(gs.flags.get("visited_home", 0)) != 2:
		printerr("[smoke] FAIL visit count during cooldown")
		phase9_ok = false
	else:
		print("[smoke] map cooldown + visit count OK")

	gs.flags["tutorial_done"] = true
	gs.npc_affinity["chan_auntie"] = 64
	gs.album = [{
		"id": "evt_test",
		"year": 2,
		"season": 1,
		"title": "測試海灘",
		"thumb_path": "res://assets/events/beach.jpg",
		"body": "浪花很淺。",
	}]
	gs.year = 2
	gs.season = 1
	if not gs.save_game(1):
		printerr("[smoke] FAIL save slot 1")
		phase9_ok = false
	var preview: Dictionary = gs.save_slot_preview(1)
	if not bool(preview.get("exists", false)) or int(preview.get("year", -1)) != 2 or str(preview.get("title", "")) != "第二本日記":
		printerr("[smoke] FAIL slot preview %s" % str(preview))
		phase9_ok = false
	elif not str(preview.get("detail", "")).contains("夏"):
		printerr("[smoke] FAIL slot season preview %s" % str(preview.get("detail", "")))
		phase9_ok = false
	else:
		print("[smoke] slot preview %s / %s OK" % [preview.get("title", ""), preview.get("detail", "")])
	gs.begin_new_game()
	if not gs.load_game(1):
		printerr("[smoke] FAIL load slot 1")
		phase9_ok = false
	elif int(gs.npc_affinity.get("chan_auntie", -1)) != 64:
		printerr("[smoke] FAIL npc affinity roundtrip")
		phase9_ok = false
	elif not bool(gs.flags.get("tutorial_done", false)):
		printerr("[smoke] FAIL tutorial flag roundtrip")
		phase9_ok = false
	elif gs.album.is_empty() or str(gs.album[0].get("id", "")) != "evt_test":
		printerr("[smoke] FAIL album roundtrip")
		phase9_ok = false
	else:
		print("[smoke] slot 1 affinity/album/tutorial roundtrip OK")
	gs.delete_save(1)
	if gs.has_save(1) or bool(gs.save_slot_preview(2).get("exists", false)):
		printerr("[smoke] FAIL empty slot preview")
		phase9_ok = false

	gs.begin_new_game()
	gs.npc_affinity["lin_xiaoqing"] = 80
	gs.npc_affinity["chan_auntie"] = 10
	gs.npc_affinity["wong_doctor"] = 10
	gs.mood = 40
	gs.stamina = 40
	gs.charm = 10
	gs.morals = 10
	gs.social = 10
	gs.academia = 10
	gs.cash = 100
	var bond: Dictionary = Endings.evaluate(gs)
	if str(bond.get("id", "")) != "town_bond" or not str(bond.get("summary", "")).contains("林小晴"):
		printerr("[smoke] FAIL town_bond ending %s" % str(bond.get("id", "")))
		phase9_ok = false
	else:
		print("[smoke] town_bond ending OK")

	# —— Mom (family, occasional hub) + biennial travel ——
	var phase10_ok := true
	for rel in [
		"res://assets/family/mom_fullbody_cutout.png",
		"res://assets/family/mom_bust_cutout.png",
		"res://assets/family/mom_portrait.jpg",
		"res://assets/family/family_photo_child.jpg",
		"res://assets/travel/travel_china_family.jpg",
		"res://assets/travel/travel_japan_family.jpg",
		"res://assets/travel/travel_asia_family.jpg",
		"res://assets/travel/travel_europe_family.jpg",
		"res://assets/travel/travel_australia_family.jpg",
		"res://assets/places/place_home.jpg",
		"res://assets/places/place_school.jpg",
		"res://assets/places/place_park.jpg",
		"res://assets/places/place_shops.jpg",
		"res://assets/places/place_clinic.jpg",
		"res://assets/places/place_culture.jpg",
	]:
		if not FileAccess.file_exists(ProjectSettings.globalize_path(rel)):
			printerr("[smoke] FAIL missing art %s" % rel)
			phase10_ok = false
		else:
			print("[smoke] art %s OK" % rel)
	for look_band in AgeLooks.BANDS:
		for rel in [
			"res://assets/family/daughter_%s.png" % look_band,
			"res://assets/family/mom_%s_cutout.png" % look_band,
			"res://assets/family/mom_%s_bust.png" % look_band,
			"res://assets/family/dad_%s.png" % look_band,
			"res://assets/family/family_%s.jpg" % look_band,
		]:
			if not FileAccess.file_exists(ProjectSettings.globalize_path(rel)):
				printerr("[smoke] FAIL missing art %s" % rel)
				phase10_ok = false
			else:
				print("[smoke] art %s OK" % rel)
	if Mom.APPEAR_CHANCE < 0.25 or Mom.APPEAR_CHANCE > 0.35:
		printerr("[smoke] FAIL mom appear chance %s" % str(Mom.APPEAR_CHANCE))
		phase10_ok = false
	if TownNpcs.has_id("mom"):
		printerr("[smoke] FAIL mom must not be a town NPC")
		phase10_ok = false
	else:
		print("[smoke] mom is family, not TownNpcs OK")
	if load("res://scripts/mom.gd") == null or load("res://scripts/travel.gd") == null:
		printerr("[smoke] FAIL mom/travel script")
		phase10_ok = false
	if load("res://scripts/home_hub.gd") == null or load("res://scripts/travel_offer.gd") == null:
		printerr("[smoke] FAIL hub/travel_offer script")
		phase10_ok = false
	if not ResourceLoader.exists("res://scenes/travel_offer.tscn"):
		printerr("[smoke] FAIL travel_offer.tscn")
		phase10_ok = false
	var hub_src := FileAccess.get_file_as_string("res://scripts/home_hub.gd")
	if not hub_src.contains("res://scenes/travel_offer.tscn") or not hub_src.contains("Mom.roll_presence"):
		printerr("[smoke] FAIL hub not wired to mom/travel")
		phase10_ok = false
	if Mom.PIN_PATH != "res://assets/family/mom_fullbody_cutout.png" or Mom.PORTRAIT_PATH != "res://assets/family/mom_bust_cutout.png":
		printerr("[smoke] FAIL mom art paths pin=%s portrait=%s" % [Mom.PIN_PATH, Mom.PORTRAIT_PATH])
		phase10_ok = false
	elif Mom.PIN_PATH.ends_with("mom_portrait.jpg") or Mom.PORTRAIT_PATH.ends_with("mom_portrait.jpg"):
		printerr("[smoke] FAIL hub/dialogue still use mom_portrait.jpg")
		phase10_ok = false
	elif hub_src.contains("mom_portrait.jpg") or not hub_src.contains("AgeLooks.mom_pin"):
		printerr("[smoke] FAIL hub pin not on the fullbody cutout")
		phase10_ok = false
	elif hub_src.contains("border_width_bottom = 16"):
		printerr("[smoke] FAIL mom hub still has a polaroid frame")
		phase10_ok = false
	else:
		print("[smoke] mom cutout paths OK")
	for cut in [Mom.PIN_PATH, Mom.PORTRAIT_PATH]:
		var cut_img := Image.load_from_file(ProjectSettings.globalize_path(cut))
		if cut_img == null or cut_img.detect_alpha() == Image.ALPHA_NONE:
			printerr("[smoke] FAIL cutout missing alpha %s" % cut)
			phase10_ok = false
		else:
			print("[smoke] cutout alpha %s OK" % cut)
	var travel_src := FileAccess.get_file_as_string("res://scripts/travel.gd")
	if travel_src.contains("THUMB_FAMILY_TEMP") or travel_src.contains("family_photo_child.jpg") or travel_src.contains("Temporary thumb"):
		printerr("[smoke] FAIL travel still uses placeholder art")
		phase10_ok = false
	if not travel_src.contains("thumb_for") or not travel_src.contains("age_bands_family"):
		printerr("[smoke] FAIL travel thumbs not age-banded")
		phase10_ok = false
	if load("res://scripts/age_looks.gd") == null:
		printerr("[smoke] FAIL age_looks script")
		phase10_ok = false
	for y_on in [2, 4, 6, 8, 10, 12]:
		if not Travel.is_travel_year(y_on):
			printerr("[smoke] FAIL travel year %d" % y_on)
			phase10_ok = false
	for y_off in [1, 3, 5, 7, 9, 11]:
		if Travel.is_travel_year(y_off):
			printerr("[smoke] FAIL unexpected travel year %d" % y_off)
			phase10_ok = false

	gs.begin_new_game()
	var seeded := false
	for fam_entry in gs.album:
		if str(fam_entry.get("id", "")) == "family_photo_child" and str(fam_entry.get("thumb_path", "")).ends_with("family_early.jpg"):
			seeded = true
	if not seeded:
		printerr("[smoke] FAIL family photo not seeded")
		phase10_ok = false
	else:
		print("[smoke] family album seed OK")

	var mom_rng := RandomNumberGenerator.new()
	mom_rng.seed = 12345
	var mom_hits := 0
	for y_roll in range(1, 13):
		for s_roll in range(4):
			gs.year = y_roll
			gs.season = s_roll
			if Mom.roll_presence(gs, mom_rng):
				mom_hits += 1
	if mom_hits < 4 or mom_hits > 28:
		printerr("[smoke] FAIL mom presence rate %d/48" % mom_hits)
		phase10_ok = false
	else:
		print("[smoke] mom presence %d/48 OK" % mom_hits)
	var seen_count := int(gs.flags.get("mom_seen_count", 0))
	var rolled_again := Mom.roll_presence(gs, mom_rng)
	if rolled_again != Mom.is_present(gs) or int(gs.flags.get("mom_seen_count", 0)) != seen_count:
		printerr("[smoke] FAIL mom roll not sticky per season")
		phase10_ok = false

	gs.begin_new_game()
	gs.flags["mom_rolled_1_0"] = true
	gs.flags["mom_present_1_0"] = true
	var line_a := Mom.advance_dialogue(gs)
	var line_b := Mom.advance_dialogue(gs)
	if line_a == "" or line_a == line_b or int(gs.flags.get("mom_dialogue_index", 0)) != 2:
		printerr("[smoke] FAIL mom dialogue advance")
		phase10_ok = false
	if not gs.save_game(0):
		printerr("[smoke] FAIL mom save")
		phase10_ok = false
	gs.begin_new_game()
	if not gs.load_game(0) or int(gs.flags.get("mom_dialogue_index", -1)) != 2:
		printerr("[smoke] FAIL mom dialogue index roundtrip")
		phase10_ok = false
	elif not bool(gs.flags.get("mom_present_1_0", false)):
		printerr("[smoke] FAIL mom present flag roundtrip")
		phase10_ok = false
	else:
		print("[smoke] mom dialogue/present save OK")
	var help_spec: Dictionary = Mom.help_spec(gs)
	var help_deltas: Dictionary = help_spec.get("deltas", {})
	var cash0 := int(gs.cash)
	var mood0 := int(gs.mood)
	var stam0 := int(gs.stamina)
	var mor0 := int(gs.morals)
	var help: Dictionary = Mom.claim_help(gs)
	if not bool(help.get("ok", false)):
		printerr("[smoke] FAIL mom help %s" % str(help))
		phase10_ok = false
	elif int(gs.cash) != cash0 + int(help_deltas.get("cash", 0)):
		printerr("[smoke] FAIL mom help cash")
		phase10_ok = false
	elif int(gs.mood) != clampi(mood0 + int(help_deltas.get("mood", 0)), 0, 100):
		printerr("[smoke] FAIL mom help mood")
		phase10_ok = false
	elif int(gs.stamina) != clampi(stam0 + int(help_deltas.get("stamina", 0)), 0, 100):
		printerr("[smoke] FAIL mom help stamina")
		phase10_ok = false
	elif int(gs.morals) != clampi(mor0 + int(help_deltas.get("morals", 0)), 0, 100):
		printerr("[smoke] FAIL mom help morals")
		phase10_ok = false
	elif bool(Mom.claim_help(gs).get("ok", true)):
		printerr("[smoke] FAIL mom help repeat")
		phase10_ok = false
	else:
		print("[smoke] mom help once per season OK")
	gs.flags["mom_present_1_0"] = false
	gs.flags.erase("mom_helped_1_0")
	if bool(Mom.claim_help(gs).get("ok", true)):
		printerr("[smoke] FAIL mom help while absent")
		phase10_ok = false
	gs.delete_save(0)

	gs.begin_new_game()
	gs.year = 6
	gs.cash = 999999
	var ids6: Array = Travel.unlocked_ids(gs)
	if ids6.size() != 1 or str(ids6[0]) != "china":
		printerr("[smoke] FAIL elementary unlock %s" % str(ids6))
		phase10_ok = false
	elif Travel.lock_reason(Travel.get_dest("japan"), gs) == "":
		printerr("[smoke] FAIL japan should lock in year 6")
		phase10_ok = false
	else:
		print("[smoke] year 6 china only OK")
	gs.year = 7
	if Travel.lock_reason(Travel.get_dest("japan"), gs) != "":
		printerr("[smoke] FAIL japan should unlock at year 7")
		phase10_ok = false
	if "asia" in Travel.unlocked_ids(gs):
		printerr("[smoke] FAIL asia unlocked too early")
		phase10_ok = false
	gs.year = 8
	var ids8: Array = Travel.unlocked_ids(gs)
	if ids8.size() != 2 or str(ids8[1]) != "japan":
		printerr("[smoke] FAIL year 8 unlock %s" % str(ids8))
		phase10_ok = false
	gs.year = 10
	if Travel.unlocked_ids(gs).size() != 5:
		printerr("[smoke] FAIL year 10 should unlock 5 destinations")
		phase10_ok = false
	elif Travel.lock_reason(Travel.get_dest("europe"), gs) != "" or Travel.lock_reason(Travel.get_dest("australia"), gs) != "":
		printerr("[smoke] FAIL europe/australia lock at year 10")
		phase10_ok = false
	else:
		print("[smoke] destination arc OK")
	var thumb_expect := {
		"china": "travel_china_family.jpg",
		"japan": "travel_japan_family.jpg",
		"asia": "travel_asia_family.jpg",
		"europe": "travel_europe_family.jpg",
		"australia": "travel_australia_family.jpg",
	}
	for dest_id in thumb_expect:
		var thumb_path := str(Travel.get_dest(str(dest_id)).get("thumb", ""))
		var thumb_file: String = str(thumb_expect[dest_id])
		if not thumb_path.ends_with(thumb_file):
			printerr("[smoke] FAIL %s thumb %s" % [dest_id, thumb_path])
			phase10_ok = false
		elif not FileAccess.file_exists(ProjectSettings.globalize_path(thumb_path)):
			printerr("[smoke] FAIL missing thumb file %s" % thumb_path)
			phase10_ok = false
	if phase10_ok:
		print("[smoke] destination stills OK")
	var band_expect := {
		1: "early", 2: "early",
		3: "elementary", 6: "elementary",
		7: "junior", 8: "junior",
		9: "senior", 12: "senior",
		13: "adult", 18: "adult",
	}
	for yb in band_expect:
		if AgeLooks.band_for_year(int(yb)) != str(band_expect[yb]):
			printerr("[smoke] FAIL age band year %s -> %s" % [str(yb), AgeLooks.band_for_year(int(yb))])
			phase10_ok = false
	if AgeLooks.label_for_year(1) != "幼年" or AgeLooks.label_for_year(4) != "國小" or AgeLooks.label_for_year(7) != "國中" or AgeLooks.label_for_year(10) != "高中" or AgeLooks.label_for_year(16) != "成年":
		printerr("[smoke] FAIL age band labels")
		phase10_ok = false
	elif AgeLooks.band_for_age(6) != "early" or AgeLooks.band_for_age(12) != "junior" or AgeLooks.band_for_age(23) != "adult":
		printerr("[smoke] FAIL age_for band")
		phase10_ok = false
	elif AgeLooks.mom_pin(3) != "res://assets/family/mom_elementary_cutout.png" or AgeLooks.mom_pin(14) != "res://assets/family/mom_adult_cutout.png" or AgeLooks.mom_portrait(9) != "res://assets/family/mom_senior_bust.png":
		printerr("[smoke] FAIL mom band art pin=%s bust=%s" % [AgeLooks.mom_pin(3), AgeLooks.mom_portrait(9)])
		phase10_ok = false
	elif AgeLooks.dad_portrait(8) != "res://assets/family/dad_junior.png":
		printerr("[smoke] FAIL dad band art %s" % AgeLooks.dad_portrait(8))
		phase10_ok = false
	elif not str(AgeLooks.family_photo(1)).ends_with("family_early.jpg") or not str(AgeLooks.family_photo(15)).ends_with("family_adult.jpg"):
		printerr("[smoke] FAIL family photo band %s / %s" % [AgeLooks.family_photo(1), AgeLooks.family_photo(15)])
		phase10_ok = false
	elif AgeLooks.daughter_portrait(16, 2) != "res://assets/family/daughter_adult.png":
		printerr("[smoke] FAIL daughter band art %s" % AgeLooks.daughter_portrait(16, 2))
		phase10_ok = false
	elif Travel.thumb_for("japan", 2) != "res://assets/album/travel_japan_early.jpg" or Travel.thumb_for("japan", 8) != "res://assets/album/travel_japan_junior.jpg":
		printerr("[smoke] FAIL japan age-band thumb %s / %s" % [Travel.thumb_for("japan", 2), Travel.thumb_for("japan", 8)])
		phase10_ok = false
	elif Travel.thumb_for("japan", 18) != str(Travel.get_dest("japan").get("thumb", "")) or Travel.thumb_for("japan", 8) == Travel.thumb_for("japan", 18):
		printerr("[smoke] FAIL japan adult thumb fallback %s" % Travel.thumb_for("japan", 18))
		phase10_ok = false
	elif Travel.thumb_for("europe", 12) != "res://assets/album/travel_europe_senior.jpg":
		printerr("[smoke] FAIL europe thumb_for %s" % Travel.thumb_for("europe", 12))
		phase10_ok = false
	else:
		print("[smoke] age_bands_family portraits OK")

	gs.begin_new_game()
	gs.year = 3
	gs.season = 1
	if Travel.offer_due(gs) or bool(Travel.depart(gs, "china").get("ok", true)):
		printerr("[smoke] FAIL odd year should not travel")
		phase10_ok = false
	gs.year = 2
	gs.season = 0
	if Travel.offer_due(gs):
		printerr("[smoke] FAIL spring should not offer travel")
		phase10_ok = false
	gs.season = 1
	if not Travel.offer_due(gs):
		printerr("[smoke] FAIL summer offer")
		phase10_ok = false
	var trip_cost := int(Travel.get_dest("china").get("cost", 0))
	gs.cash = trip_cost - 1
	gs.season_schedule[0] = "rest_sleep"
	gs.season_schedule[1] = "rest_park"
	gs.season_schedule[2] = "virtue_chores"
	var poor: Dictionary = Travel.depart(gs, "china")
	if bool(poor.get("ok", true)) or not str(poor.get("reason", "")).contains("家計不足") or int(gs.cash) != trip_cost - 1:
		printerr("[smoke] FAIL cash lock %s" % str(poor))
		phase10_ok = false
	elif not Travel.offer_due(gs):
		printerr("[smoke] FAIL failed depart closed the window")
		phase10_ok = false
	else:
		print("[smoke] travel cash lock OK")
	gs.cash = trip_cost + 50
	var mood_before := int(gs.mood)
	var went: Dictionary = Travel.depart(gs, "china")
	var mood_delta := int(Travel.get_dest("china").get("deltas", {}).get("mood", 0))
	if not bool(went.get("ok", false)):
		printerr("[smoke] FAIL depart %s" % str(went))
		phase10_ok = false
	elif int(gs.cash) != 50:
		printerr("[smoke] FAIL depart cash %d" % int(gs.cash))
		phase10_ok = false
	elif int(gs.mood) != clampi(mood_before + mood_delta, 0, 100):
		printerr("[smoke] FAIL depart mood")
		phase10_ok = false
	elif str(gs.flags.get("travel_window_2", "")) != "summer" or str(gs.flags.get("travel_dest_2", "")) != "china":
		printerr("[smoke] FAIL travel flags")
		phase10_ok = false
	elif str(gs.season_schedule[0]) != "rest_sleep" or str(gs.season_schedule[2]) != "virtue_chores":
		printerr("[smoke] FAIL travel changed the monthly schedule")
		phase10_ok = false
	elif Travel.offer_due(gs) or bool(Travel.depart(gs, "china").get("ok", true)):
		printerr("[smoke] FAIL travel window repeated")
		phase10_ok = false
	else:
		var saw_trip := false
		for trip_entry in gs.album:
			if str(trip_entry.get("id", "")) == "travel_china_y2":
				saw_trip = str(trip_entry.get("thumb_path", "")) == "res://assets/album/travel_china_early.jpg"
				if not str(trip_entry.get("body", "")).contains("媽媽"):
					saw_trip = false
		if not saw_trip:
			printerr("[smoke] FAIL china album entry")
			phase10_ok = false
		else:
			print("[smoke] china depart album/stats/schedule OK")

	gs.begin_new_game()
	gs.year = 4
	gs.season = 1
	if not Travel.skip_window(gs) or Travel.offer_due(gs):
		printerr("[smoke] FAIL skip")
		phase10_ok = false
	gs.season = 3
	if Travel.offer_due(gs):
		printerr("[smoke] FAIL skip should close winter too")
		phase10_ok = false
	else:
		print("[smoke] travel skip OK")

	gs.begin_new_game()
	gs.year = 8
	gs.season = 1
	gs.cash = 99999
	if not Travel.defer_to_winter(gs) or Travel.offer_due(gs) or Travel.hub_hint(gs) == "":
		printerr("[smoke] FAIL defer")
		phase10_ok = false
	gs.season = 2
	if Travel.offer_due(gs):
		printerr("[smoke] FAIL autumn should not depart")
		phase10_ok = false
	gs.season = 3
	if not Travel.offer_due(gs):
		printerr("[smoke] FAIL winter offer after defer")
		phase10_ok = false
	var jp: Dictionary = Travel.depart(gs, "japan")
	if not bool(jp.get("ok", false)) or str(gs.flags.get("travel_window_8", "")) != "winter":
		printerr("[smoke] FAIL japan winter depart %s" % str(jp))
		phase10_ok = false
	elif not bool(jp.get("with_mom", false)):
		printerr("[smoke] FAIL japan trip should include mom")
		phase10_ok = false
	else:
		print("[smoke] defer + japan winter OK")

	gs.begin_new_game()
	gs.year = 12
	gs.season = 3
	if not Travel.offer_due(gs):
		printerr("[smoke] FAIL unresolved winter should still offer")
		phase10_ok = false

	gs.begin_new_game()
	gs.year = 2
	gs.season = 1
	gs.cash = 8000
	var offer_packed = load("res://scenes/travel_offer.tscn")
	if offer_packed == null:
		printerr("[smoke] FAIL travel_offer scene load")
		phase10_ok = false
	else:
		var offer_node: Node = offer_packed.instantiate()
		root.add_child(offer_node)
		if offer_node.get_child_count() < 1:
			printerr("[smoke] FAIL travel_offer built no UI")
			phase10_ok = false
		else:
			print("[smoke] travel_offer scene builds OK")
		offer_node.free()

	if phase10_ok:
		print("[smoke] mom + travel OK")

	var phase11_ok := true
	var confide_rng := RandomNumberGenerator.new()
	confide_rng.seed = 20261021
	if gs.daughter_name_error("   ") != "名字還空著。":
		printerr("[smoke] FAIL blank daughter name")
		phase11_ok = false
	if gs.daughter_name_error("  阿禾  ") != "" or gs.daughter_name_error("小悠") != "":
		printerr("[smoke] FAIL warm names should pass")
		phase11_ok = false
	if gs.daughter_name_error("一二三四五六七八") != "":
		printerr("[smoke] FAIL 8-char name")
		phase11_ok = false
	if gs.daughter_name_error("一二三四五六七八九") != "八個字以內就好。":
		printerr("[smoke] FAIL 9-char name")
		phase11_ok = false
	if gs.daughter_name_error("小\n悠") != "這個名字寫不進日記。":
		printerr("[smoke] FAIL newline name")
		phase11_ok = false
	if gs.daughter_name_error("小%悠") != "這個符號先不要寫進名字。":
		printerr("[smoke] FAIL percent name")
		phase11_ok = false

	gs.begin_new_game("  阿禾  ")
	if str(gs.daughter_name) != "阿禾" or not str(gs.get_time_label()).contains("阿禾"):
		printerr("[smoke] FAIL daughter name not in time label: %s" % str(gs.get_time_label()))
		phase11_ok = false
	var saw_named_photo := false
	for named_page in gs.album:
		if str(named_page.get("id", "")) == "family_photo_child" and str(named_page.get("body", "")).contains("阿禾"):
			saw_named_photo = true
	if not saw_named_photo:
		printerr("[smoke] FAIL family album caption missing name")
		phase11_ok = false
	if not str(Mom.peek_line(gs)).contains("阿禾"):
		printerr("[smoke] FAIL mom line missing name: %s" % Mom.peek_line(gs))
		phase11_ok = false
	gs.wants_new_game_name = true
	var name_dump: Dictionary = gs.to_dict()
	if name_dump.has("wants_new_game_name") or str(name_dump.get("daughter_name", "")) != "阿禾":
		printerr("[smoke] FAIL daughter_name save shape")
		phase11_ok = false
	if not gs.save_game(0):
		printerr("[smoke] FAIL named save")
		phase11_ok = false
	gs.begin_new_game()
	if str(gs.daughter_name) != "小悠":
		printerr("[smoke] FAIL new game should reset to 小悠")
		phase11_ok = false
	var preview_named: Dictionary = gs.save_slot_preview(0)
	if not str(preview_named.get("detail", "")).contains("阿禾"):
		printerr("[smoke] FAIL slot preview name: %s" % str(preview_named.get("detail", "")))
		phase11_ok = false
	gs.wants_new_game_name = true
	if not gs.load_game(0) or str(gs.daughter_name) != "阿禾" or bool(gs.wants_new_game_name):
		printerr("[smoke] FAIL daughter_name load")
		phase11_ok = false
	else:
		print("[smoke] daughter name save/load OK")
	gs.delete_save(0)

	gs.begin_new_game("一二三四五六七八九")
	if str(gs.daughter_name) != "小悠":
		printerr("[smoke] FAIL overlong name should stay default")
		phase11_ok = false

	gs.year = 3
	var child_pick: Dictionary = Confide.pick_line(gs, confide_rng)
	gs.year = 9
	var teen_pick: Dictionary = Confide.pick_line(gs, confide_rng)
	if not str(child_pick.get("id", "")).begins_with("child_") or not str(teen_pick.get("id", "")).begins_with("teen_"):
		printerr("[smoke] FAIL age pools %s / %s" % [str(child_pick.get("id", "")), str(teen_pick.get("id", ""))])
		phase11_ok = false
	var seat_line: Dictionary = Confide.get_line("child_worry_seat")
	var seat_opts: Array = seat_line.get("options", [])
	var seat_delta: Dictionary = {}
	if seat_opts.size() < 2 or seat_opts.size() > 3:
		printerr("[smoke] FAIL confide option count")
		phase11_ok = false
	else:
		seat_delta = seat_opts[0].get("deltas", {})

	gs.begin_new_game()
	if bool(Confide.apply_choice(gs, "no_such_line", 0).get("ok", true)):
		printerr("[smoke] FAIL invalid confide id")
		phase11_ok = false
	if bool(Confide.apply_choice(gs, "child_worry_seat", 9).get("ok", true)):
		printerr("[smoke] FAIL invalid confide index")
		phase11_ok = false
	var mood_seat := int(gs.mood)
	var warmth_before := int(gs.flags.get("mom_warmth", -1))
	var chosen: Dictionary = Confide.apply_choice(gs, "child_worry_seat", 0)
	if not bool(chosen.get("ok", false)):
		printerr("[smoke] FAIL confide choice")
		phase11_ok = false
	elif int(gs.mood) != clampi(mood_seat + int(seat_delta.get("mood", 0)), 0, 100):
		printerr("[smoke] FAIL confide mood")
		phase11_ok = false
	elif warmth_before != 70 or int(chosen.get("warmth", 0)) < 1:
		printerr("[smoke] FAIL confide warmth bump")
		phase11_ok = false
	elif int(gs.flags.get("mom_warmth", -1)) != warmth_before + int(chosen.get("warmth", 0)):
		printerr("[smoke] FAIL mom_warmth flag")
		phase11_ok = false
	elif not str(chosen.get("reply", "")).contains("小悠"):
		printerr("[smoke] FAIL confide reply name")
		phase11_ok = false
	elif bool(Confide.apply_choice(gs, "child_worry_seat", 0).get("ok", true)):
		printerr("[smoke] FAIL confide twice in one season")
		phase11_ok = false
	else:
		gs.flags["tutorial_done"] = true
		gs.months_played = 1
		if not Confide.offer_for(gs, confide_rng).is_empty() or bool(gs.flags.get("confide_rolled_1_0", false)):
			printerr("[smoke] FAIL confide offered after it was answered")
			phase11_ok = false
		else:
			print("[smoke] confide choice OK")

	gs.begin_new_game()
	var blocked_tutorial: Dictionary = Confide.offer_for(gs, confide_rng)
	if not blocked_tutorial.is_empty() or bool(gs.flags.get("confide_rolled_1_0", false)):
		printerr("[smoke] FAIL confide during tutorial")
		phase11_ok = false
	gs.begin_new_game()
	gs.flags["tutorial_done"] = true
	gs.months_played = 1
	gs.flags["mom_present_1_0"] = true
	if not Confide.can_offer(gs):
		printerr("[smoke] FAIL mom home should still allow a family line")
		phase11_ok = false
	gs.begin_new_game()
	gs.flags["tutorial_done"] = true
	gs.months_played = 1
	gs.flags["mom_helped_1_0"] = true
	var blocked_help: Dictionary = Confide.offer_for(gs, confide_rng)
	if not blocked_help.is_empty() or bool(gs.flags.get("confide_rolled_1_0", false)):
		printerr("[smoke] FAIL confide after mom help")
		phase11_ok = false
	else:
		print("[smoke] confide blocked by tutorial/mom OK")

	var family_rng := RandomNumberGenerator.new()
	family_rng.seed = 20261028
	var allowed_delta_keys := ["mood", "social", "morals", "stamina"]
	var saw_grow := false
	var saw_praise := false
	var saw_mom_line := false
	var saw_parents_line := false
	for family_line in Confide.LINES:
		var family_id := str(family_line.get("id", ""))
		var family_hearer := Confide.hearer_of(family_line)
		if family_id in ["child_worry_grow", "teen_worry_grow", "teen_worry_tell"]:
			saw_grow = true
		if family_id in ["child_cling_praise", "teen_cling_praise", "child_cling_mom"]:
			saw_praise = true
		if family_hearer == "mom":
			saw_mom_line = true
		elif family_hearer == "parents":
			saw_parents_line = true
		if DialogueChrome.theme_for_confide(family_id) == "":
			printerr("[smoke] FAIL confide theme missing %s" % family_id)
			phase11_ok = false
		var family_opts: Array = family_line.get("options", [])
		if family_opts.size() < 2 or family_opts.size() > 3:
			printerr("[smoke] FAIL confide option count %s" % family_id)
			phase11_ok = false
		if (family_hearer == "mom" or family_hearer == "parents") and not str(family_line.get("body", "")).contains("媽媽"):
			printerr("[smoke] FAIL family line missing mom %s" % family_id)
			phase11_ok = false
		for family_opt in family_opts:
			if typeof(family_opt) != TYPE_DICTIONARY:
				continue
			var family_deltas: Dictionary = family_opt.get("deltas", {})
			for family_key in family_deltas.keys():
				var family_amount := int(family_deltas[family_key])
				if not allowed_delta_keys.has(str(family_key)) or absi(family_amount) > 5 or family_amount == 0:
					printerr("[smoke] FAIL confide delta %s %s" % [family_id, str(family_key)])
					phase11_ok = false
			var family_warmth := int(family_opt.get("warmth", 0))
			if family_warmth < 0 or family_warmth > 1:
				printerr("[smoke] FAIL confide warmth range %s" % family_id)
				phase11_ok = false
	if not saw_grow or not saw_praise or not saw_mom_line or not saw_parents_line:
		printerr("[smoke] FAIL confide pools grow=%s praise=%s mom=%s parents=%s" % [str(saw_grow), str(saw_praise), str(saw_mom_line), str(saw_parents_line)])
		phase11_ok = false

	gs.begin_new_game()
	gs.year = 4
	gs.season = 0
	var dad_worry := false
	var dad_cling := false
	for _dad_i in range(30):
		var dad_line: Dictionary = Confide.pick_line(gs, family_rng)
		if Confide.hearer_of(dad_line) != "dad" or not str(dad_line.get("id", "")).begins_with("child_"):
			printerr("[smoke] FAIL dad confide pool %s" % str(dad_line.get("id", "")))
			phase11_ok = false
			break
		if str(dad_line.get("tone", "")) == "worry":
			dad_worry = true
		elif str(dad_line.get("tone", "")) == "cling":
			dad_cling = true
	gs.flags["mom_present_4_0"] = true
	var home_mom := false
	var home_parents := false
	for _home_i in range(40):
		var home_line: Dictionary = Confide.pick_line(gs, family_rng)
		var home_hearer := Confide.hearer_of(home_line)
		if home_hearer == "mom":
			home_mom = true
		elif home_hearer == "parents":
			home_parents = true
		else:
			printerr("[smoke] FAIL mom-home confide hearer %s" % str(home_line.get("id", "")))
			phase11_ok = false
			break
		if not str(home_line.get("id", "")).begins_with("child_"):
			printerr("[smoke] FAIL mom-home band %s" % str(home_line.get("id", "")))
			phase11_ok = false
			break
	if not dad_worry or not dad_cling or not home_mom or not home_parents:
		printerr("[smoke] FAIL hearer coverage dad=%s/%s home=%s/%s" % [str(dad_worry), str(dad_cling), str(home_mom), str(home_parents)])
		phase11_ok = false

	gs.begin_new_game()
	gs.year = 9
	gs.season = 1
	gs.flags["mom_present_9_1"] = true
	var teen_home := false
	for _teen_i in range(24):
		var teen_home_line: Dictionary = Confide.pick_line(gs, family_rng)
		if not str(teen_home_line.get("id", "")).begins_with("teen_") or Confide.hearer_of(teen_home_line) == "dad":
			printerr("[smoke] FAIL teen mom-home %s" % str(teen_home_line.get("id", "")))
			phase11_ok = false
			break
		teen_home = true
	if not teen_home:
		printerr("[smoke] FAIL teen mom-home empty")
		phase11_ok = false

	gs.begin_new_game()
	gs.year = 3
	gs.season = 0
	gs.flags["tutorial_done"] = true
	gs.months_played = 4
	var grow_choice: Dictionary = Confide.apply_choice(gs, "child_worry_grow", 0)
	if not bool(grow_choice.get("ok", false)) or not str(grow_choice.get("reply", "")).contains("小悠"):
		printerr("[smoke] FAIL grow choice")
		phase11_ok = false
	gs.season = 1
	if not Confide.offer_for(gs, family_rng).is_empty() or not bool(gs.flags.get("confide_rolled_3_1", false)):
		printerr("[smoke] FAIL confide cooldown")
		phase11_ok = false
	elif not Confide.offer_for(gs, family_rng).is_empty():
		printerr("[smoke] FAIL confide cooldown held")
		phase11_ok = false
	else:
		print("[smoke] confide family hearers + cooldown OK")

	gs.begin_new_game()
	gs.year = 13
	gs.season = 0
	gs.months_played = 144
	gs.flags["tutorial_done"] = true
	gs.education_path = "undecided"
	if not Confide.offer_for(gs, family_rng).is_empty() or bool(gs.flags.get("confide_rolled_13_0", false)):
		printerr("[smoke] FAIL confide during education fork")
		phase11_ok = false
	gs.education_path = "university"
	if not Confide.offer_for(gs, family_rng).is_empty() or bool(gs.flags.get("confide_rolled_13_0", false)):
		printerr("[smoke] FAIL confide before adult job card")
		phase11_ok = false
	gs.flags["adult_job_intro_done"] = true
	gs.romance = 10
	gs.season_schedule = ["", "", ""] as Array[String]
	var schedule_before: Array = gs.season_schedule.duplicate()
	var adult_choice: Dictionary = Confide.apply_choice(gs, "adult_worry_late", 0)
	var family_lock: Dictionary = Activities.availability("family_meet", gs)
	if not bool(adult_choice.get("ok", false)):
		printerr("[smoke] FAIL adult confide choice")
		phase11_ok = false
	elif int(gs.romance) != 10 or str(gs.season_schedule) != str(schedule_before) or bool(family_lock.get("ok", true)):
		printerr("[smoke] FAIL confide touched adult schedule romance=%d lock=%s" % [int(gs.romance), str(family_lock)])
		phase11_ok = false
	elif Confide.chance_for(gs) != Confide.ADULT_CONFIDE_CHANCE:
		printerr("[smoke] FAIL adult confide chance")
		phase11_ok = false
	else:
		gs.flags["mom_present_13_0"] = true
		var adult_home: Dictionary = Confide.pick_line(gs, family_rng)
		if not str(adult_home.get("id", "")).begins_with("adult_") or Confide.hearer_of(adult_home) == "dad":
			printerr("[smoke] FAIL adult mom-home %s" % str(adult_home.get("id", "")))
			phase11_ok = false
		else:
			print("[smoke] adult confide respects schedule locks OK")

	gs.begin_new_game()
	gs.flags["tutorial_done"] = true
	gs.months_played = 3
	var confide_hits := 0
	var conf_offer: Dictionary = {}
	var conf_again: Dictionary = {}
	for cy in range(1, 13):
		for cs in range(4):
			gs.year = cy
			gs.season = cs
			conf_offer = Confide.offer_for(gs, confide_rng)
			if conf_offer.is_empty():
				conf_again = Confide.offer_for(gs, confide_rng)
				if not conf_again.is_empty():
					printerr("[smoke] FAIL quiet season spoke again")
					phase11_ok = false
			else:
				confide_hits += 1
				if not str(conf_offer.get("body", "")).contains(str(gs.daughter_display_name())):
					printerr("[smoke] FAIL confide body unnamed")
					phase11_ok = false
				var conf_opts: Array = conf_offer.get("options", [])
				if conf_opts.size() < 2 or conf_opts.size() > 3:
					printerr("[smoke] FAIL confide presented option count")
					phase11_ok = false
				conf_again = Confide.offer_for(gs, confide_rng)
				if str(conf_again.get("id", "")) != str(conf_offer.get("id", "")):
					printerr("[smoke] FAIL pending confide changed")
					phase11_ok = false
				elif str(gs.flags.get("confide_last_id", "")) != str(conf_offer.get("id", "")):
					printerr("[smoke] FAIL confide_last_id")
					phase11_ok = false
	if confide_hits < 2 or confide_hits > 30:
		printerr("[smoke] FAIL confide rate %d/48" % confide_hits)
		phase11_ok = false
	else:
		print("[smoke] confide rate %d/48 OK" % confide_hits)

	gs.begin_new_game("阿禾")
	gs.year = 2
	gs.season = 1
	gs.cash = 9000
	var named_trip: Dictionary = Travel.depart(gs, "china")
	var saw_named_trip := false
	if not bool(named_trip.get("ok", false)):
		printerr("[smoke] FAIL named trip %s" % str(named_trip))
		phase11_ok = false
	else:
		for named_trip_page in gs.album:
			if str(named_trip_page.get("id", "")) == "travel_china_y2":
				var trip_body := str(named_trip_page.get("body", ""))
				saw_named_trip = trip_body.contains("阿禾") and trip_body.contains("媽媽")
	if not saw_named_trip:
		printerr("[smoke] FAIL travel vignette name")
		phase11_ok = false

	var title_src := FileAccess.get_file_as_string("res://scripts/title.gd")
	var new_game_fn := ""
	if title_src.contains("func _on_new_game"):
		new_game_fn = title_src.split("func _on_new_game", true, 1)[1].split("func ", true, 1)[0]
	if not title_src.contains("返回封面") or not title_src.contains("寫下名字") or not title_src.contains("DEFAULT_DAUGHTER_NAME") or new_game_fn.contains("begin_new_game"):
		printerr("[smoke] FAIL title name panel source")
		phase11_ok = false
	gs.year = 4
	gs.wants_new_game_name = true
	var title_packed = load("res://scenes/title.tscn")
	if title_packed == null:
		printerr("[smoke] FAIL title scene for name panel")
		phase11_ok = false
	else:
		var title_node: Node = title_packed.instantiate()
		root.add_child(title_node)
		var name_layer: Node = title_node.get_node_or_null("NameLayer")
		var name_edit: LineEdit = null
		var found_back := false
		var scan: Array = [title_node]
		while scan.size() > 0:
			var scan_node: Node = scan.pop_back()
			if scan_node is LineEdit and name_edit == null:
				name_edit = scan_node
			if scan_node is Button and str(scan_node.text) == "返回封面":
				found_back = true
			for scan_child in scan_node.get_children():
				scan.append(scan_child)
		if name_layer == null or not bool(name_layer.get("visible")) or name_edit == null or str(name_edit.text) != "小悠" or not found_back or int(gs.year) != 4:
			printerr("[smoke] FAIL name panel did not open before the game")
			phase11_ok = false
		else:
			title_node.call("_on_name_cancel")
			if bool(gs.wants_new_game_name) or bool(name_layer.get("visible")) or int(gs.year) != 4:
				printerr("[smoke] FAIL name cancel should stay on the title")
				phase11_ok = false
			else:
				print("[smoke] name panel open/cancel OK")
		title_node.free()
	var ending_src := FileAccess.get_file_as_string("res://scripts/ending.gd")
	if not ending_src.contains("wants_new_game_name"):
		printerr("[smoke] FAIL ending should return to the name panel")
		phase11_ok = false
	var hub_confide_src := FileAccess.get_file_as_string("res://scripts/home_hub.gd")
	if not hub_confide_src.contains("Confide.offer_for") or not hub_confide_src.contains("想跟媽媽說") or not hub_confide_src.contains("想跟你們說"):
		printerr("[smoke] FAIL hub confide hook")
		phase11_ok = false
	if load("res://scripts/confide.gd") == null or load("res://scripts/title.gd") == null or load("res://scripts/home_hub.gd") == null:
		printerr("[smoke] FAIL script load name/confide")
		phase11_ok = false

	if phase11_ok:
		print("[smoke] name + confide OK")

	var phase12_ok := true
	if GrowthPath.level_for_xp(0) != 0 or GrowthPath.level_for_xp(1) != 1 or GrowthPath.level_for_xp(2) != 1:
		printerr("[smoke] FAIL skill level low xp")
		phase12_ok = false
	if GrowthPath.level_for_xp(3) != 2 or GrowthPath.level_for_xp(6) != 3 or GrowthPath.level_for_xp(20) != 3:
		printerr("[smoke] FAIL skill level high xp")
		phase12_ok = false
	gs.begin_new_game()
	gs.year = 6
	var piano_av6: Dictionary = Activities.availability("study_piano", gs)
	if bool(piano_av6.get("ok", true)):
		printerr("[smoke] FAIL piano should wait for year 7")
		phase12_ok = false
	gs.apply_activity("study_piano")
	GrowthPath.grant(gs, "study_piano")
	if GrowthPath.xp_of(gs, "piano") != 0 or GrowthPath.points_of(gs, "art") != 0:
		printerr("[smoke] FAIL elementary months granted skills")
		phase12_ok = false
	gs.year = 7
	var piano_av7: Dictionary = Activities.availability("study_piano", gs)
	var lang_av: Dictionary = Activities.availability("study_language", gs)
	var code_av: Dictionary = Activities.availability("study_code", gs)
	if not bool(piano_av7.get("ok", false)) or not bool(lang_av.get("ok", false)) or not bool(code_av.get("ok", false)):
		printerr("[smoke] FAIL year 7 classes %s %s %s" % [str(piano_av7), str(lang_av), str(code_av)])
		phase12_ok = false
	gs.apply_activity("study_piano")
	gs.apply_activity("study_piano")
	if GrowthPath.xp_of(gs, "piano") != 4 or GrowthPath.level_of(gs, "piano") != 2:
		printerr("[smoke] FAIL piano xp/level %d/%d" % [GrowthPath.xp_of(gs, "piano"), GrowthPath.level_of(gs, "piano")])
		phase12_ok = false
	elif GrowthPath.points_of(gs, "art") != 4:
		printerr("[smoke] FAIL art tag")
		phase12_ok = false
	elif str(gs.education_path) != "undecided":
		printerr("[smoke] FAIL education_path default")
		phase12_ok = false
	else:
		print("[smoke] middle-school skills OK")
	gs.education_path = "university"
	if not gs.save_game(0):
		printerr("[smoke] FAIL skill save")
		phase12_ok = false
	gs.begin_new_game()
	if GrowthPath.xp_of(gs, "piano") != 0 or str(gs.education_path) != "undecided":
		printerr("[smoke] FAIL new game did not clear skills")
		phase12_ok = false
	if not gs.load_game(0) or GrowthPath.xp_of(gs, "piano") != 4 or GrowthPath.points_of(gs, "art") != 4:
		printerr("[smoke] FAIL skill load")
		phase12_ok = false
	elif str(gs.education_path) != "university":
		printerr("[smoke] FAIL education_path roundtrip")
		phase12_ok = false
	else:
		print("[smoke] skill save/load OK")
	gs.delete_save(0)

	gs.begin_new_game()
	gs.academia = 70
	gs.morals = 55
	gs.stamina = 45
	gs.social = 55
	gs.charm = 30
	gs.mood = 50
	gs.cash = 100
	var plain_end: Dictionary = Endings.evaluate(gs)
	if str(plain_end.get("id", "")) != "doctor":
		printerr("[smoke] FAIL unbiased ending %s" % str(plain_end.get("id", "")))
		phase12_ok = false
	gs.skill_xp["speech"] = 6
	gs.interest_points["letters"] = 8
	if GrowthPath.ending_bonus("teacher", gs) != 6 or GrowthPath.ending_bonus("doctor", gs) != 0:
		printerr("[smoke] FAIL ending bonus teacher %d doctor %d" % [GrowthPath.ending_bonus("teacher", gs), GrowthPath.ending_bonus("doctor", gs)])
		phase12_ok = false
	var biased_end: Dictionary = Endings.evaluate(gs)
	if str(biased_end.get("id", "")) != "teacher":
		printerr("[smoke] FAIL tag bias ending %s" % str(biased_end.get("id", "")))
		phase12_ok = false
	else:
		print("[smoke] ending tag bias OK")
	var growth_hub_src := FileAccess.get_file_as_string("res://scripts/home_hub.gd")
	if not growth_hub_src.contains("翻開專長") or not growth_hub_src.contains("growth_tutorial_done"):
		printerr("[smoke] FAIL hub growth UI")
		phase12_ok = false
	if load("res://scripts/growth_path.gd") == null:
		printerr("[smoke] FAIL growth_path load")
		phase12_ok = false
	if phase12_ok:
		print("[smoke] skills + tags OK")

	var phase13_ok := true
	var adult_art := GameConfig.wardrobe_path_for_year_season(16, 2)
	var youth_art := GameConfig.wardrobe_path(5, 2)
	if adult_art == "":
		printerr("[smoke] FAIL adult portrait path empty")
		phase13_ok = false
	elif not adult_art.contains("adult_y16_") and adult_art != youth_art:
		printerr("[smoke] FAIL adult portrait should reuse youth or adult_y16, got %s" % adult_art)
		phase13_ok = false
	else:
		print("[smoke] adult portrait fallback %s OK" % adult_art)
	var cfg_src := FileAccess.get_file_as_string("res://scripts/config.gd")
	if not cfg_src.contains("adult_y") or not cfg_src.contains("TODO"):
		printerr("[smoke] FAIL adult portrait TODO missing")
		phase13_ok = false
	if GameConfig.life_phase_label(18) != "成年" or GameConfig.age_for_year(18) != 23 or GameConfig.age_for_year(13) != 18:
		printerr("[smoke] FAIL adult age/phase")
		phase13_ok = false
	if GameConfig.TOTAL_YEARS != 18 or GameConfig.TOTAL_MONTHS != 216:
		printerr("[smoke] FAIL year length")
		phase13_ok = false

	gs.begin_new_game()
	gs.year = 12
	if Activities.is_available("date_walk", gs) or Activities.shown_in_picker("date_walk", gs):
		printerr("[smoke] FAIL dating should wait for adulthood")
		phase13_ok = false
	if not Activities.is_available("study_piano", gs):
		printerr("[smoke] FAIL piano should still be open in year 12")
		phase13_ok = false
	gs.year = 13
	gs.mood = 70
	gs.cash = 8000
	if not Activities.is_available("date_walk", gs) or not Activities.shown_in_picker("date_walk", gs):
		printerr("[smoke] FAIL date_walk should open in year 13")
		phase13_ok = false
	if Activities.is_available("study_piano", gs) or Activities.shown_in_picker("study_library", gs):
		printerr("[smoke] FAIL school months should leave the adult picker")
		phase13_ok = false
	if Activities.shown_in_picker("rest_park", gs) == false:
		printerr("[smoke] FAIL rest should stay in the adult picker")
		phase13_ok = false
	var fam_locked: Dictionary = Activities.availability("family_meet", gs)
	if bool(fam_locked.get("ok", true)):
		printerr("[smoke] FAIL family act should wait for romance")
		phase13_ok = false
	gs.apply_activity("date_walk")
	if int(gs.romance) != 8:
		printerr("[smoke] FAIL romance after one date got %d" % int(gs.romance))
		phase13_ok = false
	gs.romance = 48
	gs.apply_activity("family_meet")
	gs.apply_activity("family_talk")
	if int(gs.family_prep) < 2 or not gs.family_settled:
		printerr("[smoke] FAIL family branch prep=%d settled=%s romance=%d" % [int(gs.family_prep), str(gs.family_settled), int(gs.romance)])
		phase13_ok = false
	else:
		print("[smoke] romance meter + optional family OK")

	gs.begin_new_game()
	gs.year = 13
	var only_shop: Array = Adulthood.available_jobs(gs)
	if only_shop.size() != 1 or str(only_shop[0].get("id", "")) != "shop_staff":
		printerr("[smoke] FAIL empty skills should only offer shop, got %d" % only_shop.size())
		phase13_ok = false
	gs.interest_points["art"] = 4
	gs.skill_xp["paint"] = 3
	var art_jobs: Array = Adulthood.available_jobs(gs)
	if art_jobs.is_empty() or str(art_jobs[0].get("id", "")) != "design_studio":
		printerr("[smoke] FAIL art job rank %s" % str(art_jobs))
		phase13_ok = false
	var saw_shop := false
	for art_job in art_jobs:
		if str(art_job.get("id", "")) == "shop_staff":
			saw_shop = true
	if not saw_shop:
		printerr("[smoke] FAIL shop fallback missing from art pool")
		phase13_ok = false
	gs.skill_xp = {}
	gs.interest_points = {}
	gs.education_path = "letters"
	var edu_ids: PackedStringArray = []
	var edu_jobs: Array = Adulthood.available_jobs(gs)
	for edu_job in edu_jobs:
		edu_ids.append(str(edu_job.get("id", "")))
	if not edu_ids.has("school_aide") or str(edu_jobs[0].get("id", "")) == "shop_staff":
		printerr("[smoke] FAIL education_path letters bias %s" % str(edu_ids))
		phase13_ok = false
	gs.education_path = "university"
	var uni_ids: PackedStringArray = []
	var uni_jobs: Array = Adulthood.available_jobs(gs)
	for uni_job in uni_jobs:
		uni_ids.append(str(uni_job.get("id", "")))
	if not uni_ids.has("clinic_aide") or not uni_ids.has("school_aide") or not uni_ids.has("desk_writer") or not uni_ids.has("shop_staff"):
		printerr("[smoke] FAIL university pool %s" % str(uni_ids))
		phase13_ok = false
	elif uni_ids.has("cafe_shift") or str(uni_jobs[0].get("id", "")) != "school_aide":
		printerr("[smoke] FAIL university should open study jobs first, got %s" % str(uni_ids))
		phase13_ok = false
	else:
		print("[smoke] adult job pool OK")

	gs.begin_new_game()
	gs.academia = 70
	gs.morals = 55
	gs.stamina = 45
	gs.social = 55
	gs.charm = 20
	gs.mood = 50
	gs.cash = 100
	var career_before: Dictionary = Endings.evaluate(gs)
	if str(career_before.get("id", "")) != "doctor":
		printerr("[smoke] FAIL career baseline %s" % str(career_before.get("id", "")))
		phase13_ok = false
	gs.adult_job = "school_aide"
	var career_after: Dictionary = Endings.evaluate(gs)
	if str(career_after.get("id", "")) != "teacher":
		printerr("[smoke] FAIL job should tip teacher, got %s" % str(career_after.get("id", "")))
		phase13_ok = false
	elif not str(career_after.get("life_line", "")).contains("沒有急著成家") or not str(career_after.get("life_chip", "")).contains("一個人"):
		printerr("[smoke] FAIL single life line %s" % str(career_after.get("life_chip", "")))
		phase13_ok = false
	gs.romance = 80
	gs.family_settled = true
	var settled_end: Dictionary = Endings.evaluate(gs)
	if not str(settled_end.get("life_chip", "")).contains("成家") or not str(settled_end.get("life_line", "")).contains("自己選"):
		printerr("[smoke] FAIL family ending note")
		phase13_ok = false
	else:
		print("[smoke] ending weighs job + romance + family OK")

	gs.romance = 44
	gs.family_prep = 1
	gs.family_settled = false
	gs.adult_job = "design_studio"
	gs.education_path = "art"
	if not gs.save_game(0):
		printerr("[smoke] FAIL adult save")
		phase13_ok = false
	gs.begin_new_game()
	if int(gs.romance) != 0 or str(gs.adult_job) != "" or str(gs.education_path) != "undecided":
		printerr("[smoke] FAIL new game did not clear adult fields")
		phase13_ok = false
	if not gs.load_game(0) or int(gs.romance) != 44 or int(gs.family_prep) != 1 or str(gs.adult_job) != "design_studio":
		printerr("[smoke] FAIL adult load romance=%d job=%s" % [int(gs.romance), str(gs.adult_job)])
		phase13_ok = false
	elif str(gs.education_path) != "art":
		printerr("[smoke] FAIL education_path art load")
		phase13_ok = false
	else:
		print("[smoke] adult save/load OK")
	gs.from_dict({"year": 9, "season": 1, "charm": 12})
	if int(gs.romance) != 0 or str(gs.adult_job) != "" or bool(gs.family_settled) or int(gs.year) != 9 or int(gs.charm) != 12:
		printerr("[smoke] FAIL v1 save migration")
		phase13_ok = false
	else:
		print("[smoke] v1 save defaults adult fields OK")
	gs.delete_save(0)

	gs.begin_new_game()
	gs.year = 15
	var adult_rng := RandomNumberGenerator.new()
	adult_rng.seed = 3
	var adult_pick: Dictionary = Confide.pick_line(gs, adult_rng)
	if not str(adult_pick.get("id", "")).begins_with("adult_"):
		printerr("[smoke] FAIL adult confide pool %s" % str(adult_pick.get("id", "")))
		phase13_ok = false

	gs.begin_new_game()
	gs.year = 4
	gs.cash = 3000
	gs.season_schedule = ["rest_sleep", "rest_park", "virtue_chores"] as Array[String]
	gs.resolve_season()
	if str(gs.last_deltas.get("job_name", "")) != "":
		printerr("[smoke] FAIL childhood season grew a job")
		phase13_ok = false
	gs.begin_new_game()
	gs.year = 13
	gs.cash = 2000
	gs.mood = 70
	gs.adult_job = "shop_staff"
	gs.season_schedule = ["date_walk", "rest_park", "study_night"] as Array[String]
	gs.resolve_season()
	var free_names: Array = gs.last_activity_names
	if free_names.size() < 3 or str(free_names[0]) != "黃昏散步" or str(free_names[2]) != "夜間進修":
		printerr("[smoke] FAIL free slots replaced: %s" % str(free_names))
		phase13_ok = false
	elif str(gs.last_deltas.get("job_name", "")) != "商店街店員" or int(gs.last_deltas.get("job_cash", 0)) != 4500:
		printerr("[smoke] FAIL job background %s $%s" % [str(gs.last_deltas.get("job_name", "")), str(gs.last_deltas.get("job_cash", 0))])
		phase13_ok = false
	elif int(gs.romance) != 8:
		printerr("[smoke] FAIL season romance %d" % int(gs.romance))
		phase13_ok = false
	else:
		print("[smoke] adult month = job + one free slot OK")

	gs.begin_new_game()
	gs.year = 13
	gs.season = 0
	gs.romance = 36
	gs.adult_job = "cafe_shift"
	gs.flags["tutorial_done"] = true
	gs.flags["growth_tutorial_done"] = true
	gs.flags["adult_job_intro_done"] = true
	gs.flags["confide_rolled_13_0"] = true
	var hub_packed = load("res://scenes/home_hub.tscn")
	if hub_packed == null:
		printerr("[smoke] FAIL home_hub scene")
		phase13_ok = false
	else:
		var hub: Node = hub_packed.instantiate()
		root.add_child(hub)
		var saw_romance := false
		var saw_job := false
		var saw_job_btn := false
		var walk: Array = [hub]
		while walk.size() > 0:
			var node: Node = walk.pop_back()
			if node is Label:
				var label_text := str(node.text)
				if label_text.contains("戀愛進度"):
					saw_romance = true
				if label_text.contains("咖啡店正職"):
					saw_job = true
			if node is Button and str(node.text) == "更換工作":
				saw_job_btn = true
			for child in node.get_children():
				walk.append(child)
		hub.call("_show_job_panel")
		var saw_current := false
		walk = [hub]
		while walk.size() > 0:
			var node2: Node = walk.pop_back()
			if node2 is Button and str(node2.text).contains("（目前）"):
				saw_current = true
			for child2 in node2.get_children():
				walk.append(child2)
		if not saw_romance or not saw_job or not saw_job_btn or not saw_current:
			printerr("[smoke] FAIL adult hub romance=%s job=%s btn=%s current=%s" % [str(saw_romance), str(saw_job), str(saw_job_btn), str(saw_current)])
			phase13_ok = false
		else:
			print("[smoke] adult hub romance + job OK")
		hub.free()

	if phase13_ok:
		print("[smoke] adulthood OK")

	# —— Phase B: travel stills are asserted above; lightbox + place popups ——
	var phase14_ok := true
	var album_src := FileAccess.get_file_as_string("res://scripts/album.gd")
	var review_src := FileAccess.get_file_as_string("res://scripts/year_review.gd")
	var style_src := FileAccess.get_file_as_string("res://scripts/ui_style.gd")
	if not style_src.contains("show_diary_lightbox") or not album_src.contains("show_diary_lightbox") or not review_src.contains("show_diary_lightbox"):
		printerr("[smoke] FAIL lightbox not wired")
		phase14_ok = false
	gs.begin_new_game()
	gs.flags["tutorial_done"] = true
	gs.flags["confide_rolled_1_0"] = true
	gs.flags["mom_rolled_1_0"] = true
	gs.flags["mom_present_1_0"] = false
	var album_node: Node = load("res://scenes/album.tscn").instantiate()
	root.add_child(album_node)
	var album_card: Node = null
	var seek: Array = [album_node]
	while seek.size() > 0:
		var seek_node: Node = seek.pop_back()
		if seek_node.has_meta("album_entry"):
			album_card = seek_node
			break
		for seek_child in seek_node.get_children():
			seek.append(seek_child)
	if album_card == null:
		printerr("[smoke] FAIL album card missing")
		phase14_ok = false
	else:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		album_card.gui_input.emit(click)
		var light := album_node.get_node_or_null("DiaryLightbox")
		if light == null:
			printerr("[smoke] FAIL album lightbox did not open")
			phase14_ok = false
		else:
			var saw_photo := false
			var saw_caption := false
			var light_walk: Array = [light]
			while light_walk.size() > 0:
				var light_node: Node = light_walk.pop_back()
				if light_node is TextureRect and (light_node as TextureRect).texture != null:
					saw_photo = true
				if light_node is Label and str(light_node.text).contains("門前的一家三口"):
					saw_caption = true
				for light_child in light_node.get_children():
					light_walk.append(light_child)
			if not saw_photo or not saw_caption:
				printerr("[smoke] FAIL album lightbox photo=%s caption=%s" % [str(saw_photo), str(saw_caption)])
				phase14_ok = false
			var esc := InputEventKey.new()
			esc.pressed = true
			esc.echo = false
			esc.keycode = KEY_ESCAPE
			album_node._unhandled_input(esc)
			if album_node.get_node_or_null("DiaryLightbox") != null:
				printerr("[smoke] FAIL album lightbox Esc")
				phase14_ok = false
			else:
				print("[smoke] album lightbox OK")
		var stamp_tex := load("res://assets/weather/summer.png") as Texture2D
		var family_tex := load("res://assets/family/family_early.jpg") as Texture2D
		var stamp_sz := UiStyle.lightbox_photo_size(stamp_tex, UiStyle.LIGHTBOX_PHOTO_MAX)
		var family_sz := UiStyle.lightbox_photo_size(family_tex, UiStyle.LIGHTBOX_PHOTO_MAX)
		var stamp_ratio := stamp_sz.x / stamp_sz.y
		if stamp_sz.x < 480.0 or stamp_ratio < 1.3 or stamp_ratio > 1.36:
			printerr("[smoke] FAIL stamp frame %s ratio %.3f" % [stamp_sz, stamp_ratio])
			phase14_ok = false
		elif absf(stamp_sz.x - family_sz.x) > 1.0 or absf(stamp_sz.y - family_sz.y) > 1.0:
			printerr("[smoke] FAIL stamp frame %s != photo %s" % [stamp_sz, family_sz])
			phase14_ok = false
		else:
			UiStyle.show_diary_lightbox(album_node, stamp_tex, "才藝課的音", "琴房的門關不嚴")
			var stamp_photo: TextureRect = null
			var stamp_light := album_node.get_node_or_null("DiaryLightbox")
			if stamp_light != null:
				var stamp_walk: Array = [stamp_light]
				while stamp_walk.size() > 0:
					var stamp_node: Node = stamp_walk.pop_back()
					if stamp_node is TextureRect and str(stamp_node.name) == "LandscapePhoto":
						stamp_photo = stamp_node
						break
					for stamp_child in stamp_node.get_children():
						stamp_walk.append(stamp_child)
			if stamp_photo == null or stamp_photo.texture == null:
				printerr("[smoke] FAIL stamp lightbox missing")
				phase14_ok = false
			elif stamp_photo.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_COVERED:
				printerr("[smoke] FAIL stamp lightbox stretch")
				phase14_ok = false
			elif stamp_photo.custom_minimum_size.x < stamp_photo.custom_minimum_size.y * 1.25:
				printerr("[smoke] FAIL stamp lightbox min %s" % stamp_photo.custom_minimum_size)
				phase14_ok = false
			else:
				print("[smoke] stamp lightbox landscape %s" % stamp_sz)
			UiStyle.dismiss_diary_lightbox(album_node)
	album_node.free()

	var review_node: Node = load("res://scenes/year_review.tscn").instantiate()
	root.add_child(review_node)
	var review_panel: Node = null
	var review_seek: Array = [review_node]
	while review_seek.size() > 0:
		var review_at: Node = review_seek.pop_back()
		if review_at is PanelContainer:
			for review_child in review_at.get_children():
				if review_child is TextureRect and (review_child as TextureRect).custom_minimum_size.y >= 400:
					review_panel = review_at
					break
		if review_panel != null:
			break
		for review_next in review_at.get_children():
			review_seek.append(review_next)
	if review_panel == null:
		printerr("[smoke] FAIL year review collage missing")
		phase14_ok = false
	else:
		var review_click := InputEventMouseButton.new()
		review_click.button_index = MOUSE_BUTTON_LEFT
		review_click.pressed = true
		review_panel.gui_input.emit(review_click)
		if review_node.get_node_or_null("DiaryLightbox") == null:
			printerr("[smoke] FAIL year review lightbox")
			phase14_ok = false
		else:
			var review_esc := InputEventKey.new()
			review_esc.pressed = true
			review_esc.echo = false
			review_esc.keycode = KEY_ESCAPE
			review_node._unhandled_input(review_esc)
			if review_node.get_node_or_null("DiaryLightbox") != null:
				printerr("[smoke] FAIL year review lightbox Esc")
				phase14_ok = false
			else:
				print("[smoke] year review lightbox OK")
	review_node.free()

	var hub_place: Node = load("res://scenes/home_hub.tscn").instantiate()
	root.add_child(hub_place)
	var places: Array = load("res://scripts/home_hub.gd").PLACES
	var place_ids := {}
	if places.size() != 6:
		printerr("[smoke] FAIL place count %d" % places.size())
		phase14_ok = false
	for place in places:
		var pid := str(place.get("id", ""))
		place_ids[pid] = true
		var art := str(place.get("art", ""))
		if not art.ends_with("place_%s.jpg" % pid) or not FileAccess.file_exists(ProjectSettings.globalize_path(art)):
			printerr("[smoke] FAIL place art %s -> %s" % [pid, art])
			phase14_ok = false
		var chips = place.get("chips", [])
		if typeof(chips) != TYPE_ARRAY or chips.is_empty():
			printerr("[smoke] FAIL place chips %s" % pid)
			phase14_ok = false
		hub_place._show_place_popup(place)
		if hub_place._popup_panel == null or not hub_place._popup_panel.visible:
			printerr("[smoke] FAIL place popup hidden %s" % pid)
			phase14_ok = false
		elif hub_place._popup_banner == null or hub_place._popup_banner.texture == null or not hub_place._popup_banner_frame.visible:
			printerr("[smoke] FAIL place banner %s" % pid)
			phase14_ok = false
		elif hub_place._popup_banner.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_COVERED:
			printerr("[smoke] FAIL place banner stretch %s" % pid)
			phase14_ok = false
		elif hub_place._popup_banner.custom_minimum_size.x < hub_place._popup_banner.custom_minimum_size.y * 1.6:
			printerr("[smoke] FAIL place banner ratio %s" % hub_place._popup_banner.custom_minimum_size)
			phase14_ok = false
		elif hub_place._popup_pin == null or hub_place._popup_pin.texture == null:
			printerr("[smoke] FAIL place pin %s" % pid)
			phase14_ok = false
		elif hub_place._popup_chips.get_child_count() < 1:
			printerr("[smoke] FAIL place chip row %s" % pid)
			phase14_ok = false
		elif not str(hub_place._popup_title.text).contains(str(place.get("name", ""))):
			printerr("[smoke] FAIL place title %s" % pid)
			phase14_ok = false
		else:
			var body_txt := ""
			for body_node in hub_place._popup_body.get_children():
				if body_node is Label:
					body_txt += str(body_node.text)
			if body_txt == "" or not hub_place._popup_title.text.contains("·"):
				printerr("[smoke] FAIL place body %s" % pid)
				phase14_ok = false
	if place_ids.size() != 6 or not place_ids.has("home") or not place_ids.has("shops") or not place_ids.has("culture"):
		printerr("[smoke] FAIL place ids %s" % str(place_ids.keys()))
		phase14_ok = false
	elif phase14_ok:
		print("[smoke] place popups OK")
	hub_place.free()
	if phase14_ok:
		print("[smoke] phase B lightbox + places OK")

	# —— Phase C: university vs high-school career entry ——
	var phase15_ok := true
	gs.begin_new_game()
	gs.year = 12
	if Adulthood.needs_education_choice(gs) or Adulthood.scene_after_review(gs, "hub") != Adulthood.HUB_SCENE:
		printerr("[smoke] FAIL education choice before adulthood")
		phase15_ok = false
	gs.year = 13
	if not Adulthood.needs_education_choice(gs):
		printerr("[smoke] FAIL undecided adult should ask")
		phase15_ok = false
	elif Adulthood.scene_after_review(gs, "hub") != Adulthood.FORK_SCENE:
		printerr("[smoke] FAIL y12 continue should open the fork")
		phase15_ok = false
	elif Adulthood.scene_after_review(gs, "ending") != Adulthood.ENDING_SCENE:
		printerr("[smoke] FAIL ending route changed")
		phase15_ok = false
	gs.education_path = "not-a-path"
	if not Adulthood.needs_education_choice(gs):
		printerr("[smoke] FAIL unknown education_path should ask once")
		phase15_ok = false
	gs.education_path = "letters"
	if Adulthood.needs_education_choice(gs):
		printerr("[smoke] FAIL legacy tag should keep its bias and skip the card")
		phase15_ok = false
	var axes_before := {
		"charm": int(gs.charm), "morals": int(gs.morals), "social": int(gs.social),
		"stamina": int(gs.stamina), "academia": int(gs.academia),
	}
	gs.skill_xp = {"piano": 2}
	gs.interest_points = {"art": 3}
	gs.education_path = "undecided"
	if not Adulthood.choose_education(gs, "university"):
		printerr("[smoke] FAIL choose university")
		phase15_ok = false
	elif str(gs.education_path) != "university" or Adulthood.needs_education_choice(gs):
		printerr("[smoke] FAIL university did not persist")
		phase15_ok = false
	elif int(gs.charm) != int(axes_before["charm"]) or int(gs.academia) != int(axes_before["academia"]) or int(gs.morals) != int(axes_before["morals"]) or int(gs.social) != int(axes_before["social"]) or int(gs.stamina) != int(axes_before["stamina"]):
		printerr("[smoke] FAIL education choice touched an axis")
		phase15_ok = false
	elif GrowthPath.xp_of(gs, "piano") != 2 or GrowthPath.points_of(gs, "art") != 3:
		printerr("[smoke] FAIL education choice touched skills")
		phase15_ok = false
	var hs_only := PackedStringArray()
	gs.skill_xp = {}
	gs.interest_points = {}
	gs.education_path = "high_school"
	for hs_job in Adulthood.available_jobs(gs):
		hs_only.append(str(hs_job.get("id", "")))
	if not hs_only.has("cafe_shift") or not hs_only.has("neighbor_care") or not hs_only.has("shop_staff") or hs_only.has("clinic_aide"):
		printerr("[smoke] FAIL high school pool %s" % str(hs_only))
		phase15_ok = false
	elif hs_only.is_empty() or str(Adulthood.available_jobs(gs)[0].get("id", "")) != "cafe_shift":
		printerr("[smoke] FAIL high school should open work first")
		phase15_ok = false
	gs.interest_points = {"art": 4}
	gs.skill_xp = {"paint": 3}
	var hs_art := false
	for hs_art_job in Adulthood.available_jobs(gs):
		if str(hs_art_job.get("id", "")) == "design_studio":
			hs_art = true
	if not hs_art:
		printerr("[smoke] FAIL high school locked out a skilled job")
		phase15_ok = false
	gs.romance = 80
	gs.family_settled = true
	gs.adult_job = "school_aide"
	var uni_end: Dictionary = Endings.evaluate(gs)
	gs.education_path = "university"
	var uni_family: Dictionary = Endings.evaluate(gs)
	if str(uni_end.get("id", "")) != str(uni_family.get("id", "")):
		printerr("[smoke] FAIL education path changed the ending id")
		phase15_ok = false
	elif not str(uni_family.get("life_line", "")).contains("大學") or not str(uni_family.get("life_line", "")).contains("成家"):
		printerr("[smoke] FAIL university family flavor %s" % str(uni_family.get("life_line", "")))
		phase15_ok = false
	elif not str(uni_family.get("life_chip", "")).contains("大學進路") or not str(uni_family.get("life_chip", "")).contains("成家"):
		printerr("[smoke] FAIL university life chip %s" % str(uni_family.get("life_chip", "")))
		phase15_ok = false
	gs.education_path = "high_school"
	gs.family_settled = false
	gs.romance = 0
	var hs_end: Dictionary = Endings.evaluate(gs)
	if not str(hs_end.get("life_line", "")).contains("高中") or not str(hs_end.get("life_line", "")).contains("沒有急著成家"):
		printerr("[smoke] FAIL high school family flavor %s" % str(hs_end.get("life_line", "")))
		phase15_ok = false
	elif not str(hs_end.get("life_chip", "")).contains("高中就業") or not str(hs_end.get("life_chip", "")).contains("一個人"):
		printerr("[smoke] FAIL high school life chip %s" % str(hs_end.get("life_chip", "")))
		phase15_ok = false
	if not gs.save_game(0):
		printerr("[smoke] FAIL education save")
		phase15_ok = false
	gs.begin_new_game()
	if str(gs.education_path) != "undecided" or not gs.load_game(0) or str(gs.education_path) != "high_school":
		printerr("[smoke] FAIL education_path high_school roundtrip")
		phase15_ok = false
	elif Adulthood.needs_education_choice(gs):
		printerr("[smoke] FAIL saved fork should not ask again")
		phase15_ok = false
	gs.delete_save(0)
	gs.from_dict({"year": 15, "season": 0})
	if str(gs.education_path) != "undecided" or not Adulthood.needs_education_choice(gs):
		printerr("[smoke] FAIL old adult save should ask")
		phase15_ok = false

	gs.begin_new_game()
	gs.year = 13
	gs.education_path = "undecided"
	gs.flags["tutorial_done"] = true
	gs.flags["growth_tutorial_done"] = true
	gs.flags["confide_rolled_13_0"] = true
	var fork_packed = load("res://scenes/education_fork.tscn")
	if fork_packed == null:
		printerr("[smoke] FAIL education_fork scene")
		phase15_ok = false
	else:
		var fork: Node = fork_packed.instantiate()
		root.add_child(fork)
		var choose_uni: Node = fork.find_child("ChooseUniversity", true, false)
		var choose_hs: Node = fork.find_child("ChooseHighSchool", true, false)
		var saw_lead := false
		var fork_walk: Array = [fork]
		while fork_walk.size() > 0:
			var fork_node: Node = fork_walk.pop_back()
			if fork_node is Label and str(fork_node.text).contains("高中的最後一頁"):
				saw_lead = true
			for fork_child in fork_node.get_children():
				fork_walk.append(fork_child)
		if choose_uni == null or choose_hs == null or not saw_lead:
			printerr("[smoke] FAIL fork buttons lead=%s" % str(saw_lead))
			phase15_ok = false
		elif not str(choose_uni.text).contains(Adulthood.COPY_UNIVERSITY_TITLE) or not str(choose_hs.text).contains(Adulthood.COPY_HIGH_SCHOOL_TITLE):
			printerr("[smoke] FAIL fork button copy")
			phase15_ok = false
		else:
			var fork_bust := fork.find_child("DialogueBust", true, false) as TextureRect
			var fork_stamp := fork.find_child("DialogueStamp", true, false)
			if fork_bust == null or fork_bust.texture == null or fork_stamp == null:
				printerr("[smoke] FAIL fork dialogue art bust=%s stamp=%s" % [fork_bust, fork_stamp])
				phase15_ok = false
			choose_uni.pressed.emit()
			if str(gs.education_path) != "university" or Adulthood.needs_education_choice(gs):
				printerr("[smoke] FAIL fork click did not store university")
				phase15_ok = false
			elif fork.find_child("ChooseUniversity", true, false) != null:
				printerr("[smoke] FAIL fork still offering after the choice")
				phase15_ok = false
			else:
				var saw_written := false
				var written_walk: Array = [fork]
				while written_walk.size() > 0:
					var written_node: Node = written_walk.pop_back()
					if written_node is Label and str(written_node.text).contains("寫下來了"):
						saw_written = true
					for written_child in written_node.get_children():
						written_walk.append(written_child)
				if not saw_written:
					printerr("[smoke] FAIL fork confirmation")
					phase15_ok = false
				else:
					print("[smoke] education fork once OK")
		fork.free()

	gs.begin_new_game()
	gs.year = 13
	gs.education_path = "high_school"
	gs.flags["tutorial_done"] = true
	gs.flags["growth_tutorial_done"] = true
	gs.flags["adult_job_intro_done"] = false
	gs.flags["confide_rolled_13_0"] = true
	var edu_hub: Node = load("res://scenes/home_hub.tscn").instantiate()
	root.add_child(edu_hub)
	var saw_entry := false
	var saw_note := false
	var edu_walk: Array = [edu_hub]
	while edu_walk.size() > 0:
		var edu_node: Node = edu_walk.pop_back()
		if edu_node is Label and str(edu_node.text).contains("直接就業"):
			saw_entry = true
		for edu_child in edu_node.get_children():
			edu_walk.append(edu_child)
	edu_hub._show_job_panel()
	edu_walk = [edu_hub]
	while edu_walk.size() > 0:
		var note_node: Node = edu_walk.pop_back()
		if note_node is Label and str(note_node.text).contains("高中就業"):
			saw_note = true
		for note_child in note_node.get_children():
			edu_walk.append(note_child)
	if not saw_entry or not saw_note:
		printerr("[smoke] FAIL adult entry copy intro=%s jobs=%s" % [str(saw_entry), str(saw_note)])
		phase15_ok = false
	else:
		print("[smoke] education copy on hub OK")
	edu_hub.free()

	var review_gate := FileAccess.get_file_as_string("res://scripts/year_review.gd")
	var hub_gate := FileAccess.get_file_as_string("res://scripts/home_hub.gd")
	if not review_gate.contains("scene_after_review") or not hub_gate.contains("needs_education_choice") or not hub_gate.contains("_open_education_fork"):
		printerr("[smoke] FAIL education gate not wired")
		phase15_ok = false
	if phase15_ok:
		print("[smoke] phase C education fork OK")

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

	gs.begin_new_game()
	gs.cash = 80000
	gs.mood = 90
	gs.charm = 80
	gs.stamina = 80
	gs.academia = 80
	gs.morals = 80
	gs.flags["visited_school"] = 3
	gs.flags["visited_shops"] = 3
	gs.flags["visited_culture"] = 3
	gs.flags["visited_park"] = 3
	gs.year = 1
	gs.season = 0
	gs.season_schedule = ["study_arts", "social_friends", "rest_sleep"] as Array[String]
	gs.resolve_season()
	gs.year = 1
	gs.season = 1
	gs.season_schedule = ["study_arts", "rest_park", "rest_sleep"] as Array[String]
	gs.resolve_season()
	gs.last_season_event = {
		"id": "summer_beach",
		"title": "夏天去海灘",
		"body": "一家人站在沙上。",
		"media_still": "beach",
	}
	gs.record_season_memories()
	gs.year = 2
	gs.season = 1
	gs.last_season_event = {
		"id": "summer_beach",
		"title": "夏天去海灘",
		"body": "同一段年紀又去了一次海邊。",
		"media_still": "beach",
	}
	gs.record_season_memories()
	var arts_n := 0
	var beach_n := 0
	for ruled in gs.album:
		var ruled_path := str(ruled.get("thumb_path", ""))
		if ruled_path.ends_with("arts_early.jpg"):
			arts_n += 1
		if ruled_path.ends_with("beach_early.jpg"):
			beach_n += 1
		if AlbumPhotos.is_forbidden(ruled_path) or ruled_path.contains("weather/"):
			printerr("[smoke] FAIL album stamp %s" % ruled_path)
			phase14_ok = false
	if arts_n != 1 or beach_n != 1:
		printerr("[smoke] FAIL album repeat arts=%d beach=%d" % [arts_n, beach_n])
		phase14_ok = false
	gs.year = 4
	gs.season = 1
	gs.cash = 80000
	var china_a: Dictionary = Travel.depart(gs, "china")
	gs.year = 6
	gs.season = 1
	gs.cash = 80000
	var china_b: Dictionary = Travel.depart(gs, "china")
	if str(china_a.get("thumb", "")) != "res://assets/album/travel_china_elementary.jpg" or str(china_b.get("thumb", "")) != "res://assets/album/travel_china_elementary_b.jpg":
		printerr("[smoke] FAIL travel variants %s / %s" % [str(china_a.get("thumb", "")), str(china_b.get("thumb", ""))])
		phase14_ok = false
	elif AlbumPhotos.claim(AlbumPhotos.used_paths(gs.album), "travel_china", 6) != "":
		printerr("[smoke] FAIL a third china photo in the same band")
		phase14_ok = false
	else:
		var ruled_audit := AlbumPhotos.audit(gs.album)
		if ruled_audit != "":
			printerr("[smoke] FAIL album rules %s" % ruled_audit)
			phase14_ok = false
		else:
			print("[smoke] album photo rules OK")

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
	var played_album := AlbumPhotos.audit(gs.album)
	if played_album != "":
		printerr("[smoke] FAIL played album %s" % played_album)
		phase14_ok = false
	else:
		var played_paths := {}
		for played in gs.album:
			var played_path := str(played.get("thumb_path", ""))
			played_paths[played_path] = str(played.get("title", ""))
		if played_paths.size() != gs.album.size():
			printerr("[smoke] FAIL played album path count")
			phase14_ok = false
		else:
			print("[smoke] played album %d unique photos" % gs.album.size())

	var dialogue_ok := true
	if load("res://scripts/dialogue_chrome.gd") == null:
		printerr("[smoke] FAIL dialogue chrome script")
		dialogue_ok = false
	elif DialogueChrome.theme_for_confide("child_worry_seat") != "school" or DialogueChrome.theme_for_confide("child_worry_candy") != "shop" or DialogueChrome.theme_for_confide("adult_worry_someone") != "romance" or DialogueChrome.theme_for_confide("adult_worry_late") != "work" or DialogueChrome.theme_for_confide("child_cling_hug") != "family" or DialogueChrome.theme_for_confide("child_worry_bento") != "school" or DialogueChrome.theme_for_confide("child_cling_praise") != "home" or DialogueChrome.theme_for_confide("adult_cling_table") != "family":
		printerr("[smoke] FAIL confide theme map")
		dialogue_ok = false
	elif DialogueChrome.theme_for_line("回來啦。今天在學校畫了一朵很大的花。") != "school" or DialogueChrome.theme_for_line("去巷口就好") != "park" or DialogueChrome.theme_for_line("今晚想吃湯麵嗎") != "home":
		printerr("[smoke] FAIL line theme scan")
		dialogue_ok = false
	elif DialogueChrome.speaker_path("mom", 9, 0) != AgeLooks.mom_portrait(9) or DialogueChrome.speaker_path("dad", 8, 0) != AgeLooks.dad_portrait(8) or DialogueChrome.speaker_path("daughter", 16, 2) != AgeLooks.daughter_portrait(16, 2):
		printerr("[smoke] FAIL dialogue speaker paths")
		dialogue_ok = false
	elif DialogueChrome.theme_art("family", 1) != AgeLooks.family_photo(1) or DialogueChrome.theme_art("school", 3) != "res://assets/places/place_school.jpg":
		printerr("[smoke] FAIL dialogue theme art")
		dialogue_ok = false
	elif not hub_gate.contains("DialogueChrome") or not hub_gate.contains("AgeLooks.mom_pin"):
		printerr("[smoke] FAIL hub dialogue chrome wiring")
		dialogue_ok = false
	else:
		var shell := DialogueChrome.make_shell(Vector2(860, 540), Vector2(188, 300))
		root.add_child(shell["panel"])
		DialogueChrome.apply_speaker(shell, "daughter", 3, 0)
		DialogueChrome.apply_listener(shell, "dad", 3, 0, "爸爸")
		DialogueChrome.apply_theme(shell, "school", 3)
		var bust: TextureRect = shell["portrait"]
		var listener: TextureRect = shell["listener"]
		var stamp: TextureRect = shell["theme"]
		var listener_row: Control = shell["listener_row"]
		var nameplate: Label = shell["nameplate"]
		var actions: Node = shell["actions"]
		if bust.texture == null or listener.texture == null or stamp.texture == null or not listener_row.visible:
			printerr("[smoke] FAIL dialogue shell portraits")
			dialogue_ok = false
		elif nameplate.get_parent() is PanelContainer or not actions is VBoxContainer or actions.get_parent() != shell["panel"].find_child("DiaryHost", true, false).get_child(1).get_child(0):
			# Name is a label in the story column. Choices live in DialogueActions, the last row of the shell.
			printerr("[smoke] FAIL dialogue name looks like a button or actions are not at the bottom")
			dialogue_ok = false
		else:
			print("[smoke] dialogue chrome OK")
		shell["panel"].free()

	var season_ui_ok: bool = await _check_season_summary()
	var ok := stage_ok and wardrobe_ok and map_ok and save_ok and act_ok and yr_ok and end_ok and title_ok and phase9_ok and phase10_ok and phase11_ok and phase12_ok and phase13_ok and phase14_ok and phase15_ok and packs_ok and dialogue_ok and season_ui_ok
	if months != expected:
		printerr("[smoke] FAIL: months_played != %d" % expected)
		ok = false
	if str(gs.last_deltas.get("job_name", "")) == "" or int(gs.last_deltas.get("job_cash", 0)) <= 0:
		printerr("[smoke] FAIL: final adult season missing weekday job")
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


func _check_season_summary() -> bool:
	var gs: Node = root.get_node_or_null("GameState")
	if gs == null:
		printerr("[smoke] FAIL season card: no GameState")
		return false
	var saved_year: int = gs.year
	var saved_season: int = gs.season
	var saved_deltas: Dictionary = gs.last_deltas.duplicate(true)
	var saved_vignettes: Array = gs.last_vignettes.duplicate(true)
	var saved_roam: Dictionary = gs.last_roaming_event.duplicate(true)
	var saved_event: Dictionary = gs.last_season_event.duplicate(true)
	gs.year = 1
	gs.season = 2
	gs.last_vignettes = []
	gs.last_deltas = {
		"charm": 5, "morals": 3, "social": 2, "stamina": 6,
		"academia": 11, "mood": 6, "cash": 1790,
		"activities": ["圖書館自習", "才藝課", "補習班"],
	}
	gs.last_roaming_event = {
		"skipped": false,
		"place_name": "商店街",
		"title": "文具小物",
		"body": "文具行裡她猶豫很久，最後選了一支粉紅原子筆。說要用它寫認真的日記。",
		"deltas": {"charm": 1, "academia": 1, "cash": -60},
	}
	gs.last_season_event = {
		"id": "autumn_mountain",
		"title": "秋天上山旅行",
		"body": "紅葉季節，你們搭公車到近郊山徑。她把楓葉夾進手帳，說要留給十二年後的自己看。",
		"sticker": "autumn",
		"media_still": "mountain",
		"deltas": {"mood": 5, "stamina": 3, "social": 2, "morals": 1, "cash": -280},
	}
	var mountain := load("res://assets/events/mountain.jpg") as Texture2D
	var fitted := UiStyle.contained_photo_size(mountain, Vector2(520, 300))
	var src_aspect := float(mountain.get_width()) / float(mountain.get_height())
	if fitted.x > 520.5 or fitted.y > 300.5 or absf(fitted.x / fitted.y - src_aspect) > 0.02:
		printerr("[smoke] FAIL contained still size %s aspect %.3f" % [fitted, src_aspect])
		_restore_season_summary(gs, saved_year, saved_season, saved_deltas, saved_vignettes, saved_roam, saved_event)
		return false
	var scene: Control = load("res://scenes/season_result.tscn").instantiate()
	root.add_child(scene)
	scene._dismiss_media()
	scene.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	var ok := true
	for sz in [Vector2(1280, 720), Vector2(800, 480), Vector2(390, 700)]:
		scene.size = sz
		await process_frame
		await process_frame
		await process_frame
		if not _season_card_layout_ok(scene, sz):
			ok = false
	scene.free()
	_restore_season_summary(gs, saved_year, saved_season, saved_deltas, saved_vignettes, saved_roam, saved_event)
	if ok:
		print("[smoke] season summary scroll + contained photos OK")
	return ok


func _restore_season_summary(gs: Node, year: int, season: int, deltas: Dictionary, vignettes: Array, roam: Dictionary, ev: Dictionary) -> void:
	gs.year = year
	gs.season = season
	gs.last_deltas = deltas
	gs.last_vignettes = vignettes
	gs.last_roaming_event = roam
	gs.last_season_event = ev


func _season_card_layout_ok(scene: Control, sz: Vector2) -> bool:
	var card := scene.find_child("SeasonCard", true, false) as Control
	var scroll := scene.find_child("SeasonScroll", true, false) as ScrollContainer
	var btn := scene.find_child("SeasonContinue", true, false) as Button
	var still := scene.find_child("SeasonStill", true, false) as TextureRect
	var stamp := scene.find_child("SeasonSticker", true, false) as TextureRect
	var shots := scene.find_child("SeasonShots", true, false) as Control
	if card == null or scroll == null or btn == null or still == null or stamp == null or shots == null:
		printerr("[smoke] FAIL season card nodes missing at %s" % sz)
		return false
	if scroll.is_ancestor_of(btn) or btn.get_parent() == scroll:
		printerr("[smoke] FAIL continue sits inside the scroller")
		return false
	if not btn.is_visible_in_tree() or btn.text != "繼續":
		printerr("[smoke] FAIL continue hidden at %s" % sz)
		return false
	var scene_rect := scene.get_global_rect()
	var btn_rect := btn.get_global_rect()
	var card_rect := card.get_global_rect()
	if btn_rect.size.y < 36.0 or btn_rect.position.y < scene_rect.position.y - 1.0 or btn_rect.end.y > scene_rect.end.y + 1.0 or btn_rect.position.x < scene_rect.position.x - 1.0 or btn_rect.end.x > scene_rect.end.x + 1.0:
		printerr("[smoke] FAIL continue outside %s btn=%s scene=%s" % [sz, btn_rect, scene_rect])
		return false
	if btn_rect.end.y < card_rect.end.y - 80.0 or btn_rect.end.y > card_rect.end.y + 1.0:
		printerr("[smoke] FAIL continue not pinned to card footer %s btn=%s card=%s" % [sz, btn_rect, card_rect])
		return false
	if scroll.get_global_rect().end.y > btn_rect.position.y + 2.0:
		printerr("[smoke] FAIL scroller overlaps continue at %s" % sz)
		return false
	var y_before := btn.get_global_rect().position.y
	var bar := scroll.get_v_scroll_bar()
	var span := bar.max_value - bar.page
	if span < 24.0:
		printerr("[smoke] FAIL season body does not scroll at %s span=%.1f max=%.1f page=%.1f" % [sz, span, bar.max_value, bar.page])
		return false
	scroll.scroll_vertical = int(span)
	if absf(btn.get_global_rect().position.y - y_before) > 1.0:
		printerr("[smoke] FAIL continue moved when the diary scrolled")
		return false
	scroll.scroll_vertical = 0
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = scroll.get_global_rect().get_center()
	drag.relative = Vector2(0, -90)
	scroll.gui_input.emit(drag)
	var touch_handled_by_engine := Input.is_emulating_mouse_from_touch() and DisplayServer.is_touchscreen_available()
	if scroll.scroll_vertical <= 0 and not touch_handled_by_engine:
		printerr("[smoke] FAIL touch drag did not scroll season card at %s (value %s)" % [sz, scroll.scroll_vertical])
		return false
	if still.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_CENTERED or stamp.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
		printerr("[smoke] FAIL season photos are cover-cropped")
		return false
	if still.texture == null or stamp.texture == null or still.size.x < 8.0 or still.size.y < 8.0:
		printerr("[smoke] FAIL season photo size %s / %s" % [still.size, stamp.size])
		return false
	var still_aspect := float(still.texture.get_width()) / float(still.texture.get_height())
	var stamp_aspect := float(stamp.texture.get_width()) / float(stamp.texture.get_height())
	if absf(still.size.x / still.size.y - still_aspect) > 0.08:
		printerr("[smoke] FAIL still frame %.3f != texture %.3f size %s" % [still.size.x / still.size.y, still_aspect, still.size])
		return false
	if absf(stamp.size.x / stamp.size.y - stamp_aspect) > 0.08:
		printerr("[smoke] FAIL stamp frame %.3f != texture %.3f size %s" % [stamp.size.x / stamp.size.y, stamp_aspect, stamp.size])
		return false
	if stamp_aspect < 0.95 and stamp.size.x > stamp.size.y * 1.15:
		printerr("[smoke] FAIL tall stamp cover-cropped to landscape %s" % stamp.size)
		return false
	if shots.get_combined_minimum_size().x > scroll.size.x + 8.0:
		printerr("[smoke] FAIL season photos wider than the card %s > %s" % [shots.get_combined_minimum_size().x, scroll.size.x])
		return false
	var labels := _body_labels(scroll)
	if labels.is_empty():
		printerr("[smoke] FAIL season card has no text")
		return false
	for node in labels:
		if node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			printerr("[smoke] FAIL %s eats wheel events" % node.name)
			return false
	return true


func _body_labels(scroll: ScrollContainer) -> Array[Label]:
	var out: Array[Label] = []
	var walk: Array = [scroll]
	while walk.size() > 0:
		var node: Node = walk.pop_back()
		if node is Label:
			out.append(node)
		for child in node.get_children():
			walk.append(child)
	return out
