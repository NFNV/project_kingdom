extends SceneTree

const ROOT := "res://experiments/anime_hub_assets_v06/"
var checked := 0
var errors: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, description: String) -> void:
	checked += 1
	if not ok:
		errors.append(description)
		push_error(description)


func _run() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"catalog.json"))["assets"]
	for id: String in catalog:
		var info: Dictionary = catalog[id]
		var source: Texture2D = load(ROOT+info["file"])
		_check(source!=null and source.get_width()==int(info["size"][0]) and source.get_height()==int(info["size"][1]),id+" imports at its actual source dimensions")
		if info.has("sheet"):
			var frames: SpriteFrames = load(ROOT+"godot/"+id+"_frames.tres")
			_check(frames!=null and frames.get_animation_names().size()==8,id+" has four idle and four walk animations")
			for direction in ["se","sw","ne","nw"]:
				_check(frames.get_frame_count("idle_"+direction)==1 and frames.get_frame_count("walk_"+direction)==2,id+" "+direction+" frame counts")
			for frame_info in info["sheet"]["frames"]:
				var row := int(frame_info["row"])
				var column := int(frame_info["column"])
				var animation: String = ("idle_" if row==0 else "walk_")+["se","sw","ne","nw"][column]
				var frame: AtlasTexture = frames.get_frame_texture(animation,maxi(0,row-1))
				_check(frame.get_width()==int(info["sheet"]["frame_canvas"][0]) and frame.get_height()==int(info["sheet"]["frame_canvas"][1]) and is_equal_approx(frame.margin.position.y+frame.region.size.y,float(info["sheet"]["foot_baseline_y"])),id+" pose shares registered canvas and foot baseline")
		elif bool(info["transparent"]):
			var atlas: AtlasTexture = load(ROOT+"godot/"+id+".tres")
			_check(atlas!=null and atlas.region.position.x>=0 and atlas.region.position.y>=0 and atlas.region.end.x<=source.get_width() and atlas.region.end.y<=source.get_height(),id+" cutout region is inside the source")
	for file in ["elm_wind.tres","willow_wind.tres"]:
		_check(load(ROOT+"godot/"+file) is ShaderMaterial,file+" is a native wind material")
	var scene: PackedScene = load(ROOT+"asset_review.tscn")
	_check(scene!=null,"Asset review scene loads")
	if scene!=null:
		var review = scene.instantiate()
		root.add_child(review)
		await process_frame
		for i in 4:
			review._show(i)
			await process_frame
			_check(review.stage.get_child_count()>0,"Review page %d contains assets"%i)
		for hour in 4:
			review._show(0)
			review._set_hour(hour)
			_check(review.backdrop.texture!=null,"Hub lighting %d loads"%hour)
		review.queue_free()
		await process_frame
	var report := {"checks":checked,"passed":checked-errors.size(),"errors":errors,"renderer":RenderingServer.get_current_rendering_method(),"scope":"Native resource loading, source dimensions, transparent atlas bounds, registered frame canvases and baseline, all review pages and lighting presets. Not a gameplay/FPS test."}
	FileAccess.open(ProjectSettings.globalize_path(ROOT+"godot_validation.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("Hub assets: %d/%d native resource checks passed."%[checked-errors.size(),checked])
	quit(0 if errors.is_empty() else 1)
