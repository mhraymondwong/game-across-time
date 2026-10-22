class_name TownNpcs
extends RefCounted
## 小鎮人物與好感。活動／地圖／季節事件可依 id 加減，數值維持 0–100。

const DEFS := [
	{
		"id": "lin_xiaoqing",
		"name": "林小晴",
		"role": "同班同學",
		"place": "school",
		"place_name": "學校",
		"bio": "坐在斜後方的女生。下課會分半顆糖，說話輕，笑起來卻很快。",
		"start": 18,
	},
	{
		"id": "chan_auntie",
		"name": "陳阿姨",
		"role": "鄰里長輩",
		"place": "home",
		"place_name": "住家巷口",
		"bio": "巷口總在曬菜乾。記得每個孩子的小名，口袋裡有話梅。",
		"start": 22,
	},
	{
		"id": "wong_doctor",
		"name": "王醫師",
		"role": "社區診所",
		"place": "clinic",
		"place_name": "診所",
		"bio": "社區診所的老醫師。聽診器冰涼，叮嚀卻很暖，認識鎮上每一個孩子。",
		"start": 16,
	},
]

const ACTIVITY_AFFINITY := {
	"social_friends": {"lin_xiaoqing": 5},
	"social_club": {"lin_xiaoqing": 3},
	"school_debate": {"lin_xiaoqing": 3},
	"school_library_helper": {"lin_xiaoqing": 2},
	"school_garden": {"lin_xiaoqing": 1},
	"school_class_helper": {"lin_xiaoqing": 2},
	"festival_helper": {"lin_xiaoqing": 2, "chan_auntie": 2},
	"study_library": {"lin_xiaoqing": 1},
	"culture_reading": {"lin_xiaoqing": 2},
	"talent_showcase": {"lin_xiaoqing": 2},
	"style_perform": {"lin_xiaoqing": 1},
	"social_neighbor": {"chan_auntie": 6},
	"virtue_elder": {"chan_auntie": 5},
	"virtue_volunteer": {"chan_auntie": 3},
	"virtue_recycle": {"chan_auntie": 3},
	"virtue_chores": {"chan_auntie": 2},
	"family_bento": {"chan_auntie": 2},
	"shops_market": {"chan_auntie": 2},
	"park_run": {"chan_auntie": 2},
	"rest_park": {"chan_auntie": 1},
	"health_clinic": {"wong_doctor": 4},
	"clinic_helper": {"wong_doctor": 6},
}

const SEASON_EVENT_AFFINITY := {
	"winter_gathering": {"lin_xiaoqing": 4},
	"spring_picnic": {"lin_xiaoqing": 2},
	"summer_festival": {"lin_xiaoqing": 2},
	"summer_beach": {"lin_xiaoqing": 3},
	"spring_sakura": {"lin_xiaoqing": 1},
	"autumn_mountain": {"chan_auntie": 2, "lin_xiaoqing": 1},
	"autumn_harvest": {"chan_auntie": 2},
	"winter_newyear": {"chan_auntie": 3},
	"spring_qingming": {"chan_auntie": 2},
	"winter_cold": {"wong_doctor": 1},
	"summer_heat": {"wong_doctor": 1},
}


static func defs() -> Array:
	return DEFS


static func has_id(npc_id: String) -> bool:
	return not get_def(npc_id).is_empty()


static func get_def(npc_id: String) -> Dictionary:
	for d in DEFS:
		if str(d.get("id", "")) == npc_id:
			return d
	return {}


static func starting_affinity() -> Dictionary:
	var out := {}
	for d in DEFS:
		out[str(d.get("id", ""))] = int(d.get("start", 0))
	return out


static func affinity_for_activity(activity_id: String) -> Dictionary:
	if not ACTIVITY_AFFINITY.has(activity_id):
		return {}
	return (ACTIVITY_AFFINITY[activity_id] as Dictionary).duplicate()


static func affinity_for_season_event(event_id: String) -> Dictionary:
	if not SEASON_EVENT_AFFINITY.has(event_id):
		return {}
	return (SEASON_EVENT_AFFINITY[event_id] as Dictionary).duplicate()


static func value_of(state: Node, npc_id: String) -> int:
	var aff: Dictionary = {}
	if "npc_affinity" in state and typeof(state.npc_affinity) == TYPE_DICTIONARY:
		aff = state.npc_affinity
	if aff.has(npc_id):
		return clampi(int(aff[npc_id]), 0, 100)
	return int(get_def(npc_id).get("start", 0))


static func highest(state: Node) -> Dictionary:
	var best_id := ""
	var best_v := -1
	for d in DEFS:
		var id := str(d.get("id", ""))
		var v := value_of(state, id)
		if v > best_v:
			best_v = v
			best_id = id
	var def := get_def(best_id)
	return {
		"id": best_id,
		"name": str(def.get("name", "")),
		"role": str(def.get("role", "")),
		"place_name": str(def.get("place_name", "")),
		"value": best_v,
	}


static func heart_row(value: int) -> String:
	var filled := clampi(int(round(float(value) / 20.0)), 0, 5)
	var s := ""
	for _i in range(filled):
		s += "♡"
	for _j in range(5 - filled):
		s += "・"
	return s


static func format_bump_line(bump: Dictionary) -> String:
	if bump.is_empty():
		return ""
	var parts: PackedStringArray = []
	for id in bump.keys():
		var def := get_def(str(id))
		var v := int(bump[id])
		if v == 0 or def.is_empty():
			continue
		var sign := "＋" if v > 0 else "－"
		parts.append("%s好感%s%d" % [str(def.get("name", id)), sign, abs(v)])
	if parts.is_empty():
		return ""
	return "（" + "　".join(parts) + "）"


static func season_note(state: Node) -> String:
	var top := highest(state)
	var v := int(top.get("value", 0))
	if v < 28:
		return ""
	return "她和%s（%s）的好感是 %d。小鎮的人，是這樣一點點親近起來的。" % [
		str(top.get("name", "")), str(top.get("role", "")), v
	]


static func year_highlight(state: Node) -> String:
	var top := highest(state)
	var v := int(top.get("value", 0))
	if v < 40:
		return ""
	return "人際・和%s更親近了（好感 %d）" % [str(top.get("name", "")), v]


static func hub_line(state: Node) -> String:
	var top := highest(state)
	if str(top.get("name", "")) == "":
		return ""
	return "親近　%s　%d" % [str(top.get("name", "")), int(top.get("value", 0))]


static func ending_summary(state: Node) -> String:
	var top := highest(state)
	var name := str(top.get("name", "街坊"))
	match str(top.get("id", "")):
		"lin_xiaoqing":
			return "她和林小晴約好，季節交替時還要一起走商店街。沒有響亮的頭銜，但有人在校門口等她——你看在眼裡，覺得這也是一種抵達。"
		"chan_auntie":
			return "陳阿姨還是在巷口曬菜乾。她長大後會順路幫忙提袋，被叫一聲小名就笑。你知道這條巷子會一直認得她。"
		"wong_doctor":
			return "王醫師的候診椅還在老位置。她未必穿上白袍，卻記得怎麼把溫水遞給人。診所的燈亮著，小鎮就有人照應。"
		_:
			return "她被%s記得。十八年沒有轟轟烈烈，名字卻在小鎮裡有了回音。" % name


static func ending_aside(state: Node) -> String:
	var top := highest(state)
	if int(top.get("value", 0)) < 55:
		return ""
	return "這些年，她最親近的是%s。" % str(top.get("name", ""))
