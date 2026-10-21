class_name StatRadar
extends Control
## Soft pink/white pentagon radar for ending credits (魅力／道德／人際／體力／學識)


const AXIS_KEYS: Array[String] = ["charm", "morals", "social", "stamina", "academia"]
const AXIS_LABELS: Array[String] = ["魅力", "道德", "人際", "體力", "學識"]

var values: Dictionary = {
	"charm": 50, "morals": 50, "social": 50, "stamina": 50, "academia": 50,
}


func set_from_stats(stats: Dictionary) -> void:
	for k in AXIS_KEYS:
		values[k] = clampf(float(stats.get(k, 50)), 0.0, 100.0)
	queue_redraw()


func _draw() -> void:
	var cx := size.x * 0.5
	var cy := size.y * 0.52
	var radius := mini(size.x, size.y) * 0.32
	if radius < 8.0:
		return

	var n := AXIS_KEYS.size()
	var col_ring := Color(1.0, 0.78, 0.86, 0.35)
	var col_axis := Color(1.0, 0.85, 0.90, 0.45)
	var col_fill := Color(0.94, 0.55, 0.68, 0.42)
	var col_stroke := Color(1.0, 0.82, 0.88, 0.95)
	var col_dot := Color(1.0, 0.92, 0.95, 1.0)
	var col_label := Color(1.0, 0.90, 0.93, 0.92)

	# Concentric rings at 25/50/75/100%
	for ring_i in range(1, 5):
		var r := radius * (float(ring_i) / 4.0)
		var pts := PackedVector2Array()
		for i in range(n + 1):
			var ang := _angle_for(i % n)
			pts.append(Vector2(cx + cos(ang) * r, cy + sin(ang) * r))
		draw_polyline(pts, col_ring, 1.2, true)

	# Axis spokes
	for i in range(n):
		var ang := _angle_for(i)
		var tip := Vector2(cx + cos(ang) * radius, cy + sin(ang) * radius)
		draw_line(Vector2(cx, cy), tip, col_axis, 1.0, true)

	# Value polygon
	var poly := PackedVector2Array()
	for i in range(n):
		var ang2 := _angle_for(i)
		var t: float = clampf(float(values.get(AXIS_KEYS[i], 0)) / 100.0, 0.0, 1.0)
		poly.append(Vector2(cx + cos(ang2) * radius * t, cy + sin(ang2) * radius * t))
	if poly.size() >= 3:
		draw_colored_polygon(poly, col_fill)
		var outline := PackedVector2Array(poly)
		outline.append(poly[0])
		draw_polyline(outline, col_stroke, 2.0, true)

	# Vertex dots
	for i in range(n):
		var ang3 := _angle_for(i)
		var t2: float = clampf(float(values.get(AXIS_KEYS[i], 0)) / 100.0, 0.0, 1.0)
		var p := Vector2(cx + cos(ang3) * radius * t2, cy + sin(ang3) * radius * t2)
		draw_circle(p, 3.5, col_dot)

	# Labels outside tips
	var font := ThemeDB.fallback_font
	var font_size := 14
	for i in range(n):
		var ang4 := _angle_for(i)
		var label_r := radius * 1.22
		var lp := Vector2(cx + cos(ang4) * label_r, cy + sin(ang4) * label_r)
		var text := AXIS_LABELS[i]
		var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var draw_pos := lp - sz * 0.5 + Vector2(0, sz.y * 0.35)
		draw_string(font, draw_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col_label)


func _angle_for(i: int) -> float:
	## Start at top (-PI/2), go clockwise
	var n := float(AXIS_KEYS.size())
	return -PI / 2.0 + TAU * float(i) / n
