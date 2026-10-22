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
	elif hub_src.contains("mom_portrait.jpg") or not hub_src.contains("Mom.PIN_PATH"):
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
	if not travel_src.contains("TODO"):
		printerr("[smoke] FAIL travel placeholder art missing TODO")
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
		if str(fam_entry.get("id", "")) == "family_photo_child" and str(fam_entry.get("thumb_path", "")).ends_with("family_photo_child.jpg"):
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
	if not str(Travel.get_dest("china").get("thumb", "")).ends_with("travel_china_family.jpg"):
		printerr("[smoke] FAIL china thumb")
		phase10_ok = false
	if not str(Travel.get_dest("japan").get("thumb", "")).ends_with("family_photo_child.jpg"):
		printerr("[smoke] FAIL japan temp thumb")
		phase10_ok = false

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
				saw_trip = str(trip_entry.get("thumb_path", "")).ends_with("travel_china_family.jpg")
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
	var blocked_mom: Dictionary = Confide.offer_for(gs, confide_rng)
	if not blocked_mom.is_empty() or bool(gs.flags.get("confide_rolled_1_0", false)):
		printerr("[smoke] FAIL confide while mom is home")
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
	if not hub_confide_src.contains("Confide.offer_for"):
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

	var ok := stage_ok and wardrobe_ok and map_ok and save_ok and act_ok and yr_ok and end_ok and title_ok and phase9_ok and phase10_ok and phase11_ok and phase12_ok
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
