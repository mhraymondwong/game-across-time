class_name Mom
extends RefCounted
## 家人・媽媽。不是 TownNpcs 小鎮名單；好感不計分，關係固定是暖的。
## 主畫面每季最多擲一次（約三成），出現才顯示肖像。

const ID := "mom"
const NAME := "媽媽"
const PORTRAIT_PATH := "res://assets/family/mom_portrait.jpg"
const FAMILY_PHOTO_PATH := "res://assets/family/family_photo_child.jpg"
## 25–35% per season; the roll flag makes it once per season.
const APPEAR_CHANCE := 0.30

const FAMILY_BIO := "她是這個家的人。會煮飯、會補外套，也會在你排太滿的時候，輕聲說慢一點。"

const LINES: PackedStringArray = [
	"回來啦。飯在鍋裡，%s今天在學校畫了一朵很大的花。",
	"別急著把行程排滿。%s想跟你走一段路，去巷口就好。",
	"外套我補好了。天涼的時候，記得讓%s穿上。",
	"今晚想吃湯麵嗎？簡單的也好，三個人坐在一起就很夠。",
	"%s跟我說，爸爸笑的時候，家裡就亮一點。",
	"功課我看過了，沒有催。你陪%s讀十分鐘就好。",
	"窗邊的光很好。要不要留一張？就我們三個。",
	"我偶爾出門，也偶爾回來。你不用擔心家會空著。",
]

const HELPS: Array = [
	{
		"title": "熱茶",
		"body": "媽媽熱了一壺茶。%s喝完，肩膀鬆了一點。",
		"deltas": {"mood": 5},
	},
	{
		"title": "私房錢",
		"body": "媽媽把一點私房錢放進家計信封：「買水果就好，別謝。」",
		"deltas": {"cash": 300},
	},
	{
		"title": "陽台伸展",
		"body": "媽媽帶%s在陽台伸展。太陽慢慢爬上欄杆，體力也跟著醒了。",
		"deltas": {"stamina": 3, "morals": 1},
	},
	{
		"title": "慢一點的安排",
		"body": "媽媽輕聲說：這季不妨排一次「公園散步」，或「在家好好休息」。%s需要慢的日子。",
		"deltas": {"mood": 2},
	},
]


static func _season_tag(state) -> String:
	return "%d_%d" % [int(state.year), int(state.season)]


static func is_present(state) -> bool:
	return bool(state.flags.get("mom_present_%s" % _season_tag(state), false))


static func helped_this_season(state) -> bool:
	return bool(state.flags.get("mom_helped_%s" % _season_tag(state), false))


## First hub visit of the season rolls; later visits keep the same answer.
static func roll_presence(state, rng: RandomNumberGenerator) -> bool:
	var rolled_key := "mom_rolled_%s" % _season_tag(state)
	if bool(state.flags.get(rolled_key, false)):
		return is_present(state)
	state.flags[rolled_key] = true
	var present := rng.randf() < APPEAR_CHANCE
	state.flags["mom_present_%s" % _season_tag(state)] = present
	if present:
		state.flags["mom_seen_count"] = int(state.flags.get("mom_seen_count", 0)) + 1
	return present


static func peek_line(state) -> String:
	if LINES.is_empty():
		return ""
	var i := int(state.flags.get("mom_dialogue_index", 0))
	return _named(state, LINES[posmod(i, LINES.size())])


## Shows the current line and remembers the next index in flags (saved with the slot).
static func advance_dialogue(state) -> String:
	var line := peek_line(state)
	var i := int(state.flags.get("mom_dialogue_index", 0))
	state.flags["mom_dialogue_index"] = i + 1
	return line


static func help_spec(state) -> Dictionary:
	if HELPS.is_empty():
		return {}
	var idx := posmod(int(state.year) + int(state.season), HELPS.size())
	return HELPS[idx]


static func help_available(state) -> bool:
	return is_present(state) and not helped_this_season(state)


static func claim_help(state) -> Dictionary:
	if not is_present(state):
		return {"ok": false, "reason": "媽媽這季不在家。", "deltas": {}}
	if helped_this_season(state):
		return {"ok": false, "reason": "這季她已經幫過一點小忙了。", "deltas": {}}
	var spec := help_spec(state)
	var deltas: Dictionary = {}
	var raw = spec.get("deltas", {})
	if typeof(raw) == TYPE_DICTIONARY:
		deltas = (raw as Dictionary).duplicate()
	state.flags["mom_helped_%s" % _season_tag(state)] = true
	if not deltas.is_empty():
		state.apply_map_event_delta(deltas)
	return {
		"ok": true,
		"title": str(spec.get("title", "小幫忙")),
		"body": _named(state, str(spec.get("body", ""))),
		"deltas": deltas,
	}


static func format_deltas(deltas: Dictionary) -> String:
	var parts: PackedStringArray = []
	var keys := [
		["charm", "魅力"], ["morals", "道德"], ["social", "人際"],
		["stamina", "體力"], ["academia", "學識"], ["mood", "心情"], ["cash", "家計"],
	]
	for pair in keys:
		var k: String = pair[0]
		var v := int(deltas.get(k, 0))
		if v == 0:
			continue
		if k == "cash":
			parts.append("%s%s$%d" % [pair[1], "＋" if v > 0 else "－", abs(v)])
		else:
			parts.append("%s%s%d" % [pair[1], "＋" if v > 0 else "－", abs(v)])
	return "　".join(parts)


## Childhood family photo. Idempotent — append_album_entry skips a repeated id.
static func seed_family_album(state) -> void:
	state.append_album_entry({
		"id": "family_photo_child",
		"year": 1,
		"season": 0,
		"title": "門前的一家三口",
		"thumb_path": FAMILY_PHOTO_PATH,
		"body": _named(state, "爸爸、媽媽，和還小的%s，站在花圃與石板路前。風很輕，三個人都在笑。這張照片從一開始就貼在相簿裡。"),
	})


static func _named(state, text: String) -> String:
	if not text.contains("%s"):
		return text
	if state != null and state.has_method("format_daughter"):
		return str(state.format_daughter(text))
	return text % "小悠"
