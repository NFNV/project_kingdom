extends SceneTree

const DEMO := preload("res://experiments/cozy_town_v01/walk_demo.tscn")
var failures := 0
var checks := 0
var demo: Node2D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	demo = DEMO.instantiate()
	root.add_child(demo)
	await physics_frame
	_check(demo.player.get_parent().y_sort_enabled, "Resident shares prop depth sorting")
	_check(demo.player.visual.get_child_count() == 1, "Existing resident sprite is reused")
	_check(demo.overview and demo.camera.zoom == Vector2.ONE, "Demo opens with whole-town view")
	var start := Vector2(130, 333)
	var end := await _walk(start, ["town_right"], 30)
	var straight_distance := end.distance_to(start)
	_check(absf(straight_distance - 44.0) < 2.0, "Walking speed is 88 pixels per second")
	end = await _walk(start, ["town_right", "town_up"], 30)
	_check(absf(end.distance_to(start) - straight_distance) < 2.0, "Diagonal movement is normalized")
	end = await _walk(start, ["town_right", "town_run"], 30)
	_check(absf(end.x - start.x - 75.0) < 3.0, "Shift increases movement speed")
	end = await _walk(Vector2(196, 220), ["town_up"], 60)
	_check(end.y > 186 and end.y < 191, "House blocks movement at its facade")
	end = await _walk(Vector2(443, 220), ["town_up"], 60)
	_check(end.y > 186 and end.y < 191, "Shop blocks movement at its facade")
	end = await _walk(Vector2(427, 333), ["town_up"], 60)
	_check(end.y > 309 and end.y < 314, "Parked car blocks movement")
	end = await _walk(Vector2(91, 220), ["town_up"], 60)
	_check(end.y > 200 and end.y < 205, "Fence blocks movement")
	end = await _walk(Vector2(218, 235), ["town_up"], 60)
	_check(end.y > 210 and end.y < 215, "Planter blocks movement (resident at %s)" % end)
	end = await _walk(Vector2(301, 250), ["town_up"], 60)
	_check(end.y > 228 and end.y < 233, "Notice board blocks movement")
	end = await _walk(Vector2(566, 270), ["town_up"], 60)
	_check(end.y > 246 and end.y < 251, "Bench blocks movement")
	end = await _walk(Vector2(76, 280), ["town_up"], 60)
	_check(end.y > 259 and end.y < 264, "Lamp base blocks movement")
	end = await _walk(Vector2(47, 220), ["town_up"], 60)
	_check(end.y > 199 and end.y < 204, "Tree trunk blocks movement")
	end = await _walk(Vector2(20, 330), ["town_left"], 60)
	_check(end.x > 4 and end.x < 7, "Map boundary keeps resident inside")
	end = await _walk(Vector2(200, 333), ["town_down"], 60)
	_check(end.y > 351 and end.y < 355, "Bottom boundary keeps resident above HUD")
	demo.overview = false
	demo._update_camera_mode()
	_check(demo.camera.zoom == Vector2(2, 2), "Close camera doubles the view scale")
	demo.reset_resident()
	_check(demo.player.position == demo.START, "Reset restores spawn position")
	_check(demo.player.visual.scale.x == 1.0, "Reset restores original facing")
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		demo.overview = true
		demo._update_camera_mode()
		await process_frame
		await RenderingServer.frame_post_draw
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/kingdom-town-walk.png")
		print("Screenshot: /tmp/kingdom-town-walk.png")
	print("Town walk demo: %d/%d checks passed." % [checks - failures, checks])
	demo.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)


func _walk(start: Vector2, actions: Array, frames: int) -> Vector2:
	demo.player.position = start
	demo.player.velocity = Vector2.ZERO
	await physics_frame
	for action: String in actions:
		Input.action_press(action)
	for tick in frames:
		await physics_frame
	for action: String in actions:
		Input.action_release(action)
	var end: Vector2 = demo.player.position
	await physics_frame
	return end


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)
