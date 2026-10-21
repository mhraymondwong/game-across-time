class_name ActivityScenes
extends RefCounted
## 活動小過場文案（依活動 id）。結算時由 GameState 抄進 last_vignettes。
## 文字優先；sticker 用既有天氣貼圖，still 可選 assets/events 的 media id。

const BY_ID := {
	"study_tutoring": {
		"title": "補習班的燈",
		"body": "放學後的補習班還亮著日光燈。她把錯題抄進小本子，你在樓下麵包店等，豆漿涼了又熱。出校門時她說這題終於懂了，聲音有點啞，卻很亮。",
	},
	"study_library": {
		"title": "圖書館的午後",
		"body": "圖書館很安靜，只有翻頁聲。她挑了靠窗的位子，把鉛筆削得整整齊齊。你坐在稍遠的椅子上，偶爾對上她抬起的眼睛。回家路上她說，今天的安靜很好聽。",
	},
	"study_arts": {
		"title": "才藝課的音",
		"notable": true,
		"body": "琴房的門關不嚴，一段還不成調的旋律漏出來。老師說她的指法比上個月穩。下課她把樂譜捲好，問你有沒有聽見最後那一小節。你說有，像小鎮黃昏的風。",
	},
	"work_cafe": {
		"title": "咖啡店的第一班",
		"notable": true,
		"body": "街角咖啡店讓她繫上圍裙。拿鐵拉花拉成一顆歪掉的心，客人還是笑著收下。收工時老闆塞給她一顆糖，說新手都會手忙腳亂。你在門口看見她把糖紙折得方方正正。",
	},
	"work_store": {
		"title": "便利店夜燈",
		"body": "便利店的燈白得發亮，她在收銀機後練習找零。街坊來買熱茶，她會多問一句要不要吸管。收班時她揉著手腕，說腿有點酸，口袋裡的工時單卻讓她把背挺直。",
	},
	"work_tutor": {
		"title": "家教的小桌子",
		"body": "鄰居小孩把練習簿攤在餐桌。她放慢聲音講同一題，講到第三遍，對方的眼睛才亮起來。你在廚房把水果洗好，聽見她說沒關係，我們再來一次。那語氣，很像某個人。",
	},
	"social_friends": {
		"title": "週末的同學",
		"notable": true,
		"body": "她約了同學在商店街碰面，人手一支甜筒。你保持一段不遠不近的距離，讓她們自己說話、自己笑。回家她還在講今天誰說了冷笑話，語氣輕快得像剛吹乾的頭髮。",
	},
	"social_club": {
		"title": "社團散場",
		"body": "社團拖到路燈亮起。她幫忙收椅子，袖口沾了一點海報顏料。有人說下次還要她來。你接過書包，她說自己好像有了一個固定會等她的位子。",
	},
	"social_neighbor": {
		"title": "巷口的問候",
		"body": "她抱著一疊信件送到樓梯口。巷口的長輩留她吃一顆話梅，問她最近睡得好不好。你們在鐵門前站了一會兒，聽巷子裡的電視聲。她說，被人記得名字的感覺，暖暖的。",
	},
	"rest_park": {
		"title": "公園的風",
		"body": "你們沿著老榕樹走了一圈。她數長椅、數鴿子，最後在鞦韆上坐了很短的一會兒。風把髮絲吹到嘴角，她沒有急著撥開。你覺得這個月要學的，也許就是把呼吸放慢。",
	},
	"rest_sleep": {
		"title": "在家的空白頁",
		"body": "這個月沒有往外衝。她睡到自然醒，下午窩在沙發上看舊漫畫，晚上幫忙收衣服。你把熱湯端上桌時，她問這樣的日子也要記下來嗎。你說要。平靜也是一種長大。",
	},
	"rest_trip": {
		"title": "短途的車票",
		"notable": true,
		"body": "你們搭區間車到兩站外，沒有名勝，只有一條河和一間賣蛋餅的店。她在橋上拍了一張糊掉的照片，說糊掉也沒關係，反正人是清楚的。回程她靠窗打盹，車票還夾在指間。",
	},
	"virtue_volunteer": {
		"title": "志工的手套",
		"body": "社區清掃日，她戴上大一號的手套去撿落葉。有人遞水，有人教她把垃圾袋綁緊。廣場乾淨了一角，她看著自己的鞋子，說髒了但是值得。你幫她拍掉袖口的灰。",
	},
	"virtue_recycle": {
		"title": "回收站的紙箱",
		"body": "巷口堆著壓扁的紙箱。她跟街坊把玻璃瓶、鋁罐分開，小推車一路吱呀到回收站。叔叔說她分得很仔細。回家她把手洗得很乾淨，說這些瓶子還可以再出發。",
	},
	"school_garden": {
		"title": "花圃的澆水",
		"body": "校園花圃的泥土還帶著潮氣。她提著小水壺一株一株澆，又捏掉幾根剛冒出來的雜草。同學說這棵番茄算她的。你接過沾土的手套，她說還沒紅，可是已經在努力。",
	},
	"school_library_helper": {
		"title": "圖書館的小義工",
		"notable": true,
		"body": "她把繪本依顏色送回矮架，又蹲下去把一本攤開的書合好。更小的孩子拉她袖口，要再聽一次兔子搬家。你在門口等，聽見她把聲音放得很輕。出校門她說，書回到原來的位子，人也比較定。",
	},
	"school_class_helper": {
		"title": "放學後的黑板",
		"body": "鐘聲響過，她留下擦黑板，把簿子依座號發好。粉筆灰沾在袖口，她拍一拍，又把歪掉的椅子推正。老師說謝謝小幫手。你在校門口接她，她把這句話又說了一遍，像口袋裡多了一顆糖。",
	},
	"festival_helper": {
		"title": "園遊會的彩帶",
		"notable": true,
		"body": "廟會廣場掛滿燈籠，園遊會的攤位擠在老榕樹下。她戴著義工臂章，負責發地圖、告訴人洗手間在哪。有人走錯，她帶了一小段路才放手。收場時她把彩帶捲好，說人很多，可是大家都找到位子。你替她摘掉沾在頭髮上的金蔥。",
	},
	"family_bento": {
		"title": "熱便當的路",
		"body": "她提著保溫袋走到巷口。掀開蓋子，飯還是熱的，湯匙被她擺得整整齊齊。街坊接過便當，多說了一聲乖。你給她一小張零錢當零用，她把錢夾進手帳，說下次還要一起送。",
	},
	"virtue_chores": {
		"title": "家裡的碗",
		"body": "她堅持自己洗碗，泡沫堆得比盤子還高。你在一旁切水果，步驟留給她，只在她問的時候搭腔。擦乾最後一只碗，她把抹布疊好，像完成一件很正式的事。家裡的燈因此亮得更順眼。",
	},
	"virtue_elder": {
		"title": "長輩的慢步",
		"notable": true,
		"body": "午後你們陪巷口的長輩走到公園再走回來。步伐慢到聽得見樹葉。長輩講起年輕時的戲院，她聽得很認真，還把一句話記在手帳邊。回家她說，原來時間可以走得這麼溫柔。",
	},
	"style_fashion": {
		"title": "鏡子前的練習",
		"body": "她在鏡子前把外套換了兩種穿法。你沒有急著評分，只說今天的顏色很像傍晚的雲。她耳朵紅了，還是把那件留了下來。窗縫進來的風把窗簾吹得輕輕的。",
	},
	"style_perform": {
		"title": "上台之前",
		"notable": true,
		"body": "彩排時她的手心是涼的。你站在文化中心側門，看她把第一句話說完，聲音從發顫到站住。散場她什麼都還沒說就先笑了。你把外套披上她肩，說我都看見了。",
	},
	"health_clinic": {
		"title": "診所的午後",
		"body": "王醫師讓她坐下，聽診器在衣料上輕輕一滑。他說長得結實，記得按時睡。她拿著運動建議走出診所，還在念伸展、喝水、少熬夜。你點頭，把這三件小事也寫進自己的備忘。",
	},
	"culture_reading": {
		"title": "朗讀會的故事",
		"notable": true,
		"body": "文化中心的小房間坐滿弟弟妹妹。她把故事書捧平，聲音放得比平常更柔。讀到結尾，有個孩子問然後呢。她想了想，說然後大家一起回家吃晚餐。掌聲不大，但很齊。",
	},
	"clinic_helper": {
		"title": "候診區的水杯",
		"body": "她到診所當小義工，把舊雜誌排齊，給長輩倒溫水，動作慢慢變熟。王醫師經過時點點頭，沒有多說話。離開時她說，原來照顧人是一件要彎下腰的事。你覺得她好像又高了一點點。",
	},
	"shops_market": {
		"title": "跟家人的市集",
		"notable": true,
		"body": "週末市集的帆布棚下，她站在你身旁遞袋子、把青菜擺整齊。第一聲歡迎很小，第三聲就跟你疊在一起。有街坊多買了一把菜，還摸了摸她的頭。收攤時你給她一點零用錢，她把硬幣收進手帕，說下次還要一起出來。",
	},
	"school_debate": {
		"title": "壁報與辯題",
		"body": "壁報社的桌子上全是剪報。她為一個辯題寫了三行開場，又塗掉兩行。導師說留下你真正想說的那句。放學她把那句念給你聽。風從操場吹過來，句子很短，卻站得住。",
	},
	"park_run": {
		"title": "晨跑的步點",
		"body": "天剛亮，晨跑隊在老榕樹下集合。她跟著跑了兩圈，氣喘，但沒有掉隊。有人拍拍她的肩，說下次見。你們捧著熱豆漿，看小鎮慢慢把窗戶打開。",
	},
	"talent_showcase": {
		"title": "才藝發表那一夜",
		"notable": true,
		"body": "禮堂的燈暗下來，她站上小小的舞台。你坐在靠走道的位子，節目單被捏出摺痕。曲子結束，掌聲響起，她鞠躬的角度有點急，卻很真誠。出後門她第一句問：你有沒有坐到看得到的地方。你說有，從頭到尾都有。",
	},
}


static func get_vignette(activity_id: String, season: int) -> Dictionary:
	var src: Dictionary = {}
	if BY_ID.has(activity_id):
		src = BY_ID[activity_id]
	var def := Activities.get_activity(activity_id)
	var title := str(src.get("title", ""))
	if title == "":
		title = str(def.get("name", "平靜的一個月"))
	var body := str(src.get("body", ""))
	if body == "":
		var desc := str(def.get("desc", "她把日子過得安穩"))
		body = "這個月你們沒有特別趕路。%s日子輕輕翻過，手帳上留了一小格粉紅。" % desc
	var sticker := str(src.get("sticker", ""))
	if sticker == "":
		sticker = GameConfig.season_key(season)
	return {
		"activity_id": activity_id,
		"title": title,
		"body": body,
		"notable": bool(src.get("notable", false)),
		"sticker": sticker,
		"still": str(src.get("still", "")),
	}


## Prefer a notable month; else the first month that is not plain rest.
static func highlight_index(vignettes: Array) -> int:
	var first_non_rest := -1
	for i in range(vignettes.size()):
		var item = vignettes[i]
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var v: Dictionary = item
		if bool(v.get("notable", false)):
			return i
		if first_non_rest < 0 and str(v.get("activity_id", "")) != "rest_sleep":
			first_non_rest = i
	if first_non_rest >= 0:
		return first_non_rest
	return 0
