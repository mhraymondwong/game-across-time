extends Control
## 日記封面標題：新遊戲／讀檔（三個存檔槽）／相簿

var _slot_layer: CanvasLayer
var _slot_panel: PanelContainer
var _slot_title: Label
var _slot_list: VBoxContainer
var _slot_mode: String = "load"


func _ready() -> void:
	_build_cover_bg()
	_build_bottom_cluster()
	_build_slot_layer()


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
	GameState.begin_new_game()
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
