extends Control
## Map merged into home_hub (Layout 2). Redirect for old links.


func _ready() -> void:
	get_tree().change_scene_to_file("res://scenes/home_hub.tscn")
