class_name Confide
extends RefCounted
## 她偶爾說一句。傾訴心事，或撒個嗲。
## 媽媽不在：對爸爸說。媽媽在家：對媽媽說，或對兩個人一起說。
## 每季最多一次。答過的下一季先歇著。教學沒關、媽媽這季已幫忙、
## 升學還沒寫、成年工作卡還沒關，都不出現。
## 旗標都放在 GameState.flags，隨存檔走。

const CONFIDE_CHANCE := 0.22
## 成年仍用同一張卡，比較少出現，也不寫進日記排程。
const ADULT_CONFIDE_CHANCE := 0.12

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
	{
		"id": "child_worry_grow",
		"band": "child",
		"tone": "worry",
		"hearer": "dad",
		"kicker": "傾訴心事",
		"body": "%s站直了一點，又縮回去：「同學說我長高了，看起來不像我們班的。我是不是長太快。」",
		"options": [
			{
				"label": "慢慢長就好",
				"reply": "你對%s說，高一點也還是你。她把量身高的鉛筆印對了對，沒有再擦掉。",
				"deltas": {"mood": 3, "social": 1},
				"warmth": 1,
			},
			{
				"label": "我們一起看那條線",
				"reply": "門框上的鉛筆痕還在。她用手指比了比，說原來只高了一點點。",
				"deltas": {"mood": 4},
				"warmth": 1,
			},
			{
				"label": "長高了也能被抱",
				"reply": "你蹲下來，仍舊把她抱住。她在你肩上說，那就好。",
				"deltas": {"mood": 4, "stamina": 1},
				"warmth": 1,
			},
		],
	},
	{
		"id": "child_cling_praise",
		"band": "child",
		"tone": "cling",
		"hearer": "dad",
		"kicker": "撒嗲",
		"body": "%s把圖舉到你眼前，腳跟踮著：「爸爸你看。媽媽說好看。你也說一下嘛。」",
		"options": [
			{
				"label": "好好看",
				"reply": "你把圖接過來，看了很久。她等你先說，才自己笑。",
				"deltas": {"mood": 4},
				"warmth": 1,
			},
			{
				"label": "貼在冰箱上",
				"reply": "你找了磁鐵。她盯著那張圖，說這樣每天都看得到。",
				"deltas": {"mood": 5},
				"warmth": 1,
			},
			{
				"label": "你自己也喜歡就很好",
				"reply": "你問她最喜歡哪一筆。她指給你看，聲音亮了一點。",
				"deltas": {"mood": 3, "social": 1},
				"warmth": 0,
			},
		],
	},
	{
		"id": "teen_worry_grow",
		"band": "teen",
		"tone": "worry",
		"hearer": "dad",
		"kicker": "傾訴心事",
		"body": "%s把學生證扣上又打開：「好像一下子就要變大人。我還想當一下小孩子，可以嗎。」",
		"options": [
			{
				"label": "你還是你",
				"reply": "你說，變高、變忙，回家仍是原來的人。她把證件收回口袋。",
				"deltas": {"mood": 4, "morals": 1},
				"warmth": 1,
			},
			{
				"label": "今天就當小孩子",
				"reply": "你沒有談以後。她去倒了兩杯水，杯子還是小時候那一對。",
				"deltas": {"mood": 4},
				"warmth": 1,
			},
			{
				"label": "變大人也可以回家",
				"reply": "你說，長大不是搬走。她點頭，把椅子拉近一點。",
				"deltas": {"mood": 3, "social": 1},
				"warmth": 0,
			},
		],
	},
	{
		"id": "teen_cling_praise",
		"band": "teen",
		"tone": "cling",
		"hearer": "dad",
		"kicker": "撒嗲",
		"body": "「你能不能不要只說還可以。」%s把作業簿合上又打開。「今天想聽你誇我。就一句，別笑。」",
		"options": [
			{
				"label": "我很以你為傲",
				"reply": "你說得很慢，讓她聽完。她耳朵紅了，可是沒有把簿子藏起來。",
				"deltas": {"mood": 4, "morals": 1},
				"warmth": 1,
			},
			{
				"label": "這一段寫得很清楚",
				"reply": "你指著她自己改過的那一行。她說，那就這一句就好。",
				"deltas": {"mood": 3},
				"warmth": 1,
			},
			{
				"label": "說給媽媽也聽",
				"reply": "你把那句話又說了一次，聲音大得廚房聽得見。她嘴上說丟臉，人沒有走開。",
				"deltas": {"mood": 4, "social": 1},
				"warmth": 1,
			},
		],
	},
	{
		"id": "child_worry_bento",
		"band": "child",
		"tone": "worry",
		"hearer": "parents",
		"kicker": "傾訴心事",
		"body": "%s拉著媽媽的衣角，又看你一眼：「今天有人笑我的便當。我不敢跟老師說。」",
		"options": [
			{
				"label": "我們聽你說完",
				"reply": "媽媽先蹲下來。你在旁邊，等她把便當盒的故事講完。",
				"deltas": {"mood": 4, "social": 1},
				"warmth": 1,
			},
			{
				"label": "明天換你喜歡的",
				"reply": "你們問她想帶什麼。她選了最普通的那一種，說這樣就不可笑了。",
				"deltas": {"mood": 3, "morals": 1},
				"warmth": 1,
			},
			{
				"label": "先吃飯，晚點再說",
				"reply": "沒有人急著出主意。她吃了幾口，才把名字說出來。",
				"deltas": {"mood": 3, "stamina": 1},
				"warmth": 0,
			},
		],
	},
	{
		"id": "child_cling_pudding",
		"band": "child",
		"tone": "cling",
		"hearer": "parents",
		"kicker": "撒嗲",
		"body": "%s晃著媽媽的手，聲音甜甜的：「我想吃布丁。小小一杯。媽媽說要問爸爸。」",
		"options": [
			{
				"label": "小小一杯",
				"reply": "你點頭。她捧著杯子，先分媽媽一匙，再分你一匙。",
				"deltas": {"mood": 4},
				"warmth": 1,
			},
			{
				"label": "飯後的甜",
				"reply": "你說，先吃飯，布丁當結尾。她扁了扁嘴，還是去擺碗。",
				"deltas": {"mood": 2, "morals": 1},
				"warmth": 0,
			},
			{
				"label": "三個人分一盒",
				"reply": "你們把布丁分成三小碟。她說這樣比較像在慶祝，雖然沒有節日。",
				"deltas": {"mood": 3, "social": 1},
				"warmth": 1,
			},
		],
	},
	{
		"id": "child_worry_mom",
		"band": "child",
		"tone": "worry",
		"hearer": "mom",
		"kicker": "傾訴心事",
		"body": "%s把臉埋在媽媽肩上，聲音悶悶的：「我今天在學校很安靜。不是生氣。就是不知道要跟誰一組。」",
		"options": [
			{
				"label": "讓媽媽先抱著",
				"reply": "你沒有把她拉過來。媽媽拍著她的背，你在旁邊倒了溫水。",
				"deltas": {"mood": 4},
				"warmth": 1,
			},
			{
				"label": "爸爸也在",
				"reply": "你坐到她們旁邊，說一組的事可以慢慢找。她從媽媽肩上抬起眼。",
				"deltas": {"mood": 3, "social": 1},
				"warmth": 1,
			},
			{
				"label": "回家就是一組",
				"reply": "你說，家裡這組不會散。她點頭，仍抓著媽媽的袖子。",
				"deltas": {"mood": 4, "morals": 1},
				"warmth": 1,
			},
		],
	},
	{
		"id": "child_cling_mom",
		"band": "child",
		"tone": "cling",
		"hearer": "mom",
		"kicker": "撒嗲",
		"body": "%s抱著媽媽的腰，眼睛卻看著你：「媽媽說我今天很乖。你也要說。說了我才去洗手。」",
		"options": [
			{
				"label": "今天很乖",
				"reply": "你說了。她把臉在媽媽衣服上蹭一下，才跑去洗手。",
				"deltas": {"mood": 5},
				"warmth": 1,
			},
			{
				"label": "這是你自己做到的",
				"reply": "你說，不是為了換一句話。她想了想，還是去洗手，走路有一點跳。",
				"deltas": {"mood": 3, "morals": 1},
				"warmth": 0,
			},
			{
				"label": "媽媽說得對",
				"reply": "你看著媽媽，又看著她，把那句話重複一次。她笑出聲。",
				"deltas": {"mood": 4, "social": 1},
				"warmth": 1,
			},
		],
	},
	{
		"id": "teen_worry_tell",
		"band": "teen",
		"tone": "worry",
		"hearer": "parents",
		"kicker": "傾訴心事",
		"body": "%s坐在媽媽旁邊，沒有看你：「長大的事，跟同學講會被笑，跟你們講又怕你們擔心。所以我常常不講。」",
		"options": [
			{
				"label": "擔心也沒關係",
				"reply": "你說，擔心是因為在乎，不是要她把話收回去。她肩膀鬆了一點。",
				"deltas": {"mood": 4, "morals": 1},
				"warmth": 1,
			},
			{
				"label": "你挑一個時間",
				"reply": "媽媽說，今晚或週末都行。她選了洗碗之後，那時候比較安靜。",
				"deltas": {"mood": 3, "social": 1},
				"warmth": 1,
			},
			{
				"label": "寫下來也算說了",
				"reply": "你沒有追問。她後來把日記本放在桌上，沒有打開，可是放著。",
				"deltas": {"mood": 3},
				"warmth": 0,
			},
		],
	},
	{
		"id": "teen_cling_stay",
		"band": "teen",
		"tone": "cling",
		"hearer": "parents",
		"kicker": "撒嗲",
		"body": "%s從沙發後面探出頭：「今天不要各自做自己的事。我想你和媽媽都在客廳。就一下。」",
		"options": [
			{
				"label": "今晚都留在客廳",
				"reply": "你把要看的東西合上。三個人坐著，電視開得很小。",
				"deltas": {"mood": 4, "social": 1},
				"warmth": 1,
			},
			{
				"label": "我先把事情放下",
				"reply": "你說，這一小段先屬於家。她把腳縮上沙發，靠著媽媽。",
				"deltas": {"mood": 4},
				"warmth": 1,
			},
			{
				"label": "一起坐到睏",
				"reply": "沒有人催去寫功課。她後來自己站起來，說夠了。",
				"deltas": {"mood": 3, "stamina": 1},
				"warmth": 1,
			},
		],
	},
	{
		"id": "teen_cling_mom",
		"band": "teen",
		"tone": "cling",
		"hearer": "mom",
		"kicker": "撒嗲",
		"body": "%s從廚房門口看著媽媽，又小聲叫你：「可以不要各自回房間嗎。我想靠著媽媽坐，你也坐近一點。」",
		"options": [
			{
				"label": "我坐過來",
				"reply": "你在她另一側坐下。她靠著媽媽，肩膀慢慢鬆開。",
				"deltas": {"mood": 4, "social": 1},
				"warmth": 1,
			},
			{
				"label": "今晚的位子留著",
				"reply": "你說，客廳這一段先不散。她點頭，把抱枕讓出一半。",
				"deltas": {"mood": 4},
				"warmth": 1,
			},
			{
				"label": "先喝杯熱的",
				"reply": "你熱了三杯。她捧著自己的那杯，沒有先回房間。",
				"deltas": {"mood": 3, "stamina": 1},
				"warmth": 0,
			},
		],
	},
	{
		"id": "adult_worry_table",
		"band": "adult",
		"tone": "worry",
		"hearer": "parents",
		"kicker": "想跟你說",
		"body": "%s把鑰匙放下，先看了媽媽一眼：「今天的班有點長。我想跟你們說，可是又不知道從哪一句開始。」",
		"options": [
			{
				"label": "從坐下開始",
				"reply": "你拉出椅子。她坐下來，話就短短的幾句。",
				"deltas": {"mood": 4, "stamina": 1},
				"warmth": 1,
			},
			{
				"label": "我們聽，不急",
				"reply": "媽媽把茶推過去。你沒有問班表。她說，這樣就夠。",
				"deltas": {"mood": 3, "morals": 1},
				"warmth": 1,
			},
			{
				"label": "想說的時候再說",
				"reply": "你說，飯還熱。她點頭，先吃了兩口。",
				"deltas": {"mood": 3, "stamina": 1},
				"warmth": 0,
			},
		],
	},
	{
		"id": "adult_cling_table",
		"band": "adult",
		"tone": "cling",
		"hearer": "parents",
		"kicker": "留在家裡",
		"body": "「借我賴一下。」%s說得很輕。「不是說給別人聽。就是想跟你和媽媽吃飯，然後坐久一點。」",
		"options": [
			{
				"label": "今晚留久一點",
				"reply": "碗洗完也沒有人先走。她說，這樣的晚上，她記得住。",
				"deltas": {"mood": 4, "social": 1},
				"warmth": 1,
			},
			{
				"label": "你來決定坐到幾點",
				"reply": "她笑說不用看時鐘，人在就好。你們就留在原位。",
				"deltas": {"mood": 4},
				"warmth": 1,
			},
			{
				"label": "吃完再坐一會兒",
				"reply": "飯後你們留在原位。她把白天沒說的一句，放在最後。",
				"deltas": {"mood": 3, "stamina": 1},
				"warmth": 0,
			},
		],
	},
]


static func _season_tag(state) -> String:
	return "%d_%d" % [int(state.year), int(state.season)]


static func _previous_tag(state) -> String:
	var y := int(state.year)
	var s := int(state.season)
	if s <= 0:
		return "%d_%d" % [y - 1, 3]
	return "%d_%d" % [y, s - 1]


static func _named(state, text: String) -> String:
	return Mom._named(state, text)


static func get_line(id: String) -> Dictionary:
	for line in LINES:
		if str(line.get("id", "")) == id:
			return line
	return {}


## 不在家：爸爸。人在家：對媽媽，或對兩個人。
static func hearer_of(line: Dictionary) -> String:
	var hearer := str(line.get("hearer", "dad"))
	if hearer == "mom" or hearer == "parents":
		return hearer
	return "dad"


static func _allowed_hearers(state) -> Array:
	if Mom.is_present(state):
		return ["mom", "parents"]
	return ["dad"]


static func _pool(band: String, tone: String, hearers: Array) -> Array:
	var out: Array = []
	for line in LINES:
		if str(line.get("band", "")) != band or str(line.get("tone", "")) != tone:
			continue
		if not hearers.has(hearer_of(line)):
			continue
		out.append(line)
	return out


static func _band_for(state) -> String:
	if GameConfig.is_adult_year(int(state.year)):
		return "adult"
	if int(state.year) > 6:
		return "teen"
	return "child"


static func chance_for(state) -> float:
	if GameConfig.is_adult_year(int(state.year)):
		return ADULT_CONFIDE_CHANCE
	return CONFIDE_CHANCE


static func pick_line(state, rng: RandomNumberGenerator) -> Dictionary:
	var band := _band_for(state)
	var hearers := _allowed_hearers(state)
	var tone := "worry" if rng.randf() < 0.5 else "cling"
	var pool := _pool(band, tone, hearers)
	if pool.is_empty():
		pool = _pool(band, "cling" if tone == "worry" else "worry", hearers)
	if pool.is_empty():
		return {}
	var last := str(state.flags.get("confide_last_id", ""))
	if pool.size() > 1 and last != "":
		var filtered: Array = []
		for line in pool:
			if str(line.get("id", "")) != last:
				filtered.append(line)
		if not filtered.is_empty():
			pool = filtered
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
		"hearer": hearer_of(line),
		"kicker": str(line.get("kicker", "")),
		"body": _named(state, str(line.get("body", ""))),
		"options": opts,
	}


static func can_offer(state) -> bool:
	if int(state.year) == 1 and int(state.season) == 0 and int(state.months_played) == 0:
		if not bool(state.flags.get("tutorial_done", false)):
			return false
	# 媽媽的小幫忙已經是這季的家事。
	if Mom.helped_this_season(state):
		return false
	# 升學日記和第一張工作卡佔著成年的開頭。這張卡不寫排程。
	if Adulthood.needs_education_choice(state):
		return false
	if Adulthood.is_adult(state) and not bool(state.flags.get("adult_job_intro_done", false)):
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
	# 上一季答過了：這一季先歇著，之後也不再擲。
	if bool(state.flags.get("confide_done_%s" % _previous_tag(state), false)):
		state.flags["confide_rolled_%s" % tag] = true
		return {}
	state.flags["confide_rolled_%s" % tag] = true
	if rng.randf() >= chance_for(state):
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
