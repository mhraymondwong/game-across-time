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
var _event_rng: RandomNumberGenerator = RandomNumberGenerator.new()

var flags: Dictionary = {}
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


func begin_new_game() -> void:
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
	_event_rng.randomize()
	flags.clear()
	months_played = 0
	is_game_over = false
	final_ending = {}
	year_start_stats = {}
	year_activity_names = []
	year_event_titles = []
	last_year_review = {}
	pending_ending_after_review = false
	snapshot_year_start()
	state_changed.emit()


func get_age() -> int:
	return GameConfig.age_for_year(year)


func get_season_name() -> String:
	return GameConfig.season_name(season)


func get_time_label() -> String:
	var stage := GameConfig.growth_stage_for_year(year)
	return "第 %d 年 · %s · %d 歲（%s）" % [
		year, get_season_name(), get_age(), GameConfig.growth_stage_label(stage)
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
	var month_logs: Array = []
	for i in range(GameConfig.MONTHS_PER_SEASON):
		var id: String = season_schedule[i] if i < season_schedule.size() else ""
		if id == "" or not Activities.is_available(id, self):
			id = "rest_sleep"
		var d := apply_activity(id)
		last_activity_names.append(str(d.get("name", id)))
		month_logs.append(d)

	# Seasonal weather / festival event (~55% chance of themed event, else light beat)
	var ev: Dictionary = SeasonEvents.roll_event(season, _event_rng, 0.55)
	last_season_event = ev
	SeasonEvents.apply_deltas_to_state(self, ev.get("deltas", {}))
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
	last_deltas = totals
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
		"year_start_stats": year_start_stats.duplicate(true) if typeof(year_start_stats) == TYPE_DICTIONARY else {},
		"year_activity_names": year_activity_names.duplicate(),
		"year_event_titles": year_event_titles.duplicate(),
		"last_year_review": last_year_review.duplicate(true) if typeof(last_year_review) == TYPE_DICTIONARY else {},
		"pending_ending_after_review": pending_ending_after_review,
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
	state_changed.emit()


func _save_path(slot: int) -> String:
	return "user://save_slot_%d.json" % slot


func has_save(slot: int = 0) -> bool:
	return FileAccess.file_exists(_save_path(slot))


func save_game(slot: int = 0) -> bool:
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
