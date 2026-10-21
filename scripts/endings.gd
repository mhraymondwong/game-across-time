class_name Endings
extends RefCounted
## 結局定義（原創名稱，約 10 條路線）


static func all() -> Array:
	return [
		{"id": "burnout", "name": "喘不過氣的日子", "priority": 100,
			"summary": "十二年走得好累。她仍被你愛著，但需要好好休息，重新找回步伐。"},
		{"id": "doctor", "name": "社區診所的白袍", "priority": 90,
			"summary": "她通過考試，回到小鎮診所實習。街坊叫她「小醫生」，你坐在候診椅上，驕傲得說不出話。"},
		{"id": "teacher", "name": "溫柔的黑板燈", "priority": 88,
			"summary": "她成為小學老師。放學後教室還亮著燈，她在改作業，你送來熱湯。"},
		{"id": "designer", "name": "紙上的光與影", "priority": 85,
			"summary": "她做獨立設計師，接小鎮店招與書籍封面。工作桌上貼滿你收藏的她的塗鴉。"},
		{"id": "cafe_owner", "name": "街角那杯溫度", "priority": 82,
			"summary": "她開了一間小小咖啡店。你每天固定坐靠窗位，她假裝不認識你，卻總多加一塊蛋糕。"},
		{"id": "civil", "name": "市政廳的穩步", "priority": 80,
			"summary": "她通過公職，在區公所服務街坊。說話溫和、做事牢靠——像你一直希望的那樣。"},
		{"id": "coach", "name": "操場上的哨音", "priority": 78,
			"summary": "她成為運動教練，帶小孩跑步、打球。夕陽下的操場，有她的笑聲，也有你的掌聲。"},
		{"id": "writer", "name": "寫進時光的句子", "priority": 76,
			"summary": "她出版了第一本散文集，寫小鎮、四季，與一位不太會說「我愛你」的父親。"},
		{"id": "caregiver", "name": "家裡的燈一直亮", "priority": 70,
			"summary": "她選擇留在身邊照顧家人與鄰居。日子平凡，卻沒有遺憾。"},
		{"id": "wanderer", "name": "行李裡的地圖", "priority": 65,
			"summary": "她收拾背包去遠方追夢，約定每個季節寄一張明信片回來。你把明信片貼滿廚房牆。"},
		{"id": "town_bond", "name": "被記住的名字", "priority": 20,
			"summary": "她沒有急著遠走。小鎮裡有人叫得出她的名字，十二年就這樣變得具體。"},
		{"id": "ordinary_happy", "name": "普通而確實的幸福", "priority": 10,
			"summary": "沒有轟轟烈烈的頭銜。她有工作、有朋友、有你。十二年，夠了。"},
	]


static func evaluate(state: Node) -> Dictionary:
	var list := all()
	list.sort_custom(func(a, b): return int(a["priority"]) > int(b["priority"]))
	for e in list:
		if _matches(str(e["id"]), state):
			var chosen: Dictionary = (e as Dictionary).duplicate(true)
			if str(chosen.get("id", "")) == "town_bond":
				chosen["summary"] = TownNpcs.ending_summary(state)
			else:
				var aside := TownNpcs.ending_aside(state)
				if aside != "":
					chosen["summary"] = str(chosen.get("summary", "")) + aside
			return chosen
	return list[-1]


static func _matches(id: String, s: Node) -> bool:
	match id:
		"burnout":
			return int(s.stamina) < 20 or int(s.mood) < 20
		"doctor":
			return int(s.academia) >= 70 and int(s.morals) >= 55 and int(s.stamina) >= 45
		"teacher":
			return int(s.academia) >= 55 and int(s.social) >= 55 and int(s.morals) >= 50
		"designer":
			return int(s.charm) >= 65 and int(s.academia) >= 45
		"cafe_owner":
			return int(s.social) >= 55 and int(s.charm) >= 50 and int(s.cash) >= 5000
		"civil":
			return int(s.morals) >= 60 and int(s.academia) >= 50 and int(s.social) >= 40
		"coach":
			return int(s.stamina) >= 70 and int(s.social) >= 50
		"writer":
			return int(s.academia) >= 60 and int(s.charm) >= 45 and int(s.morals) >= 40
		"caregiver":
			return int(s.morals) >= 65 and int(s.social) >= 45
		"wanderer":
			return int(s.charm) >= 50 and int(s.stamina) >= 50 and int(s.social) >= 40 and int(s.cash) >= 3000
		"town_bond":
			var top := TownNpcs.highest(s)
			return int(top.get("value", 0)) >= 68 and int(s.mood) >= 30 and int(s.stamina) >= 25
		"ordinary_happy":
			return true
		_:
			return false
