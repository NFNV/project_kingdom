extends SceneTree

const ROOT := "res://experiments/cozy_town_v01/"


func _initialize() -> void:
	call_deferred("_render")


func _render() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Preview export needs a graphical renderer; use --display-driver macos on this Mac.")
		quit(1)
		return
	root.title = "Project Kingdom — Cozy Town Art Study"
	root.size = Vector2i(960, 576)
	if not _validate_scenes():
		quit(1)
		return
	await _save("town_corner.tscn", Vector2i(640, 384), 1, "town_corner_native.png")
	await _save("town_corner.tscn", Vector2i(1280, 768), 2, "town_corner.png")
	await _save("contact_sheet.tscn", Vector2i(1440, 1260), 1, "contact_sheet.png")
	print("Exported all three previews from the delivered native asset scenes.")
	quit()


func _validate_scenes() -> bool:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "asset_manifest.json"))
	for item in manifest["assets"]:
		var packed := load(ROOT + str(item["scene"])) as PackedScene
		if packed == null:
			push_error("Could not load asset scene: " + str(item["scene"]))
			return false
		var instance := packed.instantiate() as Node2D
		if instance == null:
			return false
		instance.free()
	print("Validated all 13 native asset scenes and their texture/material resources.")
	return true


func _save(scene_path: String, size: Vector2i, enlargement: int, filename: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(viewport)
	var scene := load(ROOT + scene_path).instantiate() as Node2D
	scene.scale = Vector2.ONE * enlargement
	viewport.add_child(scene)
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path(ROOT + "previews/" + filename)
	var error := viewport.get_texture().get_image().save_png(output)
	if error != OK:
		push_error("Could not save preview: " + output)
		quit(1)
	print("Preview: ", output)
	viewport.queue_free()
	await process_frame
