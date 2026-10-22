class_name Adulthood
extends RefCounted
## 第 13–18 年（約 18–23 歲）。鎖：adult_plus6_end_y18、排程 A+B、戀愛 C+D。
## 平日工作是背景，每月日記仍只排 1 格（戀愛／進修／成家／工作小事）。
## 戀愛是抽象「戀愛進度」，不綁特定戀愛 NPC。成家是可選支線，單身可以走到結局。
## education_path 若已是興趣標籤或工作 id，只輕輕把對上的工作排進名單並提前；
## 沒有升學選擇畫面（Phase C）。undecided 與認不得的字串不改變名單。


const ROMANCE_MAX := 100
## 成家活動解鎖。沒到之前，日記不強迫排。
const FAMILY_ROMANCE_MIN := 40
## 進度夠、而且自己排過兩次成家，才算走上這條支線。
const FAMILY_SETTLE_PREP := 2
const FAMILY_SETTLE_ROMANCE := 50
## 結局加分。只在原本已經達標、而且優先度落在視窗內的路線之間重排。
const CAREER_BONUS := 4
const FALLBACK_JOB := "shop_staff"

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


static func _education_matches(state, job: Dictionary) -> bool:
	## Phase C hook. Tag ids and job ids bias the pool; anything else is ignored.
	var edu := str(state.education_path).strip_edges()
	if edu == "" or edu == "undecided":
		return false
	if edu == str(job.get("id", "")):
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
	return "戀愛進度　%s　·　%s" % [romance_band(int(state.romance)), settled]


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
	return "".join(bits)
