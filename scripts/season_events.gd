class_name SeasonEvents
extends RefCounted
## 四季天氣／節慶偶發事件（溫馨、成人懷舊、無露骨）
## Special trips carry media_still / media_video ids for dedicated stills + clips.

## Each event: id, season(s), title, body, sticker, deltas,
## optional media_still (assets/events/{id}.jpg), media_video (assets/videos/{id}.mp4)
const EVENTS: Array[Dictionary] = [
	# —— 春 ——
	{
		"id": "spring_sakura",
		"seasons": [0],
		"title": "櫻花微風",
		"body": "公園的老櫻樹忽然開滿了。你陪她在樹下拍照，花瓣落在肩上，像小鎮悄悄送的一封信。",
		"sticker": "spring",
		"deltas": {"social": 2, "mood": 4, "charm": 1},
	},
	{
		"id": "spring_rain",
		"seasons": [0],
		"title": "春雨午後",
		"body": "細雨把街道洗得發亮。你們分享一把傘回家，她說聽雨聲特別安心。",
		"sticker": "spring",
		"deltas": {"mood": 3, "stamina": 1, "social": 1},
	},
	{
		"id": "spring_qingming",
		"seasons": [0],
		"title": "掃墓小旅行",
		"body": "清明前後，你們回鄉下掃墓。她幫著擦碑、插花，安靜地聽你講外婆的故事。",
		"sticker": "spring",
		"deltas": {"morals": 3, "mood": 1},
	},
	{
		"id": "spring_picnic",
		"seasons": [0],
		"title": "春日野餐",
		"body": "週末帶著便當去河堤野餐。風箏線在指尖顫著，她把三明治分你一半。",
		"sticker": "spring",
		"deltas": {"mood": 4, "social": 2, "stamina": 1, "cash": -100},
	},
	# —— 夏 ——
	{
		"id": "summer_beach",
		"seasons": [1],
		"title": "夏天去海灘",
		"body": "週末驅車到近郊海灘。陽光、浪聲與防曬乳的味道——她在沙上寫下你們的名字，潮水慢慢把它們帶走。",
		"sticker": "summer",
		"media_still": "beach",
		"media_video": "event_beach",
		"deltas": {"mood": 6, "stamina": 2, "charm": 2, "social": 2, "cash": -350},
	},
	{
		"id": "summer_heat",
		"seasons": [1],
		"title": "酷熱午後",
		"body": "氣溫破表，連風扇都懶洋洋。你買了兩支冰棒，勸她少在太陽下跑跳。",
		"sticker": "summer",
		"deltas": {"stamina": -3, "mood": -1, "cash": -80},
	},
	{
		"id": "summer_typhoon",
		"seasons": [1],
		"title": "颱風警報",
		"body": "警報響起，小鎮提早關門。你們囤好電池與泡麵，聽著窗外狂風，守著一盞小燈。",
		"sticker": "summer",
		"deltas": {"stamina": -2, "mood": -2, "cash": -200},
	},
	{
		"id": "summer_festival",
		"seasons": [1],
		"title": "夏夜廟會",
		"body": "廟前掛起燈籠，空氣裡有炸雞排與煙火味。她拉著你去撈金魚，贏了一隻小小的海豹公仔。",
		"sticker": "summer",
		"deltas": {"social": 3, "charm": 1, "mood": 4, "cash": -150},
	},
	# —— 秋 ——
	{
		"id": "autumn_mountain",
		"seasons": [2],
		"title": "秋天上山旅行",
		"body": "紅葉季節，你們搭公車到近郊山徑。她把楓葉夾進手帳，說要留給十二年後的自己看。",
		"sticker": "autumn",
		"media_still": "mountain",
		"media_video": "event_mountain",
		"deltas": {"mood": 5, "stamina": 3, "social": 2, "morals": 1, "cash": -280},
	},
	{
		"id": "autumn_harvest",
		"seasons": [2],
		"title": "豐收市集",
		"body": "秋天市集擺滿柿子與地瓜。她幫忙顧攤半日，賺到一點零用，也學會跟人好好打招呼。",
		"sticker": "autumn",
		"deltas": {"cash": 300, "social": 2, "stamina": -1},
	},
	{
		"id": "autumn_typhoon",
		"seasons": [2],
		"title": "秋颱過境",
		"body": "秋颱來得急。學校停課一天，你們一起補窗戶膠條，事後去公園撿被吹落的枝葉。",
		"sticker": "autumn",
		"deltas": {"stamina": -2, "morals": 1, "mood": -1},
	},
	{
		"id": "autumn_moon",
		"seasons": [2],
		"title": "中秋賞月",
		"body": "陽台擺開柚子與月餅。她問月亮上有沒有另一個小鎮——你說，有的話，也一定有人陪著女兒看月亮。",
		"sticker": "autumn",
		"deltas": {"mood": 4, "social": 1, "cash": -120},
	},
	# —— 冬 ——
	{
		"id": "winter_festival",
		"seasons": [3],
		"title": "冬日小鎮燈會",
		"body": "文化中心前掛起溫暖的燈串。你們捧著熱可可慢慢走，她說希望每年冬天都能這樣。",
		"sticker": "winter",
		"deltas": {"mood": 5, "social": 3, "charm": 1, "cash": -180},
	},
	{
		"id": "winter_cold",
		"seasons": [3],
		"title": "寒流來襲",
		"body": "寒流把窗戶結出薄霧。你把厚外套塞進她書包，晚上一起喝熱薑茶。",
		"sticker": "winter",
		"deltas": {"stamina": -2, "mood": 1, "cash": -100},
	},
	{
		"id": "winter_gathering",
		"seasons": [3],
		"title": "寒假聚會",
		"body": "同學約在文化中心交換小禮物。她回來時臉頰紅紅的，說交到一個新朋友。",
		"sticker": "winter",
		"deltas": {"social": 4, "mood": 3, "stamina": 1},
	},
	{
		"id": "winter_newyear",
		"seasons": [3],
		"title": "年夜圍爐",
		"body": "除夕桌上多了一盤她堅持要做的沙拉。煙火在遠處開，小鎮靜靜聽著彼此的祝福。",
		"sticker": "winter",
		"deltas": {"mood": 5, "morals": 1, "social": 2, "cash": -250},
	},
]

## Soft always-available light events (any season) if pick fails
const LIGHT_FALLBACK: Dictionary = {
	"id": "quiet_weekend",
	"seasons": [0, 1, 2, 3],
	"title": "平靜週末",
	"body": "沒有大事發生。陽光、洗衣香，還有餐桌上多了一碟水果——這樣就很好。",
	"sticker": "",
	"deltas": {"mood": 2},
}


static func events_for_season(season: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in EVENTS:
		var ss: Array = e.get("seasons", [])
		if season in ss or str(season) in ss:
			out.append(e)
	return out


## chance 0.0–1.0: probability to roll a seasonal event (else light fallback or none)
## Returns event dict (never empty if use_fallback); may be LIGHT_FALLBACK
## Slightly boosts special media events so beach / mountain show up more often.
static func roll_event(season: int, rng: RandomNumberGenerator, chance: float = 0.55) -> Dictionary:
	var pool := events_for_season(season)
	if pool.is_empty():
		return LIGHT_FALLBACK.duplicate(true)
	if rng.randf() > chance:
		var light := LIGHT_FALLBACK.duplicate(true)
		light["sticker"] = GameConfig.season_key(season)
		return light
	# Weighted: media events get +1 weight
	var weights: Array[float] = []
	var total := 0.0
	for e in pool:
		var w := 2.0 if str(e.get("media_still", "")) != "" else 1.0
		weights.append(w)
		total += w
	var pick := rng.randf() * total
	var acc := 0.0
	for i in range(pool.size()):
		acc += weights[i]
		if pick <= acc:
			return pool[i].duplicate(true)
	return pool[pool.size() - 1].duplicate(true)


static func sticker_path(sticker_key: String) -> String:
	if sticker_key == "":
		return ""
	return "res://assets/weather/%s.png" % sticker_key


static func has_media(ev: Dictionary) -> bool:
	return str(ev.get("media_still", "")) != "" or str(ev.get("media_video", "")) != ""


static func resolve_media_paths(ev: Dictionary) -> Dictionary:
	## Returns {still: res path or "", video: res path or ""}
	var still_id := str(ev.get("media_still", ""))
	var video_id := str(ev.get("media_video", ""))
	return {
		"still": GameConfig.event_still_path(still_id),
		"video": GameConfig.event_video_path(video_id),
	}


static func apply_deltas_to_state(state: Node, deltas: Dictionary) -> void:
	if deltas.is_empty():
		return
	if state.has_method("_apply_delta"):
		var d := {
			"charm": int(deltas.get("charm", 0)),
			"morals": int(deltas.get("morals", 0)),
			"social": int(deltas.get("social", 0)),
			"stamina": int(deltas.get("stamina", 0)),
			"academia": int(deltas.get("academia", 0)),
			"mood": int(deltas.get("mood", 0)),
			"cash": int(deltas.get("cash", 0)),
		}
		state.call("_apply_delta", d)
		return
	for k in ["charm", "morals", "social", "stamina", "academia", "mood"]:
		if deltas.has(k) and k in state:
			state.set(k, clampi(int(state.get(k)) + int(deltas[k]), GameConfig.STAT_MIN, GameConfig.STAT_MAX))
	if deltas.has("cash") and "cash" in state:
		state.cash = int(state.cash) + int(deltas["cash"])
