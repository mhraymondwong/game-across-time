class_name MapEvents
extends RefCounted
## 地圖地點小事件（港台小鎮懷舊、成人溫馨、年齡 6–17 適宜）
## 每筆：id, place, title, body, deltas?, flag?, once?

const PLACE_IDS: Array[String] = ["home", "school", "park", "shops", "clinic", "culture"]

const EVENTS: Array[Dictionary] = [
	# —— 住家 ——
	{
		"id": "home_fridge_note",
		"place": "home",
		"title": "冰箱上的紙條",
		"body": "冰箱門上貼著學校通知與她畫的小星星。你幫她把過期的便當盒清掉，她說下次自己會記得。",
		"deltas": {"morals": 1, "mood": 2},
	},
	{
		"id": "home_rainy_window",
		"place": "home",
		"title": "雨聲窗邊",
		"body": "午後下雨，你們坐在窗邊剝橘子。她把橘子皮排成一隻小貓，說家裡聞起來最安心。",
		"deltas": {"mood": 3, "social": 1},
	},
	{
		"id": "home_laundry_day",
		"place": "home",
		"title": "曬衣午後",
		"body": "陽台曬滿衣服。她踮腳幫忙夾衣架，笑說長大後要買一台不會卡住的洗衣機。",
		"deltas": {"stamina": 1, "morals": 1, "mood": 1},
	},
	{
		"id": "home_night_story",
		"place": "home",
		"title": "睡前小故事",
		"body": "關燈前她還想聽一個短故事。你講小鎮舊戲院的傳說，她聽著睡著，手還抓著被角。",
		"deltas": {"mood": 4, "social": 1},
		"once": true,
		"flag": "home_story_told",
	},
	{
		"id": "home_quiet_morning",
		"place": "home",
		"title": "安靜早晨",
		"body": "週末醒來，廚房有粥的香味。沒有大事，只有彼此的腳步聲——這樣就很好。",
		"deltas": {"mood": 2},
	},
	# —— 學校 ——
	{
		"id": "school_banyan",
		"place": "school",
		"title": "老榕樹下",
		"body": "鐘聲過後，她在操場邊的老榕樹下等你。樹幹上還有往屆同學的鉛筆印。",
		"deltas": {"mood": 2, "social": 1},
	},
	{
		"id": "school_notice",
		"place": "school",
		"title": "佈告欄一瞥",
		"body": "佈告欄貼滿社團招募。她指著書法社說「以後也可以試試」，臉有點紅。",
		"deltas": {"academia": 1, "social": 1},
	},
	{
		"id": "school_teacher_hello",
		"place": "school",
		"title": "老師點頭",
		"body": "走廊遇見導師，對方誇她最近作業很用心。她悄悄拉你袖子，走路都輕快了。",
		"deltas": {"academia": 2, "mood": 2, "morals": 1},
		"once": true,
		"flag": "school_teacher_praise",
	},
	{
		"id": "school_library_corner",
		"place": "school",
		"title": "圖書角落",
		"body": "下課後她窩在圖書角抄筆記。陽光從百葉窗縫進來，整排字典都安靜。",
		"deltas": {"academia": 2, "stamina": -1, "mood": 1},
	},
	{
		"id": "school_after_bell",
		"place": "school",
		"title": "放學鈴聲",
		"body": "放學鈴聲一響，她背著書包跑出來，說今天小考還不錯——你先買了兩瓶豆漿。",
		"deltas": {"mood": 2, "cash": -40},
	},
	# —— 公園 ——
	{
		"id": "park_evening_walk",
		"place": "park",
		"title": "傍晚散步",
		"body": "街坊慢慢走著，她數著飛過的鳥。夕陽把長椅染成橘色，你們坐了一會兒。",
		"deltas": {"stamina": 2, "mood": 3, "social": 1},
	},
	{
		"id": "park_swing",
		"place": "park",
		"title": "鞦韆輕輕",
		"body": "她坐上鞦韆，要你輕輕推。風把髮絲吹開，她說公園的味道每年都不太一樣。",
		"deltas": {"mood": 3, "charm": 1},
	},
	{
		"id": "park_fallen_leaf",
		"place": "park",
		"title": "落葉一枚",
		"body": "她撿起一片漂亮的葉子，夾進手帳。說要留給以後的自己看，記得今天的風。",
		"deltas": {"mood": 2, "morals": 1},
		"once": true,
		"flag": "park_leaf_kept",
	},
	{
		"id": "park_neighbor_dog",
		"place": "park",
		"title": "鄰居的狗",
		"body": "隔壁王媽媽牽著小狗經過。她蹲下來打招呼，小狗把鼻子湊到她手心。",
		"deltas": {"social": 2, "mood": 2},
	},
	{
		"id": "park_quiet_bench",
		"place": "park",
		"title": "長椅閒聊",
		"body": "沒有特別的話題。你們並肩坐著，看遠方電車開過——有時候陪伴本身就夠了。",
		"deltas": {"mood": 2, "social": 1},
	},
	# —— 商店街 ——
	{
		"id": "shops_bakery",
		"place": "shops",
		"title": "麵包香",
		"body": "麵包店剛出爐。她選了菠蘿包，你買了雜糧吐司。老闆多給了一塊小麵包。",
		"deltas": {"mood": 2, "cash": -80, "stamina": 1},
	},
	{
		"id": "shops_stationery",
		"place": "shops",
		"title": "文具小物",
		"body": "文具行裡她猶豫很久，最後選了一支粉紅原子筆。說要用它寫認真的日記。",
		"deltas": {"academia": 1, "charm": 1, "cash": -60},
	},
	{
		"id": "shops_window_look",
		"place": "shops",
		"title": "櫥窗一望",
		"body": "制服店櫥窗換了季節款。她看了一眼又趕緊移開視線，耳朵有點紅。",
		"deltas": {"charm": 1, "mood": 1},
	},
	{
		"id": "shops_help_carry",
		"place": "shops",
		"title": "幫忙提袋",
		"body": "阿婆買菜太多，她主動幫忙提到巷口。阿婆塞給她一顆蘋果，說乖孩子。",
		"deltas": {"morals": 2, "social": 1, "mood": 1},
		"once": true,
		"flag": "shops_helped_granny",
	},
	{
		"id": "shops_weekend_crowd",
		"place": "shops",
		"title": "週末人潮",
		"body": "週末商店街擠滿人。她緊緊牽著你，說熱鬧是熱鬧，還是家裡比較能喘口氣。",
		"deltas": {"social": 1, "stamina": -1, "mood": 1},
	},
	# —— 診所 ——
	{
		"id": "clinic_checkup",
		"place": "clinic",
		"title": "例行檢查",
		"body": "王醫師聽完心跳，說長得結實。她拿到一顆糖，走出門時還在數脈搏玩。",
		"deltas": {"stamina": 2, "mood": 1, "cash": -150},
	},
	{
		"id": "clinic_waiting",
		"place": "clinic",
		"title": "候診閒坐",
		"body": "候診區有人看報紙。她安靜翻兒童繪本，偶爾抬眼看你，像在確認你還在。",
		"deltas": {"mood": 1, "morals": 1},
	},
	{
		"id": "clinic_height",
		"place": "clinic",
		"title": "量身高",
		"body": "身高尺旁她踮了一下腳又乖乖站直。醫師笑說又高了一點，你把數字記在手帳。",
		"deltas": {"stamina": 1, "mood": 2},
		"once": true,
		"flag": "clinic_height_noted",
	},
	{
		"id": "clinic_advice",
		"place": "clinic",
		"title": "少喝冰的",
		"body": "醫師叮嚀夏天少喝冰的。回家路上她還是看了冰店一眼，最後選了溫熱豆漿。",
		"deltas": {"stamina": 1, "morals": 1, "cash": -30},
	},
	{
		"id": "clinic_quiet_hall",
		"place": "clinic",
		"title": "走廊消毒水",
		"body": "診所走廊有淡淡消毒水味。她說這裡讓人覺得小鎮有人照顧著大家，很安心。",
		"deltas": {"mood": 2, "social": 1},
	},
	# —— 文化中心 ——
	{
		"id": "culture_library",
		"place": "culture",
		"title": "圖書館午後",
		"body": "圖書館很安靜。她借了兩本故事書，封面還有別人留下的借閱章。",
		"deltas": {"academia": 2, "mood": 2},
	},
	{
		"id": "culture_poster",
		"place": "culture",
		"title": "社團海報",
		"body": "大廳貼著社區課程海報：素描、合唱、志工。她用手指描過標題，說以後想試試。",
		"deltas": {"charm": 1, "social": 1, "academia": 1},
	},
	{
		"id": "culture_small_stage",
		"place": "culture",
		"title": "小劇場彩排",
		"body": "小劇場正在彩排。隔著門縫聽到鋼琴聲，她聽得入神，後來輕輕跟著哼。",
		"deltas": {"charm": 2, "mood": 2},
		"once": true,
		"flag": "culture_heard_rehearsal",
	},
	{
		"id": "culture_volunteer_board",
		"place": "culture",
		"title": "志工欄",
		"body": "志工欄徵人幫忙整理舊書。她說有空可以來——你點頭，把電話記在手帳角。",
		"deltas": {"morals": 2, "social": 1},
	},
	{
		"id": "culture_sunset_steps",
		"place": "culture",
		"title": "台階看夕陽",
		"body": "文化中心台階被夕陽照暖。你們坐著看飛鳥回家，她說這裡像小鎮的客廳。",
		"deltas": {"mood": 3, "social": 1},
	},
]


static func events_for_place(place_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in EVENTS:
		if str(e.get("place", "")) == place_id:
			out.append(e)
	return out


static func place_ids_covered() -> Array[String]:
	var seen: Dictionary = {}
	for e in EVENTS:
		seen[str(e.get("place", ""))] = true
	var out: Array[String] = []
	for id in PLACE_IDS:
		if seen.has(id):
			out.append(id)
	return out


## Prefer unused once-events; else random from remaining pool.
static func pick_event(place_id: String, flags: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var pool := events_for_place(place_id)
	if pool.is_empty():
		return {
			"id": "empty_%s" % place_id,
			"place": place_id,
			"title": "平靜一角",
			"body": "這裡今天很安靜。你們站了一會兒，然後繼續往前走。",
			"deltas": {"mood": 1},
		}
	var once_fresh: Array[Dictionary] = []
	var flavor: Array[Dictionary] = []
	for e in pool:
		var is_once := bool(e.get("once", false))
		var flag_key := str(e.get("flag", e.get("id", "")))
		if is_once:
			if not flags.get(flag_key, false):
				once_fresh.append(e)
		else:
			flavor.append(e)
	var chosen: Dictionary
	if not once_fresh.is_empty() and rng.randf() < 0.45:
		chosen = once_fresh[rng.randi_range(0, once_fresh.size() - 1)]
	elif not flavor.is_empty():
		chosen = flavor[rng.randi_range(0, flavor.size() - 1)]
	elif not once_fresh.is_empty():
		chosen = once_fresh[rng.randi_range(0, once_fresh.size() - 1)]
	else:
		chosen = pool[rng.randi_range(0, pool.size() - 1)]
	return chosen.duplicate(true)


static func format_delta_line(deltas: Dictionary) -> String:
	if deltas.is_empty():
		return ""
	var labels := {
		"charm": "魅力", "morals": "道德", "social": "人際",
		"stamina": "體力", "academia": "學識", "mood": "心情", "cash": "家計",
	}
	var parts: PackedStringArray = []
	for k in ["charm", "morals", "social", "stamina", "academia", "mood", "cash"]:
		if not deltas.has(k):
			continue
		var v := int(deltas[k])
		if v == 0:
			continue
		var name: String = labels.get(k, k)
		if k == "cash":
			parts.append("%s %s$%d" % [name, "＋" if v > 0 else "－", abs(v)])
		else:
			parts.append("%s %s%d" % [name, "＋" if v > 0 else "", v])
	if parts.is_empty():
		return ""
	return "（" + "　".join(parts) + "）"
