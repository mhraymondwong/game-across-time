extends Control
## Living scrapbook. Same sticker-album spread as the year review, filled over time.


func _ready() -> void:
	UiStyle.make_bg(self, GameConfig.COL_BG)
	var album_path := GameConfig.year_review_album_bg()
	if album_path != "":
		var bg := TextureRect.new()
		bg.texture = _load_tex(album_path)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.modulate = Color(1, 1, 1, 0.92)
		add_child(bg)

	var wash := ColorRect.new()
	wash.color = Color(1.0, 0.94, 0.96, 0.42)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 36)
	root.add_theme_constant_override("margin_right", 36)
	root.add_theme_constant_override("margin_top", 24)
	root.add_theme_constant_override("margin_bottom", 20)
	add_child(root)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UiStyle.panel_style(Color("FFF8FA"), Color("F5A8C0"), 20))
	root.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	var entries := _entries()

	var title := Label.new()
	title.text = "累積相簿"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(title, 30)
	v.add_child(title)

	var meta := Label.new()
	if entries.is_empty():
		meta.text = "還沒有貼上照片"
	else:
		meta.text = "貼了 %d 張　·　點一下可以看大" % entries.size()
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(meta, 15, true)
	v.add_child(meta)

	var tape := ColorRect.new()
	tape.custom_minimum_size = Vector2(0, 8)
	tape.color = Color("FFC0D4")
	v.add_child(tape)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.custom_minimum_size = Vector2(760, 0)
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)

	if entries.is_empty():
		var empty := Label.new()
		empty.text = "相簿還是空白的。家人的合照、兩年一次的遠行，或值得記住的一個月，照片都會貼上來。"
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiStyle.apply_label(empty, 18)
		list.add_child(empty)
	else:
		for i in range(entries.size() - 1, -1, -1):
			if typeof(entries[i]) != TYPE_DICTIONARY:
				continue
			list.add_child(_card(entries[i]))

	var back := Button.new()
	if GameState.album_return_scene.ends_with("title.tscn"):
		back.text = "回到封面 ♡"
	else:
		back.text = "回到手帳 ♡"
	UiStyle.apply_button(back, true)
	back.pressed.connect(_on_back)
	v.add_child(back)


func _entries() -> Array:
	if not GameState.album_browse.is_empty():
		GameState.album_browse = AlbumPhotos.sanitize(GameState.album_browse)
		return GameState.album_browse
	GameState.album = AlbumPhotos.sanitize(GameState.album)
	return GameState.album


func _card(entry: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _polaroid_frame())
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var thumb_path := str(entry.get("thumb_path", ""))
	var tex := _load_tex(thumb_path)
	card.set_meta("album_entry", entry)
	card.set_meta("album_tex", tex)
	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_open_lightbox(entry, tex)
			card.accept_event()
	)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)

	if tex != null:
		var frame := PanelContainer.new()
		var inner_style := UiStyle.panel_style(Color("FFFAFC"), Color("F0C0D0"), 6)
		inner_style.set_border_width_all(6)
		inner_style.border_width_bottom = 16
		inner_style.content_margin_left = 4
		inner_style.content_margin_right = 4
		inner_style.content_margin_top = 4
		inner_style.content_margin_bottom = 4
		frame.add_theme_stylebox_override("panel", inner_style)
		frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		frame.add_child(UiStyle.make_landscape_photo(tex, Vector2(148, 111)))
		row.add_child(frame)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	row.add_child(col)

	var when := Label.new()
	var y := int(entry.get("year", 1))
	var s := int(entry.get("season", 0))
	when.text = "第 %d 年 · %s" % [y, GameConfig.season_name(s)]
	UiStyle.apply_label(when, 13, true)
	col.add_child(when)

	var cap := Label.new()
	cap.text = str(entry.get("title", "一頁回憶"))
	cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(cap, 20)
	col.add_child(cap)

	var body := Label.new()
	body.text = str(entry.get("body", ""))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(body, 15)
	col.add_child(body)
	_pass_clicks(card)
	return card


func _pass_clicks(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pass_clicks(child)


func _open_lightbox(entry: Dictionary, tex: Texture2D) -> void:
	UiStyle.show_diary_lightbox(self, tex, str(entry.get("title", "一頁回憶")), str(entry.get("body", "")))


func _unhandled_input(event: InputEvent) -> void:
	if UiStyle.lightbox_consume_cancel(self, event):
		get_viewport().set_input_as_handled()


func _polaroid_frame() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("FFFAFC")
	style.border_color = Color("F0C0D0")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.45, 0.22, 0.32, 0.12)
	style.shadow_size = 6
	style.shadow_offset = Vector2(2, 3)
	style.set_content_margin_all(12)
	return style


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


func _on_back() -> void:
	var dest := GameState.album_return_scene
	if dest == "":
		dest = "res://scenes/home_hub.tscn"
	GameState.album_return_scene = ""
	GameState.album_browse = []
	get_tree().change_scene_to_file(dest)
