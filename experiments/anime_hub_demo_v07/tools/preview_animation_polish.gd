extends SceneTree

const ROOT := "res://experiments/anime_hub_demo_v07/"
var game: Node2D
var caption: Label
var animation_time := 0.0
var action_done: Dictionary = {}
var recording := false

func _initialize() -> void:
	_start.call_deferred()

func _start() -> void:
	game = load(ROOT+"demo.tscn").instantiate()
	root.add_child(game)
	game.auto_clock = false
	game._load_zone("wilds","river")
	game.player.automated = true
	game.player.grace = 0
	game.dialogue_left = 0
	game.ui.hide()
	for dog in game.dogs:
		dog.set_physics_process(false)
		dog.hide()
	var center: Vector2 = game.Map.Wilds.CAMPS[0]
	game.player.position = center
	game.player.facing = Vector2.RIGHT
	game.player.sprite.set_pose("idle","e",0)
	game.player.sprite.heading_angle = 0
	game.player.reset_physics_interpolation()
	game.camera.zoom = Vector2(2.5,2.5)
	game.camera.force_update_scroll()
	var overlay := CanvasLayer.new()
	root.add_child(overlay)
	caption = Label.new()
	caption.position = Vector2(35,30)
	caption.add_theme_font_size_override("font_size",25)
	caption.add_theme_color_override("font_outline_color",Color("17382c"))
	caption.add_theme_constant_override("outline_size",8)
	overlay.add_child(caption)
	recording = true

func once(id: String) -> bool:
	if action_done.has(id):
		return false
	action_done[id] = true
	return true

func snapshot(id: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(ROOT+"previews/animation_"+id+".png"))

func _physics_process(delta: float) -> bool:
	if not recording:
		return false
	animation_time += delta
	game.player.intent = Vector2.ZERO
	Input.action_release("hub_run")
	var label_text := "IDLE / SWORD SHEATHED"
	if animation_time>=.8 and animation_time<1.6:
		label_text = "WALK / DISTANCE-BASED STEPS"
		game.player.intent = Vector2.RIGHT
	elif animation_time>=1.6 and animation_time<2.3:
		label_text = "DOWNWARD WALK / REGISTERED FOOT PHASE"
		game.player.intent = Vector2.DOWN
	elif animation_time>=2.3 and animation_time<3.0:
		label_text = "RUN / SAME GAIT PHASE"
		Input.action_press("hub_run")
		game.player.intent = Vector2.LEFT
	elif animation_time>=3.0 and animation_time<3.5:
		label_text = "TURN / DRAWN PIVOT VIEWS"
		game.player.intent = Vector2.RIGHT
	elif animation_time>=3.7 and animation_time<4.6:
		label_text = "DRAW → ANTICIPATION → CONTACT → RECOVERY → SHEATHE"
		if once("light"):
			game.player.try_attack(Vector2.RIGHT)
	elif animation_time>=4.6 and animation_time<5.3:
		label_text = "RESUME WALK / EMPTY HANDS"
		game.player.intent = Vector2.LEFT
	elif animation_time>=5.4 and animation_time<6.5:
		label_text = "Q / WIND SLASH / TIMED RELEASE"
		if once("skill"):
			game.player.facing = Vector2.RIGHT
			game.player.try_skill()
	elif animation_time>=6.6 and animation_time<7.5:
		label_text = "DOWNWARD-FACING DRAW / STRIKE / SHEATHE"
		if once("down"):
			game.player.try_attack(Vector2(1,1))
	elif animation_time>=7.6 and animation_time<8.5:
		label_text = "REAR VIEW / CONSISTENT HEAD AND BOOT ANCHORS"
		if once("back"):
			game.player.try_attack(Vector2(-1,-1))
	for marker in [[3.74,"draw"],[3.96,"contact"],[4.25,"sheathe"],[5.77,"wind"]]:
		if animation_time>=marker[0] and once("snapshot_"+marker[1]):
			snapshot.call_deferred(marker[1])
	caption.text = label_text
	if game.player.swing>0:
		caption.text += "\n"+game.player.combat_art.current_phase.to_upper()
	if animation_time>9.1:
		Input.action_release("hub_run")
		quit()
	return false
