extends Node2D

# Static art composition only. No input, actors, physics, or gameplay systems.
const ROOT := "res://experiments/cozy_town_v01/"
const SIZE := Vector2(640, 384)
var tiles: Dictionary = {}


func _ready() -> void:
	for key in ["grass_tile", "pavement_tile", "road_tile"]:
		tiles[key] = load(ROOT + "assets/textures/" + key + ".tres")
	var objects := Node2D.new()
	objects.name = "TownObjects"
	objects.y_sort_enabled = true
	add_child(objects)
	var layout: Array = [
		["house", Vector2(168, 179)],
		["community_shop", Vector2(443, 179)],
		["tree", Vector2(47, 192)],
		["tree", Vector2(591, 190)],
		["fence", Vector2(91, 193)],
		["fence", Vector2(151, 193)],
		["fence", Vector2(245, 193)],
		["planter", Vector2(218, 203)],
		["planter", Vector2(373, 201)],
		["planter", Vector2(519, 201)],
		["notice_board", Vector2(301, 221)],
		["bench", Vector2(566, 239)],
		["street_lamp", Vector2(76, 252)],
		["street_lamp", Vector2(518, 252)],
		["resident", Vector2(345, 240)],
		["old_car", Vector2(427, 302)]
	]
	for item in layout:
		var object := load(ROOT + "assets/scenes/" + str(item[0]) + ".tscn").instantiate() as Node2D
		object.position = item[1]
		objects.add_child(object)
	queue_redraw()


func _draw() -> void:
	for y in 12:
		for x in 20:
			var key := "grass_tile"
			if y in [6, 7, 11]:
				key = "pavement_tile"
			elif y in [8, 9, 10]:
				key = "road_tile"
			var rect := Rect2(x * 32, y * 32, 32, 32)
			if key == "grass_tile":
				draw_rect(rect, Color("9cae7c"))
				draw_texture_rect(tiles[key], rect, false, Color(1, 1, 1, 0.25))
			else:
				draw_texture_rect(tiles[key], rect, false)
	# Simple composition-only curb and path marks, explicitly not PNG kit assets.
	for door_x in [196, 486]:
		draw_texture_rect(tiles["pavement_tile"], Rect2(door_x - 16, 160, 32, 32), false)
	draw_rect(Rect2(0, 253, 640, 3), Color("e3d1b1"))
	draw_rect(Rect2(0, 256, 640, 2), Color("6f6a65"))
	draw_rect(Rect2(0, 350, 640, 3), Color("e3d1b1"))
	for x in range(12, 640, 32):
		draw_rect(Rect2(x, 304, 13, 2), Color("d0c3a5"))
