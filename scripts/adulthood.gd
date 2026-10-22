class_name Adulthood
extends RefCounted
## 第 13–18 年（約 18–23 歲）。鎖：adult_plus6_end_y18、排程 A+B、戀愛 C+D。
## 平日工作是背景，每月日記仍只排 1 格（戀愛／進修／成家／工作小事）。
## 戀愛是抽象「戀愛進度」，不綁特定戀愛 NPC。成家是可選支線，單身可以走到結局。
## 升學分叉只寫 education_path，並只影響工作名單與結局裡成家那一句。
## 五條屬性、心情、家計、專長經驗與興趣點數都不在這裡改。


const ROMANCE_MAX := 100
## 成家活動解鎖。沒到之前，日記不強迫排。
const FAMILY_ROMANCE_MIN := 40
## 進度夠、而且自己排過兩次成家，才算走上這條支線。
const FAMILY_SETTLE_PREP := 2
const FAMILY_SETTLE_ROMANCE := 50
## 結局加分。只在原本已經達標、而且優先度落在視窗內的路線之間重排。
const CAREER_BONUS := 4
const FALLBACK_JOB := "shop_staff"
const PATH_UNDECIDED := "undecided"
const PATH_UNIVERSITY := "university"
const PATH_HIGH_SCHOOL := "high_school"
const FORK_SCENE := "res://scenes/education_fork.tscn"
const HUB_SCENE := "res://scenes/home_hub.tscn"
const ENDING_SCENE := "res://scenes/ending.tscn"
## 大學：學業附近，以及晚一點才穩的專業。高中就業：店裡、照顧、手邊的班表。
## Order is the tie-break for an empty skill page: study-side entry, then later professional work.
const UNIVERSITY_JOBS: PackedStringArray = [
	"school_aide", "clinic_aide", "desk_writer", "design_studio", "clerk_hall",
]
## Order is the tie-break: a shift starts sooner than the later professional list.
const HIGH_SCHOOL_JOBS: PackedStringArray = [
	"cafe_shift", "shop_staff", "neighbor_care", "gym_coach", "travel_desk",
]
const COPY_UNIVERSITY_TITLE := "大學進路"
const COPY_HIGH_SCHOOL_TITLE := "高中畢業直接就業"

const JOBS: Array = [
	{
		"id": "clinic_aide",
		"name": "診所助理",
		"blurb": "平日在社區診所幫忙掛號、整理病歷。街坊還是叫她的小名。",
		"cash": 2100,
		"effects": {"morals": 1, "stamina": -1},
		"tags": ["stem", "service"],
		"skills": ["speech"],
		"ending": "doctor",
	},
	{
		"id": "school_aide",
		"name": "學校助教",
		"blurb": "放學前幫忙收本子、陪低年級讀書。燈還是那盞溫的。",
		"cash": 2000,
		"effects": {"academia": 1, "social": 1},
		"tags": ["letters", "service"],
		"skills": ["speech"],
		"ending": "teacher",
	},
	{
		"id": "design_studio",
		"name": "設計工作室",
		"blurb": "接小鎮的店招和封面。桌上仍貼著小時候的塗鴉。",
		"cash": 1900,
		"effects": {"charm": 1, "stamina": -1},
		"tags": ["art"],
		"skills": ["paint", "piano"],
		"ending": "designer",
	},
	{
		"id": "cafe_shift",
		"name": "咖啡店正職",
		"blurb": "早上開店、下午收杯。靠窗那位常客，她都認得。",
		"cash": 1800,
		"effects": {"social": 1, "stamina": -1},
		"tags": ["business"],
		"skills": ["cook"],
		"ending": "cafe_owner",
	},
	{
		"id": "clerk_hall",
		"name": "區公所辦事員",
		"blurb": "窗口的話要說清楚。她把街坊的表格一張張對好。",
		"cash": 2300,
		"effects": {"morals": 1},
		"tags": ["service", "letters"],
		"skills": ["speech"],
		"ending": "civil",
	},
	{
		"id": "gym_coach",
		"name": "社區運動指導",
		"blurb": "傍晚的操場有哨音。小孩圍過來時，她會先蹲下來。",
		"cash": 1900,
		"effects": {"stamina": 1, "social": 1},
		"tags": ["sport"],
		"skills": ["ball"],
		"ending": "coach",
	},
	{
		"id": "desk_writer",
		"name": "地方刊物編輯",
		"blurb": "把小鎮的季節寫成短稿。截稿前的燈，和家裡的燈很像。",
		"cash": 1700,
		"effects": {"academia": 1, "charm": 1},
		"tags": ["letters", "art"],
		"skills": ["language"],
		"ending": "writer",
	},
	{
		"id": "neighbor_care",
		"name": "社區照顧",
		"blurb": "送餐、陪診、把長輩的藥盒對好日期。日子不大，卻天天有人等。",
		"cash": 1600,
		"effects": {"morals": 1, "social": 1},
		"tags": ["service"],
		"skills": ["cook"],
		"ending": "caregiver",
	},
	{
		"id": "travel_desk",
		"name": "旅行社櫃檯",
		"blurb": "幫人排車票和季節。自己的地圖也摺在抽屜裡。",
		"cash": 1800,
		"effects": {"charm": 1, "social": 1},
		"tags": ["art", "sport"],
		"skills": ["language"],
		"ending": "wanderer",
	},
	{
		"id": "shop_staff",
		"name": "商店街店員",
		"blurb": "平日站在熟悉的街口。誰家缺醬油，她都知道。",
		"cash": 1500,
		"effects": {"social": 1, "stamina": -1},
		"tags": [],
		"skills": [],
		"ending": "ordinary_happy",
		"always": true,
	},
]


static func is_adult(state) -> bool:
	return GameConfig.is_adult_year(int(state.year))


static func job_def(id: String) -> Dictionary:
	for job in JOBS:
		if str(job.get("id", "")) == id:
			return job
	return {}


static func job_name_of(id: String) -> String:
	return str(job_def(id).get("name", ""))


static func education_path_of(state) -> String:
	return str(state.education_path).strip_edges()


static func is_player_fork(path: String) -> bool:
	return path == PATH_UNIVERSITY or path == PATH_HIGH_SCHOOL


static func is_recognized_education(path: String) -> bool:
	if path == "" or path == PATH_UNDECIDED:
		return false
	if is_player_fork(path):
		return true
	if GrowthPath.is_tag(path):
		return true
	return not job_def(path).is_empty()


## Adult years only. undecided and unknown strings ask once; a fork, tag, or job id does not.
static func needs_education_choice(state) -> bool:
	if not is_adult(state):
		return false
	return not is_recognized_education(education_path_of(state))


static func scene_after_review(state, review_next: String) -> String:
	if review_next == "ending":
		return ENDING_SCENE
	if needs_education_choice(state):
		return FORK_SCENE
	return HUB_SCENE


## Writes the fork only. Does not touch the five axes, mood, cash, skills, or interest tags.
static func choose_education(state, path: String) -> bool:
	if not is_player_fork(path):
		return false
	state.education_path = path
	if state.has_signal("state_changed"):
		state.state_changed.emit()
	return true


static func fork_lead(state) -> String:
	var name := str(state.daughter_display_name())
	if int(state.year) <= GameConfig.ADULT_START_YEAR:
		return "高中的最後一頁合上了。%s成年的第一個春天，手帳想先問一件事：接下來，要先把書讀下去，還是先去工作？" % name
	return "成年的手帳上，升學這一件還空著。%s現在補上就好。寫進去以後，日子還是她的。" % name


static func fork_footnote() -> String:
	return "兩條路都走得完，也都溫暖。這一筆只影響往後工作怎麼開始，以及結局裡關於成家的那一句。魅力、道德、人際、體力、學識，還有專長頁，都不會因為這一筆改掉。"


static func university_blurb() -> String:
	return "先把書讀下去。平日靠近學校、診所、設計、公所或編輯桌；日記裡還留著夜間進修、證照和作品集。"


static func high_school_blurb() -> String:
	return "先去工作。咖啡店、商店街、照顧、運動、旅行社會早一點出現。日子一樣溫暖，成家以後也可以慢慢寫。"


static func written_body(path: String) -> String:
	if path == PATH_UNIVERSITY:
		return "寫下來了。大學進路。平日會先靠近學校、診所、設計室、公所或編輯桌。夜間進修那些月份還在日記裡。"
	if path == PATH_HIGH_SCHOOL:
		return "寫下來了。高中畢業，她直接去工作。咖啡店、商店街、照顧、運動、旅行社會早一點排進來。日子一樣可以過得很暖。"
	return ""


static func education_entry_line(state) -> String:
	match education_path_of(state):
		PATH_UNIVERSITY:
			return "她寫下大學進路。平日先靠近學校、診所、設計、公所或編輯桌；日記裡的夜間進修、證照和作品集都還留著。"
		PATH_HIGH_SCHOOL:
			return "她高中畢業就直接就業。咖啡店、商店街、照顧、運動、旅行社會早一點出現在班表上。"
		_:
			return ""


static func education_job_note(state) -> String:
	var edu := education_path_of(state)
	if edu == PATH_UNIVERSITY:
		return "大學進路：學校、診所、設計、公所、編輯會排得前一點。其他工作若專長夠，也還在。"
	if edu == PATH_HIGH_SCHOOL:
		return "高中就業：咖啡店、商店街、照顧、運動、旅行社會排得前一點。其他工作若專長夠，也還在。"
	if GrowthPath.is_tag(edu):
		return "手帳上記著「%s」。對上的工作會排得前一點。" % GrowthPath.tag_name(edu)
	return ""


static func job_picker_blurb(state) -> String:
	var base := "選一份就固定在平日。日記裡的三個月，仍是她自己的事。"
	var note := education_job_note(state)
	if note == "":
		return base + "名單跟著專長與興趣。"
	return base + note


static func education_chip(state) -> String:
	match education_path_of(state):
		PATH_UNIVERSITY:
			return "大學進路"
		PATH_HIGH_SCHOOL:
			return "高中就業"
		_:
			return ""


static func education_ending_flavor(state) -> String:
	var settled := bool(state.family_settled)
	match education_path_of(state):
		PATH_UNIVERSITY:
			if settled:
				return "大學那幾年的筆記收進了新家的抽屜。成家以後，她仍會留幾個晚上給還沒讀完的章節。"
			return "她走大學進路，工作靠近學業和以後的專業。成家的那一頁先空著，家的燈仍為她留著。"
		PATH_HIGH_SCHOOL:
			if settled:
				return "高中畢業她就先去工作。成家以後，班表和家裡的燈寫在同一頁，仍是她自己排的。"
			return "她高中畢業就走進工作，班表來得早一些。成家可以以後再寫，一個人把日子過穩也很好。"
		_:
			return ""


static func _education_rank(state, job_id: String) -> int:
	var edu := education_path_of(state)
	var list := PackedStringArray()
	if edu == PATH_UNIVERSITY:
		list = UNIVERSITY_JOBS
	elif edu == PATH_HIGH_SCHOOL:
		list = HIGH_SCHOOL_JOBS
	else:
		return 1000
	var at := list.find(job_id)
	return at if at >= 0 else 1000


static func _education_matches(state, job: Dictionary) -> bool:
	var edu := education_path_of(state)
	if not is_recognized_education(edu):
		return false
	var jid := str(job.get("id", ""))
	if edu == PATH_UNIVERSITY:
		return jid in UNIVERSITY_JOBS
	if edu == PATH_HIGH_SCHOOL:
		return jid in HIGH_SCHOOL_JOBS
	if edu == jid:
		return true
	var tags: Array = job.get("tags", [])
	return edu in tags


static func job_score(state, job: Dictionary) -> int:
	var score := 0
	var tags: Array = job.get("tags", [])
	for tid in tags:
		var pts := GrowthPath.points_of(state, str(tid))
		if pts >= 2:
			score += mini(pts, 6)
	var skills: Array = job.get("skills", [])
	for sid in skills:
		var lv := GrowthPath.level_of(state, str(sid))
		if lv > 0:
			score += lv * 2
	if _education_matches(state, job):
		score += 4
	return score


static func _is_offered(state, job: Dictionary) -> bool:
	if bool(job.get("always", false)):
		return true
	return job_score(state, job) > 0


static func available_jobs(state) -> Array:
	var rows: Array = []
	for job in JOBS:
		if _is_offered(state, job):
			rows.append(job)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var sa := job_score(state, a)
		var sb := job_score(state, b)
		if sa != sb:
			return sa > sb
		var ra := _education_rank(state, str(a.get("id", "")))
		var rb := _education_rank(state, str(b.get("id", "")))
		if ra != rb:
			return ra < rb
		return str(a.get("id", "")) < str(b.get("id", ""))
	)
	return rows


static func picker_jobs(state) -> Array:
	var rows := available_jobs(state)
	var current := str(state.adult_job)
	if current == "":
		return rows
	for row in rows:
		if str(row.get("id", "")) == current:
			return rows
	var extra := job_def(current)
	if not extra.is_empty():
		rows.append(extra)
	return rows


static func recommended_job(state) -> String:
	var rows := available_jobs(state)
	if rows.is_empty():
		return FALLBACK_JOB
	return str(rows[0].get("id", FALLBACK_JOB))


## Keep a chosen job. Empty or unknown ids fall back to the best current match.
static func ensure_job(state) -> String:
	var current := str(state.adult_job)
	if current != "" and not job_def(current).is_empty():
		return current
	var pick := recommended_job(state)
	state.adult_job = pick
	return pick


static func job_month_delta(state) -> Dictionary:
	var id := ensure_job(state)
	var job := job_def(id)
	var delta := {
		"charm": 0, "morals": 0, "social": 0, "stamina": 0,
		"academia": 0, "mood": 0, "cash": int(job.get("cash", 0)),
		"name": str(job.get("name", id)),
	}
	var effects: Dictionary = job.get("effects", {})
	for k in effects:
		if delta.has(k):
			delta[k] = int(effects[k])
	return delta


## +1 XP on the job's first skill, once per adult year. Six years can finish one skill, not all of them.
static func grant_yearly_skill(state) -> void:
	if not is_adult(state):
		return
	var key := "adult_skill_touch_%d" % int(state.year)
	if bool(state.flags.get(key, false)):
		return
	state.flags[key] = true
	var job := job_def(ensure_job(state))
	var skills: Array = job.get("skills", [])
	if skills.is_empty():
		return
	var sid := str(skills[0])
	if not GrowthPath.is_skill(sid):
		return
	state.skill_xp[sid] = int(state.skill_xp.get(sid, 0)) + 1


static func romance_band(value: int) -> String:
	if value >= 75:
		return "想把日子過在一起"
	if value >= 50:
		return "心裡有了位置"
	if value >= 25:
		return "有人慢慢走近"
	return "心還靜著"


static func romance_line(state) -> String:
	var v := clampi(int(state.romance), 0, ROMANCE_MAX)
	return "戀愛進度　%s　%s" % [TownNpcs.heart_row(v), romance_band(v)]


static func family_line(state) -> String:
	if bool(state.family_settled):
		return "成家　她自己把燈留成兩個人的。"
	if int(state.romance) >= FAMILY_ROMANCE_MIN:
		return "成家　可以排進日記。不排，也是一種選擇。"
	return "成家　還早。一個人把日子過完，也很好。"


static func hub_life_line(state) -> String:
	if not is_adult(state):
		return ""
	return "%s\n%s" % [romance_line(state), family_line(state)]


static func note_activity(state, activity_id: String) -> void:
	if not is_adult(state):
		return
	var def := Activities.get_activity(activity_id)
	if def.is_empty():
		return
	var rom := int(def.get("romance", 0))
	if rom != 0:
		state.romance = clampi(int(state.romance) + rom, 0, ROMANCE_MAX)
	var fam := int(def.get("family", 0))
	if fam <= 0 or int(state.romance) < FAMILY_ROMANCE_MIN:
		return
	state.family_prep = int(state.family_prep) + fam
	if int(state.family_prep) >= FAMILY_SETTLE_PREP and int(state.romance) >= FAMILY_SETTLE_ROMANCE:
		state.family_settled = true


static func career_bonus(ending_id: String, state) -> int:
	var job := job_def(str(state.adult_job))
	if job.is_empty():
		return 0
	if str(job.get("ending", "")) == ending_id:
		return CAREER_BONUS
	return 0


static func life_chip(state) -> String:
	var settled := "成家" if bool(state.family_settled) else "一個人"
	var core := "戀愛進度　%s　·　%s" % [romance_band(int(state.romance)), settled]
	var path := education_chip(state)
	if path == "":
		return core
	return "%s　·　%s" % [path, core]


static func life_aside(state) -> String:
	var bits: PackedStringArray = []
	var job_name := job_name_of(str(state.adult_job))
	if job_name != "":
		bits.append("這些年她的平日是%s。" % job_name)
	var rom := int(state.romance)
	if bool(state.family_settled):
		bits.append("戀愛進度走到想靠近的地方，她也把成家排進了日子；那是她自己選的。")
	elif rom >= 50:
		bits.append("心裡有一個人，步伐仍由她自己決定。成家不是這一局的必經。")
	elif rom >= 25:
		bits.append("有人慢慢走近，她沒有急著把名字寫進家裡。")
	else:
		bits.append("她沒有急著成家。一個人的房間也亮著，你仍是她回來看的地方。")
	var edu := education_ending_flavor(state)
	if edu != "":
		bits.append(edu)
	return "".join(bits)
