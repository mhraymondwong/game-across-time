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
## Mom hub pin. Source art is 385×1152; this size keeps that ratio.
## Narrow enough to stand left of the home map pin, much smaller than the daughter.
const MOM_PIN_W := 76.0
const MOM_PIN_H := 227.0

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
var _popup_banner_frame: PanelContainer
var _popup_banner: TextureRect
var _popup_pin: TextureRect
var _popup_chips: HFlowContainer
var _round_shader: Shader
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
var _mom_card: Control
var _mom_tex: TextureRect
var _mom_shadow: TextureRect
var _mom_popup: PanelContainer
var _mom_line: Label
var _mom_help_lbl: Label
var _mom_help_btn: Button
var _mom_portrait: TextureRect
var _mom_shell: Dictionary = {}
var _travel_hint: Label
var _confide_popup: PanelContainer
var _confide_box: VBoxContainer
var _confide_actions: VBoxContainer
var _confide_shell: Dictionary = {}
var _confide_offer: Dictionary = {}
var _growth_lbl: Label
var _growth_btn: Button
var _growth_popup: PanelContainer
var _growth_box: VBoxContainer
var _growth_layer: CanvasLayer
var _sched_title: Label
var _job_lbl: Label
var _job_btn: Button
var _romance_lbl: Label
var _job_popup: PanelContainer
var _job_list: VBoxContainer
var _job_note: Label
var _adult_layer: CanvasLayer

## Approximate pin positions on 1280x720 map (fractions of viewport)
const PLACES := [
	{
		"id": "home", "name": "住家", "pin": "res://assets/pins/home.png",
		"art": "res://assets/places/place_home.jpg",
		"chips": ["♡ 家", "燈火", "熱湯"],
		"pos": Vector2(0.10, 0.46), "color": Color("F5C6C0"),
		"text": "你們的家。溫暖、有點雜亂，冰箱上貼著學校通知。\n可在日記裡安排家務與休息。"
	},
	{
		"id": "school", "name": "學校", "pin": "res://assets/pins/school.png",
		"art": "res://assets/places/place_school.jpg",
		"chips": ["書本", "鐘聲", "操場"],
		"pos": Vector2(0.55, 0.16), "color": Color("C9B8E8"),
		"text": "小鎮小學／中學。鐘聲準時，操場邊有老榕樹。\n學習、校園園藝與小義工多在這裡展開。"
	},
	{
		"id": "park", "name": "公園", "pin": "res://assets/pins/park.png",
		"art": "res://assets/places/place_park.jpg",
		"chips": ["✿ 花", "散步", "樹蔭"],
		"pos": Vector2(0.40, 0.54), "color": Color("B8E0B0"),
		"text": "春天花多、秋天落葉。傍晚常有街坊散步。\n適合休閒與偶發邂逅。"
	},
	{
		"id": "shops", "name": "商店街", "pin": "res://assets/pins/shops.png",
		"art": "res://assets/places/place_shops.jpg",
		"chips": ["袋子", "麵包", "週末"],
		"pos": Vector2(0.22, 0.34), "color": Color("F0D4A8"),
		"text": "麵包店、文具行、制服店。週末人潮較多。\n小時候可跟家人去市集幫忙；長大後才有打工。"
	},
	{
		"id": "clinic", "name": "診所", "pin": "res://assets/pins/clinic.png",
		"art": "res://assets/places/place_clinic.jpg",
		"chips": ["診療", "健康", "白袍"],
		"pos": Vector2(0.28, 0.18), "color": Color("B8D4E8"),
		"text": "社區診所。王醫師認識鎮上每一個孩子。\n可安排健康檢查；年紀到了，也能來當暑期小義工。"
	},
	{
		"id": "culture", "name": "文化中心", "pin": "res://assets/pins/culture.png",
		"art": "res://assets/places/place_culture.jpg",
		"chips": ["劇場", "閱讀", "社團"],
		"pos": Vector2(0.62, 0.42), "color": Color("F0C8C0"),
		"text": "圖書館、小劇場、社區課程。\n才藝與社團多在這裡。"
	},
]


func _ready() -> void:
	# First adult entry: university or high-school career, before the job card and before a trip.
	if get_tree().current_scene == self and Adulthood.needs_education_choice(GameState):
		call_deferred("_open_education_fork")
		return
	# Even years: the trip page comes before this season's three months.
	if Travel.offer_due(GameState):
		call_deferred("_open_travel_offer")
		return
	_map_rng.randomize()
	_build_layout()
	_refresh()
	_maybe_growth_tutorial()
	_maybe_adult_intro()
	_maybe_confide()
	GameState.state_changed.connect(_refresh)
	resized.connect(_on_resized)
	call_deferred("_on_resized")


func _on_resized() -> void:
	_reposition_pins()
	_reposition_girl()
	_position_mom_card()


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

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	sched.add_child(title_row)

	_sched_title = Label.new()
	_sched_title.text = "♡ 本季日記排程（每月選一項）"
	_sched_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sched_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyle.apply_label(_sched_title, 15)
	title_row.add_child(_sched_title)

	_job_btn = Button.new()
	_job_btn.text = "選定工作"
	_job_btn.visible = false
	UiStyle.apply_soft_chip(_job_btn, Color("FFE0C8"))
	_job_btn.add_theme_font_size_override("font_size", 13)
	_job_btn.custom_minimum_size = Vector2(108, 36)
	_job_btn.pressed.connect(_show_job_panel)
	title_row.add_child(_job_btn)

	_job_lbl = Label.new()
	_job_lbl.visible = false
	_job_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(_job_lbl, 13, true)
	sched.add_child(_job_lbl)

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

	_travel_hint = Label.new()
	_travel_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(_travel_hint, 13, true)
	_travel_hint.visible = false
	stats_col.add_child(_travel_hint)

	_affinity_lbl = Label.new()
	_affinity_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(_affinity_lbl, 13, true)
	stats_col.add_child(_affinity_lbl)

	_growth_lbl = Label.new()
	_growth_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_growth_lbl.visible = false
	UiStyle.apply_label(_growth_lbl, 13, true)
	stats_col.add_child(_growth_lbl)

	_growth_btn = Button.new()
	_growth_btn.text = "翻開專長"
	_growth_btn.visible = false
	UiStyle.apply_soft_chip(_growth_btn, Color("FFE0C8"))
	_growth_btn.add_theme_font_size_override("font_size", 14)
	_growth_btn.custom_minimum_size = Vector2(0, 36)
	_growth_btn.pressed.connect(_show_growth_panel)
	stats_col.add_child(_growth_btn)

	_romance_lbl = Label.new()
	_romance_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_romance_lbl.visible = false
	UiStyle.apply_label(_romance_lbl, 13, true)
	stats_col.add_child(_romance_lbl)

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

	_mom_popup = _make_mom_popup()
	_mom_popup.visible = false
	_popup_layer.add_child(_mom_popup)

	_confide_popup = _make_confide_popup()
	_confide_popup.visible = false
	_popup_layer.add_child(_confide_popup)

	_growth_popup = _make_growth_popup()
	_growth_popup.visible = false
	_popup_layer.add_child(_growth_popup)

	_job_popup = _make_job_popup()
	_job_popup.visible = false
	_popup_layer.add_child(_job_popup)

	_save_popup = _make_save_popup()
	_save_popup.visible = false
	_popup_layer.add_child(_save_popup)

	_build_mom_card()
	_maybe_tutorial()


func _update_daughter_art() -> void:
	if _girl == null:
		return
	var stage := GameConfig.growth_stage_for_year(GameState.year)
	var path := AgeLooks.daughter_portrait(GameState.year, GameState.season)
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
	_girl.set_meta("age_band", AgeLooks.band_for_year(GameState.year))


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
	panel.custom_minimum_size = Vector2(720, 680)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -370
	panel.offset_right = 370
	panel.offset_top = -340
	panel.offset_bottom = 340
	var shell := UiStyle.panel_style(Color("FFF5F8"), Color("F5B8C8"), 22)
	shell.content_margin_left = 14
	shell.content_margin_right = 14
	shell.content_margin_top = 12
	shell.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", shell)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	_popup_banner_frame = PanelContainer.new()
	var banner_style := StyleBoxFlat.new()
	banner_style.bg_color = Color("FFF8FA")
	banner_style.set_corner_radius_all(18)
	banner_style.set_content_margin_all(0)
	_popup_banner_frame.add_theme_stylebox_override("panel", banner_style)
	_popup_banner_frame.clip_contents = true
	_popup_banner_frame.visible = false
	v.add_child(_popup_banner_frame)

	_popup_banner_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_popup_banner = TextureRect.new()
	# 16:9, same shape as the place stills, so the header is a photo rather than a thin band.
	_popup_banner.custom_minimum_size = Vector2(554, 312)
	_popup_banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_popup_banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_popup_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popup_banner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_popup_banner.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_popup_banner_frame.add_child(_popup_banner)
	_apply_round_corners(_popup_banner, 18.0)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(title_row)

	_popup_pin = TextureRect.new()
	_popup_pin.custom_minimum_size = Vector2(36, 42)
	_popup_pin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_popup_pin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_popup_pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(_popup_pin)

	_popup_title = Label.new()
	_popup_title.text = title_text
	_popup_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_popup_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_popup_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(_popup_title, 22)
	title_row.add_child(_popup_title)

	_popup_chips = HFlowContainer.new()
	_popup_chips.add_theme_constant_override("h_separation", 6)
	_popup_chips.add_theme_constant_override("v_separation", 6)
	_popup_chips.alignment = FlowContainer.ALIGNMENT_CENTER
	v.add_child(_popup_chips)

	_popup_body = VBoxContainer.new()
	_popup_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_popup_body.add_theme_constant_override("separation", 8)
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


func _clear_box(box: Node) -> void:
	if box == null:
		return
	for c in box.get_children():
		box.remove_child(c)
		c.free()


func _make_place_chip(text: String, tint: Color) -> PanelContainer:
	var wrap := PanelContainer.new()
	var fill := Color(tint.r, tint.g, tint.b, 0.95)
	var sb := UiStyle.button_style(fill, Color("E8A0B4"), 14)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	wrap.add_theme_stylebox_override("panel", sb)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lbl := Label.new()
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.apply_label(lbl, 13)
	wrap.add_child(lbl)
	return wrap


func _load_ui_tex(path: String) -> Texture2D:
	if path == "":
		return null
	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded is Texture2D:
			return loaded
	var abs_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img:
			return ImageTexture.create_from_image(img)
	return null


func _apply_round_corners(tex: TextureRect, radius: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if _round_shader == null:
		_round_shader = Shader.new()
		_round_shader.code = """shader_type canvas_item;
uniform vec2 rect_size = vec2(554.0, 312.0);
uniform float radius = 18.0;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 px = UV * rect_size;
	vec2 half_size = rect_size * 0.5;
	vec2 q = abs(px - half_size) - (half_size - vec2(radius));
	float dist = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0);
	if (dist > radius) {
		tex.a = 0.0;
	}
	COLOR = tex;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = _round_shader
	mat.set_shader_parameter("rect_size", Vector2(554, 312))
	mat.set_shader_parameter("radius", radius)
	tex.material = mat
	if not tex.resized.is_connected(_sync_banner_radius):
		tex.resized.connect(_sync_banner_radius)


func _sync_banner_radius() -> void:
	if _popup_banner == null:
		return
	var mat := _popup_banner.material as ShaderMaterial
	if mat == null:
		return
	var sz := _popup_banner.size
	if sz.x < 2.0 or sz.y < 2.0:
		return
	mat.set_shader_parameter("rect_size", sz)


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
	var art_tex := _load_ui_tex(str(p.get("art", "")))
	if art_tex == null:
		_popup_banner.texture = null
		_popup_banner_frame.visible = false
	else:
		_popup_banner.texture = art_tex
		_popup_banner_frame.visible = true
	_popup_pin.texture = _load_ui_tex(str(p.get("pin", "")))
	_clear_box(_popup_chips)
	var chip_tint: Color = p.get("color", Color("FFD0E4"))
	var chip_list = p.get("chips", [])
	if typeof(chip_list) == TYPE_ARRAY:
		for chip_text in chip_list:
			_popup_chips.add_child(_make_place_chip(str(chip_text), chip_tint))
	_clear_box(_popup_body)
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
		"排滿之後，按「確認本季排程」，就會結算，並讀到%s的小故事。" % GameState.daughter_display_name(),
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
	_position_mom_card()


func _dismiss_tutorial() -> void:
	GameState.flags["tutorial_done"] = true
	if _tutorial_layer:
		_tutorial_layer.queue_free()
		_tutorial_layer = null
	_position_mom_card()
	_maybe_growth_tutorial()
	_maybe_adult_intro()
	_maybe_confide()


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
		tip.text = "%s心情偏低，激烈活動暫時鎖上；安排休息或休閒會比較好。" % GameState.daughter_display_name()
		tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiStyle.apply_label(tip, 13, false)
		tip.add_theme_color_override("font_color", Color("C45A7A"))
		_activity_list.add_child(tip)
	var by_cat := Activities.ids_by_category_for(GameState)
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
	if _confide_popup != null and _confide_popup.visible:
		return
	_popup_panel.visible = false
	_activity_popup.visible = false
	if _npc_popup:
		_npc_popup.visible = false
	if _mom_popup:
		_mom_popup.visible = false
	if _growth_popup:
		_growth_popup.visible = false
	if _job_popup:
		_job_popup.visible = false
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
	sub.text = "好感會跟著活動、地圖小事與季節，慢慢暖起來。媽媽是家人，不在這裡計分。"
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
	_npc_list.add_child(_mom_family_card())
	for d in TownNpcs.defs():
		var id := str(d.get("id", ""))
		var value := TownNpcs.value_of(GameState, id)
		var card := PanelContainer.new()
		var style := UiStyle.panel_style(Color("FFF0F6"), Color("F5C0D0"), 14)
		style.content_margin_left = 10
		style.content_margin_right = 12
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", style)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)
		row.add_child(_npc_thumb(DialogueChrome.place_art(str(d.get("place", ""))), false))
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 2)
		row.add_child(col)

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
		if _confide_popup != null and _confide_popup.visible:
			return
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
	if GameConfig.is_adult_year(GameState.year):
		_time_lbl.text = "♡  %s · %s裝" % [GameState.get_time_label(), sn]
	else:
		_time_lbl.text = "♡  %s · 成長階段 %d（%s）· %s裝" % [
			GameState.get_time_label(), stage, GameConfig.growth_stage_label(stage), sn
		]
	var adult := Adulthood.is_adult(GameState)
	if _sched_title:
		_sched_title.text = "♡ 本季日記（平日工作照舊，每月另選一件事）" if adult else "♡ 本季日記排程（每月選一項）"
	if _job_lbl:
		_job_lbl.visible = adult
		if adult:
			var jn := Adulthood.job_name_of(str(GameState.adult_job))
			_job_lbl.text = "平日　%s" % jn if jn != "" else "平日　還沒選定。工作會一直在，日記仍每月一格。"
	if _job_btn:
		_job_btn.visible = adult
		_job_btn.text = "更換工作" if str(GameState.adult_job) != "" else "選定工作"
	if _romance_lbl:
		_romance_lbl.visible = adult
		_romance_lbl.text = Adulthood.hub_life_line(GameState)
	var s := GameState.get_stats_dict()
	_stats_lbl.text = "魅力 %d　道德 %d\n人際 %d　體力 %d\n學識 %d　心情 %d" % [
		s["charm"], s["morals"],
		s["social"], s["stamina"],
		s["academia"], s["mood"],
	]
	_cash_lbl.text = "家計  $%d" % s["cash"]
	if _affinity_lbl:
		_affinity_lbl.text = TownNpcs.hub_line(GameState)
	var growth_open := GrowthPath.unlocked(GameState)
	if _growth_lbl:
		_growth_lbl.visible = growth_open
		_growth_lbl.text = GrowthPath.drawer_line(GameState)
	if _growth_btn:
		_growth_btn.visible = growth_open
	_refresh_slots_highlight()
	if GameState.is_season_fully_scheduled():
		_confirm_btn.text = "確認本季排程 → 結算"
		UiStyle.apply_button(_confirm_btn, true)
	else:
		_confirm_btn.text = "排滿三個月後可結算"
		UiStyle.apply_button(_confirm_btn, false)
	_confirm_btn.disabled = false
	if _travel_hint:
		_travel_hint.text = Travel.hub_hint(GameState)
		_travel_hint.visible = _travel_hint.text != ""
	_refresh_mom()


func _open_education_fork() -> void:
	get_tree().change_scene_to_file(Adulthood.FORK_SCENE)


func _open_travel_offer() -> void:
	get_tree().change_scene_to_file("res://scenes/travel_offer.tscn")


func _build_mom_card() -> void:
	# Frameless standing cutout. No polaroid panel, no name plate.
	_mom_card = Control.new()
	_mom_card.name = "MomPin"
	_mom_card.visible = false
	_mom_card.z_index = 9
	_mom_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mom_card.tooltip_text = "點一下，跟媽媽說說話"
	add_child(_mom_card)

	_mom_shadow = TextureRect.new()
	_mom_shadow.name = "MomShadow"
	_mom_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mom_shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_mom_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mom_shadow.modulate = Color(0.22, 0.10, 0.16, 0.22)
	_mom_card.add_child(_mom_shadow)

	_mom_tex = TextureRect.new()
	_mom_tex.name = "MomCutout"
	_mom_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mom_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mom_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_mom_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mom_card.add_child(_mom_tex)

	var hit := Button.new()
	hit.name = "MomHit"
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.tooltip_text = "點一下，跟媽媽說說話"
	var empty := StyleBoxEmpty.new()
	hit.add_theme_stylebox_override("normal", empty)
	hit.add_theme_stylebox_override("hover", empty)
	hit.add_theme_stylebox_override("pressed", empty)
	hit.add_theme_stylebox_override("focus", empty)
	hit.pressed.connect(_on_mom_pressed)
	_mom_card.add_child(hit)
	_position_mom_card()


func _position_mom_card() -> void:
	if _mom_card == null:
		return
	var sz := size
	if sz.y < 10:
		sz = Vector2(GameConfig.VIEWPORT_W, GameConfig.VIEWPORT_H)
	var pin := Vector2(MOM_PIN_W, MOM_PIN_H)
	var drawer_top := sz.y - (DRAWER_H if _drawer_expanded else DRAWER_COLLAPSED)
	# Year-1 tutorial card sits at the top-left; keep the pin beside it, above the drawer.
	var x := 488.0 if _tutorial_open() else 16.0
	var y := 66.0
	if y + pin.y > drawer_top - 8.0:
		y = maxf(66.0, drawer_top - pin.y - 8.0)
	_mom_card.position = Vector2(x, y)
	_mom_card.size = pin
	if _mom_shadow != null:
		_mom_shadow.position = Vector2(3, 4)
		_mom_shadow.size = pin


func _tutorial_open() -> bool:
	return _tutorial_layer != null and is_instance_valid(_tutorial_layer)


func _refresh_mom() -> void:
	if _mom_card == null:
		return
	Mom.roll_presence(GameState, _map_rng)
	var present := Mom.is_present(GameState)
	_mom_card.visible = present
	if not present:
		return
	if _mom_tex != null:
		var pin_path := AgeLooks.mom_pin(GameState.year)
		if str(_mom_tex.get_meta("look_path", "")) != pin_path:
			var tex := _load_tex(pin_path)
			_mom_tex.texture = tex
			_mom_tex.set_meta("look_path", pin_path)
			if _mom_shadow != null:
				_mom_shadow.texture = tex


func _on_mom_pressed() -> void:
	if not Mom.is_present(GameState):
		return
	_hide_popups()
	_popup_layer.get_node("Dim").visible = true
	var line := Mom.advance_dialogue(GameState)
	_mom_line.text = line
	_paint_mom_dialogue(line)
	_refresh_mom_help_label()
	_mom_popup.visible = true


func _refresh_mom_help_label() -> void:
	if _mom_help_btn == null:
		return
	var available := Mom.help_available(GameState)
	_mom_help_btn.visible = available
	_mom_help_btn.disabled = not available
	if Mom.helped_this_season(GameState):
		if _mom_help_lbl.text == "":
			_mom_help_lbl.text = "這季她已經幫過一點小忙了。"
	elif _mom_help_lbl != null and not available:
		_mom_help_lbl.text = ""


func _on_mom_next_line() -> void:
	var line := Mom.advance_dialogue(GameState)
	_mom_line.text = line
	_paint_mom_dialogue(line)


func _paint_mom_dialogue(line: String) -> void:
	if _mom_shell.is_empty():
		return
	DialogueChrome.apply_speaker(_mom_shell, "mom", GameState.year, GameState.season)
	DialogueChrome.apply_listener(
		_mom_shell, "daughter", GameState.year, GameState.season, GameState.daughter_display_name()
	)
	DialogueChrome.apply_heading(_mom_shell, "家裡的對話", Mom.NAME)
	DialogueChrome.apply_theme(_mom_shell, DialogueChrome.theme_for_line(line), GameState.year)


func _on_mom_help() -> void:
	var res: Dictionary = Mom.claim_help(GameState)
	if not bool(res.get("ok", false)):
		_mom_help_lbl.text = str(res.get("reason", ""))
		_refresh_mom_help_label()
		return
	var line := "%s\n%s" % [str(res.get("title", "")), str(res.get("body", ""))]
	var delta_line := Mom.format_deltas(res.get("deltas", {}))
	if delta_line != "":
		line += "\n" + delta_line
	_mom_help_lbl.text = line
	_refresh_mom_help_label()


func _make_mom_popup() -> PanelContainer:
	# Bust stays in proportion (source is a tall cutout, not a square crop).
	# Tall enough for the bust, the listener, and a full-width button row inside the card.
	_mom_shell = DialogueChrome.make_shell(Vector2(860, 640), Vector2(200, 300))
	var panel: PanelContainer = _mom_shell["panel"]
	var col: VBoxContainer = _mom_shell["body"]
	var actions: VBoxContainer = _mom_shell["actions"]
	_mom_portrait = _mom_shell["portrait"]

	_mom_line = Label.new()
	_mom_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mom_line.size_flags_vertical = Control.SIZE_EXPAND_FILL
	UiStyle.apply_label(_mom_line, 16)
	col.add_child(_mom_line)

	_mom_help_lbl = Label.new()
	_mom_help_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(_mom_help_lbl, 14, true)
	col.add_child(_mom_help_lbl)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	actions.add_child(action_row)

	var again := Button.new()
	again.text = "再聽一句"
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyle.apply_button(again, false)
	again.pressed.connect(_on_mom_next_line)
	action_row.add_child(again)

	_mom_help_btn = Button.new()
	_mom_help_btn.text = "媽媽的小幫忙"
	_mom_help_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyle.apply_button(_mom_help_btn, true)
	_mom_help_btn.pressed.connect(_on_mom_help)
	action_row.add_child(_mom_help_btn)

	var close := Button.new()
	close.text = "好的 ♡"
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyle.apply_button(close, false)
	close.pressed.connect(_hide_popups)
	actions.add_child(close)
	return panel


func _mom_family_card() -> PanelContainer:
	var card := PanelContainer.new()
	var style := UiStyle.panel_style(Color("FFF0F6"), Color("F5C0D0"), 14)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	row.add_child(_npc_thumb(AgeLooks.mom_portrait(GameState.year), true))
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)

	var head := Label.new()
	head.text = "%s　·　家人　·　家" % Mom.NAME
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(head, 16)
	col.add_child(head)

	var bio := Label.new()
	bio.text = Mom.FAMILY_BIO
	bio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(bio, 13, true)
	col.add_child(bio)

	var hearts := Label.new()
	hearts.text = "一直是暖的　·　不計分"
	UiStyle.apply_label(hearts, 15)
	col.add_child(hearts)
	return card


func _maybe_growth_tutorial() -> void:
	if not GrowthPath.unlocked(GameState):
		return
	if bool(GameState.flags.get("growth_tutorial_done", false)):
		return
	if _growth_tutorial_open():
		return
	_growth_layer = CanvasLayer.new()
	_growth_layer.layer = 14
	add_child(_growth_layer)

	var card := PanelContainer.new()
	card.offset_left = 360
	card.offset_top = 72
	card.offset_right = 900
	card.offset_bottom = 312
	card.add_theme_stylebox_override("panel", UiStyle.panel_style(Color(1, 0.96, 0.97, 0.96), Color("F090A8"), 18))
	_growth_layer.add_child(card)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)

	var title := Label.new()
	title.text = "國中的手帳"
	UiStyle.apply_label(title, 20)
	v.add_child(title)

	for line in [
		"專長會跟著相關的月份慢慢升級：鋼琴、外語、程式、繪畫、球類、烹飪、演講。",
		"興趣也會累起來：藝術、理工、服務、文教、運動、商業。以後找工作時，會輕輕偏向她走得比較久的那些。",
		"這一季可以排學鋼琴、外語班，或程式興趣班。手帳裡的「翻開專長」隨時能看。",
	]:
		var lbl := Label.new()
		lbl.text = line
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiStyle.apply_label(lbl, 14)
		v.add_child(lbl)

	var ok := Button.new()
	ok.text = "知道了 ♡"
	UiStyle.apply_button(ok, true)
	ok.pressed.connect(_dismiss_growth_tutorial)
	v.add_child(ok)


func _growth_tutorial_open() -> bool:
	return _growth_layer != null and is_instance_valid(_growth_layer)


func _dismiss_growth_tutorial() -> void:
	GameState.flags["growth_tutorial_done"] = true
	if _growth_layer:
		_growth_layer.queue_free()
		_growth_layer = null
	_maybe_adult_intro()
	_maybe_confide()


func _show_growth_panel() -> void:
	if not GrowthPath.unlocked(GameState):
		return
	if _confide_popup != null and _confide_popup.visible:
		return
	_hide_popups()
	_fill_growth_panel()
	var dim := _popup_layer.get_node_or_null("Dim")
	if dim:
		dim.visible = true
	_growth_popup.visible = true


func _fill_growth_panel() -> void:
	if _growth_box == null:
		return
	for node in _growth_box.get_children():
		_growth_box.remove_child(node)
		node.free()
	for line in GrowthPath.skill_lines(GameState):
		var row := Label.new()
		row.text = line
		UiStyle.apply_label(row, 16, line.ends_with("未學"))
		_growth_box.add_child(row)
	var tags := Label.new()
	tags.text = GrowthPath.tag_line(GameState)
	tags.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(tags, 15)
	_growth_box.add_child(tags)
	var bright := Label.new()
	bright.text = GrowthPath.brightest_tag_line(GameState)
	bright.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(bright, 14, true)
	_growth_box.add_child(bright)


func _make_growth_popup() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 460)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -270
	panel.offset_right = 270
	panel.offset_top = -250
	panel.offset_bottom = 250
	panel.add_theme_stylebox_override("panel", UiStyle.panel_style(Color("FFF5F8"), Color("F5B8C8"), 22))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	margin.add_child(v)

	var title := Label.new()
	title.text = "專長與興趣"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(title, 24)
	v.add_child(title)

	var sub := Label.new()
	sub.text = "國中以後，每月的安排會慢慢寫進這一頁。"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(sub, 13, true)
	v.add_child(sub)

	_growth_box = VBoxContainer.new()
	_growth_box.add_theme_constant_override("separation", 4)
	_growth_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_growth_box)

	var close := Button.new()
	close.text = "好的 ♡"
	UiStyle.apply_button(close, false)
	close.pressed.connect(_hide_popups)
	v.add_child(close)
	return panel


func _maybe_confide() -> void:
	if _tutorial_open() or _growth_tutorial_open() or _adult_intro_open():
		return
	if _confide_popup == null or _confide_popup.visible:
		return
	var offer: Dictionary = Confide.offer_for(GameState, _map_rng)
	if offer.is_empty():
		return
	_open_confide(offer)


func _open_confide(offer: Dictionary) -> void:
	_confide_offer = offer
	_hide_popups()
	var dim := _popup_layer.get_node_or_null("Dim")
	if dim:
		dim.visible = true
	_show_confide_offer()
	_confide_popup.visible = true


func _clear_confide_box() -> void:
	for box in [_confide_box, _confide_actions]:
		if box == null:
			continue
		for node in box.get_children():
			box.remove_child(node)
			node.free()


func _confide_label(text: String, size: int, muted: bool, min_h: int, center: bool) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.custom_minimum_size = Vector2(0, min_h)
	UiStyle.apply_label(lbl, size, muted)
	return lbl


func _show_confide_offer() -> void:
	_clear_confide_box()
	_paint_confide_frame(str(_confide_offer.get("id", "")))
	DialogueChrome.apply_heading(
		_confide_shell,
		str(_confide_offer.get("kicker", "傾訴心事")),
		"%s想說說話" % GameState.daughter_display_name()
	)
	_confide_box.add_child(_confide_label(str(_confide_offer.get("body", "")), 16, false, 72, false))

	var opts: Array = _confide_offer.get("options", [])
	for i in range(opts.size()):
		var opt: Dictionary = opts[i]
		var btn := Button.new()
		btn.text = str(opt.get("label", ""))
		btn.custom_minimum_size = Vector2(0, 48)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UiStyle.apply_button(btn, false)
		var choice_i := i
		btn.pressed.connect(func() -> void: _on_confide_choice(choice_i))
		_confide_actions.add_child(btn)


func _on_confide_choice(index: int) -> void:
	var picked := str(_confide_offer.get("id", ""))
	var res: Dictionary = Confide.apply_choice(GameState, picked, index)
	call_deferred("_show_confide_result", res)


func _show_confide_result(res: Dictionary) -> void:
	_clear_confide_box()
	_paint_confide_frame(str(_confide_offer.get("id", "")))
	DialogueChrome.apply_heading(_confide_shell, "她接著說", GameState.daughter_display_name())
	_confide_box.add_child(_confide_label(str(res.get("reply", "")), 16, false, 72, false))
	var delta_line := Mom.format_deltas(res.get("deltas", {}))
	if delta_line != "":
		_confide_box.add_child(_confide_label(delta_line, 14, true, 28, false))
	if int(res.get("warmth", 0)) > 0:
		_confide_box.add_child(_confide_label("家裡更暖了一點。", 14, true, 28, false))
	var ok_btn := Button.new()
	ok_btn.text = "好的"
	ok_btn.custom_minimum_size = Vector2(0, 48)
	ok_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyle.apply_button(ok_btn, true)
	ok_btn.pressed.connect(_close_confide)
	_confide_actions.add_child(ok_btn)


func _close_confide() -> void:
	if _confide_popup:
		_confide_popup.visible = false
	_confide_offer = {}
	_hide_popups()


func _make_confide_popup() -> PanelContainer:
	_confide_shell = DialogueChrome.make_shell(Vector2(860, 640), Vector2(168, 250))
	var panel: PanelContainer = _confide_shell["panel"]
	_confide_box = _confide_shell["body"]
	_confide_actions = _confide_shell["actions"]
	return panel


func _paint_confide_frame(line_id: String) -> void:
	if _confide_shell.is_empty():
		return
	DialogueChrome.apply_speaker(_confide_shell, "daughter", GameState.year, GameState.season)
	DialogueChrome.apply_listener(_confide_shell, "dad", GameState.year, GameState.season, "爸爸")
	DialogueChrome.apply_theme(_confide_shell, DialogueChrome.theme_for_confide(line_id), GameState.year)


func _npc_thumb(path: String, cutout: bool) -> TextureRect:
	var thumb := TextureRect.new()
	thumb.custom_minimum_size = Vector2(72, 84 if cutout else 56)
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if cutout else TextureRect.STRETCH_KEEP_ASPECT_COVERED
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.texture = DialogueChrome.load_texture(path)
	thumb.visible = thumb.texture != null
	return thumb


func _adult_intro_open() -> bool:
	return _adult_layer != null and is_instance_valid(_adult_layer)


func _maybe_adult_intro() -> void:
	if not Adulthood.is_adult(GameState):
		return
	if bool(GameState.flags.get("adult_job_intro_done", false)):
		return
	if _tutorial_open() or _growth_tutorial_open() or _adult_intro_open():
		return
	_adult_layer = CanvasLayer.new()
	_adult_layer.layer = 15
	add_child(_adult_layer)

	var card := PanelContainer.new()
	card.offset_left = 280
	card.offset_top = 64
	card.offset_right = 1000
	card.offset_bottom = 520
	card.add_theme_stylebox_override("panel", DialogueChrome.paper_style())
	_adult_layer.add_child(card)

	var intro_row := HBoxContainer.new()
	intro_row.add_theme_constant_override("separation", 12)
	card.add_child(intro_row)
	var side := VBoxContainer.new()
	side.add_theme_constant_override("separation", 8)
	side.add_child(DialogueChrome.make_bust("daughter", GameState.year, GameState.season, Vector2(110, 180)))
	side.add_child(DialogueChrome.make_stamp("home", GameState.year))
	intro_row.add_child(side)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	intro_row.add_child(v)

	var title := Label.new()
	title.text = "成年的手帳"
	UiStyle.apply_label(title, 20)
	v.add_child(title)

	var suggest := Adulthood.job_name_of(Adulthood.recommended_job(GameState))
	var lines: Array[String] = [
		"她成年了。平日的工作會一直在，日記裡每個月仍只選一件自己的事。",
		"可以靠近一個人、進修、把工作做深一點。成家要等戀愛進度夠了才出現，不排也很好。",
	]
	var entry := Adulthood.education_entry_line(GameState)
	if entry != "":
		lines.append(entry)
	lines.append("依現在的專長和興趣，平日先從「%s」開始。之後還能換。" % suggest)
	for line in lines:
		var lbl := Label.new()
		lbl.text = line
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiStyle.apply_label(lbl, 14)
		v.add_child(lbl)

	var intro_spacer := Control.new()
	intro_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(intro_spacer)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)

	var ok := Button.new()
	ok.text = "就這份工作 ♡"
	UiStyle.apply_button(ok, true)
	ok.pressed.connect(_accept_adult_job)
	row.add_child(ok)

	var browse := Button.new()
	browse.text = "換一份看看"
	UiStyle.apply_button(browse, false)
	browse.pressed.connect(_browse_adult_jobs)
	row.add_child(browse)
	DialogueChrome.dress_panel(card)


func _close_adult_intro() -> void:
	if _adult_layer:
		_adult_layer.queue_free()
		_adult_layer = null


func _accept_adult_job() -> void:
	GameState.flags["adult_job_intro_done"] = true
	Adulthood.ensure_job(GameState)
	_close_adult_intro()
	_refresh()
	_maybe_confide()


func _browse_adult_jobs() -> void:
	GameState.flags["adult_job_intro_done"] = true
	_close_adult_intro()
	_show_job_panel()


func _show_job_panel() -> void:
	if not Adulthood.is_adult(GameState):
		return
	if _confide_popup != null and _confide_popup.visible:
		return
	_hide_popups()
	_fill_job_panel()
	var dim := _popup_layer.get_node_or_null("Dim")
	if dim:
		dim.visible = true
	_job_popup.visible = true


func _fill_job_panel() -> void:
	if _job_list == null:
		return
	for node in _job_list.get_children():
		_job_list.remove_child(node)
		node.free()
	if _job_note:
		_job_note.text = Adulthood.job_picker_blurb(GameState)
	var current := str(GameState.adult_job)
	for job in Adulthood.picker_jobs(GameState):
		var jid := str(job.get("id", ""))
		var row := Button.new()
		var mark := "（目前）" if jid == current else ""
		row.text = "%s%s　每月 $%d\n%s" % [str(job.get("name", "")), mark, int(job.get("cash", 0)), str(job.get("blurb", ""))]
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UiStyle.apply_soft_chip(row, Color("FFE8F0") if jid != current else Color("FFD0E4"))
		row.add_theme_font_size_override("font_size", 14)
		var picked := jid
		row.pressed.connect(func() -> void:
			GameState.adult_job = picked
			GameState.flags["adult_job_intro_done"] = true
			_hide_popups()
			_refresh()
		)
		_job_list.add_child(row)


func _make_job_popup() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 480)
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -280
	panel.offset_right = 280
	panel.offset_top = -250
	panel.offset_bottom = 250
	panel.add_theme_stylebox_override("panel", UiStyle.panel_style(Color("FFF5F8"), Color("F5B8C8"), 22))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	margin.add_child(v)

	var title := Label.new()
	title.text = "平日的工作"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(title, 24)
	v.add_child(title)

	_job_note = Label.new()
	_job_note.text = Adulthood.job_picker_blurb(GameState)
	_job_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_job_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(_job_note, 13, true)
	v.add_child(_job_note)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 280)
	v.add_child(scroll)

	_job_list = VBoxContainer.new()
	_job_list.add_theme_constant_override("separation", 6)
	_job_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_job_list)

	var close := Button.new()
	close.text = "先這樣 ♡"
	UiStyle.apply_button(close, false)
	close.pressed.connect(_hide_popups)
	v.add_child(close)
	return panel


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
