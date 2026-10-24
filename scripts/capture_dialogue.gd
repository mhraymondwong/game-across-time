extends SceneTree
## Screenshots of the dialogue surfaces (mom, confide, education fork).
## Usage: godot --path <project> --script res://scripts/capture_dialogue.gd
## Optional: SHOT_DIR=/tmp/dialogue-shots SHOT_TAG=before


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs: Node = root.get_node_or_null("GameState")
	if gs == null:
		printerr("[dialogue-shot] no GameState")
		quit(1)
		return
	var shot_dir := OS.get_environment("SHOT_DIR").strip_edges()
	if shot_dir == "":
		shot_dir = ProjectSettings.globalize_path("res://shots/dialogue")
	var tag := OS.get_environment("SHOT_TAG").strip_edges()
	if tag == "":
		tag = "after"
	DirAccess.make_dir_recursive_absolute(shot_dir)

	gs.begin_new_game()
	gs.year = 3
	gs.season = 0
	gs.months_played = 6
	gs.flags["tutorial_done"] = true
	gs.flags["growth_tutorial_done"] = true
	gs.flags["mom_rolled_3_0"] = true
	gs.flags["mom_present_3_0"] = true
	# Year 3 is not a travel year, and she is already past the name gate.
	var err := change_scene_to_file("res://scenes/home_hub.tscn")
	if err != OK:
		printerr("[dialogue-shot] hub ", err)
		quit(1)
		return
	await process_frame
	await process_frame
	await process_frame
	var hub := root.get_node_or_null("HomeHub")
	if hub == null:
		# current_scene may be the hub itself
		hub = current_scene
	if hub == null or not hub.has_method("_on_mom_pressed"):
		printerr("[dialogue-shot] hub missing")
		quit(1)
		return
	hub._on_mom_pressed()
	await process_frame
	await process_frame
	await create_timer(0.35).timeout
	if not _save(shot_dir, "mom_%s.png" % tag):
		quit(1)
		return

	if hub.has_method("_hide_popups"):
		hub._hide_popups()
	var line: Dictionary = Confide.get_line("child_worry_homework")
	var offer: Dictionary = Confide.present_line(gs, line)
	if hub.has_method("_open_confide"):
		hub._open_confide(offer)
	await process_frame
	await process_frame
	await create_timer(0.25).timeout
	if not _save(shot_dir, "confide_%s.png" % tag):
		quit(1)
		return

	# Adult worry, so the romance / work themes are visible too.
	gs.year = 14
	gs.season = 1
	gs.flags["adult_job_intro_done"] = true
	gs.education_path = "university"
	var adult_line: Dictionary = Confide.get_line("adult_worry_someone")
	var adult_offer: Dictionary = Confide.present_line(gs, adult_line)
	if hub.has_method("_hide_popups"):
		hub._hide_popups()
	if hub.has_method("_refresh"):
		hub._refresh()
	if hub.has_method("_open_confide"):
		hub._open_confide(adult_offer)
	await process_frame
	await process_frame
	await create_timer(0.25).timeout
	if not _save(shot_dir, "confide_adult_%s.png" % tag):
		quit(1)
		return

	if hub.has_method("_hide_popups"):
		hub._hide_popups()
	if hub.has_method("_show_npc_panel"):
		hub._show_npc_panel()
	await process_frame
	await process_frame
	await create_timer(0.2).timeout
	if not _save(shot_dir, "npc_%s.png" % tag):
		quit(1)
		return

	gs.year = 15
	gs.season = 0
	gs.education_path = "university"
	gs.flags["adult_job_intro_done"] = false
	gs.flags["tutorial_done"] = true
	gs.flags["growth_tutorial_done"] = true
	err = change_scene_to_file("res://scenes/home_hub.tscn")
	if err != OK:
		printerr("[dialogue-shot] adult hub ", err)
		quit(1)
		return
	await process_frame
	await process_frame
	await create_timer(0.35).timeout
	if not _save(shot_dir, "adult_%s.png" % tag):
		quit(1)
		return

	gs.year = 13
	gs.season = 0
	gs.education_path = "undecided"
	err = change_scene_to_file("res://scenes/education_fork.tscn")
	if err != OK:
		printerr("[dialogue-shot] fork ", err)
		quit(1)
		return
	await process_frame
	await process_frame
	await create_timer(0.35).timeout
	if not _save(shot_dir, "fork_%s.png" % tag):
		quit(1)
		return
	print("[dialogue-shot] saved under ", shot_dir, " tag=", tag)
	quit(0)


func _save(dir_path: String, file_name: String) -> bool:
	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		printerr("[dialogue-shot] no image")
		return false
	var path := dir_path.path_join(file_name)
	var save_err := img.save_png(path)
	print("[dialogue-shot] ", path, " err=", save_err, " ", img.get_width(), "x", img.get_height())
	return save_err == OK
