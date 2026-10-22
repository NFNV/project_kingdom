extends SceneTree

const DEMO := preload("res://experiments/hd2d_town_v02/demo.tscn")
var demo: Node3D
var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	demo = DEMO.instantiate()
	root.add_child(demo)
	for tick in 15:
		await physics_frame
	_check(demo.resident.is_on_floor(), "Resident stands on the native 3D floor")
	_check(demo.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "Orthographic camera")
	_check(demo.resident.frames.size() == 16, "Sixteen directional walk frames")
	for index in demo.resident.frames.size():
		var frame: AtlasTexture = demo.resident.frames[index]
		_check(frame.get_size() == Vector2(180, 300) and frame.margin.position.y + frame.region.size.y == 300, "Registered feet in frame %d" % index)
	var start := Vector3(-1.0, 0.06, 0)
	var end := await _walk(start, ["hd_right"], 30)
	var distance := Vector2(end.x-start.x, end.z-start.z).length()
	_check(absf(distance - 1.5) < 0.1, "Walking speed")
	_check(demo.resident.facing_row == 1, "Right-facing walk frames")
	end = await _walk(start, ["hd_right", "hd_up"], 30)
	_check(absf(Vector2(end.x-start.x, end.z-start.z).length() - distance) < 0.1, "Normalized diagonal movement")
	end = await _walk(start, ["hd_right", "hd_run"], 30)
	_check(absf(Vector2(end.x-start.x, end.z-start.z).length() - 2.35) < 0.15, "Running speed")
	_check(_blocked(Vector3(6.3, 0.06, 1.5), Vector3(0, 0, -3)), "Parked car blocks motion")
	_check(_blocked(Vector3(-7.6, 0.06, 4.5), Vector3(0, 0, 2)), "Cottage blocks motion")
	_check(_blocked(Vector3(4, 0.06, -3.2), Vector3(0, 0, -2)), "Shop blocks motion")
	_check(_blocked(Vector3(-12, 0.06, -6.5), Vector3(0, 0, -2)), "Tree trunk blocks motion")
	_check(_blocked(Vector3(-3, 0.06, 4.3), Vector3(0, 0, 1.2)), "Fence blocks motion")
	_check(_blocked(Vector3(14, 0.06, 0), Vector3(2, 0, 0)), "Town boundary blocks motion")
	_check(not _blocked(Vector3(-1, 0.06, 0), Vector3(1, 0, 0)), "Open road permits motion")
	var tab := InputEventKey.new()
	tab.physical_keycode = KEY_TAB
	tab.pressed = true
	demo._unhandled_key_input(tab)
	_check(demo.overview, "Tab changes the camera mode")
	var reset := InputEventKey.new()
	reset.physical_keycode = KEY_R
	reset.pressed = true
	demo._unhandled_key_input(reset)
	_check(demo.resident.position == demo.SPAWN, "R resets the resident")
	root.size = Vector2i(1920, 1080)
	await process_frame
	await process_frame
	_check(root.get_texture().get_size() == Vector2(1280,720), "Resizing preserves the fixed rendering resolution")
	root.size = Vector2i(1280,720)
	var stats := InputEventKey.new()
	stats.physical_keycode = KEY_F3
	stats.pressed = true
	demo._unhandled_key_input(stats)
	_check(not demo.fps_label.visible, "F3 toggles performance display")
	print("HD-2D demo: %d/%d checks passed." % [checks-failures, checks])
	demo.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)


func _walk(start: Vector3, actions: Array, ticks: int) -> Vector3:
	demo.resident.position = start
	demo.resident.velocity = Vector3.ZERO
	await physics_frame
	for tick in ticks:
		for action: String in actions:
			Input.action_press(action)
		await physics_frame
	for action: String in actions:
		Input.action_release(action)
	var end: Vector3 = demo.resident.position
	await physics_frame
	return end


func _blocked(at: Vector3, motion: Vector3) -> bool:
	return demo.resident.test_move(Transform3D(Basis.IDENTITY, at), motion)


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)
