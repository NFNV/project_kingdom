extends Node
## Keep the live journey in memory while its overworld is displayed.
const OVERWORLD := preload("res://experiments/overworld_2d_v01/world.tscn")
var hub: Node2D
var overworld: Node2D
var fade: ColorRect
var window_state: Dictionary = {}
var hub_process_mode: ProcessMode
var audio_process_mode: ProcessMode
var returning := false
var regional_visit := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	fade = ColorRect.new()
	fade.size = Vector2(1920,1080)
	fade.color = Color("10241d")
	fade.modulate.a = 0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade)

func fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade,"modulate:a",alpha,.22)
	await tween.finished

func settle_player() -> void:
	# Travel finishes transient actions but keeps health and skill recharge.
	hub.player.swing = 0
	hub.player.windup = 0
	hub.player.skill_buffer = 0
	hub.player.light_buffer = 0
	hub.player.knockback = Vector2.ZERO
	hub.player.stop_motion()

func begin(from_zone := "town") -> void:
	if is_instance_valid(overworld):
		if regional_visit: await resume_from_region(from_zone)
		return
	settle_player()
	await fade_to(1)
	var window := get_window()
	window_state = {"size":window.content_scale_size,"mode":window.content_scale_mode,"aspect":window.content_scale_aspect,"title":window.title}
	hub_process_mode = hub.process_mode
	audio_process_mode = hub.audio.process_mode
	# Persist the current facts at a safe town-side checkpoint, using the existing
	# save schema. No separate inventory, quest graph or fresh hero is created.
	var saved := save_checkpoint(true) if hub.autosave_enabled else true
	hub.autosave_queued = false
	hub.camera.enabled = false
	hub.ui.hide()
	hub.hide()
	hub.process_mode = Node.PROCESS_MODE_DISABLED
	hub.audio.process_mode = Node.PROCESS_MODE_ALWAYS
	hub.audio.enter_zone("trail")
	get_viewport().canvas_transform = Transform2D.IDENTITY
	overworld = OVERWORLD.instantiate()
	overworld.linked_journey = true
	overworld.day_phase = hub.clock
	overworld.auto_clock = hub.auto_clock
	overworld.clock_target = hub.clock_target
	overworld.journey_clock_changed.connect(sync_journey_clock)
	overworld.return_requested.connect(return_to_town,CONNECT_DEFERRED)
	overworld.mill_requested.connect(visit_mill,CONNECT_DEFERRED)
	overworld.save_requested.connect(save_from_overworld)
	get_tree().root.add_child(overworld)
	if from_zone=="mill_garden": overworld.enter_from_mill()
	else: overworld.enter_from_town()
	if not saved: overworld.notice = "The journey is still active, but autosaving failed: "+hub.saves.last_error
	overworld.transitioning = true
	await fade_to(0)
	overworld.transitioning = false

func sync_journey_clock(phase: float) -> void:
	hub.clock = phase
	if is_instance_valid(overworld): hub.clock_target = overworld.clock_target

func save_checkpoint(automatic := false) -> bool:
	var document: Dictionary = hub.make_save_document()
	var zone := "mill_garden" if hub.zone in ["mill_garden","mill_room"] else "town"
	var at: Vector2 = hub.Map.arrival(zone,"overworld")
	document.player.zone = zone
	document.player.erase("mill_room_layout")
	if zone=="mill_garden": document.player.mill_garden_layout = hub.Mill.GARDEN_LAYOUT
	document.player.position = [at.x,at.y]
	return hub.saves.write_document(document,hub.save_path+".auto" if automatic else hub.save_path)

func save_from_overworld() -> void:
	if not is_instance_valid(overworld) or overworld.transitioning: return
	var saved := save_checkpoint()
	overworld.notice = ("Journey saved · Continue returns to Windsong Mill's garden." if hub.zone in ["mill_garden","mill_room"] else "Journey saved · Continue returns to Garden Square's southwest gate.") if saved else hub.saves.last_error
	overworld.notice_left = 6

func _process(_delta: float) -> void:
	if is_instance_valid(overworld) and not regional_visit:
		var quiet: bool = overworld.paused or overworld.region_map
		if hub.audio.paused!=quiet: hub.audio.set_paused(quiet)

func restore_window() -> void:
	var window := get_window()
	window.content_scale_size = window_state.size
	window.content_scale_mode = window_state.mode
	window.content_scale_aspect = window_state.aspect
	window.title = window_state.title

func visit_mill() -> void:
	if returning or regional_visit or not is_instance_valid(overworld): return
	regional_visit = true
	overworld.transitioning = true
	await fade_to(1)
	overworld.hide()
	overworld.process_mode = Node.PROCESS_MODE_DISABLED
	restore_window()
	hub._load_zone("mill_garden","overworld")
	hub.show()
	hub.ui.show()
	hub.process_mode = hub_process_mode
	hub.audio.process_mode = audio_process_mode
	hub.audio.set_paused(false)
	hub.camera.enabled = true
	hub.camera.make_current()
	hub.camera.force_update_scroll()
	hub.dialogue_left = 0
	hub.talk_panel.hide()
	await fade_to(0)
	hub.transitioning = false
	hub.queue_autosave()
	hub.ui.show_notice("Windsong Mill · E to talk or enter · South gate returns to the Greenshire.")

func resume_from_region(from_zone: String) -> void:
	settle_player()
	await fade_to(1)
	if hub.autosave_enabled: save_checkpoint(true)
	hub.autosave_queued = false
	hub.camera.enabled = false
	hub.ui.hide()
	hub.hide()
	hub.process_mode = Node.PROCESS_MODE_DISABLED
	hub.audio.process_mode = Node.PROCESS_MODE_ALWAYS
	hub.audio.enter_zone("trail")
	get_viewport().canvas_transform = Transform2D.IDENTITY
	get_window().content_scale_size = Vector2i(1920,1080)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	overworld.day_phase = hub.clock
	overworld.clock_target = hub.clock_target
	overworld.auto_clock = hub.auto_clock
	overworld.show()
	overworld.process_mode = Node.PROCESS_MODE_INHERIT
	if from_zone=="mill_garden": overworld.enter_from_mill()
	else: overworld.enter_from_town()
	regional_visit = false
	await fade_to(0)
	overworld.transitioning = false

func return_to_town() -> void:
	if returning or not is_instance_valid(overworld): return
	returning = true
	overworld.transitioning = true
	overworld.velocity = Vector2.ZERO
	await fade_to(1)
	overworld.process_mode = Node.PROCESS_MODE_DISABLED
	overworld.hide()
	var window := get_window()
	window.content_scale_size = window_state.size
	window.content_scale_mode = window_state.mode
	window.content_scale_aspect = window_state.aspect
	window.title = window_state.title
	if hub.zone!="town": hub._load_zone("town","overworld")
	hub.player.position = hub.Map.arrival("town","overworld")
	hub.player.facing = Vector2(1,-.65).normalized()
	settle_player()
	hub.player.reset_physics_interpolation()
	hub.near_exit = ""
	hub.nearest = ""
	hub.dialogue_left = 0
	hub.talk_panel.hide()
	hub.travel_cooldown = 1.2
	hub.show()
	hub.ui.show()
	hub.process_mode = hub_process_mode
	hub.camera.enabled = true
	hub.camera.make_current()
	hub.camera.reset_smoothing()
	hub.camera.force_update_scroll()
	hub.audio.set_paused(false)
	hub.audio.process_mode = audio_process_mode
	hub.audio.enter_zone("town")
	overworld.queue_free()
	overworld = null
	await get_tree().physics_frame
	await fade_to(0)
	hub.transitioning = false
	hub.queue_autosave()
	hub.ui.show_notice("Garden Square · The southwest road leads to the Greenshire.")
	returning = false

func _exit_tree() -> void:
	if is_instance_valid(overworld): overworld.queue_free()
