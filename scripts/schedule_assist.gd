class_name ScheduleAssist
extends RefCounted
## 排程捷徑：重複上季、季預設、三個月同選、體力見底時的休息月。
## 只寫 season_schedule。不改平日工作，也不改五條屬性。


const LOW_STAMINA := 22
const REST_ID := "rest_sleep"

const PRESET_ORDER: PackedStringArray = ["home", "study", "rest"]

const PRESET_CHILD := {
	"home": ["virtue_chores", "family_bento", "shops_market", "virtue_elder", "virtue_recycle", "social_neighbor"],
	"study": ["study_library", "taste_language", "taste_piano", "taste_code", "study_language", "study_code", "study_piano", "culture_reading", "school_debate", "study_tutoring"],
	"rest": ["rest_sleep", "rest_park", "health_clinic", "school_garden", "virtue_chores"],
}

const PRESET_ADULT := {
	"home": ["work_side", "work_overtime", "work_colleagues", "family_talk", "date_letter"],
	"study": ["study_night", "study_license", "study_portfolio"],
	"rest": ["rest_park", "rest_sleep", "date_walk", "date_letter", "work_colleagues"],
}


static func preset_label(key: String) -> String:
	match key:
		"home":
			return "穩健家計"
		"study":
			return "衝學識"
		"rest":
			return "平衡恢復"
		_:
			return key


static func repeat_label(state) -> String:
	if Adulthood.is_adult(state):
		return "套用上季課餘安排"
	return "套用上季排程"


static func force_rest_on(state) -> bool:
	return not bool(state.flags.get("force_rest_off", false))


static func toggle_force_rest(state) -> void:
	state.flags["force_rest_off"] = force_rest_on(state)
	if state.has_signal("state_changed"):
		state.state_changed.emit()


static func recovery_line(state) -> String:
	if int(state.stamina) > LOW_STAMINA:
		return ""
	var line := "本季建議：家務／休息類（預估體力＋）。"
	if int(state.stamina) <= 0 and force_rest_on(state):
		line += "體力見底，已先排好在家休息。可改單月，或關掉強制休息月。"
	elif GrowthPath.unlocked(state) and GrowthPath.learned_count(state) == 1:
		line += "想再多一項專長，陪伴長輩幾乎不花錢。"
	return line


static func assign(state, ids: Array) -> int:
	var n := 0
	for i in range(GameConfig.MONTHS_PER_SEASON):
		var id := ""
		if i < ids.size():
			id = str(ids[i])
		if id == "":
			continue
		if not Activities.shown_in_picker(id, state) or not Activities.is_available(id, state):
			continue
		state.season_schedule[i] = id
		n += 1
	if n > 0 and state.has_signal("state_changed"):
		state.state_changed.emit()
	return n


static func apply_previous(state) -> int:
	var src: Array = state.previous_schedule
	return assign(state, src)


static func preset_ids(state, key: String) -> Array:
	var table: Dictionary = PRESET_ADULT if Adulthood.is_adult(state) else PRESET_CHILD
	var cands: Array = table.get(key, [])
	var picked: Array = []
	for id in cands:
		var sid := str(id)
		if picked.has(sid):
			continue
		if Activities.shown_in_picker(sid, state) and Activities.is_available(sid, state):
			picked.append(sid)
		if picked.size() >= GameConfig.MONTHS_PER_SEASON:
			break
	if picked.is_empty():
		return [REST_ID, REST_ID, REST_ID]
	while picked.size() < GameConfig.MONTHS_PER_SEASON:
		picked.append(picked[picked.size() - 1])
	return picked


static func apply_preset(state, key: String) -> int:
	return assign(state, preset_ids(state, key))


static func repeat_activity(state, activity_id: String) -> int:
	if not Activities.is_available(activity_id, state):
		return 0
	return assign(state, [activity_id, activity_id, activity_id])


## 體力為 0、三格都空、而且沒有關掉時，一次填滿休息，不必開三次清單。
static func maybe_force_rest(state) -> bool:
	if not force_rest_on(state) or int(state.stamina) > 0:
		return false
	for id in state.season_schedule:
		if str(id) != "":
			return false
	return assign(state, [REST_ID, REST_ID, REST_ID]) > 0
