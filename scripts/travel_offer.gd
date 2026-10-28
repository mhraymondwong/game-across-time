extends Control
## Even-year trip offer. Summer asks when to go; winter (if deferred) asks where.
## Confirming does not touch the three monthly schedule slots.


var _body: VBoxContainer
var _selected_id: String = ""
var _notice: String = ""


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
	root.add_theme_constant_override("margin_left", 48)
	root.add_theme_constant_override("margin_right", 48)
	root.add_theme_constant_override("margin_top", 28)
	root.add_theme_constant_override("margin_bottom", 24)
	add_child(root)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UiStyle.panel_style(Color("FFF8FA"), Color("F5A8C0"), 22))
	root.add_child(panel)

	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 10)
	panel.add_child(_body)

	if Travel.window_open(GameState) and int(GameState.season) == 1 and Travel.status_of(GameState) == "":
		_show_when()
	elif Travel.window_open(GameState):
		_show_dest()
	else:
		_show_note("這一年的遠行已經決定好了。", "回到手帳就好。")


func _clear_body() -> void:
	if _body == null:
		return
	var kids := _body.get_children()
	for c in kids:
		_body.remove_child(c)
		c.queue_free()


func _show_when() -> void:
	_clear_body()
	_add_kicker("兩年一次")
	_add_title("要出遠門嗎")
	var cash := int(GameState.cash)
	_add_body("第 %d 年可以走一趟遠的。選在這個夏天出發，或留到冬天；也可以今年先不去。日記還是排三個月，旅行是額外的一頁。" % int(GameState.year))
	_add_meta("家計　$%d" % cash)
	var tex := _load_tex(AgeLooks.family_photo(int(GameState.year)))
	if tex != null:
		_body.add_child(_photo_frame(tex, Vector2(360, 200)))
	_body.add_child(_button("夏天出發", true, _on_summer))
	_body.add_child(_button("留到冬天", false, _on_defer))
	_body.add_child(_button("今年不去", false, _on_skip))


func _show_dest() -> void:
	_clear_body()
	var summer := int(GameState.season) == 1
	_add_kicker("夏天出發" if summer else "冬天出發")
	_add_title("要去哪裡")
	_add_meta("家計　$%d　·　媽媽會一起去" % int(GameState.cash))
	if _notice != "":
		var note := Label.new()
		note.text = _notice
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.add_theme_color_override("font_color", Color("C45A7A"))
		UiStyle.apply_label(note, 15)
		note.add_theme_color_override("font_color", Color("C45A7A"))
		_body.add_child(note)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, 280)
	_body.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.custom_minimum_size = Vector2(720, 0)
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	for d in Travel.destinations():
		list.add_child(_dest_card(d))

	var confirm := Button.new()
	var why := ""
	if _selected_id == "":
		confirm.text = "先選一個地方"
		confirm.disabled = true
	else:
		why = Travel.lock_reason(Travel.get_dest(_selected_id), GameState)
		if why != "":
			confirm.text = why
			confirm.disabled = true
		else:
			var cost := int(Travel.get_dest(_selected_id).get("cost", 0))
			confirm.text = "確認出發　－$%d" % cost
			confirm.disabled = false
	UiStyle.apply_button(confirm, not confirm.disabled)
	confirm.pressed.connect(_on_confirm)
	_body.add_child(confirm)

	if summer:
		_body.add_child(_button("改留到冬天", false, _on_defer))
	_body.add_child(_button("今年不去", false, _on_skip))


func _dest_card(dest: Dictionary) -> PanelContainer:
	var dest_id := str(dest.get("id", ""))
	var selected := dest_id == _selected_id
	var reason := Travel.lock_reason(dest, GameState)
	var card := PanelContainer.new()
	var border := Color("E87898") if selected else Color("F0C0D0")
	var bg := Color("FFE4EE") if selected else Color("FFF0F6")
	var style := UiStyle.panel_style(bg, border, 14)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)

	var tex := _load_tex(Travel.scene_for(dest_id))
	if tex != null:
		row.add_child(_photo_frame(tex, Vector2(112, 84)))

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)

	var title := Label.new()
	title.text = "%s　·　$%d" % [str(dest.get("title", "")), int(dest.get("cost", 0))]
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(title, 18)
	col.add_child(title)

	var blurb := Label.new()
	if reason != "":
		blurb.text = reason
		blurb.add_theme_color_override("font_color", Color("C45A7A"))
	else:
		blurb.text = str(dest.get("blurb", ""))
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(blurb, 14, reason == "")
	if reason != "":
		blurb.add_theme_color_override("font_color", Color("C45A7A"))
	col.add_child(blurb)

	var pick := Button.new()
	if reason != "":
		pick.text = "還不能去"
		pick.disabled = true
	elif selected:
		pick.text = "已選擇"
	else:
		pick.text = "選這裡"
	UiStyle.apply_soft_chip(pick, Color("FFD0E4") if selected else Color("FFE8F0"))
	pick.custom_minimum_size = Vector2(108, 40)
	pick.pressed.connect(func() -> void: _select_dest(dest_id))
	row.add_child(pick)
	return card


func _show_result(res: Dictionary) -> void:
	_clear_body()
	_add_kicker("貼進相簿")
	_add_title(str(res.get("title", "遠行")))
	var scene_path := str(res.get("scene", ""))
	var thumb_path := str(res.get("thumb", ""))
	var scene_tex := _load_tex(scene_path)
	var album_tex := _load_tex(thumb_path)
	var scene_distinct := scene_tex != null and scene_path != thumb_path
	if scene_distinct:
		_body.add_child(_photo_frame(scene_tex, Vector2(480, 250)))
	if album_tex != null and scene_distinct:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 14)
		row.add_child(_photo_frame(album_tex, Vector2(148, 111)))
		var note := Label.new()
		note.text = "相簿貼上這張全家福。"
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UiStyle.apply_label(note, 15, true)
		row.add_child(note)
		_body.add_child(row)
	elif album_tex != null:
		_body.add_child(_photo_frame(album_tex, Vector2(480, 270)))
	elif scene_tex != null:
		_body.add_child(_photo_frame(scene_tex, Vector2(480, 270)))
	_add_body(str(res.get("body", "")))
	var delta_line := Travel.format_deltas(res.get("deltas", {}))
	if delta_line != "":
		_add_meta(delta_line)
	if bool(res.get("with_mom", false)) and str(res.get("thumb", "")) != "":
		_add_meta("這張照片裡，有媽媽。")
	_body.add_child(_button("回到手帳 ♡", true, _back))


func _show_note(title: String, body: String) -> void:
	_clear_body()
	_add_kicker("遠行")
	_add_title(title)
	if body != "":
		_add_body(body)
	_body.add_child(_button("回到手帳 ♡", true, _back))


func _on_summer() -> void:
	call_deferred("_show_dest")


func _on_defer() -> void:
	if not Travel.defer_to_winter(GameState):
		_notice = "沒能把旅行留到冬天。"
		call_deferred("_show_dest")
		return
	_notice = ""
	call_deferred("_show_note", "留到冬天", "好。夏天先在鎮上過。冬天回到這裡時，再一起決定要去哪裡。三個月的日記，照常排。")


func _on_skip() -> void:
	if not Travel.skip_window(GameState):
		call_deferred("_show_note", "這趟窗口已經關上了。", "回到手帳就好。")
		return
	call_deferred("_show_note", "今年留在鎮上", "沒有行李也很好。巷口、學校和家裡的燈，夠這一年慢慢走。")


func _on_confirm() -> void:
	if _selected_id == "":
		return
	var res: Dictionary = Travel.depart(GameState, _selected_id)
	if not bool(res.get("ok", false)):
		_notice = str(res.get("reason", "還不能出發。"))
		call_deferred("_show_dest")
		return
	_notice = ""
	call_deferred("_show_result", res)


func _select_dest(dest_id: String) -> void:
	_selected_id = dest_id
	_notice = ""
	call_deferred("_show_dest")


func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/home_hub.tscn")


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
	UiStyle.apply_label(lbl, 28)
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
	UiStyle.apply_label(lbl, 15, true)
	_body.add_child(lbl)


func _button(text: String, primary: bool, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	UiStyle.apply_button(b, primary)
	b.pressed.connect(cb)
	return b


func _photo_frame(tex: Texture2D, min_size: Vector2) -> PanelContainer:
	var frame := PanelContainer.new()
	var inner := UiStyle.panel_style(Color("FFFAFC"), Color("F0C0D0"), 8)
	inner.set_border_width_all(6)
	inner.border_width_bottom = 16
	inner.content_margin_left = 4
	inner.content_margin_right = 4
	inner.content_margin_top = 4
	inner.content_margin_bottom = 4
	frame.add_theme_stylebox_override("panel", inner)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var thumb := TextureRect.new()
	thumb.custom_minimum_size = min_size
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.texture = tex
	frame.add_child(thumb)
	return frame


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
