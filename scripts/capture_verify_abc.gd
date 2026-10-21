extends SceneTree
## Verify A/B/C: Y1 spring HUD 春裝+pins, Y7 summer wardrobe, Y11 winter
## Usage: DISPLAY=:22 /home/box/bin/godot --path . --script res://scripts/capture_verify_abc.gd

const OUT := "res://shots/playtest"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var gs = root.get_node_or_null("GameState")
	if gs == null:
		printerr("[verify] GameState missing")
		quit(1)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	# 09 Hub Y1 spring — 春裝 + pins
	gs.begin_new_game()
	gs.year = 1
	gs.season = 0
	gs.state_changed.emit()
	await _goto("res://scenes/home_hub.tscn")
	await _shot("09_hub_season_zh_pins.png")

	# 10 Hub Y7 summer wardrobe
	gs.begin_new_game()
	gs.year = 7
	gs.season = 1
	gs.months_played = 6 * 12 + 3
	gs.charm = 58
	gs.morals = 60
	gs.social = 55
	gs.stamina = 62
	gs.academia = 52
	gs.mood = 70
	gs.cash = 11000
	gs.state_changed.emit()
	await _goto("res://scenes/home_hub.tscn")
	await _shot("10_hub_y7_summer_wardrobe.png")

	# 11 Hub Y11 winter
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
	gs.state_changed.emit()
	await _goto("res://scenes/home_hub.tscn")
	await _shot("11_hub_y11_winter.png")

	print("[verify] ALL DONE")
	quit(0)


func _goto(path: String) -> void:
	var err := change_scene_to_file(path)
	if err != OK:
		printerr("[verify] failed scene ", path, " err=", err)
	await process_frame
	await process_frame
	await process_frame
	await create_timer(1.0).timeout


func _shot(name: String) -> void:
	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		printerr("[verify] no image for ", name)
		return
	var out := ProjectSettings.globalize_path("%s/%s" % [OUT, name])
	img.save_png(out)
	print("[verify] ", out, " ", img.get_width(), "x", img.get_height())
