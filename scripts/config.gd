class_name GameConfig
extends RefCounted
## 《時光裡的她》常數與顯示用字串

const GAME_TITLE := "時光裡的她"
const START_AGE := 6
## Childhood is years 1–12 (about ages 6–17). Adulthood adds years 13–18 (about 18–23).
## The ending fires after year 18's winter review, when `year` becomes 19.
const CHILDHOOD_YEARS := 12
const ADULT_START_YEAR := 13
const TOTAL_YEARS := 18
const SEASONS_PER_YEAR := 4
const MONTHS_PER_SEASON := 3
const TOTAL_MONTHS := TOTAL_YEARS * SEASONS_PER_YEAR * MONTHS_PER_SEASON  # 216
const GROWTH_STAGES := 6  # childhood art: every 2 years, stages 0..5

const SEASON_NAMES := ["春", "夏", "秋", "冬"]
## English keys for wardrobe / weather asset filenames
const SEASON_KEYS := ["spring", "summer", "autumn", "winter"]
const MONTH_LABELS := ["第一個月", "第二個月", "第三個月"]
const STAGE_LABELS := ["幼年", "童年", "高小", "少年", "青春", "青年"]

const STAT_MIN := 0
const STAT_MAX := 100
const STARTING_CASH := 8000
const STARTING_STATS := {
	"charm": 35,
	"morals": 40,
	"social": 35,
	"stamina": 50,
	"academia": 30,
	"mood": 60,
}

const VIEWPORT_W := 1280
const VIEWPORT_H := 720

## Soft pink scrapbook palette (diary / Grok Imagine art)
const COL_BG := Color("FFF0F5")
const COL_PANEL := Color("FFF5F8")
const COL_PANEL_BORDER := Color("F5B8C8")
const COL_ACCENT := Color("F090A8")
const COL_ACCENT_DARK := Color("D87088")
const COL_TEXT := Color("5A3040")
const COL_TEXT_MUTED := Color("9A6878")
const COL_OK := Color("E898B0")
const COL_WARN := Color("E8A878")
const COL_MAP_BG := Color("D4E8D8")
const COL_HUD := Color("FFE8F0")
const COL_CHIP := Color("FFE0EC")
const COL_CHIP_HOVER := Color("FFD0E4")


static func season_name(index: int) -> String:
	return SEASON_NAMES[clampi(index, 0, SEASONS_PER_YEAR - 1)]


static func season_key(index: int) -> String:
	return SEASON_KEYS[clampi(index, 0, SEASONS_PER_YEAR - 1)]


static func age_for_year(year: int) -> int:
	return START_AGE + year - 1


## Years 1–2→0, 3–4→1, 5–6→2, 7–8→3, 9–10→4, 11–12→5.
## Years 13–18 stay on stage 5 for the numeric index. Adult outfits are separate
## files (one set per year, four seasons) and fall back to this stage when missing.
static func growth_stage_for_year(year: int) -> int:
	var y := clampi(year, 1, TOTAL_YEARS)
	return clampi((y - 1) / 2, 0, GROWTH_STAGES - 1)


static func growth_stage_label(stage: int) -> String:
	return STAGE_LABELS[clampi(stage, 0, GROWTH_STAGES - 1)]


static func is_adult_year(year: int) -> bool:
	return year >= ADULT_START_YEAR


static func life_phase_label(year: int) -> String:
	if is_adult_year(year):
		return "成年"
	return growth_stage_label(growth_stage_for_year(year))


static func age_band(age: int) -> String:
	## Display band derived from growth stage (every 2 years); adult ages say 成年
	var year := clampi(age - START_AGE + 1, 1, TOTAL_YEARS)
	return life_phase_label(year)


static func age_art_band(age: int) -> String:
	## Legacy 3-band helper kept for older call sites
	if age <= 11:
		return "child"
	if age <= 15:
		return "teen"
	return "young"


static func _file_exists(path: String) -> bool:
	if path == "":
		return false
	if ResourceLoader.exists(path):
		return true
	# Also accept raw files not yet imported (headless / fresh copy)
	var abs := ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
	return FileAccess.file_exists(abs)


## Prefer png then jpg for s{stage}_{season}; fallback chain:
## same stage other seasons → that stage spring → nearest stage spring → legacy daughter art
static func wardrobe_path(stage: int, season: int) -> String:
	var st := clampi(stage, 0, GROWTH_STAGES - 1)
	var seasons_try: Array[int] = [clampi(season, 0, 3)]
	for s in range(4):
		if s not in seasons_try:
			seasons_try.append(s)
	# Prefer spring early in fallback after primary
	if 0 not in seasons_try:
		seasons_try.append(0)

	for s_idx in seasons_try:
		var key := season_key(s_idx)
		for ext in ["png", "jpg"]:
			var p := "res://assets/wardrobe/s%d_%s.%s" % [st, key, ext]
			if _file_exists(p):
				return p

	# Nearest stage that has spring (walk outward)
	for delta in range(1, GROWTH_STAGES):
		for sign in [-1, 1]:
			var ns: int = st + int(sign) * delta
			if ns < 0 or ns >= GROWTH_STAGES:
				continue
			for ext in ["png", "jpg"]:
				var p2 := "res://assets/wardrobe/s%d_spring.%s" % [ns, ext]
				if _file_exists(p2):
					return p2

	# Legacy fullbody fallbacks
	for fb in [
		"res://assets/daughter_child_full.png",
		"res://assets/daughter_fullbody_crop.png",
		"res://assets/daughter_teen.png",
		"res://assets/daughter_young.png",
		"res://assets/daughter_child.jpg",
	]:
		if _file_exists(fb):
			return fb
	return ""


## Adult outfits keep childhood's seasonal cadence, one set per adult year
## (art_yearly_season): ages 18–23 are years 13–18.
## Plates live in assets/adulthood/ and ship as packs/adulthood.pck so they
## stay out of index.pck. A wardrobe/ copy is still accepted.
## TODO(art): these yearly plates are stylistic stand-ins (same face, new clothes
## per year and season), not the final painted set. A missing season reuses
## another season of that same year. A missing year still falls back to youth s5.
static func wardrobe_path_for_year_season(year: int, season: int) -> String:
	if is_adult_year(year):
		var adult := _adult_wardrobe_path(year, season)
		if adult != "":
			return adult
		return wardrobe_path(GROWTH_STAGES - 1, season)
	return wardrobe_path(growth_stage_for_year(year), season)


static func _adult_wardrobe_path(year: int, season: int) -> String:
	var seasons_try: Array[int] = [clampi(season, 0, 3)]
	for s in range(4):
		if s not in seasons_try:
			seasons_try.append(s)
	var folders: Array[String] = [
		"res://assets/adulthood/",
		"res://assets/wardrobe/",
	]
	for s_idx in seasons_try:
		var key := season_key(s_idx)
		for folder in folders:
			for ext in ["png", "jpg"]:
				var p := "%sadult_y%d_%s.%s" % [folder, year, key, ext]
				if _file_exists(p):
					return p
	return ""


static func daughter_texture_path(age: int) -> String:
	## Prefer wardrobe (spring) for the age's year, including the adult fallback
	var year := clampi(age - START_AGE + 1, 1, TOTAL_YEARS)
	var wp := wardrobe_path_for_year_season(year, 0)
	if wp != "":
		return wp
	match age_art_band(age):
		"teen":
			return "res://assets/daughter_teen.png"
		"young":
			return "res://assets/daughter_young.png"
		_:
			return "res://assets/daughter_child_full.png"


static func event_still_path(media_id: String) -> String:
	if media_id == "":
		return ""
	for ext in ["jpg", "png"]:
		var p := "res://assets/events/%s.%s" % [media_id, ext]
		if _file_exists(p):
			return p
	return ""


static func event_video_path(media_id: String) -> String:
	if media_id == "":
		return ""
	# Prefer Theora (.ogv) for stock Godot VideoStreamPlayer; keep mp4 as source asset
	for ext in ["ogv", "webm", "mp4"]:
		var p := "res://assets/videos/%s.%s" % [media_id, ext]
		if _file_exists(p):
			return p
	return ""


static func year_review_album_bg() -> String:
	for ext in ["png", "jpg"]:
		var p := "res://assets/year_review/album_bg.%s" % ext
		if _file_exists(p):
			return p
	return ""


static func year_review_polaroid_path(band: String) -> String:
	## Fallback: young→teen→child→album_bg
	var order: Array[String] = []
	match band:
		"young":
			order = ["young", "teen", "child"]
		"teen":
			order = ["teen", "child"]
		_:
			order = ["child"]
	for b in order:
		for ext in ["png", "jpg"]:
			var p := "res://assets/year_review/polaroids_%s.%s" % [b, ext]
			if _file_exists(p):
				return p
	return year_review_album_bg()


static func polaroid_band_for_age(age: int) -> String:
	if age <= 11:
		return "child"
	if age <= 15:
		return "teen"
	return "young"


static func ending_art_path(ending_id: String) -> String:
	## Prefer png then jpg under assets/endings/{id}; fallback ordinary_happy → credits_bg
	var id := ending_id.strip_edges()
	if id == "":
		id = "ordinary_happy"
	var candidates: Array[String] = [id]
	if id != "ordinary_happy":
		candidates.append("ordinary_happy")
	candidates.append("credits_bg")
	for cid in candidates:
		for ext in ["png", "jpg"]:
			var p := "res://assets/endings/%s.%s" % [cid, ext]
			if _file_exists(p):
				return p
	return ""
