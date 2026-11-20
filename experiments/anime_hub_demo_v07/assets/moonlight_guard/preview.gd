extends Node2D
const ROOT := "res://experiments/anime_hub_demo_v07/assets/moonlight_guard/"
const RenderSettings := preload("res://experiments/anime_hub_demo_v07/tools/render_settings.gd")
const IDS := ["ashen_vanguard","briar_spearman","gloam_arbalist","blackthorn_captain"]
const NAMES := ["Ashen Vanguard","Briar Spearman","Gloam Arbalist","Blackthorn Captain"]
const DIRECTIONS := ["se","sw","ne","nw"]
var samples: Array[Node2D] = []
var direction := 0
var current_action := "idle"
var fireflies: Node2D
var night := true
var status: Label

func _ready() -> void:
	RenderSettings.configure(get_window())
	scale = Vector2.ONE*RenderSettings.SCALE
	get_window().title = "Project Kingdom — Moonlight Guard asset preview"
	var background := Sprite2D.new()
	background.texture = load("res://experiments/anime_hub_demo_v07/assets/moonlight/chapel.png")
	background.centered = false
	background.scale = Vector2(1920,1080)/background.texture.get_size()
	background.modulate = Color("6d7190")
	add_child(background)
	var detail: Node2D = load("res://experiments/anime_hub_demo_v07/assets/moonlight/forest_detail.gd").new()
	detail.panel_root = "res://experiments/anime_hub_demo_v07/assets/moonlight/chapel_panels/"
	detail.scale = Vector2(1920,1080)/Vector2(3072,1728)
	detail.modulate = Color("6d7190")
	add_child(detail)
	var positions := [Vector2(265,795),Vector2(650,795),Vector2(1035,795),Vector2(1510,795)]
	for index in IDS.size():
		var sample: Node2D = load(ROOT+IDS[index]+".tscn").instantiate()
		sample.display_height = 350 if index==3 else 215
		sample.position = positions[index]
		add_child(sample)
		samples.append(sample)
		label(NAMES[index],Rect2(positions[index].x-190,835,380,50),30)
		label("Greatsword boss" if index==3 else ["Sword & shield","Spear guard","Crossbow soldier"][index],Rect2(positions[index].x-190,888,380,40),20)
	fireflies = load(ROOT+"fireflies.tscn").instantiate()
	fireflies.area = Rect2(60,370,1800,440)
	fireflies.amount = 100
	fireflies.insect_size = Vector2(12,22)
	fireflies.night_weight = 1
	add_child(fireflies)
	label("THE MOONLIGHT GUARD",Rect2(90,40,1740,80),48)
	label("Three grim soldiers · one dark captain · reusable nighttime fireflies",Rect2(90,135,1740,60),26)
	status = label("Idle · Southeast · Night",Rect2(90,215,1740,55),24)
	label("1 Idle   2 Walk   3 Attack   4 Hurt   Q / E Turn   N Day / night   Space Pause",Rect2(60,990,1800,50),22)
	if "--capture-guard-assets" in OS.get_cmdline_user_args(): capture.call_deferred()

func label(words: String, rect: Rect2, size: int) -> Label:
	var text := Label.new()
	text.text = words
	text.position = rect.position
	text.size = rect.size
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size",size)
	text.add_theme_color_override("font_color",Color("f4e6c1"))
	text.add_theme_color_override("font_outline_color",Color("171c28"))
	text.add_theme_constant_override("outline_size",5)
	add_child(text)
	return text

func update_samples() -> void:
	for sample in samples: sample.play_action(current_action,DIRECTIONS[direction])
	status.text = current_action.capitalize()+" · "+DIRECTIONS[direction].to_upper()+" · "+("Night" if night else "Day")

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo(): return
	match event.physical_keycode:
		KEY_1: current_action = "idle"
		KEY_2: current_action = "walk"
		KEY_3: current_action = "attack"
		KEY_4: current_action = "hurt"
		KEY_Q: direction = posmod(direction-1,4)
		KEY_E: direction = posmod(direction+1,4)
		KEY_N:
			night = not night
			fireflies.night_weight = 1.0 if night else 0.0
		KEY_SPACE:
			for sample in samples:
				if sample.art.is_playing(): sample.art.pause()
				else: sample.art.play()
			return
	update_samples()

func capture() -> void:
	for i in 12: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/moonlight-forest/moonlight-guard-assets.png")
	get_tree().quit()
