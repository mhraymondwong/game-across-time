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
