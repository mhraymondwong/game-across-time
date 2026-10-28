class_name AgeLooks
extends RefCounted
## age_bands_family — 女兒、媽媽、爸爸各有五段外貌。
## 年段跟既有立繪階段對齊（每兩年一階），成年另成一段。
##
## TODO(art): 女兒、媽媽、爸爸與全家福的五段圖已在 assets/family/。
## 解析時若檔案不在，就退回現在這一張，不要另造暫代圖。
## 目的地風景是 assets/travel/travel_{dest}_scene.jpg（選擇卡與短過場），不是年齡段全家福。
## 遠行 assets/travel/{dest}_{band} 仍缺，繼續退回 travel_{dest}_family.jpg。
##
## 檔名裡的 band：
##   early       幼年  第 1–2 年（約 6–7 歲）  階段 0
##   elementary  國小  第 3–6 年（約 8–11 歲） 階段 1–2
##   junior      國中  第 7–8 年（約 12–13 歲）階段 3
##   senior      高中  第 9–12 年（約 14–17 歲）階段 4–5
##   adult       成年  第 13–18 年（約 18–23 歲）
##
## 路徑（缺檔才用後面的退路）：
##   assets/travel/{dest}_{band}.jpg          → travel_{dest}_family.jpg
##   assets/family/daughter_{band}.png        → 既有季立繪（含成年缺檔回青年）
##   assets/family/mom_{band}_cutout.png      → mom_fullbody_cutout.png
##   assets/family/mom_{band}_bust.png        → mom_bust_cutout.png
##   assets/family/dad_{band}.png             → （畫面上還沒有位子；缺檔退路是空字串）
##   assets/family/family_{band}.jpg          → family_photo_child.jpg

const BANDS: Array[String] = ["early", "elementary", "junior", "senior", "adult"]
const MOM_PIN_FALLBACK := "res://assets/family/mom_fullbody_cutout.png"
const MOM_BUST_FALLBACK := "res://assets/family/mom_bust_cutout.png"
const FAMILY_PHOTO_FALLBACK := "res://assets/family/family_photo_child.jpg"

const BAND_LABELS := {
	"early": "幼年",
	"elementary": "國小",
	"junior": "國中",
	"senior": "高中",
	"adult": "成年",
}


static func band_for_year(year: int) -> String:
	if GameConfig.is_adult_year(year):
		return "adult"
	match GameConfig.growth_stage_for_year(year):
		0:
			return "early"
		1, 2:
			return "elementary"
		3:
			return "junior"
		_:
			return "senior"


static func band_for_age(age: int) -> String:
	var year := clampi(age - GameConfig.START_AGE + 1, 1, GameConfig.TOTAL_YEARS)
	return band_for_year(year)


static func label_for_year(year: int) -> String:
	return str(BAND_LABELS.get(band_for_year(year), ""))


## Destination family still for this game year. `fallback` is today's single JPG.
static func travel_thumb(dest_id: String, year: int, fallback: String) -> String:
	var found := _banded("res://assets/travel/%s_%s" % [dest_id.strip_edges(), band_for_year(year)], ["jpg", "png"])
	if found != "":
		return found
	return fallback


static func daughter_portrait(year: int, season: int) -> String:
	var found := _banded("res://assets/family/daughter_%s" % band_for_year(year), ["png", "jpg"])
	if found != "":
		return found
	return GameConfig.wardrobe_path_for_year_season(year, season)


static func mom_pin(year: int) -> String:
	var found := _banded("res://assets/family/mom_%s_cutout" % band_for_year(year), ["png", "jpg"])
	if found != "":
		return found
	return MOM_PIN_FALLBACK


static func mom_portrait(year: int) -> String:
	var found := _banded("res://assets/family/mom_%s_bust" % band_for_year(year), ["png", "jpg"])
	if found != "":
		return found
	return MOM_BUST_FALLBACK


static func dad_portrait(year: int) -> String:
	return _banded("res://assets/family/dad_%s" % band_for_year(year), ["png", "jpg"])


static func family_photo(year: int) -> String:
	var found := _banded("res://assets/family/family_%s" % band_for_year(year), ["jpg", "png"])
	if found != "":
		return found
	return FAMILY_PHOTO_FALLBACK


static func _banded(stem: String, exts: Array) -> String:
	if stem.ends_with("_") or stem.ends_with("/"):
		return ""
	for ext in exts:
		var path := "%s.%s" % [stem, str(ext)]
		if _exists(path):
			return path
	return ""


static func _exists(path: String) -> bool:
	if path == "":
		return false
	if ResourceLoader.exists(path):
		return true
	var abs := ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
	return FileAccess.file_exists(abs)
