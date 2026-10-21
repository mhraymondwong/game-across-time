extends Control
## Season settlement + optional event media (still / video) overlay

var _media_layer: CanvasLayer
var _video: VideoStreamPlayer
var _still: TextureRect
var _skip_btn: Button
var _main_root: CenterContainer
var _showing_media: bool = false
var _vignette_layer: CanvasLayer
var _showing_vignette: bool = false


func _ready() -> void:
	UiStyle.make_bg(self, GameConfig.COL_BG)
	_main_root = CenterContainer.new()
	_main_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_main_root)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.panel_style())
	panel.custom_minimum_size = Vector2(760, 540)
	_main_root.add_child(panel)

	var outer := HBoxContainer.new()
	outer.add_theme_constant_override("separation", 16)
	panel.add_child(outer)

	var ev: Dictionary = GameState.last_season_event
	var sticker_key := str(ev.get("sticker", ""))
	var sticker_res := SeasonEvents.sticker_path(sticker_key)
	if sticker_res != "" and ResourceLoader.exists(sticker_res):
		var stick := TextureRect.new()
		stick.texture = load(sticker_res)
		stick.custom_minimum_size = Vector2(140, 280)
		stick.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stick.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		stick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		outer.add_child(stick)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(v)

	var title := Label.new()
	title.text = "季節結算"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(title, 28)
	v.add_child(title)

	var time_lbl := Label.new()
	var stage := GameConfig.growth_stage_for_year(GameState.year)
	time_lbl.text = "%s · 階段 %d（%s）" % [
		GameState.get_time_label(), stage, GameConfig.growth_stage_label(stage)
	]
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(time_lbl, 16, true)
	v.add_child(time_lbl)

	var d: Dictionary = GameState.last_deltas
	var acts: Array = d.get("activities", [])
	var act_lbl := Label.new()
	act_lbl.text = "本季活動：%s" % "、".join(PackedStringArray(acts))
	act_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(act_lbl, 15)
	v.add_child(act_lbl)

	if not GameState.last_vignettes.is_empty():
		var hi := ActivityScenes.highlight_index(GameState.last_vignettes)
		if hi >= 0 and hi < GameState.last_vignettes.size():
			var hv: Dictionary = GameState.last_vignettes[hi]
			var story := Label.new()
			story.text = "手帳最亮的一頁：%s" % str(hv.get("title", ""))
			story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			UiStyle.apply_label(story, 15)
			v.add_child(story)

	if not ev.is_empty():
		var ev_title := Label.new()
		ev_title.text = "☁ %s" % str(ev.get("title", "小鎮小事"))
		UiStyle.apply_label(ev_title, 20)
		v.add_child(ev_title)
		var ev_body := Label.new()
		ev_body.text = str(ev.get("body", ""))
		ev_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiStyle.apply_label(ev_body, 15, true)
		v.add_child(ev_body)
		var ed: Dictionary = ev.get("deltas", {})
		var ed_txt := _format_event_deltas(ed)
		if ed_txt != "":
			var ed_lbl := Label.new()
			ed_lbl.text = ed_txt
			UiStyle.apply_label(ed_lbl, 14)
			v.add_child(ed_lbl)
		# Thumbnail of special still on result card
		var media := SeasonEvents.resolve_media_paths(ev)
		if media["still"] != "":
			var thumb := TextureRect.new()
			thumb.custom_minimum_size = Vector2(280, 160)
			thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var tex := _load_tex(media["still"])
			if tex:
				thumb.texture = tex
				v.add_child(thumb)

	var delta_lbl := Label.new()
	delta_lbl.text = _format_deltas(d)
	delta_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(delta_lbl, 17)
	v.add_child(delta_lbl)

	var now := Label.new()
	var s := GameState.get_stats_dict()
	now.text = "目前：魅力 %d｜道德 %d｜人際 %d｜體力 %d｜家計 $%d｜心情 %d" % [
		s["charm"], s["morals"], s["social"], s["stamina"], s["cash"], s["mood"]
	]
	now.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(now, 14, true)
	v.add_child(now)

	var aff_note := str(d.get("affinity_note", ""))
	if aff_note != "":
		var aff_lbl := Label.new()
		aff_lbl.text = aff_note
		aff_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiStyle.apply_label(aff_lbl, 15)
		v.add_child(aff_lbl)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	v.add_child(spacer)

	var cont := Button.new()
	cont.text = "繼續"
	UiStyle.apply_button(cont, true)
	cont.pressed.connect(_on_continue)
	v.add_child(cont)

	var has_vig := not GameState.last_vignettes.is_empty()
	if has_vig:
		_build_vignette_layer()

	# Media first, then activity vignettes, then the number card.
	if SeasonEvents.has_media(ev):
		_build_media_layer(ev)
		_main_root.visible = false
		if _vignette_layer:
			_vignette_layer.visible = false
		_showing_media = true
		_show_event_media(ev)
	elif has_vig:
		_main_root.visible = false
		_showing_vignette = true


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


func _build_media_layer(ev: Dictionary) -> void:
	_media_layer = CanvasLayer.new()
	_media_layer.layer = 40
	add_child(_media_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.12, 0.06, 0.10, 0.92)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_media_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_media_layer.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.custom_minimum_size = Vector2(900, 560)
	center.add_child(box)

	var cap := Label.new()
	cap.text = "✿ %s" % str(ev.get("title", "特別回憶"))
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(cap, 26)
	cap.add_theme_color_override("font_color", Color("FFE8F0"))
	box.add_child(cap)

	var media_host := Control.new()
	media_host.custom_minimum_size = Vector2(880, 460)
	media_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(media_host)

	_still = TextureRect.new()
	_still.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_still.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_still.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_still.mouse_filter = Control.MOUSE_FILTER_IGNORE
	media_host.add_child(_still)

	_video = VideoStreamPlayer.new()
	_video.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_video.expand = true
	_video.visible = false
	_video.finished.connect(_on_video_finished)
	media_host.add_child(_video)

	_skip_btn = Button.new()
	_skip_btn.text = "略過／繼續 ▶"
	UiStyle.apply_button(_skip_btn, true)
	_skip_btn.custom_minimum_size = Vector2(0, 44)
	_skip_btn.pressed.connect(_dismiss_media)
	box.add_child(_skip_btn)


func _show_event_media(ev: Dictionary) -> void:
	var paths := SeasonEvents.resolve_media_paths(ev)
	var still_tex := _load_tex(paths["still"])
	if still_tex:
		_still.texture = still_tex
		_still.visible = true

	var vpath: String = paths["video"]
	if vpath != "" and _try_play_video(vpath):
		_video.visible = true
		_still.visible = still_tex == null  # keep still under if video fails mid-way
	else:
		_video.visible = false
		if still_tex == null:
			# No media file yet — dismiss quickly after showing title
			_skip_btn.text = "尚無短片，查看結算 ▶"


func _try_play_video(vpath: String) -> bool:
	# Stock Godot plays Theora (.ogv) via VideoStreamTheora.
	if vpath.ends_with(".ogv"):
		var th := VideoStreamTheora.new()
		th.file = vpath
		_video.stream = th
		_video.loop = false
		_video.play()
		return true
	if ResourceLoader.exists(vpath):
		var stream = load(vpath)
		if stream != null:
			_video.stream = stream
			_video.loop = false
			_video.play()
			return true
	print("[season_result] video present but not playable in this build: ", vpath)
	return false


func _on_video_finished() -> void:
	# After clip, keep last frame / still and wait for skip
	_skip_btn.text = "繼續 ▶"


func _dismiss_media() -> void:
	if _video and _video.is_playing():
		_video.stop()
	if _media_layer:
		_media_layer.visible = false
	_showing_media = false
	if _vignette_layer and not GameState.last_vignettes.is_empty():
		_vignette_layer.visible = true
		_showing_vignette = true
		_main_root.visible = false
	else:
		_main_root.visible = true


func _dismiss_vignette() -> void:
	if _vignette_layer:
		_vignette_layer.visible = false
	_showing_vignette = false
	_main_root.visible = true


func _build_vignette_layer() -> void:
	var vignettes: Array = GameState.last_vignettes
	var hi := ActivityScenes.highlight_index(vignettes)

	_vignette_layer = CanvasLayer.new()
	_vignette_layer.layer = 30
	add_child(_vignette_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.55, 0.25, 0.35, 0.28)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_vignette_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(860, 620)
	panel.add_theme_stylebox_override("panel", UiStyle.panel_style(Color("FFF5F8"), Color("F5B8C8"), 22))
	center.add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	panel.add_child(outer)

	var title := Label.new()
	title.text = "本季小過場"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(title, 26)
	outer.add_child(title)

	var sub := Label.new()
	sub.text = "三個月的日子，先讀成故事，再看數字。"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.apply_label(sub, 14, true)
	outer.add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(800, 460)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	var list := VBoxContainer.new()
	list.custom_minimum_size = Vector2(780, 0)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	if hi >= 0 and hi < vignettes.size() and typeof(vignettes[hi]) == TYPE_DICTIONARY:
		list.add_child(_vignette_card(vignettes[hi], true))

	var others := 0
	for i in range(vignettes.size()):
		if i == hi or typeof(vignettes[i]) != TYPE_DICTIONARY:
			continue
		others += 1
	if others > 0:
		var more := Label.new()
		more.text = "另外的月份"
		UiStyle.apply_label(more, 15, true)
		list.add_child(more)
		for i in range(vignettes.size()):
			if i == hi or typeof(vignettes[i]) != TYPE_DICTIONARY:
				continue
			list.add_child(_vignette_card(vignettes[i], false))

	var next := Button.new()
	next.text = "翻開結算 ♡"
	UiStyle.apply_button(next, true)
	next.pressed.connect(_dismiss_vignette)
	outer.add_child(next)


func _vignette_card(v: Dictionary, highlighted: bool) -> PanelContainer:
	var card := PanelContainer.new()
	var fill := Color("FFF0F6") if highlighted else Color("FFF8FB")
	var border := Color("F090A8") if highlighted else Color("F5C8D4")
	var style := UiStyle.panel_style(fill, border, 16)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)

	var art = _vignette_art(v, highlighted)
	if art != null:
		row.add_child(art)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 4)
	row.add_child(text_col)

	var month := Label.new()
	var act_name := str(v.get("activity_name", ""))
	var month_label := str(v.get("month_label", ""))
	month.text = "%s · %s" % [month_label, act_name] if act_name != "" else month_label
	UiStyle.apply_label(month, 13, true)
	text_col.add_child(month)

	var cap := Label.new()
	cap.text = str(v.get("title", "小鎮小事"))
	cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(cap, 20 if highlighted else 16)
	text_col.add_child(cap)

	var body := Label.new()
	body.text = str(v.get("body", ""))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(body, 16 if highlighted else 14, not highlighted)
	text_col.add_child(body)
	return card


func _vignette_art(v: Dictionary, highlighted: bool):
	var path := ""
	var still_id := str(v.get("still", ""))
	if still_id != "":
		path = GameConfig.event_still_path(still_id)
	if path == "":
		path = SeasonEvents.sticker_path(str(v.get("sticker", "")))
	var tex := _load_tex(path)
	if tex == null:
		return null
	var stick := TextureRect.new()
	var side := 120 if highlighted else 72
	stick.custom_minimum_size = Vector2(side, side + (36 if highlighted else 12))
	stick.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stick.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stick.texture = tex
	return stick


func _format_event_deltas(ed: Dictionary) -> String:
	if ed.is_empty():
		return ""
	var parts: PackedStringArray = []
	var keys := [
		["charm", "魅力"], ["morals", "道德"], ["social", "人際"],
		["stamina", "體力"], ["academia", "學識"], ["mood", "心情"], ["cash", "金錢"],
	]
	for pair in keys:
		var k: String = pair[0]
		var label: String = pair[1]
		var v := int(ed.get(k, 0))
		if v == 0:
			continue
		if k == "cash":
			parts.append("%s%s$%d" % [label, "＋" if v > 0 else "－", abs(v)])
		else:
			parts.append("%s%s%d" % [label, "＋" if v > 0 else "－", abs(v)])
	if parts.is_empty():
		return ""
	return "事件影響：%s" % "　".join(parts)


func _format_deltas(d: Dictionary) -> String:
	var parts: PackedStringArray = []
	var keys := [
		["charm", "魅力"], ["morals", "道德"], ["social", "人際"],
		["stamina", "體力"], ["academia", "學識"], ["mood", "心情"], ["cash", "金錢"],
	]
	for pair in keys:
		var k: String = pair[0]
		var label: String = pair[1]
		var v := int(d.get(k, 0))
		if v == 0:
			continue
		var sign := "＋" if v > 0 else "－"
		if k == "cash":
			parts.append("%s%s$%d" % [label, "＋" if v > 0 else "－", abs(v)])
		else:
			parts.append("%s%s%d" % [label, sign, abs(v)])
	if parts.is_empty():
		return "本季數值變化不大。"
	return "本季合計：%s" % "　".join(parts)


func _on_continue() -> void:
	if _showing_media:
		_dismiss_media()
		return
	if _showing_vignette:
		_dismiss_vignette()
		return
	var next := GameState.advance_after_season()
	if next == "year_review":
		get_tree().change_scene_to_file("res://scenes/year_review.tscn")
	elif next == "ending":
		get_tree().change_scene_to_file("res://scenes/ending.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/home_hub.tscn")
