class_name GrowthPath
extends RefCounted
## 國中（第 7 年）起的專長與興趣。
## 五條屬性不動。升學分叉先留 education_path，這一輪不做選擇畫面。
## 結局仍先看原本的門檻；通過的路線裡，優先度相差 8 以內才用下面的加分重排，加分最多 6。

const MIDDLE_SCHOOL_YEAR := 7
const MAX_LEVEL := 3
## xp needed to reach level 1, 2, 3
const LEVEL_XP: Array[int] = [0, 1, 3, 6]
const LEVEL_NAMES: PackedStringArray = ["未學", "入門", "上手", "擅長"]
const BIAS_WINDOW := 8
const MAX_BONUS := 6

const SKILLS: Array = [
	{"id": "piano", "name": "鋼琴"},
	{"id": "language", "name": "外語"},
	{"id": "code", "name": "程式"},
	{"id": "paint", "name": "繪畫"},
	{"id": "ball", "name": "球類"},
	{"id": "cook", "name": "烹飪"},
	{"id": "speech", "name": "演講"},
]

const TAGS: Array = [
	{"id": "art", "name": "藝術"},
	{"id": "stem", "name": "理工"},
	{"id": "service", "name": "服務"},
	{"id": "letters", "name": "文教"},
	{"id": "sport", "name": "運動"},
	{"id": "business", "name": "商業"},
]

## Dedicated classes grant 2 skill XP. Related months grant 1.
const ACTIVITY_GAINS: Dictionary = {
	"study_piano": {"skills": {"piano": 2}, "tags": {"art": 2}},
	"study_language": {"skills": {"language": 2}, "tags": {"letters": 2}},
	"study_code": {"skills": {"code": 2}, "tags": {"stem": 2}},
	"study_arts": {"skills": {"paint": 1, "piano": 1}, "tags": {"art": 2}},
	"talent_showcase": {"skills": {"paint": 1, "piano": 1, "speech": 1}, "tags": {"art": 2}},
	"style_perform": {"skills": {"speech": 1}, "tags": {"art": 1}},
	"style_fashion": {"skills": {}, "tags": {"art": 1, "business": 1}},
	"study_library": {"skills": {"language": 1}, "tags": {"letters": 1}},
	"culture_reading": {"skills": {"language": 1}, "tags": {"letters": 2}},
	"study_tutoring": {"skills": {}, "tags": {"stem": 1, "letters": 1}},
	"school_debate": {"skills": {"speech": 2}, "tags": {"letters": 2}},
	"work_tutor": {"skills": {"speech": 1}, "tags": {"letters": 2, "service": 1}},
	"school_library_helper": {"skills": {}, "tags": {"letters": 1, "service": 1}},
	"park_run": {"skills": {"ball": 1}, "tags": {"sport": 2}},
	"social_club": {"skills": {"ball": 1}, "tags": {"sport": 1}},
	"family_bento": {"skills": {"cook": 1}, "tags": {"service": 1}},
	"virtue_chores": {"skills": {"cook": 1}, "tags": {"service": 1}},
	"shops_market": {"skills": {"cook": 1}, "tags": {"business": 2}},
	"work_cafe": {"skills": {"cook": 1}, "tags": {"business": 2}},
	"work_store": {"skills": {}, "tags": {"business": 2}},
	"virtue_volunteer": {"skills": {}, "tags": {"service": 2}},
	"virtue_elder": {"skills": {}, "tags": {"service": 2, "letters": 1}},
	"virtue_recycle": {"skills": {}, "tags": {"service": 1}},
	"clinic_helper": {"skills": {}, "tags": {"service": 2, "stem": 1}},
	"health_clinic": {"skills": {}, "tags": {"service": 1, "stem": 1}},
	"festival_helper": {"skills": {}, "tags": {"service": 1, "art": 1}},
	"school_class_helper": {"skills": {}, "tags": {"service": 1, "letters": 1}},
}

## Tag match: first place +3, second place +1. Best listed skill: lv1 +1, lv2 +2, lv3 +3. Cap 6.
const ENDING_BIAS: Dictionary = {
	"doctor": {"tags": ["stem", "service"], "skills": []},
	"teacher": {"tags": ["letters", "service"], "skills": ["speech"]},
	"designer": {"tags": ["art"], "skills": ["paint", "piano"]},
	"cafe_owner": {"tags": ["business"], "skills": ["cook"]},
	"civil": {"tags": ["service", "letters"], "skills": ["speech"]},
	"coach": {"tags": ["sport"], "skills": ["ball"]},
	"writer": {"tags": ["letters", "art"], "skills": ["language"]},
	"caregiver": {"tags": ["service"], "skills": ["cook"]},
	"wanderer": {"tags": ["art", "sport"], "skills": ["language"]},
}


static func unlocked(state) -> bool:
	return int(state.year) >= MIDDLE_SCHOOL_YEAR


static func is_skill(id: String) -> bool:
	for row in SKILLS:
		if str(row.get("id", "")) == id:
			return true
	return false


static func is_tag(id: String) -> bool:
	for row in TAGS:
		if str(row.get("id", "")) == id:
			return true
	return false


static func skill_name(id: String) -> String:
	for row in SKILLS:
		if str(row.get("id", "")) == id:
			return str(row.get("name", id))
	return id


static func tag_name(id: String) -> String:
	for row in TAGS:
		if str(row.get("id", "")) == id:
			return str(row.get("name", id))
	return id


static func level_for_xp(xp: int) -> int:
	var level := 0
	for i in range(1, LEVEL_XP.size()):
		if xp >= LEVEL_XP[i]:
			level = i
	return mini(level, MAX_LEVEL)


static func level_name(level: int) -> String:
	var i := clampi(level, 0, LEVEL_NAMES.size() - 1)
	return LEVEL_NAMES[i]


static func xp_of(state, skill_id: String) -> int:
	return int(state.skill_xp.get(skill_id, 0))


static func level_of(state, skill_id: String) -> int:
	return level_for_xp(xp_of(state, skill_id))


static func points_of(state, tag_id: String) -> int:
	return int(state.interest_points.get(tag_id, 0))


static func ranked_tags(state) -> Array:
	var rows: Array = []
	var index := 0
	for row in TAGS:
		rows.append({
			"id": str(row.get("id", "")),
			"name": str(row.get("name", "")),
			"points": points_of(state, str(row.get("id", ""))),
			"index": index,
		})
		index += 1
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("points", 0)) == int(b.get("points", 0)):
			return int(a.get("index", 0)) < int(b.get("index", 0))
		return int(a.get("points", 0)) > int(b.get("points", 0))
	)
	return rows


static func grant(state, activity_id: String) -> void:
	if not unlocked(state):
		return
	var spec: Dictionary = ACTIVITY_GAINS.get(activity_id, {})
	if spec.is_empty():
		return
	var skills: Dictionary = spec.get("skills", {})
	for sid in skills:
		var key := str(sid)
		if not is_skill(key):
			continue
		state.skill_xp[key] = int(state.skill_xp.get(key, 0)) + int(skills[sid])
	var tags: Dictionary = spec.get("tags", {})
	for tid in tags:
		var tkey := str(tid)
		if not is_tag(tkey):
			continue
		state.interest_points[tkey] = int(state.interest_points.get(tkey, 0)) + int(tags[tid])


static func ending_bonus(ending_id: String, state) -> int:
	var spec: Dictionary = ENDING_BIAS.get(ending_id, {})
	if spec.is_empty():
		return 0
	var wanted_tags: Array = spec.get("tags", [])
	var wanted_skills: Array = spec.get("skills", [])
	var ranked := ranked_tags(state)
	var bonus := 0
	if ranked.size() > 0 and int(ranked[0].get("points", 0)) > 0 and str(ranked[0].get("id", "")) in wanted_tags:
		bonus += 3
	if ranked.size() > 1 and int(ranked[1].get("points", 0)) > 0 and str(ranked[1].get("id", "")) in wanted_tags:
		bonus += 1
	var best_level := 0
	for sid in wanted_skills:
		best_level = maxi(best_level, level_of(state, str(sid)))
	if best_level >= 3:
		bonus += 3
	elif best_level == 2:
		bonus += 2
	elif best_level == 1:
		bonus += 1
	return mini(bonus, MAX_BONUS)


static func drawer_line(state) -> String:
	if not unlocked(state):
		return ""
	var best_id := ""
	var best_level := 0
	var best_xp := 0
	for row in SKILLS:
		var sid := str(row.get("id", ""))
		var lv := level_of(state, sid)
		var xp := xp_of(state, sid)
		if lv > best_level or (lv == best_level and xp > best_xp):
			best_level = lv
			best_xp = xp
			best_id = sid
	var ranked := ranked_tags(state)
	var tag_bit := ""
	if ranked.size() > 0 and int(ranked[0].get("points", 0)) > 0:
		tag_bit = "%s %d" % [str(ranked[0].get("name", "")), int(ranked[0].get("points", 0))]
	if best_level <= 0 and tag_bit == "":
		return "專長頁還是空白的。排一個相關的月份，就會寫上。"
	if best_level <= 0:
		return "興趣　%s" % tag_bit
	var skill_bit := "%s　%s" % [skill_name(best_id), level_name(best_level)]
	if tag_bit == "":
		return "專長　%s" % skill_bit
	return "專長　%s　·　%s" % [skill_bit, tag_bit]


static func skill_lines(state) -> PackedStringArray:
	var lines: PackedStringArray = []
	for row in SKILLS:
		var sid := str(row.get("id", ""))
		lines.append("%s　　%s" % [str(row.get("name", "")), level_name(level_of(state, sid))])
	return lines


static func tag_line(state) -> String:
	var parts: PackedStringArray = []
	for row in ranked_tags(state):
		parts.append("%s %d" % [str(row.get("name", "")), int(row.get("points", 0))])
	return "　".join(parts)


static func brightest_tag_line(state) -> String:
	var ranked := ranked_tags(state)
	if ranked.is_empty() or int(ranked[0].get("points", 0)) <= 0:
		return "興趣還沒累起來。"
	return "現在最亮的是%s。" % str(ranked[0].get("name", ""))
