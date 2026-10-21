extends Control
## Phase 7 · 電影片尾風結局：暗色字幕＋側邊屬性雷達

const _StatRadar = preload("res://scripts/stat_radar.gd")


func _ready() -> void:
	if GameState.final_ending.is_empty():
		GameState.finish_game()

	var ending: Dictionary = GameState.final_ending
	var ending_id := str(ending.get("id", "ordinary_happy"))
	var stats: Dictionary = GameState.get_stats_dict()

	# 1) Fullscreen credits background (cover)
	var bg_path := GameConfig.ending_art_path("credits_bg")
	if bg_path == "":
		# Soft fallback dark wash if asset missing
		var dark := ColorRect.new()
		dark.color = Color(0.06, 0.04, 0.08, 1.0)
		dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dark)
	else:
		var bg := TextureRect.new()
		bg.texture = _load_tex(bg_path)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)

	# 2) Soft dark wash for readability
	var wash := ColorRect.new()
	wash.color = Color(0.04, 0.02, 0.06, 0.52)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	# Layout root
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 28)
	margin.add_child(h)

	# 3) Left/center: ending still (keep aspect)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.35
	left.add_theme_constant_override("separation", 14)
	h.add_child(left)

	var still_wrap := CenterContainer.new()
	still_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(still_wrap)

	var still := TextureRect.new()
	still.custom_minimum_size = Vector2(520, 460)
	still.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	still.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	still.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art_path := GameConfig.ending_art_path(ending_id)
	if art_path != "":
		still.texture = _load_tex(art_path)
	# Soft vignette panel behind still
	var still_panel := PanelContainer.new()
	still_panel.add_theme_stylebox_override("panel", _still_frame())
	still_panel.add_child(still)
	still_wrap.add_child(still_panel)

	# 4) Credit-style text band under / with still
	var credits := VBoxContainer.new()
	credits.add_theme_constant_override("separation", 8)
	left.add_child(credits)

	var after := Label.new()
	after.text = "十二年之後"
	after.add_theme_font_size_override("font_size", 16)
	after.add_theme_color_override("font_color", Color(1.0, 0.82, 0.88, 0.75))
	credits.add_child(after)

	var name_lbl := Label.new()
	name_lbl.text = str(ending.get("name", "普通而確實的幸福"))
	name_lbl.add_theme_font_size_override("font_size", 36)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.97, 0.98))
	credits.add_child(name_lbl)

	var summary := Label.new()
	summary.text = str(ending.get("summary", ""))
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.custom_minimum_size = Vector2(520, 0)
	summary.add_theme_font_size_override("font_size", 17)
	summary.add_theme_color_override("font_color", Color(0.96, 0.90, 0.93, 0.88))
	credits.add_child(summary)

	var muted := Label.new()
	muted.text = "共度過 %d 個月　·　家計 $%d" % [GameState.months_played, int(stats.get("cash", 0))]
	muted.add_theme_font_size_override("font_size", 14)
	muted.add_theme_color_override("font_color", Color(0.85, 0.72, 0.78, 0.65))
	credits.add_child(muted)

	# 5) Right: attribute radar
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(340, 0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 0.85
	right.add_theme_constant_override("separation", 12)
	h.add_child(right)

	var radar_title := Label.new()
	radar_title.text = "最終屬性"
	radar_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	radar_title.add_theme_font_size_override("font_size", 15)
	radar_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.90, 0.7))
	right.add_child(radar_title)

	var radar := _StatRadar.new()
	radar.custom_minimum_size = Vector2(300, 300)
	radar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	radar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	radar.set_from_stats(stats)
	right.add_child(radar)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(spacer)

	# 6) Bottom-right soft chips on dark
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	btn_row.add_theme_constant_override("separation", 12)
	right.add_child(btn_row)

	var again := Button.new()
	again.text = "再養育一次"
	_apply_dark_chip(again, true)
	again.pressed.connect(_on_again)
	btn_row.add_child(again)

	var title_btn := Button.new()
	title_btn.text = "回標題"
	_apply_dark_chip(title_btn, false)
	title_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/title.tscn"))
	btn_row.add_child(title_btn)


func _still_frame() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.05, 0.10, 0.55)
	s.border_color = Color(0.95, 0.70, 0.80, 0.35)
	s.set_border_width_all(1)
	s.set_corner_radius_all(8)
	s.set_content_margin_all(6)
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 12
	s.shadow_offset = Vector2(0, 4)
	return s


func _apply_dark_chip(btn: Button, primary: bool) -> void:
	## Translucent soft chips readable on dark cinematic BG
	var fill: Color
	var border: Color
	var text_c: Color
	if primary:
		fill = Color(0.94, 0.56, 0.68, 0.78)
		border = Color(1.0, 0.78, 0.86, 0.55)
		text_c = Color(1, 1, 1, 0.98)
	else:
		fill = Color(0.25, 0.14, 0.20, 0.65)
		border = Color(0.95, 0.70, 0.80, 0.40)
		text_c = Color(1.0, 0.90, 0.93, 0.95)
	btn.add_theme_stylebox_override("normal", UiStyle.button_style(fill, border, 18))
	btn.add_theme_stylebox_override("hover", UiStyle.button_style(fill.lightened(0.08), border.lightened(0.1), 18))
	btn.add_theme_stylebox_override("pressed", UiStyle.button_style(fill.darkened(0.08), border, 18))
	btn.add_theme_color_override("font_color", text_c)
	btn.add_theme_color_override("font_hover_color", text_c)
	btn.add_theme_color_override("font_pressed_color", text_c)
	btn.add_theme_font_size_override("font_size", 16)
	btn.custom_minimum_size = Vector2(140, 42)


func _load_tex(path: String) -> Texture2D:
	if path == "":
		return null
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var abs_path := ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img:
			return ImageTexture.create_from_image(img)
	return null


func _on_again() -> void:
	GameState.begin_new_game()
	get_tree().change_scene_to_file("res://scenes/home_hub.tscn")
