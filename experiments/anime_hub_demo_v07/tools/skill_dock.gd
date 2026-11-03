extends Panel
## Compact equipment-cross layout; only implemented skills are interactive.
const ICON := "res://experiments/anime_hub_demo_v07/assets/hud/wind_slash_v1.png"
var hub: Node2D
var button: Button
var status: Label
var recharge: ProgressBar
var icon: TextureRect
var countdown: Label
var serif: Font

func _ready() -> void:
	size = Vector2(216,230)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	button = Button.new()
	button.position = Vector2(66,0)
	button.size = Vector2(84,84)
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = "Wind Slash · Q or click\nA piercing wind blade. Can be queued during a sword attack."
	for state in ["normal","hover","pressed","disabled"]:
		var frame := StyleBoxFlat.new()
		frame.bg_color = Color("2b322e")
		frame.border_color = Color("d9c18a") if state=="hover" else Color("a18c62")
		frame.set_border_width_all(2)
		frame.set_corner_radius_all(5)
		frame.shadow_color = Color(0,0,0,.35)
		frame.shadow_size = 4
		button.add_theme_stylebox_override(state,frame)
	add_child(button)
	icon = TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.texture = load(ICON)
	icon.position = Vector2(6,6)
	icon.size = Vector2(72,72)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)
	countdown = make_label("",Vector2(0,28),Vector2(84,30),22,button)
	countdown.add_theme_color_override("font_color",Color("fff3cb"))
	countdown.add_theme_constant_override("outline_size",5)
	countdown.add_theme_color_override("font_outline_color",Color("182c29"))
	var badge := Panel.new()
	badge.position = Vector2(57,-8)
	badge.size = Vector2(26,26)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color("293c34")
	badge_style.border_color = Color("c4aa75")
	badge_style.set_border_width_all(1)
	badge_style.set_corner_radius_all(5)
	badge.add_theme_stylebox_override("panel",badge_style)
	add_child(badge)
	make_label("Q",Vector2(0,2),Vector2(26,24),15,badge)
	for at in [Vector2(11,78),Vector2(153,78),Vector2(82,137)]:
		var empty := Panel.new()
		empty.position = at
		empty.size = Vector2(52,52)
		empty.mouse_filter = Control.MOUSE_FILTER_STOP
		empty.tooltip_text = "No skill equipped"
		var frame := StyleBoxFlat.new()
		frame.bg_color = Color(.075,.105,.09,.70)
		frame.border_color = Color(.64,.56,.39,.45)
		frame.set_border_width_all(1)
		frame.set_corner_radius_all(4)
		empty.add_theme_stylebox_override("panel",frame)
		add_child(empty)
		var mark := make_label("·",Vector2(0,9),Vector2(52,30),23,empty)
		mark.modulate.a = .35
	make_label("Wind Slash",Vector2(0,191),Vector2(216,24),18,self)
	status = make_label("Ready",Vector2(0,215),Vector2(216,19),12,self)
	status.add_theme_color_override("font_color",Color("c3c9b4"))
	recharge = ProgressBar.new()
	recharge.position = Vector2(70,88)
	recharge.size = Vector2(76,4)
	recharge.show_percentage = false
	recharge.add_theme_font_size_override("font_size",1)
	recharge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back := StyleBoxFlat.new()
	back.bg_color = Color("172b26")
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("a8d6cc")
	recharge.add_theme_stylebox_override("background",back)
	recharge.add_theme_stylebox_override("fill",fill)
	add_child(recharge)
	recharge.size = Vector2(76,4)
	button.pressed.connect(func(): hub.player.try_skill())

func make_label(words: String, at: Vector2, dimensions: Vector2, font_size: int, parent: Node) -> Label:
	var text := Label.new()
	text.text = words
	text.position = at
	text.size = dimensions
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_font_size_override("font_size",font_size)
	text.add_theme_color_override("font_color",Color("eadbb9"))
	text.add_theme_color_override("font_shadow_color",Color("122820"))
	text.add_theme_constant_override("shadow_offset_y",2)
	if serif: text.add_theme_font_override("font",serif)
	parent.add_child(text)
	return text

func _process(_delta: float) -> void:
	if not is_instance_valid(hub.player): return
	var remaining: float = hub.player.skill_cooldown
	countdown.visible = remaining>.05
	countdown.text = "%.1f" % remaining
	icon.modulate = Color("69857d") if remaining>0 or button.disabled else Color.WHITE
	recharge.value = recharge.max_value-remaining
	queue_redraw()

func _draw() -> void:
	# Fine worn-metal brackets join the empty slots without a large HUD box.
	var ink := Color(.70,.62,.43,.45)
	for side in [-1,1]:
		draw_polyline(PackedVector2Array([Vector2(108+side*44,50),Vector2(108+side*57,66),Vector2(108+side*57,74)]),ink,1.0,true)
		draw_polyline(PackedVector2Array([Vector2(108+side*57,132),Vector2(108+side*35,153)]),ink,1.0,true)
