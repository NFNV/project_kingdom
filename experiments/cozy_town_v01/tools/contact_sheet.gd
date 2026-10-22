extends Node2D

const ROOT := "res://experiments/cozy_town_v01/"
const SIZE := Vector2(1440, 1260)
const INK := Color("2d4945")
const MUTED := Color("6c796a")
var manifest: Dictionary
var font: Font
var ground_textures: Dictionary = {}


func _ready() -> void:
	manifest = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "asset_manifest.json"))
	font = ThemeDB.fallback_font
	for index in manifest["assets"].size():
		var item: Dictionary = manifest["assets"][index]
		var key: String = item["id"]
		var origin := _card_origin(index)
		if item["category"] == "ground":
			ground_textures[key] = load(ROOT + item["texture"])
			continue
		var multiplier := _display_scale(key)
		var object := load(ROOT + item["scene"]).instantiate() as Node2D
		object.position = origin + Vector2(162, 204)
		object.scale = Vector2.ONE * multiplier
		add_child(object)
	# True common-scale comparison; unlike the enlarged inspection thumbnails.
	for pair in [["resident", Vector2(42, 205)], ["street_lamp", Vector2(93, 205)],
		["tree", Vector2(160, 205)], ["bench", Vector2(253, 205)]]:
		var object := load(ROOT + "assets/scenes/" + str(pair[0]) + ".tscn").instantiate() as Node2D
		object.position = _card_origin(13) + pair[1]
		add_child(object)
	queue_redraw()


func _card_origin(index: int) -> Vector2:
	return Vector2(36 + (index % 4) * 344, 136 + (index / 4) * 264)


func _display_scale(key: String) -> float:
	match key:
		"house", "community_shop": return 1.0
		"tree": return 1.5
		"resident", "planter": return 3.0
		_: return 2.0


func _text(point: Vector2, text: String, size: int = 16, color: Color = INK) -> void:
	draw_string(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _draw() -> void:
	if font == null:
		return
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color("f0e8d5"))
	_text(Vector2(36, 37), "P R O J E C T   K I N G D O M", 13, MUTED)
	_text(Vector2(34, 81), "OLD TOWN / ART STUDY 01", 34)
	_text(Vector2(36, 110), "Original asset experiment · 32 px logical grid · 21 October 2026", 16, MUTED)
	for index in 16:
		var origin := _card_origin(index)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("fbf4e4")
		style.border_color = Color("d5cab2")
		style.set_border_width_all(1)
		style.set_corner_radius_all(7)
		draw_style_box(style, Rect2(origin, Vector2(324, 248)))
		if index < manifest["assets"].size():
			_draw_asset_card(index, origin)
	_text(_card_origin(13) + Vector2(18, 29), "Common scale / 1×", 17)
	_text(_card_origin(13) + Vector2(18, 231), "Resident 40h · lamp 64h · tree 83h", 12, MUTED)
	_draw_palette(_card_origin(14))
	_draw_notes(_card_origin(15))
	_text(Vector2(36, 1237), "Inspection thumbnails use labeled enlargement; the town composition uses the common logical scale.", 14, MUTED)


func _draw_asset_card(index: int, origin: Vector2) -> void:
	var item: Dictionary = manifest["assets"][index]
	_text(origin + Vector2(18, 29), "%02d  %s" % [index + 1, item["label"]], 17)
	var target: Array = item["logical_target"]
	var key: String = item["id"]
	var detail := "%d×%d target · %s" % [int(target[0]), int(target[1]), item["status"]]
	_text(origin + Vector2(18, 231), detail, 11, MUTED)
	if item["category"] == "ground":
		var texture := ground_textures[key] as Texture2D
		for y in 2:
			for x in 4:
				var rect := Rect2(origin + Vector2(34 + x * 64, 56 + y * 64), Vector2(64, 64))
				if key == "grass_tile":
					draw_rect(rect, Color("9cae7c"))
					draw_texture_rect(texture, rect, false, Color(1, 1, 1, 0.25))
				else:
					draw_texture_rect(texture, rect, false)
		_text(origin + Vector2(18, 214), "Repeated sample — edge continuity pending", 11, MUTED)
	else:
		_text(origin + Vector2(18, 49), "%s× inspection" % str(_display_scale(key)), 11, MUTED)


func _draw_palette(origin: Vector2) -> void:
	_text(origin + Vector2(18, 29), "Palette anchors", 17)
	var colors := ["f7e7bf", "e8d5b0", "b96f58", "547a79", "9cae7c", "405d4e",
		"cab79f", "847f77", "d3ab59", "cf8875", "524b5b"]
	for index in colors.size():
		var point := origin + Vector2(20 + (index % 4) * 73, 51 + (index / 4) * 56)
		draw_rect(Rect2(point, Vector2(57, 30)), Color(colors[index]))
		_text(point + Vector2(0, 43), "#" + str(colors[index]).to_upper(), 10, MUTED)
	_text(origin + Vector2(18, 231), "Palette family; sources are not indexed.", 11, MUTED)


func _draw_notes(origin: Vector2) -> void:
	_text(origin + Vector2(18, 29), "Readiness / honest scope", 17)
	var lines := ["13 original generated sources", "2 buildings · 7 props · 3 grounds", "1 resident concept pose",
		"Native Godot texture + scene wrappers", "Alpha cutout used in these previews", "Ground seams need production work",
		"No character animation or gameplay", "No existing game files replaced"]
	for index in lines.size():
		_text(origin + Vector2(18, 62 + index * 21), lines[index], 13, MUTED)
