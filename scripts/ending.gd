extends Control
## Phase 7 · 電影片尾風結局：暗色字幕＋側邊屬性雷達
## Short laptop heights keep 再養育一次／回標題 in the safe area.
## The story column scrolls on its own; overflow shows 向下捲動看完整結局.

const _StatRadar = preload("res://scripts/stat_radar.gd")

var _margin: MarginContainer
var _scroll: ScrollContainer
var _scroll_hint: Label
var _still: TextureRect
var _radar: Control
var _name_lbl: Label
var _summary: Label
var _life_lbl: Label
var _chip_lbl: Label
var _muted: Label
var _after: Label
var _radar_title: Label
var _fitting := false


func _ready() -> void:
	GameState.hide_busy()
	if GameState.final_ending.is_empty():
		GameState.finish_game()

	var ending: Dictionary = GameState.final_ending
	var ending_id := str(ending.get("id", "ordinary_happy"))
	var stats: Dictionary = GameState.get_stats_dict()

	var bg_path := GameConfig.ending_art_path("credits_bg")
	if bg_path == "":
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

	var wash := ColorRect.new()
	wash.color = Color(0.04, 0.02, 0.06, 0.52)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	_margin = MarginContainer.new()
	_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_margin)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_margin.add_child(column)

	_scroll = ScrollContainer.new()
	_scroll.name = "EndingScroll"
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.follow_focus = true
	_scroll.gui_input.connect(_on_scroll_drag)
	column.add_child(_scroll)
	_style_scroll(_scroll)

	var h := HBoxContainer.new()
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_theme_constant_override("separation", 28)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll.add_child(h)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.35
	left.add_theme_constant_override("separation", 12)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(left)

	var still_panel := PanelContainer.new()
	still_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	still_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	still_panel.add_theme_stylebox_override("panel", _still_frame())
	left.add_child(still_panel)

	_still = TextureRect.new()
	_still.name = "EndingStill"
	_still.custom_minimum_size = Vector2(420, 280)
	_still.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_still.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_still.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art_path := GameConfig.ending_art_path(ending_id)
	if art_path != "":
		_still.texture = _load_tex(art_path)
	still_panel.add_child(_still)

	var credits := VBoxContainer.new()
	credits.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	credits.add_theme_constant_override("separation", 8)
	credits.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(credits)

	_after = Label.new()
	_after.text = "十八年之後"
	_after.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_after.add_theme_font_size_override("font_size", 16)
	_after.add_theme_color_override("font_color", Color(1.0, 0.82, 0.88, 0.75))
	credits.add_child(_after)

	_name_lbl = Label.new()
	_name_lbl.name = "EndingName"
	_name_lbl.text = str(ending.get("name", "普通而確實的幸福"))
	_name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_lbl.add_theme_font_size_override("font_size", 34)
	_name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.97, 0.98))
	credits.add_child(_name_lbl)

	_summary = Label.new()
	_summary.name = "EndingSummary"
	_summary.text = str(ending.get("summary", ""))
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_summary.add_theme_font_size_override("font_size", 17)
	_summary.add_theme_color_override("font_color", Color(0.96, 0.90, 0.93, 0.88))
	credits.add_child(_summary)

	var life := str(ending.get("life_line", ""))
	if life != "":
		_life_lbl = Label.new()
		_life_lbl.name = "EndingLife"
		_life_lbl.text = life
		_life_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_life_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_life_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_life_lbl.add_theme_font_size_override("font_size", 16)
		_life_lbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.90, 0.9))
		credits.add_child(_life_lbl)

	var chip := str(ending.get("life_chip", ""))
	if chip != "":
		_chip_lbl = Label.new()
		_chip_lbl.text = chip
		_chip_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_chip_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_chip_lbl.add_theme_font_size_override("font_size", 15)
		_chip_lbl.add_theme_color_override("font_color", Color(0.98, 0.80, 0.86, 0.8))
		credits.add_child(_chip_lbl)

	_muted = Label.new()
	_muted.text = "共度過 %d 個月　·　家計 $%d" % [GameState.months_played, int(stats.get("cash", 0))]
	_muted.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_muted.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_muted.add_theme_font_size_override("font_size", 14)
	_muted.add_theme_color_override("font_color", Color(0.85, 0.72, 0.78, 0.65))
	credits.add_child(_muted)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(220, 0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 0.72
	right.add_theme_constant_override("separation", 8)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(right)

	_radar_title = Label.new()
	_radar_title.text = "最終屬性"
	_radar_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_radar_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_radar_title.add_theme_font_size_override("font_size", 15)
	_radar_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.90, 0.7))
	right.add_child(_radar_title)

	var radar := _StatRadar.new()
	radar.name = "EndingRadar"
	radar.custom_minimum_size = Vector2(220, 220)
	radar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	radar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	radar.set_from_stats(stats)
	right.add_child(radar)
	_radar = radar

	_scroll_hint = Label.new()
	_scroll_hint.name = "EndingScrollHint"
	_scroll_hint.text = "向下捲動看完整結局"
	_scroll_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_scroll_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll_hint.visible = false
	_scroll_hint.add_theme_font_size_override("font_size", 14)
	_scroll_hint.add_theme_color_override("font_color", Color(1.0, 0.86, 0.90, 0.92))
	column.add_child(_scroll_hint)

	var btn_row := HBoxContainer.new()
	btn_row.name = "EndingActions"
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(btn_row)

	var again := Button.new()
	again.name = "EndingAgain"
	again.text = "再養育一次"
	_apply_dark_chip(again, true)
	again.pressed.connect(_on_again)
	btn_row.add_child(again)

	var title_btn := Button.new()
	title_btn.name = "EndingTitle"
	title_btn.text = "回標題"
	_apply_dark_chip(title_btn, false)
	title_btn.pressed.connect(_on_title)
	btn_row.add_child(title_btn)

	resized.connect(_fit_layout)
	_scroll.get_v_scroll_bar().changed.connect(_sync_ending_hint)
	call_deferred("_fit_layout")


func _fit_layout() -> void:
	if _fitting or _still == null:
		return
	var vp := size
	if vp.x < 64.0 or vp.y < 64.0:
		return
	_fitting = true
	var margin_x := 20.0 if vp.x < 1100.0 else 40.0
	var margin_top := 12.0 if vp.y < 700.0 else 24.0
	var margin_bottom := 10.0 if vp.y < 700.0 else 16.0
	_margin.add_theme_constant_override("margin_left", int(margin_x))
	_margin.add_theme_constant_override("margin_right", int(margin_x))
	_margin.add_theme_constant_override("margin_top", int(margin_top))
	_margin.add_theme_constant_override("margin_bottom", int(margin_bottom))
	var footer := 58.0
	var content_h := maxf(160.0, vp.y - margin_top - margin_bottom - footer)
	var still_h := clampf(content_h * 0.38, 120.0, 320.0)
	var still_w := clampf(minf(vp.x * 0.46, still_h * 1.25), 180.0, 480.0)
	_still.custom_minimum_size = Vector2(still_w, still_h)
	var radar_s := clampf(minf(content_h * 0.42, vp.x * 0.22), 140.0, 260.0)
	_radar.custom_minimum_size = Vector2(radar_s, radar_s)
	var name_size := 28 if vp.y < 760.0 else 34
	var body_size := 16 if vp.y < 760.0 else 17
	_name_lbl.add_theme_font_size_override("font_size", name_size)
	_summary.add_theme_font_size_override("font_size", body_size)
	if _life_lbl:
		_life_lbl.add_theme_font_size_override("font_size", body_size - 1)
	_fitting = false
	call_deferred("_sync_ending_hint")


func _sync_ending_hint() -> void:
	if _scroll == null or _scroll_hint == null:
		return
	var bar := _scroll.get_v_scroll_bar()
	var overflow := bar.max_value > bar.page + 6.0
	if _scroll_hint.visible != overflow:
		_scroll_hint.visible = overflow


func _style_scroll(scroll: ScrollContainer) -> void:
	var bar := scroll.get_v_scroll_bar()
	bar.custom_minimum_size = Vector2(10, 0)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1, 1, 1, 0.08)
	track.set_corner_radius_all(6)
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(1.0, 0.78, 0.84, 0.85)
	grab.set_corner_radius_all(6)
	grab.content_margin_top = 8
	grab.content_margin_bottom = 8
	bar.add_theme_stylebox_override("scroll", track)
	bar.add_theme_stylebox_override("scroll_focus", track)
	bar.add_theme_stylebox_override("grabber", grab)
	bar.add_theme_stylebox_override("grabber_highlight", grab)
	bar.add_theme_stylebox_override("grabber_pressed", grab)


func _on_scroll_drag(event: InputEvent) -> void:
	var drag := event as InputEventScreenDrag
	if drag == null or _scroll == null:
		return
	if Input.is_emulating_mouse_from_touch() and DisplayServer.is_touchscreen_available():
		return
	_scroll.scroll_vertical -= drag.relative.y


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
	GameState.show_busy("正在回到封面…")
	await get_tree().process_frame
	GameState.wants_new_game_name = true
	get_tree().change_scene_to_file("res://scenes/title.tscn")


func _on_title() -> void:
	GameState.show_busy("正在回到封面…")
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://scenes/title.tscn")
