class_name Activities
extends RefCounted
## 每月可選活動定義（原創名稱與效果）＋解鎖／心情強度閘門

const PLACE_NAMES := {
	"home": "住家",
	"school": "學校",
	"park": "公園",
	"shops": "商店街",
	"clinic": "診所",
	"culture": "文化中心",
}

const STAT_LABELS := {
	"charm": "魅力",
	"morals": "道德",
	"social": "人際",
	"stamina": "體力",
	"academia": "學識",
	"mood": "心情",
}

## Category → default intensity (0 light / 1 medium / 2 heavy)
const CATEGORY_INTENSITY := {
	"休閒": 0,
	"品格": 0,
	"社交": 1,
	"學習": 1,
	"氣質": 1,
	"打工": 2,
	"戀愛": 0,
	"進修": 1,
	"成家": 0,
	"工作": 1,
}


## id -> activity def
static func all() -> Dictionary:
	return {
		"study_tutoring": {
			"name": "補習班",
			"category": "學習",
			"desc": "加強課業，消耗體力與學費。",
			"effects": {"academia": 5, "stamina": -4, "charm": 0, "morals": 1, "social": -1},
			"cash": -600,
			"mood": -2,
			"intensity": 2,
			"max_year": 12,
		},
		"study_library": {
			"name": "圖書館自習",
			"category": "學習",
			"desc": "安靜讀書，省錢但進度較慢。",
			"effects": {"academia": 3, "stamina": -2, "morals": 1, "social": 0, "charm": 0},
			"cash": -50,
			"mood": 0,
			"intensity": 1,
			"max_year": 12,
		},
		"study_arts": {
			"name": "才藝課",
			"category": "學習",
			"desc": "音樂或繪畫，兼顧氣質。",
			"effects": {"academia": 2, "charm": 4, "stamina": -3, "social": 1, "morals": 0},
			"cash": -800,
			"mood": 3,
			"intensity": 1,
			"max_year": 12,
		},
		"work_cafe": {
			"name": "咖啡店打工",
			"category": "打工",
			"desc": "端盤泡茶，賺零用錢。",
			"effects": {"social": 2, "stamina": -5, "charm": 1, "academia": 0, "morals": 0},
			"cash": 1200,
			"mood": -1,
			"intensity": 2,
			"min_year": 10,
			"max_year": 12,
			"unlock_hint": "十五歲左右才適合咖啡店打工",
		},
		"work_store": {
			"name": "便利店打工",
			"category": "打工",
			"desc": "排班較累，收入穩定。",
			"effects": {"stamina": -6, "social": 1, "morals": 1, "charm": 0, "academia": 0},
			"cash": 1500,
			"mood": -3,
			"intensity": 2,
			"min_year": 11,
			"max_year": 12,
			"unlock_hint": "十六歲左右才能排便利店的班",
		},
		"work_tutor": {
			"name": "家教",
			"category": "打工",
			"desc": "教鄰居小孩，需要學識。",
			"effects": {"academia": 2, "social": 2, "stamina": -4, "morals": 2, "charm": 0},
			"cash": 1800,
			"mood": 1,
			"intensity": 2,
			"min_academia": 40,
			"min_year": 11,
			"max_year": 12,
			"unlock_hint": "學識夠、十六歲左右才接得住家教",
		},
		"social_friends": {
			"name": "朋友聚會",
			"category": "社交",
			"desc": "週末約同學出去玩。",
			"effects": {"social": 5, "charm": 2, "stamina": -2, "academia": -1, "morals": 0},
			"cash": -300,
			"mood": 6,
			"intensity": 1,
		},
		"social_club": {
			"name": "社團活動",
			"category": "社交",
			"desc": "參加學校或社區社團。",
			"effects": {"social": 4, "stamina": -3, "charm": 1, "academia": 1, "morals": 1},
			"cash": -150,
			"mood": 4,
			"intensity": 1,
			"min_year": 2,
		},
		"social_neighbor": {
			"name": "拜訪鄰居",
			"category": "社交",
			"desc": "幫忙拿信、聊天。",
			"effects": {"social": 3, "morals": 3, "charm": 1, "stamina": -1, "academia": 0},
			"cash": 0,
			"mood": 3,
			"intensity": 0,
		},
		"rest_park": {
			"name": "公園散步",
			"category": "休閒",
			"desc": "呼吸新鮮空氣，恢復體力。",
			"effects": {"stamina": 6, "mood_via": 0, "charm": 1, "social": 1, "morals": 0, "academia": 0},
			"cash": 0,
			"mood": 5,
			"intensity": 0,
			"season_bonus": {0: 1.2, 1: 1.0, 2: 1.1, 3: 0.8},
		},
		"rest_sleep": {
			"name": "在家好好休息",
			"category": "休閒",
			"desc": "睡飽、看書、發呆。",
			"effects": {"stamina": 8, "academia": 0, "social": -1, "charm": 0, "morals": 0},
			"cash": 0,
			"mood": 7,
			"intensity": 0,
		},
		"rest_trip": {
			"name": "短途旅行",
			"category": "休閒",
			"desc": "週末去郊外走走。",
			"effects": {"stamina": 4, "charm": 2, "social": 2, "academia": 0, "morals": 0},
			"cash": -1200,
			"mood": 8,
			"intensity": 1,
			"min_year": 3,
		},
		"virtue_volunteer": {
			"name": "社區志工",
			"category": "品格",
			"desc": "社區清潔日：掃落葉、擦長椅，再去探訪長輩。",
			"effects": {"morals": 6, "social": 2, "stamina": -3, "charm": 0, "academia": 0},
			"cash": 0,
			"mood": 4,
			"intensity": 0,
			"min_year": 2,
		},
		"virtue_recycle": {
			"name": "環保回收義工",
			"category": "品格",
			"desc": "跟街坊把紙箱、玻璃瓶和鋁罐分好，送到社區回收站。",
			"effects": {"morals": 5, "social": 2, "stamina": -2, "academia": 1, "charm": 0},
			"cash": 0,
			"mood": 3,
			"intensity": 0,
			"min_year": 1,
		},
		"school_garden": {
			"name": "校園園藝",
			"category": "品格",
			"desc": "在花圃澆水、拔小草，看番茄慢慢變紅。",
			"effects": {"morals": 3, "stamina": 2, "social": 1, "charm": 1, "academia": 0},
			"cash": 0,
			"mood": 4,
			"intensity": 0,
			"require_visit": "school",
			"min_year": 1,
			"max_year": 12,
			"unlock_hint": "先去過學校，就可以加入校園園藝",
		},
		"school_library_helper": {
			"name": "學校圖書館小義工",
			"category": "品格",
			"desc": "把繪本歸回書架，偶爾念一段給更小的孩子聽。",
			"effects": {"morals": 3, "academia": 2, "social": 2, "charm": 1, "stamina": -1},
			"cash": 0,
			"mood": 3,
			"intensity": 0,
			"require_visit": "school",
			"min_year": 3,
			"max_year": 12,
			"unlock_hint": "去過學校，八歲左右可以當圖書館小義工",
		},
		"school_class_helper": {
			"name": "班務小幫手",
			"category": "社交",
			"desc": "擦黑板、依座號發簿子、把歪掉的椅子推正。",
			"effects": {"social": 3, "morals": 3, "charm": 1, "stamina": -1, "academia": 0},
			"cash": 0,
			"mood": 2,
			"intensity": 0,
			"require_visit": "school",
			"min_year": 2,
			"max_year": 12,
			"unlock_hint": "去過學校，七歲左右可以當班務小幫手",
		},
		"festival_helper": {
			"name": "廟會園遊會義工",
			"category": "社交",
			"desc": "廟會或校園園遊會幫忙發地圖、指路、把彩帶收好。",
			"effects": {"social": 4, "morals": 2, "charm": 2, "stamina": -2, "academia": 0},
			"cash": 0,
			"mood": 5,
			"intensity": 1,
			"min_year": 2,
			"unlock_hint": "七歲左右可以去廟會、園遊會當義工",
		},
		"family_bento": {
			"name": "跟家人送便當",
			"category": "品格",
			"desc": "把熱便當送到家人的攤位或巷口，順便跟街坊問午安。",
			"effects": {"morals": 3, "social": 2, "stamina": -1, "charm": 0, "academia": 0},
			"cash": 100,
			"mood": 3,
			"intensity": 0,
			"min_year": 1,
		},
		"virtue_chores": {
			"name": "家務與照顧",
			"category": "品格",
			"desc": "幫忙煮飯、打掃、照顧家人。",
			"effects": {"morals": 4, "stamina": -2, "social": 1, "academia": 0, "charm": 0},
			"cash": 200,
			"mood": 2,
			"intensity": 0,
		},
		"virtue_elder": {
			"name": "陪伴長輩",
			"category": "品格",
			"desc": "聽故事、陪散步。",
			"effects": {"morals": 5, "social": 3, "stamina": -1, "academia": 1, "charm": 1},
			"cash": 0,
			"mood": 5,
			"intensity": 0,
		},
		"style_fashion": {
			"name": "穿搭與儀態",
			"category": "氣質",
			"desc": "學穿衣打扮與站姿。",
			"effects": {"charm": 6, "social": 1, "stamina": -1, "academia": 0, "morals": 0},
			"cash": -700,
			"mood": 3,
			"intensity": 1,
			"min_year": 3,
		},
		"style_perform": {
			"name": "表演練習",
			"category": "氣質",
			"desc": "舞台或演講練習。",
			"effects": {"charm": 5, "social": 3, "stamina": -4, "academia": 1, "morals": 0},
			"cash": -400,
			"mood": 2,
			"intensity": 2,
			"min_year": 4,
			"min_charm": 25,
		},
		"health_clinic": {
			"name": "健康檢查與運動",
			"category": "休閒",
			"desc": "診所檢查或規律運動。",
			"effects": {"stamina": 7, "morals": 1, "charm": 1, "social": 0, "academia": 0},
			"cash": -350,
			"mood": 3,
			"intensity": 0,
		},
		# —— Phase 5：地點／年級解鎖活動 ——
		"culture_reading": {
			"name": "文化中心朗讀會",
			"category": "學習",
			"desc": "在文化中心朗讀故事給小朋友聽。",
			"effects": {"academia": 3, "charm": 2, "social": 2, "stamina": -2, "morals": 1},
			"cash": -100,
			"mood": 4,
			"intensity": 1,
			"require_visit": "culture",
			"min_year": 3,
			"unlock_hint": "先去過文化中心，且滿三年級",
		},
		"clinic_helper": {
			"name": "診所暑期小幫手",
			"category": "品格",
			"desc": "暑假到診所當小義工，整理候診區、送水給長輩。",
			"effects": {"morals": 5, "social": 2, "stamina": -3, "academia": 1, "charm": 0},
			"cash": 400,
			"mood": 3,
			"intensity": 1,
			"require_visit": "clinic",
			"min_year": 5,
			"max_year": 12,
			"min_morals": 35,
			"unlock_hint": "拜訪過診所、道德夠，十歲左右可當小義工",
		},
		"shops_market": {
			"name": "跟爸媽市集幫忙",
			"category": "品格",
			"desc": "週末跟著爸媽擺攤、遞袋子、跟街坊說歡迎。收攤有一點零用錢。",
			"effects": {"social": 3, "charm": 1, "stamina": -2, "academia": 0, "morals": 3},
			"cash": 200,
			"mood": 4,
			"intensity": 0,
			"require_visit": "shops",
			"min_year": 2,
			"unlock_hint": "逛過商店街後，可以跟著家人去市集幫忙",
		},
		"school_debate": {
			"name": "學校辯論／壁報社",
			"category": "學習",
			"desc": "辯論練習或辦壁報，鍛鍊表達。",
			"effects": {"academia": 4, "social": 2, "stamina": -3, "charm": 1, "morals": 1},
			"cash": -80,
			"mood": 2,
			"intensity": 1,
			"require_visit": "school",
			"min_academia": 30,
			"min_year": 3,
			"max_year": 12,
			"unlock_hint": "去過學校且學識達標",
		},
		"park_run": {
			"name": "公園晨跑隊",
			"category": "休閒",
			"desc": "早上跟鄰居一起慢跑，鍛鍊體力。",
			"effects": {"stamina": 6, "social": 2, "morals": 1, "charm": 1, "academia": 0},
			"cash": 0,
			"mood": 4,
			"intensity": 1,
			"require_visit": "park",
			"min_stamina": 25,
			"unlock_hint": "到過公園再加入晨跑隊",
		},
		"study_piano": {
			"name": "學鋼琴",
			"category": "學習",
			"desc": "文化中心琴房的固定課。音階慢慢變得順，回家還會再彈一小段。",
			"effects": {"charm": 3, "academia": 1, "stamina": -2, "social": 1, "morals": 0},
			"cash": -700,
			"mood": 2,
			"intensity": 1,
			"min_year": 7,
			"max_year": 12,
			"unlock_hint": "國中以後可以排學鋼琴",
		},
		"study_language": {
			"name": "外語班",
			"category": "學習",
			"desc": "每週跟著課文念對話。有一天她會把菜單唸給你聽。",
			"effects": {"academia": 3, "charm": 1, "social": 1, "stamina": -2, "morals": 0},
			"cash": -500,
			"mood": 1,
			"intensity": 1,
			"min_year": 7,
			"max_year": 12,
			"unlock_hint": "國中以後可以排外語班",
		},
		"study_code": {
			"name": "程式興趣班",
			"category": "學習",
			"desc": "在電腦教室把一個小程式跑起來。錯了就改，改完會亮。",
			"effects": {"academia": 4, "social": 1, "stamina": -2, "charm": 0, "morals": 1},
			"cash": -400,
			"mood": 2,
			"intensity": 1,
			"min_year": 7,
			"max_year": 12,
			"unlock_hint": "國中以後可以排程式興趣班",
		},
		"talent_showcase": {
			"name": "高年級才藝發表",
			"category": "氣質",
			"desc": "學校或社區的才藝發表會上台演出。",
			"effects": {"charm": 6, "social": 3, "stamina": -4, "academia": 1, "morals": 0},
			"cash": -500,
			"mood": 5,
			"intensity": 2,
			"min_year": 7,
			"max_year": 12,
			"min_charm": 40,
			"unlock_hint": "七年級起、魅力夠才適合上台",
		},
		# —— 成年自由格（第 13 年起）。平日工作另計，不佔這三格。 ——
		"date_walk": {
			"name": "黃昏散步",
			"category": "戀愛",
			"desc": "沒有特定的誰。只是把黃昏留給一個慢慢走近的人。",
			"effects": {"social": 2, "charm": 1, "stamina": 1, "morals": 0, "academia": 0},
			"cash": -200,
			"mood": 4,
			"intensity": 0,
			"romance": 8,
			"min_year": 13,
			"adult_only": true,
			"unlock_hint": "成年以後，每月可以留一格給靠近的人",
		},
		"date_letter": {
			"name": "寫一封短短的信",
			"category": "戀愛",
			"desc": "信紙上不寫全名。把這一個月想說的話，慢慢寄出去。",
			"effects": {"charm": 1, "academia": 1, "social": 1, "morals": 0, "stamina": 0},
			"cash": -40,
			"mood": 3,
			"intensity": 0,
			"romance": 6,
			"min_year": 13,
			"adult_only": true,
			"unlock_hint": "成年以後，每月可以留一格給靠近的人",
		},
		"date_cook": {
			"name": "一起準備晚餐",
			"category": "戀愛",
			"desc": "兩個人在廚房說很少的話。湯滾了，日子也暖一點。",
			"effects": {"social": 2, "morals": 1, "stamina": -1, "charm": 1, "academia": 0},
			"cash": -180,
			"mood": 4,
			"intensity": 0,
			"romance": 7,
			"min_year": 13,
			"adult_only": true,
			"unlock_hint": "成年以後，每月可以留一格給靠近的人",
		},
		"study_night": {
			"name": "夜間進修",
			"category": "進修",
			"desc": "下班後的燈還亮著。她把白天沒看完的章節補上。",
			"effects": {"academia": 4, "stamina": -3, "morals": 1, "social": 0, "charm": 0},
			"cash": -400,
			"mood": -1,
			"intensity": 1,
			"min_year": 13,
			"adult_only": true,
			"unlock_hint": "成年以後可以排夜間進修",
		},
		"study_license": {
			"name": "準備一張證照",
			"category": "進修",
			"desc": "題目很多，她一張張摺好。考過了，工作會更穩一點。",
			"effects": {"academia": 3, "morals": 1, "stamina": -2, "social": 0, "charm": 0},
			"cash": -250,
			"mood": 0,
			"intensity": 1,
			"min_year": 13,
			"adult_only": true,
			"unlock_hint": "成年以後可以準備證照",
		},
		"study_portfolio": {
			"name": "整理作品集",
			"category": "進修",
			"desc": "舊塗鴉和新稿放在一起。她挑出願意給別人看的那幾頁。",
			"effects": {"charm": 2, "academia": 2, "stamina": -1, "social": 0, "morals": 0},
			"cash": -150,
			"mood": 2,
			"intensity": 1,
			"min_year": 13,
			"adult_only": true,
			"unlock_hint": "成年以後可以整理作品集",
		},
		"family_meet": {
			"name": "帶回家吃頓飯",
			"category": "成家",
			"desc": "多一雙筷子。沒有人把這頓飯說成典禮，湯還是家裡的味道。",
			"effects": {"social": 2, "morals": 1, "charm": 0, "stamina": 0, "academia": 0},
			"cash": -300,
			"mood": 3,
			"intensity": 0,
			"romance": 4,
			"family": 1,
			"require_romance": 40,
			"min_year": 13,
			"adult_only": true,
			"unlock_hint": "戀愛進度還淺，成家的事先放著",
		},
		"family_nest": {
			"name": "布置以後的小房間",
			"category": "成家",
			"desc": "窗簾、桌子、一盞不太亮的燈。她問你這張椅子要不要留下。",
			"effects": {"charm": 1, "morals": 1, "social": 1, "stamina": -1, "academia": 0},
			"cash": -800,
			"mood": 2,
			"intensity": 0,
			"romance": 2,
			"family": 1,
			"require_romance": 40,
			"min_year": 13,
			"adult_only": true,
			"unlock_hint": "戀愛進度還淺，成家的事先放著",
		},
		"family_talk": {
			"name": "談以後怎麼過日子",
			"category": "成家",
			"desc": "沒有期限。只是把「要不要住近一點」這句話，放在桌上。",
			"effects": {"morals": 2, "social": 1, "charm": 0, "stamina": 0, "academia": 0},
			"cash": 0,
			"mood": 2,
			"intensity": 0,
			"romance": 3,
			"family": 1,
			"require_romance": 40,
			"min_year": 13,
			"adult_only": true,
			"unlock_hint": "戀愛進度還淺，成家的事先放著",
		},
		"work_overtime": {
			"name": "把工作做深一點",
			"category": "工作",
			"desc": "平日的班已經上完。這個月她多留一會兒，把一件事做到能放心。",
			"effects": {"academia": 1, "morals": 1, "stamina": -4, "social": 0, "charm": 0},
			"cash": 400,
			"mood": -1,
			"intensity": 2,
			"min_year": 13,
			"adult_only": true,
			"unlock_hint": "成年以後可以把工作做深一點",
		},
		"work_colleagues": {
			"name": "跟同事吃便飯",
			"category": "工作",
			"desc": "便當攤的位子很擠。她聽同事講家裡的事，也把自己的份量說少一點。",
			"effects": {"social": 3, "charm": 1, "stamina": -1, "morals": 0, "academia": 0},
			"cash": -180,
			"mood": 2,
			"intensity": 0,
			"min_year": 13,
			"adult_only": true,
			"unlock_hint": "成年以後可以跟同事吃便飯",
		},
		"work_side": {
			"name": "接一件小案子",
			"category": "工作",
			"desc": "店招、代筆、或一堂小課。不是離職，是把本事借出去一個月。",
			"effects": {"charm": 1, "academia": 1, "stamina": -3, "social": 1, "morals": 0},
			"cash": 600,
			"mood": 1,
			"intensity": 1,
			"min_year": 13,
			"adult_only": true,
			"unlock_hint": "成年以後可以接一件小案子",
		},
	}


static func get_activity(id: String) -> Dictionary:
	var a := all()
	if a.has(id):
		return a[id]
	return {}


static func ids() -> Array:
	return all().keys()


static func ids_by_category() -> Dictionary:
	var out := {}
	for id in all():
		var cat: String = all()[id]["category"]
		if not out.has(cat):
			out[cat] = []
		out[cat].append(id)
	return out


static func shown_in_picker(id: String, state: Node) -> bool:
	var def := get_activity(id)
	if def.is_empty():
		return false
	if bool(def.get("adult_only", false)) and int(state.year) < GameConfig.ADULT_START_YEAR:
		return false
	if def.has("max_year") and int(state.year) > int(def["max_year"]):
		return false
	return true


static func ids_by_category_for(state: Node) -> Dictionary:
	var grouped := {}
	for id in all():
		if not shown_in_picker(id, state):
			continue
		var cat: String = str(all()[id].get("category", ""))
		if not grouped.has(cat):
			grouped[cat] = []
		grouped[cat].append(id)
	if int(state.year) < GameConfig.ADULT_START_YEAR:
		return grouped
	var out := {}
	for cat in ["戀愛", "進修", "成家", "工作", "休閒", "社交", "品格", "氣質", "學習", "打工"]:
		if grouped.has(cat):
			out[cat] = grouped[cat]
	for cat in grouped:
		if not out.has(cat):
			out[cat] = grouped[cat]
	return out


static func intensity_of(def: Dictionary) -> int:
	if def.has("intensity"):
		return int(def["intensity"])
	var cat: String = str(def.get("category", ""))
	if CATEGORY_INTENSITY.has(cat):
		return int(CATEGORY_INTENSITY[cat])
	return 1


static func _flag_truthy(state: Node, key: String) -> bool:
	if not state.flags.has(key):
		return false
	var v = state.flags[key]
	if typeof(v) == TYPE_BOOL:
		return v
	if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
		return int(v) >= 1
	if typeof(v) == TYPE_STRING:
		return str(v) != "" and str(v) != "0"
	return v != null


static func _stat_of(state: Node, key: String) -> int:
	match key:
		"charm":
			return int(state.charm)
		"morals":
			return int(state.morals)
		"social":
			return int(state.social)
		"stamina":
			return int(state.stamina)
		"academia":
			return int(state.academia)
		"mood":
			return int(state.mood)
		_:
			return 0


## Returns { ok: bool, reason: String } — reason is zh-Hant when locked
static func availability(id: String, state: Node) -> Dictionary:
	var def := get_activity(id)
	if def.is_empty():
		return {"ok": false, "reason": "找不到這個活動"}

	var intensity := intensity_of(def)
	var mood := int(state.mood)

	# Mood intensity gates (highest priority soft block for heavy/medium)
	if mood < 20 and intensity > 0:
		return {"ok": false, "reason": "心情太低，先好好休息吧"}
	if mood < 35 and intensity >= 2:
		return {"ok": false, "reason": "心情偏低，激烈活動先暫緩"}

	# Year / age
	if def.has("min_year") and int(state.year) < int(def["min_year"]):
		var hint := str(def.get("unlock_hint", ""))
		if hint != "":
			return {"ok": false, "reason": hint}
		return {"ok": false, "reason": "還要再長大一點（第 %d 年起）" % int(def["min_year"])}
	if def.has("min_age"):
		var age := int(state.get_age()) if state.has_method("get_age") else 0
		if age < int(def["min_age"]):
			var hint2 := str(def.get("unlock_hint", ""))
			if hint2 != "":
				return {"ok": false, "reason": hint2}
			return {"ok": false, "reason": "年紀還不夠（需 %d 歲）" % int(def["min_age"])}
	if def.has("max_year") and int(state.year) > int(def["max_year"]):
		return {"ok": false, "reason": "學生時期的安排，先留在相簿裡"}
	if def.has("require_romance") and int(state.get("romance")) < int(def["require_romance"]):
		var hint_rom := str(def.get("unlock_hint", ""))
		if hint_rom != "":
			return {"ok": false, "reason": hint_rom}
		return {"ok": false, "reason": "戀愛進度還淺，成家的事先放著"}

	# Soft stat floors
	for sk in ["charm", "morals", "social", "stamina", "academia", "mood"]:
		var mk := "min_%s" % sk
		if def.has(mk) and _stat_of(state, sk) < int(def[mk]):
			var hint3 := str(def.get("unlock_hint", ""))
			if hint3 != "":
				return {"ok": false, "reason": hint3}
			var label: String = STAT_LABELS.get(sk, sk)
			return {"ok": false, "reason": "%s還不夠（需 %d）" % [label, int(def[mk])]}

	# Flag required
	if def.has("require_flag"):
		var fk := str(def["require_flag"])
		if not _flag_truthy(state, fk):
			var hint4 := str(def.get("unlock_hint", ""))
			if hint4 != "":
				return {"ok": false, "reason": hint4}
			return {"ok": false, "reason": "尚未達成解鎖條件"}

	# Visit required
	if def.has("require_visit"):
		var place := str(def["require_visit"])
		var vk := "visited_%s" % place
		if not _flag_truthy(state, vk):
			var hint5 := str(def.get("unlock_hint", ""))
			if hint5 != "":
				return {"ok": false, "reason": hint5}
			var pname: String = PLACE_NAMES.get(place, place)
			return {"ok": false, "reason": "先去地圖拜訪「%s」吧" % pname}

	# Soft cash: cannot afford a costing activity
	var cash_d := int(def.get("cash", 0))
	if cash_d < 0 and int(state.cash) + cash_d < 0:
		return {"ok": false, "reason": "家計不足"}

	return {"ok": true, "reason": ""}


static func is_available(id: String, state: Node) -> bool:
	return bool(availability(id, state).get("ok", false))
