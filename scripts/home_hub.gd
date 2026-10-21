extends Control
## Layout 2: fullscreen town map + bottom pink scrapbook diary drawer
## Full-body daughter mascot spans map ↔ drawer (right side)

const DRAWER_H := 280
const DRAWER_COLLAPSED := 48
const PIN_SIZE := Vector2(72, 84)
const PIN_LABEL_EXTRA := 22  # name plate below pin icon
const GIRL_W := 210.0
const GIRL_H := 520.0
## Right margin reserved so schedule/stats stay clear of the girl
const DRAWER_RIGHT_CLEAR := 230

var _time_lbl: Label
var _slot_btns: Array[Button] = []
var _confirm_btn: Button
var _stats_lbl: Label
var _cash_lbl: Label
var _selected_month: int = 0
var _drawer: Control
var _drawer_body: Control
var _drawer_expanded: bool = true
var _handle_btn: Button
var _popup_layer: CanvasLayer
var _popup_panel: PanelContainer
var _popup_title: Label
var _popup_body: Control
var _activity_popup: PanelContainer
var _activity_title: Label
var _activity_list: VBoxContainer
var _girl: TextureRect
var _save_btn: Button
var _save_toast: Label
var _npc_btn: Button
var _album_btn: Button
var _affinity_lbl: Label
var _npc_popup: PanelContainer
var _npc_list: VBoxContainer
var _save_popup: PanelContainer
var _save_list: VBoxContainer
var _pending_save_slot: int = -1
var _tutorial_layer: CanvasLayer
var _map_rng: RandomNumberGenerator = RandomNumberGenerator.new()

## Approximate pin positions on 1280x720 map (fractions of viewport)
const PLACES := [
	{
		"id": "home", "name": "住家", "pin": "res://assets/pins/home.png",
		"pos": Vector2(0.10, 0.46), "color": Color("F5C6C0"),
		"text": "你們的家。溫暖、有點雜亂，冰箱上貼著學校通知。\n可在日記裡安排家務與休息。"
	},
	{
		"id": "school", "name": "學校", "pin": "res://assets/pins/school.png",
		"pos": Vector2(0.55, 0.16), "color": Color("C9B8E8"),
		"text": "小鎮小學／中學。鐘聲準時，操場邊有老榕樹。\n學習類活動多在這裡展開。"
	},
	{
		"id": "park", "name": "公園", "pin": "res://assets/pins/park.png",
		"pos": Vector2(0.40, 0.54), "color": Color("B8E0B0"),
		"text": "春天花多、秋天落葉。傍晚常有街坊散步。\n適合休閒與偶發邂逅。"
	},
	{
		"id": "shops", "name": "商店街", "pin": "res://assets/pins/shops.png",
		"pos": Vector2(0.22, 0.34), "color": Color("F0D4A8"),
		"text": "麵包店、文具行、制服店。週末人潮較多。\n打工與氣質類活動相關。"
	},
	{
		"id": "clinic", "name": "診所", "pin": "res://assets/pins/clinic.png",
		"pos": Vector2(0.28, 0.18), "color": Color("B8D4E8"),
		"text": "社區診所。王醫師認識鎮上每一個孩子。\n可安排健康檢查與運動。"
	},
	{
		"id": "culture", "name": "文化中心", "pin": "res://assets/pins/culture.png",
		"pos": Vector2(0.62, 0.42), "color": Color("F0C8C0"),
		"text": "圖書館、小劇場、社區課程。\n才藝與社團多在這裡。"
	},
]


func _ready() -> void:
	_map_rng.randomize()
	_build_layout()
	_refresh()
	GameState.state_changed.connect(_refresh)
	resized.connect(_on_resized)
	call_deferred("_on_resized")


func _on_resized() -> void:
	_reposition_pins()
	_reposition_girl()


func _build_layout() -> void:
	# --- Fullscreen map ---
	var map_bg := TextureRect.new()
	map_bg.name = "MapBg"
	map_bg.texture = load("res://assets/town_map.jpg")
	map_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	map_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(map_bg)

	# Soft pink vignette at bottom so drawer reads clearly
	var fade := ColorRect.new()
	fade.color = Color(0.55, 0.25, 0.35, 0.14)
	fade.anchor_left = 0.0
	fade.anchor_right = 1.0
	fade.anchor_top = 0.55
	fade.anchor_bottom = 1.0
	fade.offset_left = 0
	fade.offset_right = 0
	fade.offset_top = 0
	fade.offset_bottom = 0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)

	# Pin layer
	var pin_layer := Control.new()
	pin_layer.name = "PinLayer"
	pin_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pin_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pin_layer.z_index = 8  # above drawer so labels never hidden under手帳
	add_child(pin_layer)

	for p in PLACES:
		var pin := _make_pin(p)
		pin_layer.add_child(pin)

	# --- Top thin HUD (pink glass) ---
	var top_hud := PanelContainer.new()
	top_hud.name = "TopHud"
	top_hud.anchor_left = 0.0
	top_hud.anchor_right = 1.0
	top_hud.anchor_top = 0.0
	top_hud.anchor_bottom = 0.0
	top_hud.offset_left = 16
	top_hud.offset_right = -16
	top_hud.offset_top = 10
	top_hud.offset_bottom = 52
	var hud_style := UiStyle.panel_style(Color(1, 0.94, 0.96, 0.90), Color("F5B8C8"), 14)
	hud_style.content_margin_top = 8
	hud_style.content_margin_bottom = 8
	hud_style.content_margin_left = 18
	hud_style.content_margin_right = 18
	top_hud.add_theme_stylebox_override("panel", hud_style)
	add_child(top_hud)

	_time_lbl = Label.new()
	_time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(_time_lbl, 20)
	top_hud.add_child(_time_lbl)

	# --- Bottom pink scrapbook diary drawer ---
	_drawer = Control.new()
	_drawer.name = "DiaryDrawer"
	_drawer.anchor_left = 0.0
	_drawer.anchor_right = 1.0
	_drawer.anchor_top = 1.0
	_drawer.anchor_bottom = 1.0
	_drawer.offset_left = 0
	_drawer.offset_right = 0
	_drawer.offset_top = -DRAWER_H
	_drawer.offset_bottom = 0
	add_child(_drawer)

	# Handle (pink chip)
	_handle_btn = Button.new()
	_handle_btn.text = "♥ 收起手帳"
	_handle_btn.anchor_left = 0.5
	_handle_btn.anchor_right = 0.5
	_handle_btn.anchor_top = 0.0
	_handle_btn.anchor_bottom = 0.0
	_handle_btn.offset_left = -78
	_handle_btn.offset_right = 78
	_handle_btn.offset_top = -34
	_handle_btn.offset_bottom = -2
	UiStyle.apply_soft_chip(_handle_btn, Color("FFD0E4"))
	_handle_btn.add_theme_font_size_override("font_size", 13)
	_handle_btn.pressed.connect(_toggle_drawer)
	_drawer.add_child(_handle_btn)

	# Drawer panel — pink scrapbook frame
	var drawer_panel := PanelContainer.new()
	drawer_panel.name = "DrawerPanel"
	drawer_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	drawer_panel.offset_left = 10
	drawer_panel.offset_right = -10
	drawer_panel.offset_top = 0
	drawer_panel.offset_bottom = -6
	var pink_frame := UiStyle.panel_style(Color("FFF5F8"), Color("F090A8"), 22)
	pink_frame.content_margin_left = 10
	pink_frame.content_margin_right = 10
	pink_frame.content_margin_top = 8
	pink_frame.content_margin_bottom = 8
	pink_frame.set_border_width_all(3)
	drawer_panel.add_theme_stylebox_override("panel", pink_frame)
	_drawer.add_child(drawer_panel)

	# Pink lace/hearts/bows diary art backdrop
	var diary_art := TextureRect.new()
	diary_art.name = "DiaryArt"
	diary_art.texture = load("res://assets/diary_pink.jpg")
	diary_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	diary_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	diary_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	diary_art.modulate = Color(1, 1, 1, 0.92)
	diary_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drawer_panel.add_child(diary_art)

	# Soft cream wash so text stays readable over busy scrapbook pattern
	var wash := ColorRect.new()
	wash.color = Color(1.0, 0.96, 0.97, 0.42)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drawer_panel.add_child(wash)

	_drawer_body = MarginContainer.new()
	_drawer_body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_drawer_body.add_theme_constant_override("margin_left", 14)
	_drawer_body.add_theme_constant_override("margin_right", DRAWER_RIGHT_CLEAR)
	_drawer_body.add_theme_constant_override("margin_top", 6)
	_drawer_body.add_theme_constant_override("margin_bottom", 6)
	drawer_panel.add_child(_drawer_body)

	var body_h := HBoxContainer.new()
	body_h.add_theme_constant_override("separation", 16)
	_drawer_body.add_child(body_h)

	# Schedule column (left / center — clear of girl)
	var sched := VBoxContainer.new()
	sched.add_theme_constant_override("separation", 6)
	sched.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_h.add_child(sched)

	var sched_title := Label.new()
	sched_title.text = "♡ 本季日記排程（每月選一項）"
	UiStyle.apply_label(sched_title, 15)
	sched.add_child(sched_title)

	var slots_row := HBoxContainer.new()
	slots_row.add_theme_constant_override("separation", 10)
	sched.add_child(slots_row)

	_slot_btns.clear()
	for i in range(GameConfig.MONTHS_PER_SEASON):
		var b := Button.new()
		b.text = "%s\n未選擇" % GameConfig.MONTH_LABELS[i]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 58)
		UiStyle.apply_sticker_chip(b, false, false)
		b.add_theme_font_size_override("font_size", 13)
		var idx := i
		b.pressed.connect(func(): _on_month_slot(idx))
		slots_row.add_child(b)
		_slot_btns.append(b)

	_confirm_btn = Button.new()
	_confirm_btn.text = "確認本季排程 → 結算"
	UiStyle.apply_button(_confirm_btn, true)
	_confirm_btn.custom_minimum_size = Vector2(0, 40)
	_confirm_btn.pressed.connect(_on_confirm_season)
	sched.add_child(_confirm_btn)

	# Stats column
	var stats_col := VBoxContainer.new()
	stats_col.add_theme_constant_override("separation", 6)
	stats_col.custom_minimum_size = Vector2(200, 0)
	body_h.add_child(stats_col)

	var stats_title := Label.new()
	stats_title.text = "✿ 屬性"
	UiStyle.apply_label(stats_title, 15)
	stats_col.add_child(stats_title)

	_stats_lbl = Label.new()
	_stats_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(_stats_lbl, 14)
	stats_col.add_child(_stats_lbl)

	_cash_lbl = Label.new()
	UiStyle.apply_label(_cash_lbl, 16)
	stats_col.add_child(_cash_lbl)

	_affinity_lbl = Label.new()
	_affinity_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(_affinity_lbl, 13, true)
	stats_col.add_child(_affinity_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 6)
	stats_col.add_child(btn_row)

	_npc_btn = Button.new()
	_npc_btn.text = "人際"
	UiStyle.apply_soft_chip(_npc_btn, Color("FFD0E4"))
	_npc_btn.add_theme_font_size_override("font_size", 14)
	_npc_btn.custom_minimum_size = Vector2(0, 36)
	_npc_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_npc_btn.pressed.connect(_show_npc_panel)
	btn_row.add_child(_npc_btn)

	_album_btn = Button.new()
	_album_btn.text = "相簿"
	UiStyle.apply_soft_chip(_album_btn, Color("FFD0E4"))
	_album_btn.add_theme_font_size_override("font_size", 14)
	_album_btn.custom_minimum_size = Vector2(0, 36)
	_album_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_album_btn.pressed.connect(_on_album_pressed)
	btn_row.add_child(_album_btn)

	_save_btn = Button.new()
	_save_btn.text = "♡ 存檔"
	UiStyle.apply_soft_chip(_save_btn, Color("FFD0E4"))
	_save_btn.add_theme_font_size_override("font_size", 14)
	_save_btn.custom_minimum_size = Vector2(0, 36)
	_save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_save_btn.pressed.connect(_on_save_pressed)
	btn_row.add_child(_save_btn)

	_save_toast = Label.new()
	_save_toast.text = ""
	_save_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(_save_toast, 13, true)
	stats_col.add_child(_save_toast)

	# --- Full-body girl: spans map + drawer; art swaps by age band ---
	_girl = TextureRect.new()
	_girl.name = "DaughterFullbody"
	_girl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_girl.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_girl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_girl.z_index = 5
	_girl.modulate = Color(1, 1, 1, 1)  # never ghost/semi-transparent
	add_child(_girl)
	_update_daughter_art()

	# --- Cute popup layer (location + activity) ---
	_popup_layer = CanvasLayer.new()
	_popup_layer.layer = 20
	add_child(_popup_layer)

	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.35, 0.18, 0.25, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	dim.gui_input.connect(_on_dim_input)
	_popup_layer.add_child(dim)

	_popup_panel = _make_popup_shell("地點")
	_popup_panel.visible = false
	_popup_layer.add_child(_popup_panel)

	_activity_popup = _make_activity_popup()
	_activity_popup.visible = false
	_popup_layer.add_child(_activity_popup)

	_npc_popup = _make_npc_popup()
	_npc_popup.visible = false
	_popup_layer.add_child(_npc_popup)

	_save_popup = _make_save_popup()
	_save_popup.visible = false
	_popup_layer.add_child(_save_popup)

	_maybe_tutorial()


func _update_daughter_art() -> void:
	if _girl == null:
		return
	var stage := GameConfig.growth_stage_for_year(GameState.year)
	var path := GameConfig.wardrobe_path_for_year_season(GameState.year, GameState.season)
	var tex: Texture2D = null
	if path != "" and (ResourceLoader.exists(path) or FileAccess.file_exists(ProjectSettings.globalize_path(path))):
		tex = load(path) if ResourceLoader.exists(path) else null
		if tex == null and FileAccess.file_exists(ProjectSettings.globalize_path(path)):
			var img := Image.load_from_file(ProjectSettings.globalize_path(path))
			if img:
				tex = ImageTexture.create_from_image(img)
	if tex == null:
		for fb in [
			"res://assets/daughter_fullbody_crop.png",
			"res://assets/daughter_fullbody.png",
			"res://assets/daughter_child.jpg",
		]:
			if ResourceLoader.exists(fb):
				tex = load(fb)
				break
	if tex != null:
		_girl.texture = tex
	_girl.set_meta("growth_stage", stage)
	_girl.set_meta("wardrobe_path", path)
	_girl.set_meta("art_band", GameConfig.age_art_band(GameState.get_age()))


func _reposition_girl() -> void:
	if _girl == null:
		return
	var sz := size
	if sz.x < 10 or sz.y < 10:
		sz = Vector2(GameConfig.VIEWPORT_W, GameConfig.VIEWPORT_H)
	# Tall enough to cross map/drawer boundary; feet sit in diary area
	var h := GIRL_H
	var w := GIRL_W
	# Scale slightly with viewport
	var scale_f := clampf(sz.y / float(GameConfig.VIEWPORT_H), 0.85, 1.15)
	h *= scale_f
	w *= scale_f
	var feet_pad := 18.0
	if not _drawer_expanded:
		# When collapsed, tuck a bit higher so she still peeks over the strip
		feet_pad = 8.0
	var bottom := sz.y - feet_pad
	var top := bottom - h
	# Center-right: leave left ~70% clear for map pins + drawer content
	var x := sz.x - w - 28.0
	_girl.position = Vector2(x, top)
	_girl.size = Vector2(w, h)


func _make_pin(p: Dictionary) -> Control:
	var wrap := Control.new()
	wrap.name = "Pin_%s" % p["id"]
	wrap.custom_minimum_size = PIN_SIZE
	wrap.size = PIN_SIZE
	wrap.mouse_filter = Control.MOUSE_FILTER_STOP
	wrap.set_meta("place", p)

	var tex := TextureRect.new()
	tex.texture = load(p["pin"])
	tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(tex)

	var plate := PanelContainer.new()
	plate.anchor_left = 0.1
	plate.anchor_right = 0.9
	plate.anchor_top = 1.0
	plate.anchor_bottom = 1.0
	plate.offset_top = 0
	plate.offset_bottom = 20
	var ps := UiStyle.panel_style(Color(p["color"].r, p["color"].g, p["color"].b, 0.92), Color(0, 0, 0, 0.06), 10)
	ps.content_margin_top = 2
	ps.content_margin_bottom = 2
	ps.content_margin_left = 4
	ps.content_margin_right = 4
	ps.shadow_size = 2
	plate.add_theme_stylebox_override("panel", ps)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(plate)
	var lbl := Label.new()
	lbl.text = p["name"]
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(lbl, 11)
	plate.add_child(lbl)

	var btn := Button.new()
	btn.flat = true
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.offset_bottom = 20
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var place: Dictionary = p
	btn.pressed.connect(func(): _show_place_popup(place))
	wrap.add_child(btn)
	return wrap


func _reposition_pins() -> void:
	var layer := get_node_or_null("PinLayer")
	if layer == null:
		return
	var sz := size
	if sz.x < 10 or sz.y < 10:
		sz = Vector2(GameConfig.VIEWPORT_W, GameConfig.VIEWPORT_H)
	for child in layer.get_children():
		if not child.has_meta("place"):
			continue
		var p: Dictionary = child.get_meta("place")
		var frac: Vector2 = p["pos"]
		var px := frac.x * sz.x - PIN_SIZE.x * 0.5
		var py := frac.y * sz.y - PIN_SIZE.y * 0.7
		var max_y := sz.y - (DRAWER_H if _drawer_expanded else DRAWER_COLLAPSED) - PIN_SIZE.y - PIN_LABEL_EXTRA - 10
		py = mini(py, max_y)
		# Keep pins left of girl a bit
		var max_x := sz.x - GIRL_W - 40
		px = mini(px, max_x)
		child.position = Vector2(px, maxf(py, 56))


func _toggle_drawer() -> void:
	_drawer_expanded = not _drawer_expanded
	if _drawer_expanded:
		_drawer.offset_top = -DRAWER_H
		_drawer_body.visible = true
		_handle_btn.text = "♥ 收起手帳"
	else:
		_drawer.offset_top = -DRAWER_COLLAPSED
		_drawer_body.visible = false
		_handle_btn.text = "♡ 展開手帳"
	_on_resized()


func _make_popup_shell(title_text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 300)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -240
	panel.offset_right = 240
	panel.offset_top = -180
	panel.offset_bottom = 180
	panel.add_theme_stylebox_override("panel", UiStyle.panel_style(Color("FFF5F8"), Color("F5B8C8"), 22))

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)

	_popup_title = Label.new()
	_popup_title.text = title_text
	_popup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(_popup_title, 24)
	v.add_child(_popup_title)

	_popup_body = VBoxContainer.new()
	_popup_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_popup_body)

	var close := Button.new()
	close.text = "好的 ♡"
	UiStyle.apply_button(close, true)
	close.pressed.connect(_hide_popups)
	v.add_child(close)
	return panel


func _make_activity_popup() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 480)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -260
	panel.offset_right = 260
	panel.offset_top = -250
	panel.offset_bottom = 250
	panel.add_theme_stylebox_override("panel", UiStyle.panel_style(Color("FFF5F8"), Color("F5B8C8"), 22))

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	_activity_title = Label.new()
	_activity_title.text = "選擇活動"
	_activity_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(_activity_title, 22)
	v.add_child(_activity_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 360)
	v.add_child(scroll)

	_activity_list = VBoxContainer.new()
	_activity_list.add_theme_constant_override("separation", 6)
	_activity_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_activity_list)

	var close := Button.new()
	close.text = "關閉"
	UiStyle.apply_button(close, false)
	close.pressed.connect(_hide_popups)
	v.add_child(close)
	return panel


func _show_place_popup(p: Dictionary) -> void:
	_hide_popups()
	_popup_layer.get_node("Dim").visible = true
	var place_id := str(p.get("id", ""))
	var place_name := str(p.get("name", "地點"))
	var ev: Dictionary = GameState.trigger_place_event(place_id, _map_rng, true, true)
	var deltas: Dictionary = {}
	var raw_d = ev.get("deltas", {})
	if typeof(raw_d) == TYPE_DICTIONARY:
		deltas = raw_d
	_popup_title.text = "%s · %s" % [place_name, str(ev.get("title", ""))]
	for c in _popup_body.get_children():
		c.queue_free()
	var intro := Label.new()
	intro.text = str(p.get("text", ""))
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(intro, 13, true)
	_popup_body.add_child(intro)
	var body := Label.new()
	body.text = str(ev.get("body", ""))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(body, 16)
	_popup_body.add_child(body)
	var delta_line := MapEvents.format_delta_line(deltas if typeof(deltas) == TYPE_DICTIONARY else {})
	if delta_line != "":
		var dl := Label.new()
		dl.text = delta_line
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiStyle.apply_label(dl, 14)
		_popup_body.add_child(dl)
	var aff = ev.get("affinity", {})
	if typeof(aff) == TYPE_DICTIONARY and not aff.is_empty() and not bool(ev.get("skipped", false)):
		var aff_line := TownNpcs.format_bump_line(aff)
		if aff_line != "":
			var al := Label.new()
			al.text = aff_line
			al.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			UiStyle.apply_label(al, 14)
			_popup_body.add_child(al)
	var act_btn := Button.new()
	act_btn.text = "在這裡安排活動"
	UiStyle.apply_button(act_btn, false)
	act_btn.pressed.connect(_on_place_schedule_activity)
	_popup_body.add_child(act_btn)
	_popup_panel.visible = true


func _on_place_schedule_activity() -> void:
	_hide_popups()
	# Prefer first empty month slot; else currently selected / 0
	var target := _selected_month
	for i in range(GameConfig.MONTHS_PER_SEASON):
		if i < GameState.season_schedule.size() and GameState.season_schedule[i] == "":
			target = i
			break
	_selected_month = clampi(target, 0, GameConfig.MONTHS_PER_SEASON - 1)
	_show_activity_picker()


func _on_album_pressed() -> void:
	GameState.album_return_scene = ""
	GameState.album_browse = []
	get_tree().change_scene_to_file("res://scenes/album.tscn")


func _on_save_pressed() -> void:
	_hide_popups()
	_pending_save_slot = -1
	_popup_layer.get_node("Dim").visible = true
	_rebuild_save_slots(false)
	_save_popup.visible = true


func _make_save_popup() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 420)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -240
	panel.offset_right = 240
	panel.offset_top = -230
	panel.offset_bottom = 230
	panel.add_theme_stylebox_override("panel", UiStyle.panel_style(Color("FFF5F8"), Color("F5B8C8"), 22))

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	var title := Label.new()
	title.text = "寫進哪一本日記"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(title, 22)
	v.add_child(title)

	_save_list = VBoxContainer.new()
	_save_list.add_theme_constant_override("separation", 8)
	_save_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_save_list)

	var close := Button.new()
	close.text = "返回"
	UiStyle.apply_button(close, false)
	close.pressed.connect(_hide_popups)
	v.add_child(close)
	return panel


func _rebuild_save_slots(confirming: bool) -> void:
	if _save_list == null:
		return
	for c in _save_list.get_children():
		c.queue_free()
	if confirming:
		var preview: Dictionary = GameState.save_slot_preview(_pending_save_slot)
		var warn := Label.new()
		warn.text = "要覆寫「%s」嗎？\n裡面是%s。" % [str(preview.get("title", "")), str(preview.get("detail", ""))]
		warn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiStyle.apply_label(warn, 16)
		_save_list.add_child(warn)
		var yes := Button.new()
		yes.text = "覆寫"
		UiStyle.apply_button(yes, true)
		yes.pressed.connect(func() -> void: _write_slot(_pending_save_slot))
		_save_list.add_child(yes)
		var no := Button.new()
		no.text = "先不要"
		UiStyle.apply_button(no, false)
		no.pressed.connect(func() -> void: _rebuild_save_slots(false))
		_save_list.add_child(no)
		return
	for i in range(3):
		var preview: Dictionary = GameState.save_slot_preview(i)
		var btn := Button.new()
		btn.text = "%s\n%s" % [str(preview.get("title", "")), str(preview.get("detail", ""))]
		btn.custom_minimum_size = Vector2(0, 64)
		UiStyle.apply_soft_chip(btn, Color("FFE8F0"))
		btn.add_theme_font_size_override("font_size", 15)
		var slot := i
		var exists := bool(preview.get("exists", false))
		btn.pressed.connect(func() -> void: _on_save_slot(slot, exists))
		_save_list.add_child(btn)


func _on_save_slot(slot: int, exists: bool) -> void:
	if exists:
		_pending_save_slot = slot
		_rebuild_save_slots(true)
		return
	_write_slot(slot)


func _write_slot(slot: int) -> void:
	var ok := GameState.save_game(slot)
	_hide_popups()
	if _save_toast:
		if ok:
			_save_toast.text = "已寫進%s ♡" % GameState.slot_title(slot)
		else:
			_save_toast.text = "存檔失敗…"
		get_tree().create_timer(1.6).timeout.connect(func() -> void:
			if is_instance_valid(_save_toast):
				_save_toast.text = ""
		)


func _maybe_tutorial() -> void:
	if GameState.year != 1 or GameState.season != 0 or GameState.months_played > 0:
		return
	if bool(GameState.flags.get("tutorial_done", false)):
		return
	_tutorial_layer = CanvasLayer.new()
	_tutorial_layer.layer = 12
	add_child(_tutorial_layer)

	var card := PanelContainer.new()
	card.offset_left = 24
	card.offset_top = 68
	card.offset_right = 460
	card.offset_bottom = 292
	card.add_theme_stylebox_override("panel", UiStyle.panel_style(Color(1, 0.96, 0.97, 0.96), Color("F090A8"), 18))
	_tutorial_layer.add_child(card)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)

	var title := Label.new()
	title.text = "第一季的手帳"
	UiStyle.apply_label(title, 20)
	v.add_child(title)

	for line in [
		"地圖上的圖釘可以走訪住家、學校、公園。每個地方，一季只會遇見一件小事。",
		"在下方日記替三個月各選一項活動。",
		"排滿之後，按「確認本季排程」，就會結算，並讀到她們的小故事。",
	]:
		var lbl := Label.new()
		lbl.text = line
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiStyle.apply_label(lbl, 14)
		v.add_child(lbl)

	var ok := Button.new()
	ok.text = "知道了 ♡"
	UiStyle.apply_button(ok, true)
	ok.pressed.connect(_dismiss_tutorial)
	v.add_child(ok)


func _dismiss_tutorial() -> void:
	GameState.flags["tutorial_done"] = true
	if _tutorial_layer:
		_tutorial_layer.queue_free()
		_tutorial_layer = null


func _on_month_slot(i: int) -> void:
	_selected_month = i
	_refresh_slots_highlight()
	_show_activity_picker()


func _show_activity_picker() -> void:
	_hide_popups()
	_popup_layer.get_node("Dim").visible = true
	_activity_title.text = "選擇活動 · %s" % GameConfig.MONTH_LABELS[_selected_month]
	_rebuild_activity_list()
	_activity_popup.visible = true


func _rebuild_activity_list() -> void:
	for c in _activity_list.get_children():
		c.queue_free()
	# Soft mood tip when heavy activities are gated
	if int(GameState.mood) < 35:
		var tip := Label.new()
		tip.text = "女兒心情偏低，激烈活動暫時鎖上；安排休息或休閒會比較好。"
		tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiStyle.apply_label(tip, 13, false)
		tip.add_theme_color_override("font_color", Color("C45A7A"))
		_activity_list.add_child(tip)
	var by_cat := Activities.ids_by_category()
	for cat in by_cat:
		var cat_lbl := Label.new()
		cat_lbl.text = "— %s —" % cat
		UiStyle.apply_label(cat_lbl, 14, true)
		_activity_list.add_child(cat_lbl)
		for id in by_cat[cat]:
			var def: Dictionary = Activities.get_activity(id)
			var row := Button.new()
			var cash_s := int(def.get("cash", 0))
			var cash_txt := ("＋$%d" % cash_s) if cash_s > 0 else ("－$%d" % abs(cash_s) if cash_s < 0 else "$0")
			var avail: Dictionary = Activities.availability(id, GameState)
			var ok: bool = bool(avail.get("ok", false))
			var reason: String = str(avail.get("reason", ""))
			if ok:
				row.text = "%s（%s）" % [def.get("name", id), cash_txt]
				row.tooltip_text = str(def.get("desc", ""))
			else:
				var short_reason := reason
				if short_reason.length() > 14:
					short_reason = short_reason.substr(0, 14) + "…"
				row.text = "%s（%s）· %s" % [def.get("name", id), cash_txt, short_reason]
				row.tooltip_text = "%s\n🔒 %s" % [str(def.get("desc", "")), reason]
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			UiStyle.apply_soft_chip(row, Color("FFE8F0"))
			var aid: String = id
			row.disabled = not ok
			row.pressed.connect(func(): _pick_activity(aid))
			_activity_list.add_child(row)


func _pick_activity(id: String) -> void:
	GameState.set_schedule_slot(_selected_month, id)
	for i in range(GameConfig.MONTHS_PER_SEASON):
		if GameState.season_schedule[i] == "":
			_selected_month = i
			break
	_hide_popups()
	_refresh()


func _hide_popups() -> void:
	_popup_panel.visible = false
	_activity_popup.visible = false
	if _npc_popup:
		_npc_popup.visible = false
	if _save_popup:
		_save_popup.visible = false
	var dim := _popup_layer.get_node_or_null("Dim")
	if dim:
		dim.visible = false


func _make_npc_popup() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 460)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -260
	panel.offset_right = 260
	panel.offset_top = -240
	panel.offset_bottom = 240
	panel.add_theme_stylebox_override("panel", UiStyle.panel_style(Color("FFF5F8"), Color("F5B8C8"), 22))

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	var title := Label.new()
	title.text = "人際"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(title, 24)
	v.add_child(title)

	var sub := Label.new()
	sub.text = "好感會跟著活動、地圖小事與季節，慢慢暖起來。"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(sub, 13, true)
	v.add_child(sub)

	_npc_list = VBoxContainer.new()
	_npc_list.add_theme_constant_override("separation", 8)
	_npc_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_npc_list)

	var close := Button.new()
	close.text = "好的 ♡"
	UiStyle.apply_button(close, true)
	close.pressed.connect(_hide_popups)
	v.add_child(close)
	return panel


func _show_npc_panel() -> void:
	_hide_popups()
	_popup_layer.get_node("Dim").visible = true
	_rebuild_npc_list()
	_npc_popup.visible = true


func _rebuild_npc_list() -> void:
	if _npc_list == null:
		return
	for c in _npc_list.get_children():
		c.queue_free()
	for d in TownNpcs.defs():
		var id := str(d.get("id", ""))
		var value := TownNpcs.value_of(GameState, id)
		var card := PanelContainer.new()
		var style := UiStyle.panel_style(Color("FFF0F6"), Color("F5C0D0"), 14)
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", style)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 2)
		card.add_child(col)

		var head := Label.new()
		head.text = "%s　·　%s　·　%s" % [
			str(d.get("name", "")), str(d.get("role", "")), str(d.get("place_name", ""))
		]
		head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiStyle.apply_label(head, 16)
		col.add_child(head)

		var bio := Label.new()
		bio.text = str(d.get("bio", ""))
		bio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiStyle.apply_label(bio, 13, true)
		col.add_child(bio)

		var hearts := Label.new()
		hearts.text = "好感 %d　%s" % [value, TownNpcs.heart_row(value)]
		UiStyle.apply_label(hearts, 15)
		col.add_child(hearts)
		_npc_list.add_child(card)


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_hide_popups()


func _on_confirm_season() -> void:
	if not GameState.is_season_fully_scheduled():
		_confirm_btn.text = "請先排滿三個月！"
		return
	GameState.resolve_season()
	get_tree().change_scene_to_file("res://scenes/season_result.tscn")


func _refresh_slots_highlight() -> void:
	for i in range(_slot_btns.size()):
		var id: String = GameState.season_schedule[i] if i < GameState.season_schedule.size() else ""
		var label: String = GameConfig.MONTH_LABELS[i]
		var filled := id != ""
		var selected := i == _selected_month
		if not filled:
			_slot_btns[i].text = "%s\n未選擇" % label
		else:
			var def: Dictionary = Activities.get_activity(id)
			_slot_btns[i].text = "%s\n%s" % [label, def.get("name", id)]
		UiStyle.apply_sticker_chip(_slot_btns[i], selected, filled)
		_slot_btns[i].add_theme_font_size_override("font_size", 13)


func _refresh() -> void:
	_update_daughter_art()
	var stage := GameConfig.growth_stage_for_year(GameState.year)
	var sn := GameConfig.season_name(GameState.season)
	_time_lbl.text = "♡  %s · 成長階段 %d（%s）· %s裝" % [
		GameState.get_time_label(), stage, GameConfig.growth_stage_label(stage), sn
	]
	var s := GameState.get_stats_dict()
	_stats_lbl.text = "魅力 %d　道德 %d\n人際 %d　體力 %d\n學識 %d　心情 %d" % [
		s["charm"], s["morals"],
		s["social"], s["stamina"],
		s["academia"], s["mood"],
	]
	_cash_lbl.text = "家計  $%d" % s["cash"]
	if _affinity_lbl:
		_affinity_lbl.text = TownNpcs.hub_line(GameState)
	_refresh_slots_highlight()
	if GameState.is_season_fully_scheduled():
		_confirm_btn.text = "確認本季排程 → 結算"
		UiStyle.apply_button(_confirm_btn, true)
	else:
		_confirm_btn.text = "排滿三個月後可結算"
		UiStyle.apply_button(_confirm_btn, false)
	_confirm_btn.disabled = false
