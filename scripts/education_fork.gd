extends Control
## Diary page at the childhood → adulthood gate.
## Two warm paths. Neither changes the five axes or the skill pages.


var _body: VBoxContainer


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
		bg.modulate = Color(1, 1, 1, 0.88)
		add_child(bg)

	var wash := ColorRect.new()
	wash.color = Color(1.0, 0.94, 0.96, 0.55)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 80)
	root.add_theme_constant_override("margin_right", 80)
	root.add_theme_constant_override("margin_top", 36)
	root.add_theme_constant_override("margin_bottom", 32)
	add_child(root)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", DialogueChrome.paper_style())
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 12)
	margin.add_child(_body)
	DialogueChrome.dress_panel(panel)

	var path := Adulthood.education_path_of(GameState)
	if Adulthood.needs_education_choice(GameState):
		_show_choice()
	elif Adulthood.is_player_fork(path):
		_show_written(path)
	else:
		_show_note("這一頁還沒到", "升學的事，等她成年的第一個春天再寫。")


func _clear_body() -> void:
	if _body == null:
		return
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()


func _show_choice() -> void:
	_clear_body()
	_add_kicker("手帳新的一頁")
	_add_title("高中之後")
	_add_body(Adulthood.fork_lead(GameState))
	_body.add_child(_illustration_row("school", "work"))
	_body.add_child(_choice_button(
		"ChooseUniversity",
		Adulthood.COPY_UNIVERSITY_TITLE,
		Adulthood.university_blurb(),
		Adulthood.PATH_UNIVERSITY
	))
	_body.add_child(_choice_button(
		"ChooseHighSchool",
		Adulthood.COPY_HIGH_SCHOOL_TITLE,
		Adulthood.high_school_blurb(),
		Adulthood.PATH_HIGH_SCHOOL
	))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(spacer)
	_add_meta(Adulthood.fork_footnote())


func _show_written(path: String) -> void:
	_clear_body()
	_add_kicker("寫進手帳")
	_add_title("這一頁合上了")
	_add_body(Adulthood.written_body(path))
	var written_theme := "school" if path == Adulthood.PATH_UNIVERSITY else "work"
	_body.add_child(_illustration_row(written_theme, ""))
	_add_meta(Adulthood.fork_footnote())
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(spacer)
	_body.add_child(_button("翻開成年的手帳 ♡", true, _leave))


func _show_note(title: String, body: String) -> void:
	_clear_body()
	_add_kicker("手帳")
	_add_title(title)
	_add_body(body)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(spacer)
	_body.add_child(_button("回到手帳 ♡", true, _leave))


func _on_choose(path: String) -> void:
	if not Adulthood.choose_education(GameState, path):
		return
	_show_written(path)


func _leave() -> void:
	if get_tree() == null:
		return
	if get_tree().current_scene == self:
		get_tree().change_scene_to_file(Adulthood.HUB_SCENE)


func _choice_button(node_name: String, title: String, body: String, path: String) -> Button:
	var b := Button.new()
	b.name = node_name
	b.text = "%s\n%s" % [title, body]
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	UiStyle.apply_button(b, false)
	b.add_theme_font_size_override("font_size", 16)
	b.custom_minimum_size = Vector2(0, 108)
	b.pressed.connect(func() -> void: _on_choose(path))
	return b


func _illustration_row(theme_a: String, theme_b: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "ForkArt"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	row.add_child(DialogueChrome.make_bust("daughter", GameState.year, GameState.season, Vector2(108, 168)))
	row.add_child(DialogueChrome.make_stamp(theme_a, GameState.year))
	if theme_b != "":
		row.add_child(DialogueChrome.make_stamp(theme_b, GameState.year))
	return row


func _add_kicker(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(lbl, 14, true)
	_body.add_child(lbl)


func _add_title(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(lbl, 30)
	_body.add_child(lbl)


func _add_body(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(lbl, 16)
	_body.add_child(lbl)


func _add_meta(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(lbl, 14, true)
	_body.add_child(lbl)


func _button(text: String, primary: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	UiStyle.apply_button(b, primary)
	b.pressed.connect(cb)
	return b


func _load_tex(path: String) -> Texture2D:
	if path == "":
		return null
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	var abs := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs):
		var img := Image.load_from_file(abs)
		if img:
			return ImageTexture.create_from_image(img)
	return null
