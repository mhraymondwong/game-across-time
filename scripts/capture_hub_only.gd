extends SceneTree
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var gs = root.get_node_or_null("GameState")
	if gs:
		gs.begin_new_game()
		gs.year = 5
		gs.season = 1
		gs.state_changed.emit()
	change_scene_to_file("res://scenes/home_hub.tscn")
	await process_frame
	await process_frame
	await process_frame
	await create_timer(0.8).timeout
	var img: Image = root.get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://shots/04b_wardrobe_hub.png")
	img.save_png(path)
	print("[hub-shot] ", path, " ", img.get_width(), "x", img.get_height())
	quit(0)
