class_name Travel
extends RefCounted
## 每兩年一次的遠行：第 2、4、6、8、10、12 年。
## 夏天進入主畫面時先問要不要出發；可留到冬天，或今年不去。
## 不取代每季三個活動格（「短途旅行」仍是普通休閒活動）。
##
## TODO: Japan / Asia / Europe / Australia have no dedicated stills yet.
## Their album thumbs temporarily reuse assets/family/family_photo_child.jpg.
## China uses assets/travel/travel_china_family.jpg.

const TRAVEL_YEARS: Array[int] = [2, 4, 6, 8, 10, 12]
const THUMB_CHINA := "res://assets/travel/travel_china_family.jpg"
## TODO: replace with destination art when those trips are illustrated.
const THUMB_FAMILY_TEMP := "res://assets/family/family_photo_child.jpg"

const DESTINATIONS: Array = [
	{
		"id": "china",
		"title": "中國・家附近的遠方",
		"place": "中國",
		"min_year": 1,
		"cost": 1800,
		"with_mom": true,
		"thumb": THUMB_CHINA,
		"blurb": "坐火車就到的城。老街、江風，和一碗熱湯。",
		"lock_hint": "",
		"vignette_title": "江邊的合照",
		"vignette_body": "媽媽把外套披上她的肩，爸爸站在旁邊數著腳步。路人幫忙按下快門，三個人都笑了。這張照片要貼進相簿。",
		"deltas": {"mood": 8, "social": 3, "stamina": 2, "charm": 1},
	},
	{
		"id": "japan",
		"title": "日本・短途的海",
		"place": "日本",
		"min_year": 7,
		"cost": 4200,
		"with_mom": true,
		# TODO: dedicated Japan trip art. Temporary thumb is the childhood family photo.
		"thumb": THUMB_FAMILY_TEMP,
		"blurb": "電車、石階、便利商店的熱茶。",
		"lock_hint": "國中以後開放（第 7 年・約 12 歲）",
		"vignette_title": "神社石階上",
		"vignette_body": "她拉著媽媽的袖子，一級一級往上走。爸爸在後面跟著數。風很乾淨，三個人的影子疊在一起。",
		"deltas": {"mood": 7, "academia": 3, "charm": 2, "social": 2},
	},
	{
		"id": "asia",
		"title": "亞洲・更遠的街",
		"place": "亞洲",
		"min_year": 10,
		"cost": 5400,
		"with_mom": true,
		# TODO: dedicated Asia trip art. Temporary thumb is the childhood family photo.
		"thumb": THUMB_FAMILY_TEMP,
		"blurb": "另一座城市的夜市與海風。",
		"lock_hint": "稍後幾年開放（第 10 年・約 15 歲）",
		"vignette_title": "夜市燈下",
		"vignette_body": "媽媽挑了不辣的那串，她卻說想試試看。爸爸笑著付錢。燈很亮，像把家裡的燈帶到了別的街上。",
		"deltas": {"mood": 6, "social": 4, "charm": 2, "stamina": 1},
	},
	{
		"id": "europe",
		"title": "歐洲・很長的一天",
		"place": "歐洲",
		"min_year": 10,
		"cost": 7600,
		"with_mom": true,
		# TODO: dedicated Europe trip art. Temporary thumb is the childhood family photo.
		"thumb": THUMB_FAMILY_TEMP,
		"blurb": "很長的飛行，很短的散步。石頭路與麵包香。",
		"lock_hint": "稍後幾年開放（第 10 年・約 15 歲）",
		"vignette_title": "石板路上的黃昏",
		"vignette_body": "時差讓大家都有點睏。媽媽還是拉著她在橋上站了一會兒。爸爸說，看完這條河，我們就回去睡覺。",
		"deltas": {"mood": 6, "academia": 4, "charm": 3, "social": 1},
	},
	{
		"id": "australia",
		"title": "澳洲・相反的季節",
		"place": "澳洲",
		"min_year": 10,
		"cost": 6800,
		"with_mom": true,
		# TODO: dedicated Australia trip art. Temporary thumb is the childhood family photo.
		"thumb": THUMB_FAMILY_TEMP,
		"blurb": "季節是反的。天很寬，風走很遠也不累。",
		"lock_hint": "稍後幾年開放（第 10 年・約 15 歲）",
		"vignette_title": "季節相反的天空",
		"vignette_body": "她問為什麼這裡的冬天這麼亮。媽媽說，世界很大，天氣也會跟家裡不一樣。爸爸把帽子按好，風還是把三個人的頭髮吹亂了。",
		"deltas": {"mood": 8, "stamina": 4, "social": 2, "charm": 1},
	},
]


static func is_travel_year(year: int) -> bool:
	return year in TRAVEL_YEARS


static func _flag(year: int) -> String:
	return "travel_window_%d" % year


static func status_of(state) -> String:
	return str(state.flags.get(_flag(int(state.year)), ""))


static func destinations() -> Array:
	return DESTINATIONS


static func get_dest(dest_id: String) -> Dictionary:
	for d in DESTINATIONS:
		if str(d.get("id", "")) == dest_id:
			return d
	return {}


## Age unlock only. Cash is a separate lock (see lock_reason).
static func unlocked_ids(state) -> Array:
	var out: Array = []
	var y := int(state.year)
	for d in DESTINATIONS:
		if y >= int(d.get("min_year", 1)):
			out.append(str(d.get("id", "")))
	return out


static func lock_reason(dest: Dictionary, state) -> String:
	if dest.is_empty():
		return "先選一個地方。"
	var min_year := int(dest.get("min_year", 1))
	if int(state.year) < min_year:
		var hint := str(dest.get("lock_hint", ""))
		if hint != "":
			return hint
		return "還沒到能去的年紀。"
	var cost := int(dest.get("cost", 0))
	if int(state.cash) < cost:
		return "家計不足（需要 $%d）" % cost
	return ""


## Summer of a travel year, before any choice; or winter if still open (deferred, or never asked).
static func window_open(state) -> bool:
	var y := int(state.year)
	if not is_travel_year(y):
		return false
	var status := status_of(state)
	if status == "summer" or status == "winter" or status == "skipped":
		return false
	var season := int(state.season)
	if season == 1 and status == "":
		return true
	if season == 3 and (status == "" or status == "deferred"):
		return true
	return false


static func offer_due(state) -> bool:
	return window_open(state)


static func hub_hint(state) -> String:
	if not is_travel_year(int(state.year)):
		return ""
	if status_of(state) == "deferred" and int(state.season) < 3:
		return "今年的遠行留到冬天。"
	return ""


static func defer_to_winter(state) -> bool:
	if int(state.season) != 1 or not window_open(state):
		return false
	state.flags[_flag(int(state.year))] = "deferred"
	return true


static func skip_window(state) -> bool:
	if not window_open(state):
		return false
	state.flags[_flag(int(state.year))] = "skipped"
	return true


## Deduct cash, apply stats, append an album page, close the window.
static func depart(state, dest_id: String) -> Dictionary:
	if not window_open(state):
		return {"ok": false, "reason": "這趟旅行的窗口已經過去了。"}
	var dest := get_dest(dest_id)
	var why := lock_reason(dest, state)
	if why != "":
		return {"ok": false, "reason": why}
	var y := int(state.year)
	var season_now := int(state.season)
	var cost := int(dest.get("cost", 0))
	var deltas: Dictionary = {}
	var raw = dest.get("deltas", {})
	if typeof(raw) == TYPE_DICTIONARY:
		deltas = (raw as Dictionary).duplicate()
	deltas["cash"] = -cost
	var went := "summer" if season_now == 1 else "winter"
	state.flags[_flag(y)] = went
	state.flags["travel_dest_%d" % y] = dest_id
	state.apply_map_event_delta(deltas)
	var title := str(dest.get("vignette_title", dest.get("title", "遠行")))
	var body := str(dest.get("vignette_body", ""))
	var thumb := str(dest.get("thumb", ""))
	state.append_album_entry({
		"id": "travel_%s_y%d" % [dest_id, y],
		"year": y,
		"season": season_now,
		"title": title,
		"thumb_path": thumb,
		"body": body,
	})
	state.note_year_event(title)
	return {
		"ok": true,
		"title": title,
		"body": body,
		"thumb": thumb,
		"deltas": deltas,
		"cost": cost,
		"place": str(dest.get("place", "")),
		"with_mom": bool(dest.get("with_mom", false)),
		"when": went,
	}


static func format_deltas(deltas: Dictionary) -> String:
	return Mom.format_deltas(deltas)
