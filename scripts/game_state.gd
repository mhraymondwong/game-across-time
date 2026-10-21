extends Node
## Autoload：年／季／月、屬性、家計、排程與結算

signal state_changed
signal season_resolved(deltas: Dictionary)
signal game_ended(ending: Dictionary)

var year: int = 1
var season: int = 0  # 0春 1夏 2秋 3冬
var month_in_season: int = 0

var charm: int = 35
var morals: int = 40
var social: int = 35
var stamina: int = 50
var academia: int = 30
var mood: int = 60
var cash: int = 8000

## Current season schedule: Array of activity id strings length 3 (or empty slots)
var season_schedule: Array[String] = ["", "", ""]

## Last season deltas for result screen
var last_deltas: Dictionary = {}
var last_activity_names: Array[String] = []
## Last seasonal weather / festival event (title, body, sticker, deltas)
var last_season_event: Dictionary = {}
## One vignette per scheduled month (title, body, sticker, notable…)
var last_vignettes: Array = []
## Optional map beat rolled at season resolve (once per place per season)
var last_roaming_event: Dictionary = {}
## Living album: {id, year, season, title, thumb_path, body}
## New games seed a family photo via Mom.seed_family_album. Trips append more.
var album: Array = []
## When set, the album scene returns here and may show album_browse instead of album
var album_return_scene: String = ""
var album_browse: Array = []
var save_name: String = ""
## Chosen on the title screen before a new game. Session-only: not written to saves.
var wants_new_game_name: bool = false
var daughter_name: String = "小悠"
## Skill id -> XP. Levels are derived. Interest tag id -> points.
## education_path is a later adulthood hook; this build never opens a choice UI.
var skill_xp: Dictionary = {}
var interest_points: Dictionary = {}
var education_path: String = "undecided"
var _event_rng: RandomNumberGenerator = RandomNumberGenerator.new()

const DEFAULT_DAUGHTER_NAME := "小悠"
const DAUGHTER_NAME_MAX := 8

const SLOT_TITLES: PackedStringArray = ["第一本日記", "第二本日記", "第三本日記"]

var flags: Dictionary = {}
## npc id -> affinity 0–100
var npc_affinity: Dictionary = {}
var months_played: int = 0
var is_game_over: bool = false
var final_ending: Dictionary = {}

## Year-end scrapbook review (Phase 6)
var year_start_stats: Dictionary = {}
var year_activity_names: Array = []
var year_event_titles: Array = []
var last_year_review: Dictionary = {}
var pending_ending_after_review: bool = false

const _STAT_KEYS := ["charm", "morals", "social", "stamina", "academia", "mood"]


func _ready() -> void:
	pass


func begin_new_game(given_name: String = "") -> void:
	daughter_name = DEFAULT_DAUGHTER_NAME
	var given := given_name.strip_edges()
	if given != "" and daughter_name_error(given) == "":
		daughter_name = given
	wants_new_game_name = false
	year = 1
	season = 0
	month_in_season = 0
	charm = int(GameConfig.STARTING_STATS["charm"])
	morals = int(GameConfig.STARTING_STATS["morals"])
	social = int(GameConfig.STARTING_STATS["social"])
	stamina = int(GameConfig.STARTING_STATS["stamina"])
	academia = int(GameConfig.STARTING_STATS["academia"])
	mood = int(GameConfig.STARTING_STATS["mood"])
	cash = GameConfig.STARTING_CASH
	season_schedule = ["", "", ""]
	last_deltas = {}
	last_activity_names = []
	last_season_event = {}
	last_vignettes = []
	last_roaming_event = {}
	album = []
	album_return_scene = ""
	album_browse = []
	save_name = ""
	_event_rng.randomize()
	flags.clear()
	flags["mom_warmth"] = 70
	skill_xp = {}
	interest_points = {}
	education_path = "undecided"
	reset_npc_affinity()
	months_played = 0
	is_game_over = false
	final_ending = {}
	year_start_stats = {}
	year_activity_names = []
	year_event_titles = []
	last_year_review = {}
	pending_ending_after_review = false
	snapshot_year_start()
	Mom.seed_family_album(self)
	state_changed.emit()


## Empty string means the name is fine to keep.
static func daughter_name_error(raw: String) -> String:
	var cleaned := raw.strip_edges()
	if cleaned == "":
		return "名字還空著。"
	if cleaned.length() > DAUGHTER_NAME_MAX:
		return "八個字以內就好。"
	if cleaned.contains("%"):
		return "這個符號先不要寫進名字。"
	for i in cleaned.length():
		var code := cleaned.unicode_at(i)
		if code < 32 or code == 127:
			return "這個名字寫不進日記。"
	return ""


func daughter_display_name() -> String:
	var cleaned := daughter_name.strip_edges()
	if daughter_name_error(cleaned) != "":
		return DEFAULT_DAUGHTER_NAME
	return cleaned


## Lines that name her use a single %s. Other sentences stay as written.
func format_daughter(text: String) -> String:
	if not text.contains("%s"):
		return text
	return text % daughter_display_name()


func get_age() -> int:
	return GameConfig.age_for_year(year)


func get_season_name() -> String:
	return GameConfig.season_name(season)


func get_time_label() -> String:
	var stage := GameConfig.growth_stage_for_year(year)
	return "第 %d 年 · %s · %s %d 歲（%s）" % [
		year, get_season_name(), daughter_display_name(), get_age(), GameConfig.growth_stage_label(stage)
	]


func get_stats_dict() -> Dictionary:
	return {
		"charm": charm,
		"morals": morals,
		"social": social,
		"stamina": stamina,
		"academia": academia,
		"mood": mood,
		"cash": cash,
	}


func set_schedule_slot(month_index: int, activity_id: String) -> void:
	if month_index < 0 or month_index >= GameConfig.MONTHS_PER_SEASON:
		return
	season_schedule[month_index] = activity_id
	state_changed.emit()


func is_season_fully_scheduled() -> bool:
	for id in season_schedule:
		if id == "" or id == null:
			return false
	return true


func begin_season() -> void:
	season_schedule = ["", "", ""]
	month_in_season = 0
	state_changed.emit()


## Apply one month activity; returns delta dict for that month
func apply_activity(activity_id: String) -> Dictionary:
	var aid := activity_id
	if aid == "" or not Activities.is_available(aid, self):
		aid = "rest_sleep"
	var def := Activities.get_activity(aid)
	var delta := {
		"charm": 0, "morals": 0, "social": 0, "stamina": 0,
		"academia": 0, "mood": 0, "cash": 0, "name": aid,
	}
	if def.is_empty():
		return delta

	var mult := 1.0
	if def.has("season_bonus"):
		var sb: Dictionary = def["season_bonus"]
		if sb.has(season):
			mult = float(sb[season])
		elif sb.has(str(season)):
			mult = float(sb[str(season)])

	var effects: Dictionary = def.get("effects", {})
	for k in effects:
		if k == "mood_via":
			continue
		var v := int(round(float(effects[k]) * mult))
		delta[k] = int(delta.get(k, 0)) + v

	var cash_d := int(def.get("cash", 0))
	delta["cash"] = cash_d
	var mood_d := int(round(float(def.get("mood", 0)) * mult))
	delta["mood"] = int(delta.get("mood", 0)) + mood_d
	delta["name"] = str(def.get("name", activity_id))

	_apply_delta(delta)
	var bump := TownNpcs.affinity_for_activity(aid)
	if not bump.is_empty():
		apply_affinity_map(bump, false)
	GrowthPath.grant(self, aid)
	var disp := str(delta.get("name", activity_id))
	if disp != "":
		year_activity_names.append(disp)
	months_played += 1
	month_in_season += 1
	# Soft bankruptcy rescue
	if cash < 0:
		cash = 500
		mood = maxi(mood - 5, 0)
		flags["rescued"] = true
	state_changed.emit()
	return delta


func _apply_delta(delta: Dictionary) -> void:
	charm = _clamp_stat(charm + int(delta.get("charm", 0)))
	morals = _clamp_stat(morals + int(delta.get("morals", 0)))
	social = _clamp_stat(social + int(delta.get("social", 0)))
	stamina = _clamp_stat(stamina + int(delta.get("stamina", 0)))
	academia = _clamp_stat(academia + int(delta.get("academia", 0)))
	mood = _clamp_stat(mood + int(delta.get("mood", 0)))
	cash += int(delta.get("cash", 0))


func _clamp_stat(v: int) -> int:
	return clampi(v, GameConfig.STAT_MIN, GameConfig.STAT_MAX)


func apply_map_event_delta(delta: Dictionary) -> void:
	## Public wrapper for map visit deltas (mirrors SeasonEvents.apply_deltas_to_state)
	if delta.is_empty():
		return
	_apply_delta({
		"charm": int(delta.get("charm", 0)),
		"morals": int(delta.get("morals", 0)),
		"social": int(delta.get("social", 0)),
		"stamina": int(delta.get("stamina", 0)),
		"academia": int(delta.get("academia", 0)),
		"mood": int(delta.get("mood", 0)),
		"cash": int(delta.get("cash", 0)),
	})
	state_changed.emit()




## Resolve all 3 months in season_schedule; fills last_deltas
func resolve_season() -> Dictionary:
	var before := get_stats_dict()
	last_activity_names = []
	last_vignettes = []
	var month_logs: Array = []
	for i in range(GameConfig.MONTHS_PER_SEASON):
		var id: String = season_schedule[i] if i < season_schedule.size() else ""
		if id == "" or not Activities.is_available(id, self):
			id = "rest_sleep"
		var d := apply_activity(id)
		last_activity_names.append(str(d.get("name", id)))
		month_logs.append(d)
		var vig := ActivityScenes.get_vignette(id, season)
		vig["month_index"] = i
		vig["month_label"] = GameConfig.MONTH_LABELS[i] if i < GameConfig.MONTH_LABELS.size() else "這個月"
		vig["activity_name"] = str(d.get("name", id))
		last_vignettes.append(vig)

	# Seasonal weather / festival event (~55% chance of themed event, else light beat)
	var ev: Dictionary = SeasonEvents.roll_event(season, _event_rng, 0.55)
	ev["body"] = str(ev.get("body", "")).replace("女兒", daughter_display_name())
	last_season_event = ev
	SeasonEvents.apply_deltas_to_state(self, ev.get("deltas", {}))
	var sev_bump := TownNpcs.affinity_for_season_event(str(ev.get("id", "")))
	if not sev_bump.is_empty():
		apply_affinity_map(sev_bump, false)
	_roll_roaming_map_event()
	var ev_title := str(ev.get("title", ""))
	if ev_title != "":
		note_year_event(ev_title)

	var after := get_stats_dict()
	var totals := {}
	for k in before:
		totals[k] = int(after[k]) - int(before[k])
	totals["activities"] = last_activity_names.duplicate()
	totals["month_logs"] = month_logs
	totals["event"] = last_season_event.duplicate(true)
	totals["vignettes"] = _dict_array_dup(last_vignettes)
	totals["affinity_note"] = TownNpcs.season_note(self)
	last_deltas = totals
	record_season_memories()
	season_resolved.emit(totals)
	return totals


## Advance to next season or year; returns "hub" | "year_review" | "ending"
func advance_after_season() -> String:
	season += 1
	if season >= GameConfig.SEASONS_PER_YEAR:
		# Winter wrap: build scrapbook for the year just finished, then increment
		season = 0
		last_year_review = build_year_review()
		year += 1
		_year_end_touch()
		if year > GameConfig.TOTAL_YEARS:
			pending_ending_after_review = true
			state_changed.emit()
			return "year_review"
		begin_season()
		state_changed.emit()
		return "year_review"
	begin_season()
	return "hub"


func snapshot_year_start() -> void:
	year_start_stats = get_stats_dict()
	year_activity_names = []
	year_event_titles = []


func note_year_event(title: String) -> void:
	var t := title.strip_edges()
	if t == "":
		return
	year_event_titles.append(t)


func build_year_review() -> Dictionary:
	## Compare current stats to year_start_stats; craft warm zh-Hant summary.
	## Call while `year` still equals the completed game year.
	var review_year := year
	var age := GameConfig.age_for_year(review_year)
	var stage := GameConfig.growth_stage_for_year(review_year)
	var stage_label := GameConfig.growth_stage_label(stage)
	var before: Dictionary = year_start_stats if not year_start_stats.is_empty() else get_stats_dict()
	var after := get_stats_dict()
	var deltas := {}
	for k in ["charm", "morals", "social", "stamina", "academia", "mood", "cash"]:
		deltas[k] = int(after.get(k, 0)) - int(before.get(k, 0))
	var highlights := _year_highlights()
	var summary := _craft_year_summary(deltas, review_year, age, stage_label)
	var band := GameConfig.polaroid_band_for_age(age)
	return {
		"year": review_year,
		"age": age,
		"stage_label": stage_label,
		"deltas": deltas,
		"highlights": highlights,
		"polaroid_band": band,
		"summary": summary,
	}


func _year_highlights() -> Array:
	var out: Array = []
	var seen := {}
	for n in year_activity_names:
		var s := str(n)
		if s == "" or seen.has(s):
			continue
		seen[s] = true
		out.append("活動・%s" % s)
		if out.size() >= 3:
			break
	for t in year_event_titles:
		var s2 := str(t)
		if s2 == "" or seen.has(s2):
			continue
		seen[s2] = true
		out.append("回憶・%s" % s2)
		if out.size() >= 6:
			break
	var aff_line := TownNpcs.year_highlight(self)
	if aff_line != "":
		out.append(aff_line)
	if out.is_empty():
		out.append("平靜的一年，手帳裡也留下了淡淡的粉紅。")
	return out


func _craft_year_summary(deltas: Dictionary, review_year: int, age: int, stage_label: String) -> String:
	var mood_d := int(deltas.get("mood", 0))
	var best_k := ""
	var best_v := 0
	var labels := {
		"charm": "氣質", "morals": "品格", "social": "人際",
		"stamina": "體力", "academia": "學識",
	}
	for k in labels:
		var v := int(deltas.get(k, 0))
		if v > best_v:
			best_v = v
			best_k = k
	if mood_d <= -8:
		return "第 %d 年有點累，%d 歲的她仍會把小手伸進你的掌心——明年，我們慢慢把笑容找回來。" % [review_year, age]
	if best_k != "" and best_v >= 8:
		return "翻開第 %d 年的相簿：%s的%s明顯長了一截。看著 %d 歲的她，你覺得這份陪伴沒有白費。" % [
			review_year, stage_label, labels[best_k], age
		]
	if int(deltas.get("cash", 0)) >= 2000:
		return "第 %d 年家計稍微寬裕了些。你們在小鎮街角買了甜點，把平凡日子也貼進相簿。" % review_year
	if mood_d >= 5:
		return "第 %d 年的標籤是溫暖。%d 歲（%s）的她笑得很多——這些拍立得，就留給將來的你們。" % [
			review_year, age, stage_label
		]
	return "第 %d 年就這樣翻過。沒有轟轟烈烈，只有你與她並肩走過的四季剪影。" % review_year


func continue_after_year_review() -> String:
	## Called by year_review scene continue button.
	if pending_ending_after_review:
		pending_ending_after_review = false
		return finish_game()
	snapshot_year_start()
	state_changed.emit()
	return "hub"


func _year_end_touch() -> void:
	# Mild recovery at year end
	stamina = _clamp_stat(stamina + 2)
	mood = _clamp_stat(mood + 3)


func finish_game() -> String:
	is_game_over = true
	final_ending = Endings.evaluate(self)
	game_ended.emit(final_ending)
	state_changed.emit()
	return "ending"


## Headless / smoke: play full 144 months with given picker Callable(month_index)->id
func run_full_auto(picker: Callable) -> Dictionary:
	begin_new_game()
	while not is_game_over and year <= GameConfig.TOTAL_YEARS:
		for m in range(GameConfig.MONTHS_PER_SEASON):
			var global_i := months_played
			var id: String = picker.call(global_i, self)
			if not Activities.is_available(id, self):
				id = "rest_sleep"
			season_schedule[m] = id
		resolve_season()
		var next := advance_after_season()
		if next == "year_review":
			var after := continue_after_year_review()
			if after == "ending":
				break
			continue
		if next == "ending":
			break
	if not is_game_over:
		finish_game()
	return final_ending


## —— Save / Load (slot JSON under user://) ——

func to_dict() -> Dictionary:
	var sched: Array = []
	for s in season_schedule:
		sched.append(str(s))
	var names: Array = []
	for n in last_activity_names:
		names.append(str(n))
	return {
		"version": 1,
		"year": year,
		"season": season,
		"month_in_season": month_in_season,
		"charm": charm,
		"morals": morals,
		"social": social,
		"stamina": stamina,
		"academia": academia,
		"mood": mood,
		"cash": cash,
		"season_schedule": sched,
		"flags": flags.duplicate(true),
		"months_played": months_played,
		"is_game_over": is_game_over,
		"final_ending": final_ending.duplicate(true) if typeof(final_ending) == TYPE_DICTIONARY else {},
		"last_deltas": last_deltas.duplicate(true) if typeof(last_deltas) == TYPE_DICTIONARY else {},
		"last_activity_names": names,
		"last_season_event": last_season_event.duplicate(true) if typeof(last_season_event) == TYPE_DICTIONARY else {},
		"last_vignettes": _dict_array_dup(last_vignettes),
		"last_roaming_event": last_roaming_event.duplicate(true) if typeof(last_roaming_event) == TYPE_DICTIONARY else {},
		"year_start_stats": year_start_stats.duplicate(true) if typeof(year_start_stats) == TYPE_DICTIONARY else {},
		"year_activity_names": year_activity_names.duplicate(),
		"year_event_titles": year_event_titles.duplicate(),
		"last_year_review": last_year_review.duplicate(true) if typeof(last_year_review) == TYPE_DICTIONARY else {},
		"pending_ending_after_review": pending_ending_after_review,
		"npc_affinity": npc_affinity.duplicate(),
		"album": _dict_array_dup(album),
		"save_name": save_name,
		"daughter_name": daughter_display_name(),
		"skill_xp": skill_xp.duplicate(),
		"interest_points": interest_points.duplicate(),
		"education_path": education_path,
	}


func from_dict(d: Dictionary) -> void:
	year = int(d.get("year", 1))
	season = int(d.get("season", 0))
	month_in_season = int(d.get("month_in_season", 0))
	charm = int(d.get("charm", GameConfig.STARTING_STATS.get("charm", 35)))
	morals = int(d.get("morals", GameConfig.STARTING_STATS.get("morals", 40)))
	social = int(d.get("social", GameConfig.STARTING_STATS.get("social", 35)))
	stamina = int(d.get("stamina", GameConfig.STARTING_STATS.get("stamina", 50)))
	academia = int(d.get("academia", GameConfig.STARTING_STATS.get("academia", 30)))
	mood = int(d.get("mood", GameConfig.STARTING_STATS.get("mood", 60)))
	cash = int(d.get("cash", GameConfig.STARTING_CASH))
	season_schedule = ["", "", ""]
	var sched = d.get("season_schedule", ["", "", ""])
	if typeof(sched) == TYPE_ARRAY:
		for i in range(mini(3, sched.size())):
			season_schedule[i] = str(sched[i])
	flags = {}
	var fl = d.get("flags", {})
	if typeof(fl) == TYPE_DICTIONARY:
		flags = fl.duplicate(true)
	months_played = int(d.get("months_played", 0))
	is_game_over = bool(d.get("is_game_over", false))
	var fe = d.get("final_ending", {})
	final_ending = fe.duplicate(true) if typeof(fe) == TYPE_DICTIONARY else {}
	var ld = d.get("last_deltas", {})
	last_deltas = ld.duplicate(true) if typeof(ld) == TYPE_DICTIONARY else {}
	last_activity_names = []
	var names = d.get("last_activity_names", [])
	if typeof(names) == TYPE_ARRAY:
		for n in names:
			last_activity_names.append(str(n))
	var lse = d.get("last_season_event", {})
	last_season_event = lse.duplicate(true) if typeof(lse) == TYPE_DICTIONARY else {}
	last_vignettes = _parse_dict_array(d.get("last_vignettes", []))
	var lre = d.get("last_roaming_event", {})
	last_roaming_event = lre.duplicate(true) if typeof(lre) == TYPE_DICTIONARY else {}
	var yss = d.get("year_start_stats", {})
	year_start_stats = yss.duplicate(true) if typeof(yss) == TYPE_DICTIONARY else {}
	year_activity_names = []
	var yan = d.get("year_activity_names", [])
	if typeof(yan) == TYPE_ARRAY:
		for n2 in yan:
			year_activity_names.append(str(n2))
	year_event_titles = []
	var yet = d.get("year_event_titles", [])
	if typeof(yet) == TYPE_ARRAY:
		for t2 in yet:
			year_event_titles.append(str(t2))
	var lyr = d.get("last_year_review", {})
	last_year_review = lyr.duplicate(true) if typeof(lyr) == TYPE_DICTIONARY else {}
	pending_ending_after_review = bool(d.get("pending_ending_after_review", false))
	_load_npc_affinity(d.get("npc_affinity", null))
	album = _parse_dict_array(d.get("album", []))
	album_browse = []
	album_return_scene = ""
	save_name = str(d.get("save_name", ""))
	var loaded_name := str(d.get("daughter_name", "")).strip_edges()
	if daughter_name_error(loaded_name) == "":
		daughter_name = loaded_name
	else:
		daughter_name = DEFAULT_DAUGHTER_NAME
	wants_new_game_name = false
	skill_xp = _int_map(d.get("skill_xp", {}), true)
	interest_points = _int_map(d.get("interest_points", {}), false)
	var edu := str(d.get("education_path", "")).strip_edges()
	education_path = edu if edu != "" else "undecided"
	state_changed.emit()


func append_album_entry(entry: Dictionary) -> void:
	var eid := str(entry.get("id", ""))
	if eid == "":
		return
	for existing in album:
		if typeof(existing) == TYPE_DICTIONARY and str(existing.get("id", "")) == eid:
			return
	album.append({
		"id": eid,
		"year": int(entry.get("year", year)),
		"season": int(entry.get("season", season)),
		"title": str(entry.get("title", "")),
		"thumb_path": str(entry.get("thumb_path", "")),
		"body": str(entry.get("body", "")),
	})


func record_season_memories() -> void:
	## Beach / mountain stills, plus notable activity vignettes from this season.
	var ev := last_season_event
	if str(ev.get("media_still", "")) != "":
		append_album_entry({
			"id": "evt_%s_y%d" % [str(ev.get("id", "event")), year],
			"year": year,
			"season": season,
			"title": str(ev.get("title", "")),
			"thumb_path": GameConfig.event_still_path(str(ev.get("media_still", ""))),
			"body": str(ev.get("body", "")),
		})
	for item in last_vignettes:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var v: Dictionary = item
		if not bool(v.get("notable", false)):
			continue
		var thumb := ""
		var still_id := str(v.get("still", ""))
		if still_id != "":
			thumb = GameConfig.event_still_path(still_id)
		if thumb == "":
			thumb = SeasonEvents.sticker_path(str(v.get("sticker", "")))
		append_album_entry({
			"id": "vig_%s_y%d_s%d_m%d" % [
				str(v.get("activity_id", "act")), year, season, int(v.get("month_index", 0))
			],
			"year": year,
			"season": season,
			"title": str(v.get("title", "")),
			"thumb_path": thumb,
			"body": str(v.get("body", "")),
		})


func map_event_flag(place_id: String) -> String:
	return "map_evt_%d_%d_%s" % [year, season, place_id]


func map_place_event_ready(place_id: String) -> bool:
	return not bool(flags.get(map_event_flag(place_id), false))


## Click or season-roam. count_visit records the pin; allow_once keeps unique stories for clicks.
func trigger_place_event(place_id: String, rng: RandomNumberGenerator, count_visit: bool, allow_once: bool = true) -> Dictionary:
	if count_visit:
		var visit_key := "visited_%s" % place_id
		flags[visit_key] = int(flags.get(visit_key, 0)) + 1
	if not map_place_event_ready(place_id):
		state_changed.emit()
		return {
			"skipped": true,
			"place": place_id,
			"title": "安靜的一角",
			"body": "這季你們已經在這裡遇過一件小事了。風還在，人聲淡了些，先把風景看進眼裡就好。",
			"deltas": {},
		}
	var ev: Dictionary = {}
	if allow_once:
		ev = MapEvents.pick_event(place_id, flags, rng)
	else:
		ev = MapEvents.pick_flavor_event(place_id, rng)
	if ev.is_empty():
		state_changed.emit()
		return {
			"skipped": true,
			"place": place_id,
			"title": "安靜的一角",
			"body": "這裡今天很安靜。你們站了一會兒，然後繼續往前走。",
			"deltas": {},
		}
	flags[map_event_flag(place_id)] = true
	if bool(ev.get("once", false)):
		var fk := str(ev.get("flag", ev.get("id", "")))
		if fk != "":
			flags[fk] = true
	var deltas: Dictionary = {}
	var raw_d = ev.get("deltas", {})
	if typeof(raw_d) == TYPE_DICTIONARY:
		deltas = raw_d
	if not deltas.is_empty():
		apply_map_event_delta(deltas)
	var aff = ev.get("affinity", {})
	if typeof(aff) == TYPE_DICTIONARY and not (aff as Dictionary).is_empty():
		apply_affinity_map(aff, false)
	var title := str(ev.get("title", ""))
	if title != "":
		note_year_event(title)
	ev["skipped"] = false
	ev["place"] = place_id
	state_changed.emit()
	return ev


func _roll_roaming_map_event() -> void:
	## About one in three seasons, a place that has not fired yet offers a small beat.
	last_roaming_event = {}
	if _event_rng.randf() >= 0.34:
		return
	var open: Array[String] = []
	for pid in MapEvents.PLACE_IDS:
		if map_place_event_ready(pid):
			open.append(pid)
	if open.is_empty():
		return
	var place_id: String = open[_event_rng.randi_range(0, open.size() - 1)]
	var ev := trigger_place_event(place_id, _event_rng, false, false)
	if bool(ev.get("skipped", true)):
		return
	ev["place_name"] = str(Activities.PLACE_NAMES.get(place_id, place_id))
	last_roaming_event = ev


func reset_npc_affinity() -> void:
	npc_affinity = TownNpcs.starting_affinity()


func apply_affinity_map(bump: Dictionary, emit_now: bool = true) -> void:
	if bump.is_empty():
		return
	if npc_affinity.is_empty():
		reset_npc_affinity()
	for k in bump.keys():
		var id := str(k)
		if not TownNpcs.has_id(id):
			continue
		var cur := int(npc_affinity.get(id, 0))
		npc_affinity[id] = clampi(cur + int(bump[k]), 0, 100)
	if emit_now:
		state_changed.emit()


func _load_npc_affinity(raw) -> void:
	if typeof(raw) != TYPE_DICTIONARY:
		reset_npc_affinity()
		return
	npc_affinity = {}
	for d in TownNpcs.defs():
		var id := str(d.get("id", ""))
		npc_affinity[id] = clampi(int(raw.get(id, d.get("start", 0))), 0, 100)


func _dict_array_dup(src: Array) -> Array:
	var out: Array = []
	for item in src:
		if typeof(item) == TYPE_DICTIONARY:
			out.append((item as Dictionary).duplicate(true))
		else:
			out.append(item)
	return out


func _int_map(raw, skills_map: bool) -> Dictionary:
	var out := {}
	if typeof(raw) != TYPE_DICTIONARY:
		return out
	for key in raw:
		var id := str(key)
		var known := GrowthPath.is_skill(id) if skills_map else GrowthPath.is_tag(id)
		if not known:
			continue
		out[id] = maxi(0, int(raw[key]))
	return out


func _parse_dict_array(raw) -> Array:
	var out: Array = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for item in raw:
		if typeof(item) == TYPE_DICTIONARY:
			out.append((item as Dictionary).duplicate(true))
	return out


func _save_path(slot: int) -> String:
	return "user://save_slot_%d.json" % slot


func has_save(slot: int = 0) -> bool:
	return FileAccess.file_exists(_save_path(slot))


func slot_title(slot: int) -> String:
	return SLOT_TITLES[clampi(slot, 0, SLOT_TITLES.size() - 1)]


func peek_save(slot: int) -> Dictionary:
	var path := _save_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data


func save_slot_preview(slot: int) -> Dictionary:
	var data := peek_save(slot)
	if data.is_empty():
		return {
			"exists": false,
			"slot": slot,
			"title": slot_title(slot),
			"detail": "尚未寫下",
			"year": 0,
			"season": 0,
			"album_count": 0,
		}
	var y := int(data.get("year", 1))
	var s := int(data.get("season", 0))
	var name := str(data.get("save_name", ""))
	if name == "":
		name = slot_title(slot)
	var dname := str(data.get("daughter_name", "")).strip_edges()
	if daughter_name_error(dname) != "":
		dname = DEFAULT_DAUGHTER_NAME
	var album_raw = data.get("album", [])
	var album_n := 0
	if typeof(album_raw) == TYPE_ARRAY:
		album_n = album_raw.size()
	return {
		"exists": true,
		"slot": slot,
		"title": name,
		"detail": "第 %d 年 · %s · %s · %d 歲" % [y, GameConfig.season_name(s), dname, GameConfig.age_for_year(y)],
		"year": y,
		"season": s,
		"album_count": album_n,
	}


func browse_album_from_slot(slot: int) -> bool:
	var data := peek_save(slot)
	if data.is_empty():
		return false
	album_browse = _parse_dict_array(data.get("album", []))
	album_return_scene = "res://scenes/title.tscn"
	return not album_browse.is_empty()


func save_game(slot: int = 0) -> bool:
	save_name = slot_title(slot)
	var path := _save_path(slot)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("save_game: cannot open %s" % path)
		return false
	var json := JSON.stringify(to_dict(), "\t")
	f.store_string(json)
	f.close()
	return true


func load_game(slot: int = 0) -> bool:
	var path := _save_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("load_game: cannot open %s" % path)
		return false
	var text := f.get_as_text()
	f.close()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("load_game: invalid JSON in %s" % path)
		return false
	from_dict(data)
	return true


func delete_save(slot: int = 0) -> void:
	var path := _save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
