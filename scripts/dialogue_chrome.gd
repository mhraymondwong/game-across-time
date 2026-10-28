class_name DialogueChrome
extends RefCounted
## Illustrated diary frame for conversations.
## Speaker busts come from AgeLooks. Theme stamps reuse place art, family photos, and the Japan trip scene.
## Corner blossoms, washi, and the two abstract stamps live in assets/dialogue/
## and ship in packs/dialogue.pck so they stay out of index.pck.
## If that pack is missing, portraits and place photos still show, and the
## frame falls back to drawn sprigs.


const PAPER_PATH := "res://assets/dialogue/paper_tile.png"
const CORNER_PATH := "res://assets/dialogue/corner_blossom.png"
const WASHI_PATH := "res://assets/dialogue/washi.png"
const GLOW_PATH := "res://assets/dialogue/bust_glow.png"
const HEART_PATH := "res://assets/dialogue/heart_stamp.png"
const WORK_PATH := "res://assets/dialogue/work_stamp.png"

const THEME_ART := {
	"home": "res://assets/places/place_home.jpg",
	"school": "res://assets/places/place_school.jpg",
	"shop": "res://assets/places/place_shops.jpg",
	"park": "res://assets/places/place_park.jpg",
	"clinic": "res://assets/places/place_clinic.jpg",
	"culture": "res://assets/places/place_culture.jpg",
	"travel": "res://assets/travel/travel_japan_family.jpg",
}

const THEME_CAPTION := {
	"home": "家",
	"school": "學校",
	"shop": "商店街",
	"park": "公園",
	"clinic": "診所",
	"culture": "文化",
	"travel": "遠行",
	"family": "一家",
	"romance": "心事",
	"work": "工作",
}

## Stable id → picture. Keyword scan is only for lines that have no id (mom).
const CONFIDE_THEMES := {
	"child_worry_seat": "school",
	"child_worry_candy": "shop",
	"child_worry_homework": "school",
	"child_cling_hug": "family",
	"child_cling_snack": "shop",
	"child_cling_home": "home",
	"teen_worry_group": "school",
	"teen_worry_quiet": "home",
	"teen_worry_sleep": "home",
	"teen_cling_noodle": "home",
	"teen_cling_lean": "home",
	"teen_cling_weekend": "home",
	"adult_worry_late": "work",
	"adult_worry_someone": "romance",
	"adult_cling_dinner": "family",
	"adult_cling_quiet": "home",
}

const LINE_KEYS: Array = [
	["學校", "school"],
	["功課", "school"],
	["老師", "school"],
	["同學", "school"],
	["位子", "school"],
	["書包", "school"],
	["商店", "shop"],
	["餅乾", "shop"],
	["糖", "shop"],
	["公園", "park"],
	["散步", "park"],
	["巷口", "park"],
	["診所", "clinic"],
	["遠行", "travel"],
	["旅行", "travel"],
	["的班", "work"],
	["工作", "work"],
	["有一個人", "romance"],
	["三個人", "family"],
	["一家", "family"],
	["窗邊", "family"],
	["媽媽", "family"],
	["爸爸", "family"],
	["沙發", "home"],
	["湯", "home"],
	["麵", "home"],
	["飯", "home"],
	["家", "home"],
]


static func paper_style() -> StyleBoxFlat:
	var s := UiStyle.panel_style(Color("FFF8F2"), Color("E7B4C4"), 26)
	s.set_border_width_all(3)
	s.set_content_margin_all(0)
	s.shadow_color = Color(0.45, 0.22, 0.32, 0.18)
	s.shadow_size = 16
	s.shadow_offset = Vector2(0, 6)
	return s


static func theme_for_confide(id: String) -> String:
	return str(CONFIDE_THEMES.get(id, "home"))


static func theme_for_line(text: String) -> String:
	for pair in LINE_KEYS:
		if text.contains(str(pair[0])):
			return str(pair[1])
	return "home"


static func speaker_path(who: String, year: int, season: int) -> String:
	match who:
		"mom":
			return AgeLooks.mom_portrait(year)
		"dad":
			return AgeLooks.dad_portrait(year)
		"daughter":
			return AgeLooks.daughter_portrait(year, season)
		_:
			return ""


static func theme_art(theme: String, year: int) -> String:
	match theme:
		"family":
			return AgeLooks.family_photo(year)
		"romance":
			return HEART_PATH
		"work":
			return WORK_PATH
		"travel":
			var scene := Travel.scene_for("japan")
			if scene != "":
				return scene
			return str(THEME_ART.get("travel", ""))
		_:
			return str(THEME_ART.get(theme, ""))


static func place_art(place_id: String) -> String:
	match place_id:
		"home":
			return theme_art("home", 1)
		"school":
			return theme_art("school", 1)
		"shops":
			return theme_art("shop", 1)
		"park":
			return theme_art("park", 1)
		"clinic":
			return theme_art("clinic", 1)
		"culture":
			return theme_art("culture", 1)
		_:
			return ""


static func theme_caption(theme: String) -> String:
	return str(THEME_CAPTION.get(theme, ""))


static func load_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	var abs := ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
	if FileAccess.file_exists(abs):
		var img := Image.load_from_file(abs)
		if img:
			return ImageTexture.create_from_image(img)
	return null


## Centered diary popup. `body` is where the caller puts the line and the buttons.
static func make_shell(min_size: Vector2, portrait_size: Vector2 = Vector2(196, 320)) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = "DialogueShell"
	panel.custom_minimum_size = min_size
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -min_size.x * 0.5
	panel.offset_right = min_size.x * 0.5
	panel.offset_top = -min_size.y * 0.5
	panel.offset_bottom = min_size.y * 0.5
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", paper_style())

	var host := Control.new()
	host.name = "DiaryHost"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(host)

	var ornament := DiaryOrnament.new()
	ornament.name = "DiaryOrnament"
	ornament.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ornament.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(ornament)
	_fill_ornament(ornament)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.mouse_filter = Control.MOUSE_FILTER_STOP
	host.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(column)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(row)

	var portrait_column := VBoxContainer.new()
	portrait_column.name = "PortraitColumn"
	portrait_column.add_theme_constant_override("separation", 6)
	portrait_column.alignment = BoxContainer.ALIGNMENT_CENTER
	portrait_column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait_column.custom_minimum_size = Vector2(portrait_size.x, 0)
	row.add_child(portrait_column)

	var portrait_host := Control.new()
	portrait_host.name = "PortraitHost"
	portrait_host.custom_minimum_size = portrait_size
	portrait_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_column.add_child(portrait_host)

	var glow := TextureRect.new()
	glow.name = "BustGlow"
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.texture = load_texture(GLOW_PATH)
	glow.visible = glow.texture != null
	glow.modulate = Color(1, 0.9, 0.93, 0.95)
	portrait_host.add_child(glow)

	var portrait := TextureRect.new()
	portrait.name = "DialogueBust"
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_host.add_child(portrait)

	var listener_row := HBoxContainer.new()
	listener_row.name = "ListenerRow"
	listener_row.add_theme_constant_override("separation", 6)
	listener_row.alignment = BoxContainer.ALIGNMENT_CENTER
	listener_row.visible = false
	portrait_column.add_child(listener_row)

	var listener := TextureRect.new()
	listener.name = "DialogueListener"
	listener.custom_minimum_size = Vector2(58, 78)
	listener.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	listener.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	listener.mouse_filter = Control.MOUSE_FILTER_IGNORE
	listener_row.add_child(listener)

	var listener_caption := Label.new()
	listener_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiStyle.apply_label(listener_caption, 13, true)
	listener_row.add_child(listener_caption)

	var text_host := Control.new()
	text_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_host)

	var paper := TextureRect.new()
	paper.name = "DiaryPaper"
	paper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode = TextureRect.STRETCH_TILE
	paper.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.texture = load_texture(PAPER_PATH)
	paper.visible = paper.texture != null
	paper.modulate = Color(1, 1, 1, 0.55)
	text_host.add_child(paper)

	var rules := PaperRules.new()
	rules.name = "PaperRules"
	rules.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rules.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_host.add_child(rules)

	var text_col := VBoxContainer.new()
	text_col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	text_col.offset_left = 10
	text_col.offset_top = 2
	text_col.offset_right = -6
	text_col.offset_bottom = -2
	text_col.add_theme_constant_override("separation", 8)
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_host.add_child(text_col)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	text_col.add_child(header)

	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 4)
	header.add_child(titles)

	var kicker := Label.new()
	kicker.name = "DialogueKicker"
	kicker.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(kicker, 13, true)
	titles.add_child(kicker)

	# Speaker name is diary text. Only the player's choices are buttons.
	var nameplate := Label.new()
	nameplate.name = "DialogueName"
	nameplate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nameplate.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.apply_label(nameplate, 26)
	titles.add_child(nameplate)

	var theme_frame := _make_stamp_frame()
	header.add_child(theme_frame)
	var theme: TextureRect = theme_frame.get_meta("photo")
	var theme_caption: Label = theme_frame.get_meta("caption")

	var body := VBoxContainer.new()
	body.name = "DialogueBody"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	text_col.add_child(body)

	var actions := VBoxContainer.new()
	actions.name = "DialogueActions"
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.size_flags_vertical = Control.SIZE_SHRINK_END
	actions.add_theme_constant_override("separation", 8)
	column.add_child(actions)

	return {
		"panel": panel,
		"body": body,
		"actions": actions,
		"portrait": portrait,
		"portrait_host": portrait_host,
		"portrait_column": portrait_column,
		"listener": listener,
		"listener_row": listener_row,
		"listener_caption": listener_caption,
		"kicker": kicker,
		"nameplate": nameplate,
		"theme": theme,
		"theme_caption": theme_caption,
		"theme_frame": theme_frame,
	}


static func apply_heading(shell: Dictionary, kicker_text: String, name_text: String) -> void:
	var kicker: Label = shell["kicker"]
	var nameplate: Label = shell["nameplate"]
	kicker.text = kicker_text
	nameplate.text = name_text


static func apply_speaker(shell: Dictionary, who: String, year: int, season: int) -> void:
	var portrait: TextureRect = shell["portrait"]
	portrait.texture = load_texture(speaker_path(who, year, season))
	var host: Control = shell["portrait_host"]
	host.visible = portrait.texture != null
	_refresh_column(shell)


static func apply_listener(shell: Dictionary, who: String, year: int, season: int, caption: String) -> void:
	var listener: TextureRect = shell["listener"]
	var row: Control = shell["listener_row"]
	var cap: Label = shell["listener_caption"]
	listener.texture = load_texture(speaker_path(who, year, season))
	cap.text = caption
	row.visible = listener.texture != null
	_refresh_column(shell)


static func apply_theme(shell: Dictionary, theme: String, year: int) -> void:
	var frame: Control = shell["theme_frame"]
	var photo: TextureRect = shell["theme"]
	var caption: Label = shell["theme_caption"]
	photo.texture = load_texture(theme_art(theme, year))
	caption.text = theme_caption(theme)
	frame.visible = photo.texture != null


static func make_bust(who: String, year: int, season: int, box: Vector2) -> Control:
	var host := Control.new()
	host.name = "DialogueBustHost"
	host.custom_minimum_size = box
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var glow_tex := load_texture(GLOW_PATH)
	if glow_tex != null:
		var glow := TextureRect.new()
		glow.texture = glow_tex
		glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.modulate = Color(1, 0.9, 0.93, 0.95)
		host.add_child(glow)
	var portrait := TextureRect.new()
	portrait.name = "DialogueBust"
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.texture = load_texture(speaker_path(who, year, season))
	host.add_child(portrait)
	host.visible = portrait.texture != null
	return host


static func make_stamp(theme: String, year: int) -> Control:
	var frame := _make_stamp_frame()
	var photo: TextureRect = frame.get_meta("photo")
	var caption: Label = frame.get_meta("caption")
	photo.texture = load_texture(theme_art(theme, year))
	caption.text = theme_caption(theme)
	frame.visible = photo.texture != null
	return frame


## Moves the panel's current child into a host and paints corners behind it.
## PanelContainer stretches every direct child, so the host stays the only one.
static func dress_panel(panel: PanelContainer) -> void:
	if panel.get_node_or_null("DiaryHost") != null:
		return
	var existing: Node = panel.get_child(0) if panel.get_child_count() > 0 else null
	var host := Control.new()
	host.name = "DiaryHost"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if existing != null:
		panel.remove_child(existing)
	panel.add_child(host)
	var ornament := DiaryOrnament.new()
	ornament.name = "DiaryOrnament"
	ornament.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ornament.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(ornament)
	_fill_ornament(ornament)
	if existing is Control:
		var ctrl := existing as Control
		ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		host.add_child(ctrl)


static func _refresh_column(shell: Dictionary) -> void:
	var host: Control = shell["portrait_host"]
	var row: Control = shell["listener_row"]
	var col: Control = shell["portrait_column"]
	col.visible = host.visible or row.visible


static func _make_stamp_frame() -> PanelContainer:
	var frame := PanelContainer.new()
	frame.name = "DialogueStamp"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := UiStyle.panel_style(Color("FFFCF8"), Color("F0C4D0"), 10)
	style.set_border_width_all(2)
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 5
	style.content_margin_bottom = 4
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	frame.add_theme_stylebox_override("panel", style)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(col)
	var photo := TextureRect.new()
	photo.name = "StampPhoto"
	photo.custom_minimum_size = Vector2(148, 82)
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(photo)
	var caption := Label.new()
	caption.name = "StampCaption"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.apply_label(caption, 12, true)
	col.add_child(caption)
	frame.set_meta("photo", photo)
	frame.set_meta("caption", caption)
	frame.visible = false
	return frame


static func _fill_ornament(ornament: Control) -> void:
	var corner := load_texture(CORNER_PATH)
	if ornament is DiaryOrnament:
		(ornament as DiaryOrnament).draw_sprigs = corner == null
	if corner != null:
		ornament.add_child(_corner_tex(corner, "tl"))
		ornament.add_child(_corner_tex(corner, "tr"))
		ornament.add_child(_corner_tex(corner, "bl"))
		ornament.add_child(_corner_tex(corner, "br"))
	var washi := load_texture(WASHI_PATH)
	if washi != null:
		var tape := TextureRect.new()
		tape.name = "Washi"
		tape.texture = washi
		tape.set_anchors_preset(Control.PRESET_TOP_WIDE)
		tape.offset_left = 36
		tape.offset_right = -36
		tape.offset_top = 5
		tape.offset_bottom = 20
		tape.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tape.stretch_mode = TextureRect.STRETCH_TILE
		tape.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		tape.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tape.modulate = Color(1, 1, 1, 0.92)
		ornament.add_child(tape)


static func _corner_tex(tex: Texture2D, corner: String) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(78, 78)
	match corner:
		"tl":
			r.set_anchors_preset(Control.PRESET_TOP_LEFT)
			r.offset_left = -2
			r.offset_top = -2
			r.offset_right = 76
			r.offset_bottom = 76
		"tr":
			r.flip_h = true
			r.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			r.offset_left = -76
			r.offset_top = -2
			r.offset_right = 2
			r.offset_bottom = 76
		"bl":
			r.flip_v = true
			r.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
			r.offset_left = -2
			r.offset_top = -76
			r.offset_right = 76
			r.offset_bottom = 2
		_:
			r.flip_h = true
			r.flip_v = true
			r.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			r.offset_left = -76
			r.offset_top = -76
			r.offset_right = 2
			r.offset_bottom = 2
	return r


class DiaryOrnament extends Control:
	var draw_sprigs: bool = true

	func _draw() -> void:
		if size.x < 16.0 or size.y < 16.0:
			return
		var inset := 7.0
		draw_rect(Rect2(inset, inset, size.x - inset * 2.0, size.y - inset * 2.0), Color(0.86, 0.55, 0.64, 0.55), false, 1.25)
		var inset2 := 11.0
		draw_rect(Rect2(inset2, inset2, size.x - inset2 * 2.0, size.y - inset2 * 2.0), Color(0.93, 0.74, 0.78, 0.7), false, 1.0)
		if not draw_sprigs:
			return
		_sprig(Vector2(20, 20), 1.0)
		_sprig(Vector2(size.x - 20, 20), -1.0)
		_sprig(Vector2(20, size.y - 20), 1.0)
		_sprig(Vector2(size.x - 20, size.y - 20), -1.0)

	func _sprig(at: Vector2, dir: float) -> void:
		var leaf := Color(0.72, 0.82, 0.66, 0.9)
		var pink := Color(0.95, 0.69, 0.76, 0.95)
		draw_circle(at + Vector2(dir * 16, 12), 6.0, leaf)
		draw_circle(at + Vector2(dir * 8, 18), 4.5, Color(0.78, 0.86, 0.7, 0.85))
		var c := at + Vector2(dir * 8, 8)
		draw_circle(c + Vector2(dir * 6, 0), 5.5, pink)
		draw_circle(c + Vector2(dir * -2, -6), 5.0, Color(0.98, 0.82, 0.86, 0.95))
		draw_circle(c + Vector2(dir * -2, 6), 5.0, pink)
		draw_circle(c, 3.4, Color(0.84, 0.47, 0.58, 0.95))


class PaperRules extends Control:
	func _draw() -> void:
		if size.x < 8.0 or size.y < 8.0:
			return
		draw_line(Vector2(6, 6), Vector2(6, size.y - 6), Color(0.86, 0.55, 0.62, 0.35), 1.5)
		var y := 34.0
		var ink := Color(0.75, 0.5, 0.56, 0.18)
		while y < size.y - 4.0:
			draw_line(Vector2(14, y), Vector2(size.x - 8, y), ink, 1.0)
			y += 28.0
