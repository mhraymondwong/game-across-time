extends Control
## Season settlement + optional event media (still / video) overlay

var _media_layer: CanvasLayer
var _video: VideoStreamPlayer
var _still: TextureRect
var _skip_btn: Button
var _main_root: CenterContainer
var _showing_media: bool = false


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

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	v.add_child(spacer)

	var cont := Button.new()
	cont.text = "繼續"
	UiStyle.apply_button(cont, true)
	cont.pressed.connect(_on_continue)
	v.add_child(cont)

	# Media overlay first when event has still/video
	if SeasonEvents.has_media(ev):
		_build_media_layer(ev)
		_main_root.visible = false
		_showing_media = true
		_show_event_media(ev)


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
	_main_root.visible = true
	_showing_media = false


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
	var next := GameState.advance_after_season()
	if next == "year_review":
		get_tree().change_scene_to_file("res://scenes/year_review.tscn")
	elif next == "ending":
		get_tree().change_scene_to_file("res://scenes/ending.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/home_hub.tscn")
