extends SceneTree
## Capture diary-cover title → shots/07_title_diary.png
## Usage: xvfb-run -a godot --path <project> --script res://scripts/capture_title.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var err := change_scene_to_file("res://scenes/title.tscn")
	if err != OK:
		printerr("[title-shot] failed to load title: ", err)
		quit(1)
		return

	await process_frame
	await process_frame
	await process_frame
	await create_timer(0.8).timeout

	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		printerr("[title-shot] no image")
		quit(1)
		return
	var out := ProjectSettings.globalize_path("res://shots/07_title_diary.png")
	img.save_png(out)
	print("[title-shot] ", out, " ", img.get_width(), "x", img.get_height())
	quit(0)
