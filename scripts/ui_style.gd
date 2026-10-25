class_name UiStyle
extends RefCounted
## Soft pink scrapbook StyleBoxes — lace/hearts diary polish, not grey system chrome

static var _ui_font: Font


static func ui_font() -> Font:
	if _ui_font == null:
		_ui_font = load("res://assets/fonts/NotoSansCJKtc-Regular.otf") as Font
	return _ui_font


static func _apply_font(ctrl: Control) -> void:
	var f := ui_font()
	if f:
		ctrl.add_theme_font_override("font", f)


static func panel_style(bg: Color = GameConfig.COL_PANEL, border: Color = GameConfig.COL_PANEL_BORDER, radius: int = 16) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(16)
	s.shadow_color = Color(0.55, 0.25, 0.35, 0.12)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 4)
	return s


static func button_style(bg: Color, border: Color = Color(0.85, 0.45, 0.55, 0.25), radius: int = 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s


static func apply_button(btn: Button, primary: bool = false) -> void:
	var normal_bg := GameConfig.COL_ACCENT if primary else GameConfig.COL_CHIP
	var hover_bg := GameConfig.COL_ACCENT_DARK if primary else GameConfig.COL_CHIP_HOVER
	var press_bg := Color("B86878") if primary else Color("F0C0D0")
	btn.add_theme_stylebox_override("normal", button_style(normal_bg, Color("F5A0B4") if primary else Color("F0B8C8")))
	btn.add_theme_stylebox_override("hover", button_style(hover_bg, Color("E888A0") if primary else Color("E8A8B8")))
	btn.add_theme_stylebox_override("pressed", button_style(press_bg, Color("C07080")))
	btn.add_theme_stylebox_override("disabled", button_style(Color("F5E0E6"), Color("E8D0D8")))
	btn.add_theme_color_override("font_color", Color.WHITE if primary else GameConfig.COL_TEXT)
	btn.add_theme_color_override("font_hover_color", Color.WHITE if primary else GameConfig.COL_TEXT)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE if primary else GameConfig.COL_TEXT)
	btn.add_theme_color_override("font_disabled_color", Color("B898A0"))
	btn.add_theme_font_size_override("font_size", 18)
	_apply_font(btn)
	btn.custom_minimum_size = Vector2(0, 44)


static func apply_soft_chip(btn: Button, fill: Color = GameConfig.COL_CHIP, text_col: Color = GameConfig.COL_TEXT) -> void:
	## Soft rounded sticker-like month / location chip
	var border := Color(fill.r * 0.85 + 0.15, fill.g * 0.7, fill.b * 0.75, 0.9)
	btn.add_theme_stylebox_override("normal", button_style(fill, border, 22))
	btn.add_theme_stylebox_override("hover", button_style(fill.lightened(0.08), border, 22))
	btn.add_theme_stylebox_override("pressed", button_style(fill.darkened(0.06), border, 22))
	btn.add_theme_stylebox_override("disabled", button_style(Color("F0E0E6"), Color("E0D0D6"), 22))
	btn.add_theme_color_override("font_color", text_col)
	btn.add_theme_color_override("font_hover_color", text_col)
	btn.add_theme_color_override("font_pressed_color", text_col)
	btn.add_theme_font_size_override("font_size", 15)
	_apply_font(btn)


static func apply_sticker_chip(btn: Button, selected: bool = false, filled: bool = false) -> void:
	## Pink scrapbook sticker slots for monthly schedule
	var fill: Color
	var border: Color
	if filled and selected:
		fill = Color("FFB0C8")
		border = Color("E87898")
	elif filled:
		fill = Color("FFD0E0")
		border = Color("F090B0")
	elif selected:
		fill = Color("FFE8F0")
		border = Color("F5A0B8")
	else:
		fill = Color("FFF0F6")
		border = Color("F5C0D0")
	apply_soft_chip(btn, fill, GameConfig.COL_TEXT)
	btn.add_theme_stylebox_override("normal", button_style(fill, border, 22))
	btn.add_theme_stylebox_override("hover", button_style(fill.lightened(0.05), border.darkened(0.05), 22))
	btn.add_theme_stylebox_override("pressed", button_style(fill.darkened(0.05), border.darkened(0.1), 22))


static func apply_label(lbl: Label, size: int = 18, muted: bool = false) -> void:
	lbl.add_theme_color_override("font_color", GameConfig.COL_TEXT_MUTED if muted else GameConfig.COL_TEXT)
	lbl.add_theme_font_size_override("font_size", size)
	_apply_font(lbl)


static func make_bg(parent: Control, color: Color = GameConfig.COL_BG) -> ColorRect:
	var bg := ColorRect.new()
	bg.color = color
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg)
	parent.move_child(bg, 0)
	return bg


## Family and travel stills are 4:3. Event stills are about 16:9.
## Weather stamps are tall canvases; cover them into the 4:3 photo frame.
const ALBUM_PHOTO_RATIO := 4.0 / 3.0
const LIGHTBOX_PHOTO_MAX := Vector2(720, 380)


static func lightbox_photo_ratio(tex: Texture2D) -> float:
	if tex == null or tex.get_width() <= 0 or tex.get_height() <= 0:
		return ALBUM_PHOTO_RATIO
	var src := float(tex.get_width()) / float(tex.get_height())
	if src >= 1.2:
		return src
	return ALBUM_PHOTO_RATIO


static func lightbox_photo_size(tex: Texture2D, max_size: Vector2) -> Vector2:
	var ratio := lightbox_photo_ratio(tex)
	var w := max_size.x
	var h := w / ratio
	if max_size.y > 0.0 and h > max_size.y:
		h = max_size.y
		w = h * ratio
	return Vector2(w, h)


## Drop the plain paper around a tall stamp so cover-crop fills the photo frame.
static func _trim_plain_margins(tex: Texture2D) -> Texture2D:
	if tex == null:
		return tex
	var img := tex.get_image()
	if img == null:
		return tex
	img = img.duplicate()
	if img.is_compressed():
		img.decompress()
	var w := img.get_width()
	var h := img.get_height()
	var min_x := w
	var min_y := h
	var max_x := -1
	var max_y := -1
	for y in range(h):
		for x in range(w):
			var c := img.get_pixel(x, y)
			if c.a < 0.05:
				continue
			if c.r >= 0.965 and c.g >= 0.965 and c.b >= 0.945:
				continue
			if x < min_x:
				min_x = x
			if y < min_y:
				min_y = y
			if x > max_x:
				max_x = x
			if y > max_y:
				max_y = y
	if max_x < min_x:
		return tex
	min_x = maxi(0, min_x - 2)
	min_y = maxi(0, min_y - 2)
	max_x = mini(w - 1, max_x + 2)
	max_y = mini(h - 1, max_y + 2)
	var cw := max_x - min_x + 1
	var ch := max_y - min_y + 1
	if cw >= w - 1 and ch >= h - 1:
		return tex
	return ImageTexture.create_from_image(img.get_region(Rect2i(min_x, min_y, cw, ch)))


## Landscape slot. Portrait stamps are covered into 4:3; wide photos keep their ratio.
static func make_landscape_photo(tex: Texture2D, max_size: Vector2) -> AspectRatioContainer:
	var shown := tex
	if tex != null and tex.get_height() > 0 and float(tex.get_width()) / float(tex.get_height()) < 1.2:
		shown = _trim_plain_margins(tex)
	var size := lightbox_photo_size(shown, max_size)
	var slot := AspectRatioContainer.new()
	slot.ratio = size.x / maxf(size.y, 1.0)
	slot.stretch_mode = AspectRatioContainer.STRETCH_FIT
	slot.alignment_horizontal = AspectRatioContainer.ALIGNMENT_CENTER
	slot.alignment_vertical = AspectRatioContainer.ALIGNMENT_CENTER
	slot.custom_minimum_size = size
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var photo := TextureRect.new()
	photo.name = "LandscapePhoto"
	photo.texture = shown
	photo.custom_minimum_size = size
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	photo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(photo)
	return slot


## Fit the whole texture inside max_size. Aspect stays; nothing is cropped.
static func contained_photo_size(tex: Texture2D, max_size: Vector2) -> Vector2:
	if tex == null or tex.get_width() <= 0 or tex.get_height() <= 0:
		return max_size
	var aspect := float(tex.get_width()) / float(tex.get_height())
	if aspect <= 0.0 or is_nan(aspect):
		return max_size
	var w := max_size.x
	var h := w / aspect
	if max_size.y > 0.0 and h > max_size.y:
		h = max_size.y
		w = h * aspect
	return Vector2(maxf(w, 1.0), maxf(h, 1.0))


## Diary photo that shows the full subject. Wide stills get a polaroid lip;
## tall stamps are trimmed of plain paper, then contained (not cover-cropped).
## Album frames stay on make_landscape_photo — that cover crop is only for the scrapbook.
static func make_contained_diary_photo(tex: Texture2D, max_size: Vector2, polaroid: bool = true, node_name: String = "ContainedPhoto") -> PanelContainer:
	var shown := tex
	if tex != null and tex.get_height() > 0 and float(tex.get_width()) / float(tex.get_height()) < 1.2:
		shown = _trim_plain_margins(tex)
	var size := contained_photo_size(shown, max_size)
	var frame := PanelContainer.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var inner := panel_style(Color("FFFAFC"), Color("F0C0D0"), 8)
	inner.shadow_size = 4
	inner.shadow_offset = Vector2(1, 2)
	if polaroid:
		inner.set_border_width_all(7)
		inner.border_width_bottom = 18
		inner.set_content_margin_all(5)
	else:
		inner.set_border_width_all(3)
		inner.set_corner_radius_all(16)
		inner.set_content_margin_all(6)
	frame.add_theme_stylebox_override("panel", inner)
	var photo := TextureRect.new()
	photo.name = node_name
	photo.texture = shown
	photo.custom_minimum_size = size
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	photo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	photo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(photo)
	return frame


## Full-screen pink diary lightbox. Tap outside,「闔上」, or Esc (via lightbox_consume_cancel).
static func show_diary_lightbox(parent: Node, tex: Texture2D, title: String, body: String) -> void:
	dismiss_diary_lightbox(parent)
	var layer := CanvasLayer.new()
	layer.name = "DiaryLightbox"
	layer.layer = 50
	parent.add_child(layer)

	var dim := ColorRect.new()
	dim.color = Color(0.33, 0.16, 0.24, 0.58)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dismiss_diary_lightbox(parent)
	)
	layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", panel_style(Color("FFF5F8"), Color("F5A8C0"), 22))
	center.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(v)

	if tex != null:
		var frame := PanelContainer.new()
		frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.clip_contents = true
		var inner := panel_style(Color("FFFAFC"), Color("F0C0D0"), 8)
		inner.set_border_width_all(8)
		inner.border_width_bottom = 22
		inner.set_content_margin_all(6)
		inner.shadow_size = 0
		frame.add_theme_stylebox_override("panel", inner)
		frame.add_child(make_landscape_photo(tex, LIGHTBOX_PHOTO_MAX))
		v.add_child(frame)

	var cap := Label.new()
	cap.text = title if title != "" else "一頁回憶"
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	apply_label(cap, 24)
	v.add_child(cap)

	if body != "":
		var copy := Label.new()
		copy.text = body
		copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		apply_label(copy, 16)
		v.add_child(copy)

	var hint := Label.new()
	hint.text = "點外面，或按 Esc，就可以闔上。"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	apply_label(hint, 13, true)
	v.add_child(hint)

	var close := Button.new()
	close.text = "闔上 ♡"
	apply_button(close, true)
	close.pressed.connect(func() -> void: dismiss_diary_lightbox(parent))
	v.add_child(close)


static func dismiss_diary_lightbox(parent: Node) -> void:
	var layer := parent.get_node_or_null("DiaryLightbox")
	if layer == null:
		return
	parent.remove_child(layer)
	layer.queue_free()


static func lightbox_open(parent: Node) -> bool:
	return parent.get_node_or_null("DiaryLightbox") != null


static func lightbox_consume_cancel(parent: Node, event: InputEvent) -> bool:
	if not lightbox_open(parent):
		return false
	var cancel := event.is_action_pressed("ui_cancel")
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_ESCAPE:
		cancel = true
	if not cancel:
		return false
	dismiss_diary_lightbox(parent)
	return true


static func make_texture_bg(parent: Control, path: String) -> TextureRect:
	var tex := TextureRect.new()
	tex.texture = load(path)
	tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(tex)
	parent.move_child(tex, 0)
	return tex
