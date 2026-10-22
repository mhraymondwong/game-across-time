class_name Confide
extends RefCounted
## 她偶爾對爸爸說一句。傾訴心事，或撒個嗲。
## 每季最多一次，教學沒關、媽媽這季在家或已幫過忙時不出現。
## 旗標都放在 GameState.flags，隨存檔走。

const CONFIDE_CHANCE := 0.22

const LINES: Array = [
	{
		"id": "child_worry_seat",
		"band": "child",
		"tone": "worry",
		"kicker": "傾訴心事",
		"body": "%s拉了拉你的袖子，聲音很小：「今天位子旁邊空空的。同學說，不想跟我一組。」",
		"options": [
			{
				"label": "爸爸坐到你旁邊",
				"reply": "你在地板上挨著%s坐下。她把事情又講了一遍，這次順一點。",
				"deltas": {"mood": 4, "social": 1},
				"warmth": 1,
			},
			{
				"label": "我們慢慢找別的朋友",
				"reply": "你說，一個人不想一組，不代表你不好。她點點頭，把書包帶抓緊。",
				"deltas": {"social": 2, "morals": 1},
				"warmth": 1,
			},
			{
				"label": "先吃點熱的",
				"reply": "你熱了牛奶。她捧著杯子，話比較願意出來。",
				"deltas": {"mood": 3, "stamina": 1},
				"warmth": 0,
			},
		],
	},
	{
		"id": "child_worry_candy",
		"band": "child",
		"tone": "worry",
		"kicker": "傾訴心事",
		"body": "%s把一顆糖握到發黏：「我分給同學，可是他沒有分回來。」",
		"options": [
			{
				"label": "分享不是交換",
				"reply": "你說，你願意分，是因為你喜歡。她把糖紙疊好，放進口袋。",
				"deltas": {"morals": 2, "mood": 2},
				"warmth": 1,
			},
			{
				"label": "爸爸也分你一顆",
				"reply": "你從罐子裡拿出另一顆。她笑了一下，靠過來。",
				"deltas": {"mood": 4},
				"warmth": 1,
			},
			{
				"label": "明天再說也行",
				"reply": "你沒有急著教她。她靠在你手臂上，呼吸慢下來。",
				"deltas": {"mood": 3, "social": 1},
				"warmth": 0,
			},
		],
	},
	{
		"id": "child_worry_homework",
		"band": "child",
		"tone": "worry",
		"kicker": "傾訴心事",
		"body": "「這一題我不會。」%s把本子推過來，耳朵都紅了。「會不會被老師說。」",
		"options": [
			{
				"label": "我們一起看十分鐘",
				"reply": "你指著題目，一步一步。她自己寫出最後一行，眼睛亮了。",
				"deltas": {"mood": 3, "morals": 1},
				"warmth": 1,
			},
			{
				"label": "不會也沒關係",
				"reply": "你說，不會可以問，問了就不可怕。她把橡皮屑吹掉。",
				"deltas": {"mood": 4, "social": 1},
				"warmth": 0,
			},
			{
				"label": "休息一下再寫",
				"reply": "你們去倒了杯水。她回來的時候，字寫得比較穩。",
				"deltas": {"stamina": 2, "mood": 2},
				"warmth": 1,
			},
		],
	},
	{
		"id": "child_cling_hug",
		"band": "child",
		"tone": "cling",
		"kicker": "撒嗲",
		"body": "%s張開手：「爸爸，抱一下。就一下。媽媽說你可以。」",
		"options": [
			{
				"label": "抱緊一點",
				"reply": "你把她抱起來，轉了小半圈。她在你肩上笑出聲。",
				"deltas": {"mood": 5},
				"warmth": 1,
			},
			{
				"label": "抱著走到沙發",
				"reply": "你們一起陷進沙發。她數你的心跳，數到十就夠了。",
				"deltas": {"mood": 4, "stamina": 1},
				"warmth": 1,
			},
			{
				"label": "媽媽也一起來",
				"reply": "你朝廚房喊了一聲。三個人擠成一小團，誰都沒有先鬆手。",
				"deltas": {"mood": 4, "social": 1},
				"warmth": 1,
			},
		],
	},
	{
		"id": "child_cling_snack",
		"band": "child",
		"tone": "cling",
		"kicker": "撒嗲",
		"body": "%s踮腳看著櫃子：「我想吃餅乾。小小一塊。求求你。」",
		"options": [
			{
				"label": "小小一塊",
				"reply": "你掰了一小塊。她吃得很慢，像在把這件事拉長。",
				"deltas": {"mood": 3},
				"warmth": 1,
			},
			{
				"label": "飯後再吃",
				"reply": "你說，先吃飯，餅乾當結尾。她扁了扁嘴，還是點頭。",
				"deltas": {"morals": 1, "mood": 2},
				"warmth": 0,
			},
			{
				"label": "我們一起排盤子",
				"reply": "你們把餅乾排在盤子上。她專心拍好，然後第一塊給你。",
				"deltas": {"social": 1, "mood": 3},
				"warmth": 1,
			},
		],
	},
	{
		"id": "child_cling_home",
		"band": "child",
		"tone": "cling",
		"kicker": "撒嗲",
		"body": "「今天可以不要出門嗎？」%s抓住你的衣角。「我想待在家，跟你，跟媽媽。」",
		"options": [
			{
				"label": "今天就留在家",
				"reply": "你把外出的計畫摺起來。她光著腳在客廳跑了一圈。",
				"deltas": {"mood": 4, "stamina": 1},
				"warmth": 1,
			},
			{
				"label": "只去巷口再回來",
				"reply": "你們走到巷口的樹，再走回來。她說這樣也算出門了。",
				"deltas": {"stamina": 2, "social": 1, "mood": 2},
				"warmth": 0,
			},
			{
				"label": "在家幫媽媽",
				"reply": "她跟著媽媽摘菜。你在旁邊洗杯子，家裡很吵，也很暖。",
				"deltas": {"morals": 1, "mood": 3},
				"warmth": 1,
			},
		],
	},
	{
		"id": "teen_worry_group",
		"band": "teen",
		"tone": "worry",
		"kicker": "傾訴心事",
		"body": "%s看著手機，又把螢幕按暗：「群組裡好像在聊，沒有人找我。」",
		"options": [
			{
				"label": "我在這裡",
				"reply": "你沒有追問群組裡說了什麼。她把手機扣在桌上，肩膀鬆了一點。",
				"deltas": {"mood": 4, "social": 1},
				"warmth": 1,
			},
			{
				"label": "安靜不一定是被落下",
				"reply": "你說，真正會找她的人，不會只活在那個群組裡。她把椅子拉近一點。",
				"deltas": {"social": 2, "mood": 2},
				"warmth": 0,
			},
			{
				"label": "要不要跟媽媽說",
				"reply": "她想了想，點頭。廚房的燈還亮著。",
				"deltas": {"mood": 3, "morals": 1},
				"warmth": 1,
			},
		],
	},
	{
		"id": "teen_worry_quiet",
		"band": "teen",
		"tone": "worry",
		"kicker": "傾訴心事",
		"body": "「我今天不太想說話。」%s把書包放下，人還站在玄關。「你可以就坐在旁邊嗎。」",
		"options": [
			{
				"label": "我就坐著",
				"reply": "你坐在旁邊，沒有開話題。過了一會兒，她自己倒了兩杯水。",
				"deltas": {"mood": 4},
				"warmth": 1,
			},
			{
				"label": "想說的時候再說",
				"reply": "你說，門開著。她點頭，進房間前看了你一眼。",
				"deltas": {"mood": 3, "social": 1},
				"warmth": 0,
			},
			{
				"label": "我去熱碗湯",
				"reply": "你沒有問原因。湯端來的時候，她說了謝謝，聲音很小。",
				"deltas": {"stamina": 1, "mood": 3},
				"warmth": 1,
			},
		],
	},
	{
		"id": "teen_worry_sleep",
		"band": "teen",
		"tone": "worry",
		"kicker": "傾訴心事",
		"body": "%s揉著眼睛：「我有點睡不著。不是因為功課。就是……腦子不肯停。」",
		"options": [
			{
				"label": "今晚不必把明天想完",
				"reply": "你說，明天的事明天再放進行程。她把鬧鐘往後挪了十分鐘。",
				"deltas": {"mood": 4, "stamina": 2},
				"warmth": 1,
			},
			{
				"label": "出去走一小段",
				"reply": "夜風很涼。走回門口時，她說腦子安靜一點了。",
				"deltas": {"stamina": 2, "mood": 2},
				"warmth": 0,
			},
			{
				"label": "我陪你坐到睏",
				"reply": "客廳只留一盞燈。她靠著椅背，呼吸慢慢變長。",
				"deltas": {"mood": 3, "morals": 1},
				"warmth": 1,
			},
		],
	},
	{
		"id": "teen_cling_noodle",
		"band": "teen",
		"tone": "cling",
		"kicker": "撒嗲",
		"body": "%s靠在門框上：「爸，我想吃你煮的麵。媽媽的也很好，可是今天想吃你的。」",
		"options": [
			{
				"label": "我現在下麵",
				"reply": "你把麵煮軟一點，照她小時候的習慣。她吃完整碗，把碗推回來。",
				"deltas": {"mood": 4, "stamina": 1},
				"warmth": 1,
			},
			{
				"label": "三個人一起吃",
				"reply": "你多煮了一人份。媽媽也坐下來，桌子一下子就滿了。",
				"deltas": {"social": 2, "mood": 3},
				"warmth": 1,
			},
			{
				"label": "你來打下手",
				"reply": "她切蔥切得很慢。你沒有接手。兩個人把麵端上桌。",
				"deltas": {"morals": 1, "mood": 3},
				"warmth": 0,
			},
		],
	},
	{
		"id": "teen_cling_lean",
		"band": "teen",
		"tone": "cling",
		"kicker": "撒嗲",
		"body": "%s在沙發上挪了挪，肩膀輕輕靠過來：「借我靠一下。就一下，別笑我。」",
		"options": [
			{
				"label": "靠著吧",
				"reply": "你讓她靠穩。電視的聲音很小，誰都沒有換台。",
				"deltas": {"mood": 4},
				"warmth": 1,
			},
			{
				"label": "爸爸也靠一下",
				"reply": "你靠回去，兩個人都笑了。她說這樣很幼稚，可是沒有坐開。",
				"deltas": {"mood": 5, "social": 1},
				"warmth": 1,
			},
			{
				"label": "去叫媽媽一起",
				"reply": "三個人擠在同一張沙發。她說再靠一下就去寫作業。",
				"deltas": {"mood": 3, "social": 1},
				"warmth": 1,
			},
		],
	},
	{
		"id": "teen_cling_weekend",
		"band": "teen",
		"tone": "cling",
		"kicker": "撒嗲",
		"body": "「這個週末可以不要排滿嗎？」%s看著手帳。「我想留在家裡。不是偷懶，是想跟你們待著。」",
		"options": [
			{
				"label": "週末留白",
				"reply": "你在手帳上畫了一個小空白。她看著那一格，說這樣就好。",
				"deltas": {"mood": 4, "morals": 1},
				"warmth": 1,
			},
			{
				"label": "只留一件輕鬆的",
				"reply": "你們約了公園散步，其他先空著。她說可以。",
				"deltas": {"stamina": 2, "mood": 2},
				"warmth": 0,
			},
			{
				"label": "在家做一頓飯",
				"reply": "她負責擺碗。媽媽煮湯，你洗碗。週末就這樣過完。",
				"deltas": {"social": 1, "mood": 3},
				"warmth": 1,
			},
		],
	},
	{
		"id": "adult_worry_late",
		"band": "adult",
		"tone": "worry",
		"kicker": "想跟你說",
		"body": "%s把外套掛好，聲音有點乾：「今天的班有點長。不是不想回來，是回來的時候已經不太會說話。」",
		"options": [
			{
				"label": "先坐下，不用報告",
				"reply": "你把熱茶推過去。她握了一會兒，才把今天的事說成很短的幾句。",
				"deltas": {"mood": 4, "stamina": 1},
				"warmth": 1,
			},
			{
				"label": "明天的班我們看一看",
				"reply": "你們把手帳翻開。她說不是要你排，只是想有人一起看。",
				"deltas": {"morals": 1, "mood": 2},
				"warmth": 1,
			},
			{
				"label": "我去熱飯",
				"reply": "飯是中午剩下的。她吃得很慢，說這樣就夠了。",
				"deltas": {"stamina": 2, "mood": 3},
				"warmth": 0,
			},
		],
	},
	{
		"id": "adult_worry_someone",
		"band": "adult",
		"tone": "worry",
		"kicker": "想跟你說",
		"body": "「有一個人。」%s看著自己的杯子，沒有說名字。「我不知道要不要讓這件事變大。變大了，家裡會不會不一樣。」",
		"options": [
			{
				"label": "家還是家",
				"reply": "你說，多一個人也好，沒有也好，這張桌子都在。她點頭，把杯子轉正。",
				"deltas": {"mood": 4, "morals": 1},
				"warmth": 1,
			},
			{
				"label": "你自己的步伐",
				"reply": "你說，想靠近就靠近，想慢就慢。她說她聽見了。",
				"deltas": {"social": 1, "mood": 3},
				"warmth": 1,
			},
			{
				"label": "想說的時候再說",
				"reply": "你沒有問是誰。她把沒說完的話留到以後，肩膀鬆了一點。",
				"deltas": {"mood": 3},
				"warmth": 0,
			},
		],
	},
	{
		"id": "adult_cling_dinner",
		"band": "adult",
		"tone": "cling",
		"kicker": "留在家裡",
		"body": "%s在玄關換鞋，忽然問：「今晚可以都留在家嗎？不是小時候那樣，就是想跟你們吃飯。」",
		"options": [
			{
				"label": "今晚不外出",
				"reply": "你把外套放回鉤上。三個人的碗，還是老位子。",
				"deltas": {"mood": 4, "social": 1},
				"warmth": 1,
			},
			{
				"label": "你來決定菜",
				"reply": "她挑了最家常的那一道。媽媽說好，你負責洗碗。",
				"deltas": {"mood": 3, "morals": 1},
				"warmth": 1,
			},
			{
				"label": "吃完再散散步",
				"reply": "飯後你們走到巷口就回頭。她說這樣的長度剛好。",
				"deltas": {"stamina": 2, "mood": 2},
				"warmth": 0,
			},
		],
	},
	{
		"id": "adult_cling_quiet",
		"band": "adult",
		"tone": "cling",
		"kicker": "留在家裡",
		"body": "「借我安靜一下。」%s坐到你旁邊，沒有靠得很近。「成年以後好像比較少這樣。可是今天想。」",
		"options": [
			{
				"label": "這裡一直有位子",
				"reply": "你沒有開電視。兩個人聽了一會兒時鐘。她說夠了，去洗碗。",
				"deltas": {"mood": 4},
				"warmth": 1,
			},
			{
				"label": "爸爸也坐一下",
				"reply": "你在她另一側坐下。誰都沒有把這件事說成撒嬌，可是很暖。",
				"deltas": {"mood": 5, "social": 1},
				"warmth": 1,
			},
			{
				"label": "想說話再叫我",
				"reply": "你去廚房把水燒上。她後來端著杯子過來說，這樣就好。",
				"deltas": {"mood": 3, "stamina": 1},
				"warmth": 0,
			},
		],
	},
]


static func _season_tag(state) -> String:
	return "%d_%d" % [int(state.year), int(state.season)]


static func _named(state, text: String) -> String:
	return Mom._named(state, text)


static func get_line(id: String) -> Dictionary:
	for line in LINES:
		if str(line.get("id", "")) == id:
			return line
	return {}


static func _pool(band: String, tone: String) -> Array:
	var out: Array = []
	for line in LINES:
		if str(line.get("band", "")) == band and str(line.get("tone", "")) == tone:
			out.append(line)
	return out


static func pick_line(state, rng: RandomNumberGenerator) -> Dictionary:
	var band := "child"
	if GameConfig.is_adult_year(int(state.year)):
		band = "adult"
	elif int(state.year) > 6:
		band = "teen"
	var tone := "worry" if rng.randf() < 0.5 else "cling"
	var pool := _pool(band, tone)
	if pool.is_empty():
		pool = _pool(band, "cling" if tone == "worry" else "worry")
	if pool.is_empty():
		return {}
	return pool[rng.randi() % pool.size()]


static func present_line(state, line: Dictionary) -> Dictionary:
	var opts: Array = []
	var raw = line.get("options", [])
	if typeof(raw) == TYPE_ARRAY:
		for opt in raw:
			if typeof(opt) != TYPE_DICTIONARY:
				continue
			opts.append({"label": str(opt.get("label", ""))})
	return {
		"id": str(line.get("id", "")),
		"tone": str(line.get("tone", "")),
		"kicker": str(line.get("kicker", "")),
		"body": _named(state, str(line.get("body", ""))),
		"options": opts,
	}


static func can_offer(state) -> bool:
	if int(state.year) == 1 and int(state.season) == 0 and int(state.months_played) == 0:
		if not bool(state.flags.get("tutorial_done", false)):
			return false
	if Mom.is_present(state):
		return false
	if Mom.helped_this_season(state):
		return false
	return true


## Empty dict means she stays quiet this visit.
static func offer_for(state, rng: RandomNumberGenerator) -> Dictionary:
	if not can_offer(state):
		return {}
	var tag := _season_tag(state)
	if bool(state.flags.get("confide_done_%s" % tag, false)):
		return {}
	var pending_id := str(state.flags.get("confide_pending_%s" % tag, ""))
	if pending_id != "":
		var pending := get_line(pending_id)
		if not pending.is_empty():
			return present_line(state, pending)
	if bool(state.flags.get("confide_rolled_%s" % tag, false)):
		return {}
	state.flags["confide_rolled_%s" % tag] = true
	if rng.randf() >= CONFIDE_CHANCE:
		return {}
	var line := pick_line(state, rng)
	if line.is_empty():
		return {}
	var picked := str(line.get("id", ""))
	state.flags["confide_pending_%s" % tag] = picked
	state.flags["confide_last_id"] = picked
	return present_line(state, line)


static func apply_choice(state, id: String, index: int) -> Dictionary:
	var fail := {"ok": false, "reply": "", "deltas": {}, "warmth": 0, "tone": ""}
	var line := get_line(id)
	if line.is_empty():
		return fail
	var tag := _season_tag(state)
	if bool(state.flags.get("confide_done_%s" % tag, false)):
		return fail
	var raw = line.get("options", [])
	if typeof(raw) != TYPE_ARRAY or index < 0 or index >= raw.size():
		return fail
	if typeof(raw[index]) != TYPE_DICTIONARY:
		return fail
	var opt: Dictionary = raw[index]
	var deltas: Dictionary = {}
	var raw_deltas = opt.get("deltas", {})
	if typeof(raw_deltas) == TYPE_DICTIONARY:
		deltas = raw_deltas.duplicate()
	state.flags["confide_done_%s" % tag] = true
	state.flags.erase("confide_pending_%s" % tag)
	state.flags["confide_count"] = int(state.flags.get("confide_count", 0)) + 1
	state.flags["confide_last_id"] = id
	if not deltas.is_empty():
		state.apply_map_event_delta(deltas)
	var bump := int(opt.get("warmth", 0))
	var current := 70
	if state.flags.has("mom_warmth"):
		current = int(state.flags.get("mom_warmth", 70))
	state.flags["mom_warmth"] = clampi(current + bump, 0, 100)
	return {
		"ok": true,
		"reply": _named(state, str(opt.get("reply", ""))),
		"deltas": deltas,
		"warmth": bump,
		"tone": str(line.get("tone", "")),
	}
