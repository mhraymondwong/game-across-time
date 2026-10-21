extends Control
## Phase 8 — 日記封面風標題：封面即標題，底部軟浮層按鈕


func _ready() -> void:
	_build_cover_bg()
	_build_bottom_cluster()


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

	# Very light bottom wash only — keep cover art visible
	var wash := ColorRect.new()
	wash.color = Color(0.96, 0.90, 0.88, 0.18)
	wash.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	wash.anchor_top = 0.72
	wash.offset_top = 0
	wash.offset_bottom = 0
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)


func _build_bottom_cluster() -> void:
	# Soft cream strip behind buttons (skip JPG ribbon — opaque grey/checker bg)
	var strip := PanelContainer.new()
	strip.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	strip.anchor_left = 0.5
	strip.anchor_right = 0.5
	strip.anchor_top = 1.0
	strip.anchor_bottom = 1.0
	strip.offset_left = -340
	strip.offset_right = 340
	strip.offset_top = -168
	strip.offset_bottom = -28
	var strip_style := UiStyle.panel_style(Color(1.0, 0.97, 0.95, 0.78), Color("F0C8D0"), 20)
	strip_style.content_margin_left = 28
	strip_style.content_margin_right = 28
	strip_style.content_margin_top = 16
	strip_style.content_margin_bottom = 16
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
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)

	var continue_btn := Button.new()
	continue_btn.text = "繼續遊戲"
	UiStyle.apply_button(continue_btn, false)
	continue_btn.custom_minimum_size = Vector2(180, 48)
	var has := GameState.has_save(0)
	continue_btn.disabled = not has
	if not has:
		continue_btn.text = "繼續遊戲（尚無存檔）"
		continue_btn.custom_minimum_size = Vector2(220, 48)
	continue_btn.pressed.connect(_on_continue)
	row.add_child(continue_btn)

	var start_btn := Button.new()
	start_btn.text = "開始養育"
	UiStyle.apply_button(start_btn, true)
	start_btn.custom_minimum_size = Vector2(180, 48)
	start_btn.pressed.connect(_on_start)
	row.add_child(start_btn)

	var quit_btn := Button.new()
	quit_btn.text = "離開"
	UiStyle.apply_button(quit_btn, false)
	quit_btn.custom_minimum_size = Vector2(120, 48)
	quit_btn.pressed.connect(func(): get_tree().quit())
	row.add_child(quit_btn)


func _on_continue() -> void:
	if not GameState.load_game(0):
		return
	get_tree().change_scene_to_file("res://scenes/home_hub.tscn")


func _on_start() -> void:
	GameState.begin_new_game()
	get_tree().change_scene_to_file("res://scenes/home_hub.tscn")
