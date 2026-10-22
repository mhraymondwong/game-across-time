extends Control
## 日記封面標題：新遊戲／讀檔（三個存檔槽）／相簿

var _slot_layer: CanvasLayer
var _slot_panel: PanelContainer
var _slot_title: Label
var _slot_list: VBoxContainer
var _slot_mode: String = "load"
var _name_layer: CanvasLayer
var _name_field: LineEdit
var _name_error: Label


func _ready() -> void:
	_build_cover_bg()
	_build_bottom_cluster()
	_build_slot_layer()
	_build_name_layer()
	if GameState.wants_new_game_name:
		_open_name_panel()


func _build_cover_bg() -> void:
	var cover_path := "res://assets/title_diary_cover.jpg"
	var fallback := "res://assets/title_bg.jpg"
	var path := cover_path if ResourceLoader.exists(cover_path) or FileAccess.file_exists(ProjectSettings.globalize_path(cover_path)) else fallback

	var bg := TextureRect.new()
	bg.texture = load(path)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var wash := ColorRect.new()
	wash.color = Color(0.96, 0.90, 0.88, 0.18)
	wash.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	wash.anchor_top = 0.72
	wash.offset_top = 0
	wash.offset_bottom = 0
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)


func _build_bottom_cluster() -> void:
	var strip := PanelContainer.new()
	strip.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	strip.anchor_left = 0.5
	strip.anchor_right = 0.5
	strip.anchor_top = 1.0
	strip.anchor_bottom = 1.0
	strip.offset_left = -400
	strip.offset_right = 400
	strip.offset_top = -168
	strip.offset_bottom = -28
	var strip_style := UiStyle.panel_style(Color(1.0, 0.97, 0.95, 0.78), Color("F0C8D0"), 20)
	strip_style.content_margin_left = 22
	strip_style.content_margin_right = 22
	strip_style.content_margin_top = 14
	strip_style.content_margin_bottom = 14
	strip_style.shadow_color = Color(0.55, 0.30, 0.35, 0.10)
	strip_style.shadow_size = 10
	strip.add_theme_stylebox_override("panel", strip_style)
	add_child(strip)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_child(v)

	var note := Label.new()
	note.text = "原創養成遊戲｜繁體中文"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(note, 13, true)
	v.add_child(note)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)

	var new_btn := Button.new()
	new_btn.text = "新遊戲"
	UiStyle.apply_button(new_btn, true)
	new_btn.custom_minimum_size = Vector2(150, 48)
	new_btn.pressed.connect(_on_new_game)
	row.add_child(new_btn)

	var load_btn := Button.new()
	load_btn.text = "讀檔"
	UiStyle.apply_button(load_btn, false)
	load_btn.custom_minimum_size = Vector2(150, 48)
	load_btn.pressed.connect(func() -> void: _open_slots("load"))
	row.add_child(load_btn)

	if _any_album():
		var album_btn := Button.new()
		album_btn.text = "相簿"
		UiStyle.apply_button(album_btn, false)
		album_btn.custom_minimum_size = Vector2(120, 48)
		album_btn.pressed.connect(func() -> void: _open_slots("album"))
		row.add_child(album_btn)

	var quit_btn := Button.new()
	quit_btn.text = "離開"
	UiStyle.apply_button(quit_btn, false)
	quit_btn.custom_minimum_size = Vector2(120, 48)
	quit_btn.pressed.connect(func() -> void: get_tree().quit())
	row.add_child(quit_btn)


func _any_album() -> bool:
	for i in range(3):
		var preview: Dictionary = GameState.save_slot_preview(i)
		if int(preview.get("album_count", 0)) > 0:
			return true
	return false


func _build_slot_layer() -> void:
	_slot_layer = CanvasLayer.new()
	_slot_layer.layer = 20
	_slot_layer.visible = false
	add_child(_slot_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.45, 0.22, 0.32, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_slot_layer.visible = false
	)
	_slot_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slot_layer.add_child(center)

	_slot_panel = PanelContainer.new()
	_slot_panel.custom_minimum_size = Vector2(520, 420)
	_slot_panel.add_theme_stylebox_override("panel", UiStyle.panel_style(Color("FFF5F8"), Color("F5B8C8"), 22))
	center.add_child(_slot_panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_slot_panel.add_child(v)

	_slot_title = Label.new()
	_slot_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(_slot_title, 24)
	v.add_child(_slot_title)

	_slot_list = VBoxContainer.new()
	_slot_list.add_theme_constant_override("separation", 8)
	_slot_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_slot_list)

	var back := Button.new()
	back.text = "返回"
	UiStyle.apply_button(back, false)
	back.pressed.connect(func() -> void: _slot_layer.visible = false)
	v.add_child(back)


func _open_slots(mode: String) -> void:
	_slot_mode = mode
	_rebuild_slots()
	_slot_layer.visible = true


func _rebuild_slots() -> void:
	for c in _slot_list.get_children():
		c.queue_free()
	if _slot_mode == "album":
		_slot_title.text = "翻開哪一本相簿"
	else:
		_slot_title.text = "讀檔"
	for i in range(3):
		var preview: Dictionary = GameState.save_slot_preview(i)
		var btn := Button.new()
		var exists := bool(preview.get("exists", false))
		var album_n := int(preview.get("album_count", 0))
		btn.text = "%s\n%s" % [str(preview.get("title", "")), str(preview.get("detail", ""))]
		if _slot_mode == "album" and exists and album_n > 0:
			btn.text += "\n相簿 %d 張" % album_n
		btn.custom_minimum_size = Vector2(0, 72)
		UiStyle.apply_soft_chip(btn, Color("FFE8F0"))
		btn.add_theme_font_size_override("font_size", 16)
		if _slot_mode == "album":
			btn.disabled = album_n <= 0
		else:
			btn.disabled = not exists
		var slot := i
		btn.pressed.connect(func() -> void: _on_slot(slot))
		_slot_list.add_child(btn)


func _on_new_game() -> void:
	_open_name_panel()


func _build_name_layer() -> void:
	_name_layer = CanvasLayer.new()
	_name_layer.name = "NameLayer"
	_name_layer.layer = 24
	_name_layer.visible = false
	add_child(_name_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.45, 0.22, 0.32, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_name_cancel()
	)
	_name_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 300)
	panel.add_theme_stylebox_override("panel", UiStyle.panel_style(Color("FFF5F8"), Color("F5B8C8"), 22))
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	margin.add_child(v)

	var title := Label.new()
	title.text = "她的名字"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(title, 26)
	v.add_child(title)

	var lead := Label.new()
	lead.text = "新的一本日記，先寫下她的名字。"
	lead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(lead, 15, true)
	v.add_child(lead)

	_name_field = LineEdit.new()
	_name_field.text = GameState.DEFAULT_DAUGHTER_NAME
	_name_field.placeholder_text = GameState.DEFAULT_DAUGHTER_NAME
	_name_field.max_length = GameState.DAUGHTER_NAME_MAX
	_name_field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_field.custom_minimum_size = Vector2(0, 52)
	_name_field.add_theme_font_override("font", UiStyle.ui_font())
	_name_field.add_theme_font_size_override("font_size", 22)
	_name_field.add_theme_color_override("font_color", GameConfig.COL_TEXT)
	_name_field.add_theme_color_override("font_placeholder_color", GameConfig.COL_TEXT_MUTED)
	_name_field.add_theme_color_override("caret_color", GameConfig.COL_TEXT)
	var field_box := StyleBoxFlat.new()
	field_box.bg_color = Color("FFF8FA")
	field_box.border_color = Color("F5B8C8")
	field_box.set_border_width_all(2)
	field_box.set_corner_radius_all(14)
	field_box.content_margin_left = 14
	field_box.content_margin_right = 14
	field_box.content_margin_top = 8
	field_box.content_margin_bottom = 8
	_name_field.add_theme_stylebox_override("normal", field_box)
	var focus_box := field_box.duplicate() as StyleBoxFlat
	focus_box.border_color = Color("F090A8")
	_name_field.add_theme_stylebox_override("focus", focus_box)
	_name_field.text_submitted.connect(func(_t: String) -> void: _on_name_confirm())
	_name_field.text_changed.connect(func(_t: String) -> void:
		if _name_error:
			_name_error.text = ""
	)
	v.add_child(_name_field)

	var hint := Label.new()
	hint.text = "一到八個字，中文、英文都可以。"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(hint, 13, true)
	v.add_child(hint)

	_name_error = Label.new()
	_name_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_error.custom_minimum_size = Vector2(0, 22)
	UiStyle.apply_label(_name_error, 14)
	_name_error.add_theme_color_override("font_color", Color("C45A7A"))
	v.add_child(_name_error)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)

	var back := Button.new()
	back.text = "返回封面"
	UiStyle.apply_button(back, false)
	back.custom_minimum_size = Vector2(150, 46)
	back.pressed.connect(_on_name_cancel)
	row.add_child(back)

	var ok := Button.new()
	ok.text = "寫下名字"
	UiStyle.apply_button(ok, true)
	ok.custom_minimum_size = Vector2(150, 46)
	ok.pressed.connect(_on_name_confirm)
	row.add_child(ok)


func _open_name_panel() -> void:
	if _slot_layer:
		_slot_layer.visible = false
	_name_field.text = GameState.DEFAULT_DAUGHTER_NAME
	_name_field.caret_column = _name_field.text.length()
	_name_error.text = ""
	_name_layer.visible = true
	_name_field.grab_focus()
	_name_field.select_all()


func _on_name_cancel() -> void:
	GameState.wants_new_game_name = false
	_name_layer.visible = false


func _on_name_confirm() -> void:
	var cleaned := _name_field.text.strip_edges()
	var err := GameState.daughter_name_error(cleaned)
	if err != "":
		_name_error.text = err
		return
	GameState.wants_new_game_name = false
	GameState.begin_new_game(cleaned)
	get_tree().change_scene_to_file("res://scenes/home_hub.tscn")


func _on_slot(slot: int) -> void:
	if _slot_mode == "album":
		if not GameState.browse_album_from_slot(slot):
			return
		get_tree().change_scene_to_file("res://scenes/album.tscn")
		return
	if not GameState.load_game(slot):
		return
	get_tree().change_scene_to_file("res://scenes/home_hub.tscn")
