extends SceneTree

const ROOT := "res://experiments/hd2d_town_v02/"


func _initialize() -> void:
	call_deferred("_render")


func _render() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1440, 1540)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var background := ColorRect.new()
	background.color = Color("e9e5d6")
	background.size = Vector2(1440, 1540)
	viewport.add_child(background)
	_label(viewport, "PROJECT KINGDOM  /  HD-2D TOWN 02", Vector2(40, 25), 30, Color("30463e"))
	_label(viewport, "Original scenery cards + registered directional walk sheet / fixed elevated camera", Vector2(40, 70), 18, Color("5d6a59"))
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "assets/catalog.json"))
	var ids := ["cottage", "shop", "tree", "garden", "lamp", "bench", "notice_board", "old_car", "resident_walk"]
	for index in ids.size():
		var id: String = ids[index]
		var origin := Vector2(36 + (index % 3) * 466, 116 + (index / 3) * 466)
		var panel := ColorRect.new()
		panel.color = Color("f7f2e5")
		panel.position = origin
		panel.size = Vector2(442, 446)
		viewport.add_child(panel)
		var atlas := AtlasTexture.new()
		atlas.atlas = load(ROOT + "assets/" + id + ".png")
		var rect: Array = catalog[id]["frames"][0] if id == "resident_walk" else catalog[id]["region"]
		atlas.region = Rect2(rect[0], rect[1], rect[2], rect[3])
		var image := TextureRect.new()
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.texture = atlas
		image.position = origin + Vector2(18, 12)
		image.size = Vector2(406, 365)
		viewport.add_child(image)
		_label(viewport, id.replace("_", " ").capitalize(), origin + Vector2(18, 386), 21, Color("30463e"))
		var note := "4 directions / 16 registered walk frames" if id == "resident_walk" else "Transparent fixed-angle scenery card"
		_label(viewport, note, origin + Vector2(18, 416), 15, Color("5d6a59"))
	for frame in 5:
		await process_frame
		await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path(ROOT + "previews/contact_sheet.png")
	var error := viewport.get_texture().get_image().save_png(output)
	print("Contact sheet export: ", error_string(error))
	quit(0 if error == OK else 1)


func _label(parent: Node, text: String, at: Vector2, size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
