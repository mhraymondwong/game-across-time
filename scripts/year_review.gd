extends Control
## Year-end scrapbook / polaroid album review (Phase 6 · 相簿貼圖風)


func _ready() -> void:
	UiStyle.make_bg(self, GameConfig.COL_BG)
	var review: Dictionary = GameState.last_year_review
	if review.is_empty():
		review = {
			"year": GameState.year,
			"age": GameState.get_age(),
			"stage_label": GameConfig.growth_stage_label(GameConfig.growth_stage_for_year(GameState.year)),
			"deltas": {},
			"highlights": ["還沒有貼上回憶呢。"],
			"polaroid_band": GameConfig.polaroid_band_for_age(GameState.get_age()),
			"summary": "這一頁還空著，等你們一起寫。",
		}

	# Album spread background
	var album_path := GameConfig.year_review_album_bg()
	if album_path != "":
		var album := TextureRect.new()
		album.texture = _load_tex(album_path)
		album.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		album.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		album.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		album.mouse_filter = Control.MOUSE_FILTER_IGNORE
		album.modulate = Color(1, 1, 1, 0.92)
		add_child(album)

	# Soft wash so text stays readable
	var wash := ColorRect.new()
	wash.color = Color(1.0, 0.94, 0.96, 0.35)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 36)
	root.add_theme_constant_override("margin_right", 36)
	root.add_theme_constant_override("margin_top", 28)
	root.add_theme_constant_override("margin_bottom", 28)
	add_child(root)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	root.add_child(h)

	# Left: polaroid collage
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(520, 0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 10)
	h.add_child(left)

	var band := str(review.get("polaroid_band", "child"))
	var polaroid_path := GameConfig.year_review_polaroid_path(band)
	var collage_panel := PanelContainer.new()
	collage_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	collage_panel.add_theme_stylebox_override("panel", _polaroid_frame())
	left.add_child(collage_panel)

	var collage := TextureRect.new()
	collage.custom_minimum_size = Vector2(480, 420)
	collage.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	collage.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	collage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if polaroid_path != "":
		collage.texture = _load_tex(polaroid_path)
	collage_panel.add_child(collage)

	var sticker_row := HBoxContainer.new()
	sticker_row.add_theme_constant_override("separation", 8)
	sticker_row.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_child(sticker_row)
	for txt in ["✿", "♡", "★", "☁", "♪"]:
		var st := Label.new()
		st.text = txt
		st.add_theme_font_size_override("font_size", 22)
		st.add_theme_color_override("font_color", Color("E87898"))
		sticker_row.add_child(st)

	# Right: scrapbook card
	var right := PanelContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size = Vector2(560, 0)
	right.add_theme_stylebox_override("panel", UiStyle.panel_style(Color("FFF8FA"), Color("F5A8C0"), 20))
	h.add_child(right)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	right.add_child(v)

	var title := Label.new()
	title.text = "第 %d 年 · 相簿回顧" % int(review.get("year", 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(title, 30)
	v.add_child(title)

	var meta := Label.new()
	meta.text = "%d 歲 · %s" % [int(review.get("age", 6)), str(review.get("stage_label", ""))]
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(meta, 18, true)
	v.add_child(meta)

	# Decorative tape strip
	var tape := ColorRect.new()
	tape.custom_minimum_size = Vector2(0, 8)
	tape.color = Color("FFC0D4")
	v.add_child(tape)

	var summary := Label.new()
	summary.text = str(review.get("summary", ""))
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(summary, 17)
	v.add_child(summary)

	var delta_title := Label.new()
	delta_title.text = "這一年的成長貼紙"
	UiStyle.apply_label(delta_title, 16)
	v.add_child(delta_title)

	var chip_wrap := HFlowContainer.new()
	chip_wrap.add_theme_constant_override("h_separation", 8)
	chip_wrap.add_theme_constant_override("v_separation", 8)
	v.add_child(chip_wrap)
	_add_delta_chips(chip_wrap, review.get("deltas", {}))

	var hi_title := Label.new()
	hi_title.text = "手帳亮點"
	UiStyle.apply_label(hi_title, 16)
	v.add_child(hi_title)

	var highlights = review.get("highlights", [])
	if typeof(highlights) != TYPE_ARRAY:
		highlights = []
	for line in highlights:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var bullet := Label.new()
		bullet.text = "♡"
		bullet.add_theme_color_override("font_color", Color("E87898"))
		bullet.add_theme_font_size_override("font_size", 16)
		row.add_child(bullet)
		var hl := Label.new()
		hl.text = str(line)
		hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UiStyle.apply_label(hl, 15)
		row.add_child(hl)
		v.add_child(row)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.custom_minimum_size = Vector2(0, 8)
	v.add_child(spacer)

	var cont := Button.new()
	if GameState.pending_ending_after_review:
		cont.text = "翻到結局的那一頁 ♡"
	else:
		cont.text = "翻到新的一年 ♡"
	UiStyle.apply_button(cont, true)
	cont.pressed.connect(_on_continue)
	v.add_child(cont)


func _polaroid_frame() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("FFFAFC")
	s.border_color = Color("F0C0D0")
	s.set_border_width_all(10)
	s.border_width_bottom = 28
	s.set_corner_radius_all(4)
	s.shadow_color = Color(0.4, 0.2, 0.3, 0.18)
	s.shadow_size = 10
	s.shadow_offset = Vector2(4, 6)
	s.set_content_margin_all(6)
	return s


func _add_delta_chips(host: HFlowContainer, deltas: Dictionary) -> void:
	var pairs := [
		["charm", "魅力"], ["morals", "道德"], ["social", "人際"],
		["stamina", "體力"], ["academia", "學識"], ["mood", "心情"], ["cash", "金錢"],
	]
	var any := false
	for pair in pairs:
		var k: String = pair[0]
		var label: String = pair[1]
		var v := int(deltas.get(k, 0)) if typeof(deltas) == TYPE_DICTIONARY else 0
		if v == 0:
			continue
		any = true
		var sign := "＋" if v > 0 else "－"
		var txt: String
		if k == "cash":
			txt = "%s%s$%d" % [label, "＋" if v > 0 else "－", abs(v)]
		else:
			txt = "%s%s%d" % [label, sign, abs(v)]
		var fill := Color("FFE0EC") if v > 0 else Color("F0E0E8")
		var sb := UiStyle.button_style(fill, Color("F0A0B8") if v > 0 else Color("D8B0C0"), 18)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6
		var wrap := PanelContainer.new()
		wrap.add_theme_stylebox_override("panel", sb)
		var inner := Label.new()
		inner.text = txt
		inner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiStyle.apply_label(inner, 14)
		wrap.add_child(inner)
		host.add_child(wrap)
	if not any:
		var none := Label.new()
		none.text = "變化不大，卻很踏實"
		UiStyle.apply_label(none, 14, true)
		host.add_child(none)


func _load_tex(path: String) -> Texture2D:
	if path == "":
		return null
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var abs := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs):
		var img := Image.load_from_file(abs)
		if img:
			return ImageTexture.create_from_image(img)
	return null


func _on_continue() -> void:
	var next := GameState.continue_after_year_review()
	if next == "ending":
		get_tree().change_scene_to_file("res://scenes/ending.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/home_hub.tscn")
