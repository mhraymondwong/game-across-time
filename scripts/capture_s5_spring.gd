extends SceneTree
const OUT := "res://shots/playtest"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var gs = root.get_node_or_null("GameState")
	if gs == null:
		printerr("no GameState"); quit(1); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	gs.begin_new_game()
	gs.year = 11
	gs.season = 0  # spring → s5_spring
	gs.months_played = 10 * 12
	gs.charm = 70; gs.morals = 65; gs.social = 68
	gs.stamina = 55; gs.academia = 72; gs.mood = 60; gs.cash = 15000
	gs.state_changed.emit()
	change_scene_to_file("res://scenes/home_hub.tscn")
	await process_frame; await process_frame; await process_frame
	await create_timer(1.2).timeout
	var img: Image = root.get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/12_hub_y11_spring_s5.png" % OUT)
	img.save_png(path)
	print("[ok] ", path)
	quit(0)
