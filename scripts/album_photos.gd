class_name AlbumPhotos
extends RefCounted
## Album stills. Each entry is the daughter alone, or the daughter with both
## parents at an activity. Weather stamps, empty places, and a parent without
## her are not photos. A file is used once.


const CATALOG := "res://assets/album/catalog.json"

const ACTIVITY_THEMES := {
	"study_arts": "arts",
	"work_cafe": "cafe",
	"social_friends": "friends",
	"rest_trip": "daytrip",
	"school_library_helper": "library",
	"festival_helper": "festival",
	"virtue_elder": "elder",
	"style_perform": "perform",
	"culture_reading": "reading",
	"shops_market": "market",
	"study_piano": "piano",
	"talent_showcase": "showcase",
	"date_walk": "date",
	"family_meet": "homemeal",
}

const EVENT_THEMES := {
	"summer_beach": "beach",
	"autumn_mountain": "mountain",
}

const HOME_DOOR_PATHS: Array[String] = [
	"res://assets/family/family_early.jpg",
	"res://assets/family/family_photo_child.jpg",
]

static var _photos: Array = []
static var _by_path: Dictionary = {}
static var _loaded := false


static func theme_for_activity(activity_id: String) -> String:
	return str(ACTIVITY_THEMES.get(activity_id, ""))


static func theme_for_event(event_id: String) -> String:
	return str(EVENT_THEMES.get(event_id, ""))


static func theme_for_travel(dest_id: String) -> String:
	return "travel_%s" % dest_id.strip_edges()


static func theme_for_entry(entry: Dictionary) -> String:
	var eid := str(entry.get("id", ""))
	if eid == "family_photo_child":
		return "home_door"
	if eid.begins_with("travel_"):
		var dest := eid.substr(7)
		var cut := dest.rfind("_y")
		if cut > 0:
			return "travel_%s" % dest.substr(0, cut)
		return ""
	if eid.begins_with("evt_"):
		var ev := eid.substr(4)
		var cut_ev := ev.rfind("_y")
		if cut_ev > 0:
			return theme_for_event(ev.substr(0, cut_ev))
		return ""
	if eid.begins_with("vig_"):
		return theme_for_activity(_activity_from_vig(eid))
	return ""


static func is_forbidden(path: String) -> bool:
	var p := path.replace("\\", "/")
	if p == "":
		return true
	for banned in ["/weather/", "/places/", "/dialogue/", "/wardrobe/", "/pins/", "/year_review/"]:
		if p.contains(banned):
			return true
	var file := p.get_file()
	if file.begins_with("mom_") or file.begins_with("dad_") or file.begins_with("daughter_"):
		return true
	return false


static func subject_of(path: String) -> String:
	_ensure()
	if _by_path.has(path):
		var subject := str(_by_path[path].get("subject", ""))
		if subject == "daughter" or subject == "family":
			return subject
		return ""
	var file := path.get_file()
	if file.begins_with("family_"):
		return "family"
	if file.begins_with("travel_") and file.contains("family"):
		return "family"
	if file == "beach.jpg" or file == "mountain.jpg":
		return "family"
	return ""


static func claim(used: Array, theme: String, year: int) -> String:
	_ensure()
	if theme == "" or theme == "home_door":
		return ""
	var band := AgeLooks.band_for_year(year)
	var alts: Array[String] = []
	for photo in _photos:
		if typeof(photo) != TYPE_DICTIONARY:
			continue
		if str(photo.get("theme", "")) != theme or str(photo.get("band", "")) != band:
			continue
		var path := str(photo.get("path", ""))
		if path == "" or used.has(path) or not _exists(path):
			continue
		if bool(photo.get("alt", false)):
			alts.append(path)
		else:
			return path
	for path in alts:
		return path
	return ""


static func primary_path(theme: String, year: int) -> String:
	return claim([], theme, year)


static func used_paths(entries: Array) -> Array:
	var out: Array = []
	for item in entries:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var path := str(item.get("thumb_path", ""))
		if path != "":
			out.append(path)
	return out


## Drop reused files and anything that is not the daughter, or her with her parents.
## Known activities and trips are pointed at the age-band still when one is free.
static func sanitize(entries: Array) -> Array:
	var used: Array = []
	var out: Array = []
	for item in entries:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = (item as Dictionary).duplicate(true)
		var year := int(entry.get("year", 1))
		var theme := theme_for_entry(entry)
		var path := str(entry.get("thumb_path", ""))
		if theme == "home_door":
			if not HOME_DOOR_PATHS.has(path) or used.has(path) or not _exists(path):
				path = _first_free(HOME_DOOR_PATHS, used)
		elif theme != "":
			var preferred := claim(used, theme, year)
			if preferred != "":
				path = preferred
			elif not _acceptable(path, used):
				path = ""
		elif not _acceptable(path, used):
			path = ""
		if not _acceptable(path, used):
			continue
		entry["thumb_path"] = path
		used.append(path)
		out.append(entry)
	return out


static func audit(entries: Array) -> String:
	var seen := {}
	for item in entries:
		if typeof(item) != TYPE_DICTIONARY:
			return "album entry is not an object"
		var path := str(item.get("thumb_path", ""))
		var title := str(item.get("title", ""))
		if is_forbidden(path):
			return "forbidden photo %s (%s)" % [path, title]
		var subject := subject_of(path)
		if subject != "daughter" and subject != "family":
			return "photo subject %s (%s)" % [path, title]
		if seen.has(path):
			return "reused photo %s (%s)" % [path, title]
		if not _exists(path):
			return "missing photo %s" % path
		seen[path] = true
	return ""


static func _activity_from_vig(eid: String) -> String:
	var body := eid.substr(4)
	var mark := body.rfind("_m")
	if mark < 0:
		return ""
	body = body.substr(0, mark)
	mark = body.rfind("_s")
	if mark < 0:
		return ""
	body = body.substr(0, mark)
	mark = body.rfind("_y")
	if mark < 0:
		return ""
	return body.substr(0, mark)


static func _acceptable(path: String, used: Array) -> bool:
	if path == "" or used.has(path) or is_forbidden(path):
		return false
	var subject := subject_of(path)
	if subject != "daughter" and subject != "family":
		return false
	return _exists(path)


static func _first_free(paths: Array[String], used: Array) -> String:
	for path in paths:
		if not used.has(path) and _exists(path):
			return path
	return ""


static func _ensure() -> void:
	if _loaded:
		return
	_loaded = true
	_photos = []
	_by_path = {}
	if not FileAccess.file_exists(CATALOG) and not ResourceLoader.exists(CATALOG):
		push_error("album catalog missing")
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("album catalog is not an object")
		return
	var rows: Variant = parsed.get("photos", [])
	if typeof(rows) != TYPE_ARRAY:
		return
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		_photos.append(row)
		var path := str(row.get("path", ""))
		if path != "":
			_by_path[path] = row


static func _exists(path: String) -> bool:
	if path == "":
		return false
	if ResourceLoader.exists(path):
		return true
	var abs := ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
	return FileAccess.file_exists(abs)
