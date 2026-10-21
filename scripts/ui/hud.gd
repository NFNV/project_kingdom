class_name KingdomHUD
extends CanvasLayer

signal pause_requested
signal restart_requested

const INK := Color("142c2d")
const PAPER := Color("f0e5c5")
const MUTED := Color("afbfaa")
const GOLD := Color("e8bd78")

var root: Control
var objective_status: Label
var ownership: Label
var capture_bar: ProgressBar
var health_text: Label
var faction_text: Label
var health_display: Control
var map_display: Control
var prompt: Panel
var prompt_title: Label
var prompt_text: Label
var intro: Control
var modal: Control
var modal_title: Label
var modal_text: Label
var resume_button: Button
var restart_button: Button
var mode: String = "playing"
var intro_time: float = 7.0
var hero: KingdomActor
var keep: KingdomCastle
var health_current: int = 8
var health_maximum: int = 8


func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_identity()
	_build_objective()
	_build_footer()
	_build_prompt()
	_build_intro()
	_build_modal()


func _panel(parent: Control, point: Vector2, size: Vector2) -> Panel:
	var panel := Panel.new()
	panel.position = point
	panel.size = size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(Color(INK, 0.94), Color("5a7060")))
	parent.add_child(panel)
	return panel


func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.shadow_color = Color(0.03, 0.09, 0.08, 0.2)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	return style


func _label(parent: Control, text: String, point: Vector2,
		font_size: int = 16, color: Color = PAPER) -> Label:
	var label := Label.new()
	label.text = text
	label.position = point
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _anchor(control: Control, at: Vector2, offset: Vector2, size: Vector2) -> void:
	control.anchor_left = at.x
	control.anchor_right = at.x
	control.anchor_top = at.y
	control.anchor_bottom = at.y
	control.offset_left = offset.x
	control.offset_top = offset.y
	control.offset_right = offset.x + size.x
	control.offset_bottom = offset.y + size.y


func _build_identity() -> void:
	var panel := _panel(root, Vector2(24, 24), Vector2(286, 139))
	_label(panel, "P R O J E C T   K I N G D O M", Vector2(20, 13), 11, GOLD)
	_label(panel, "The Willow March", Vector2(19, 35), 25)
	faction_text = _label(panel, "CAT KINGDOM  /  WARRIOR", Vector2(20, 76), 11, Color.WHITE)
	health_display = Control.new()
	health_display.position = Vector2(20, 106)
	health_display.size = Vector2(205, 12)
	panel.add_child(health_display)
	health_display.draw.connect(_draw_health)
	health_text = _label(panel, "8 / 8", Vector2(229, 101), 13, MUTED)


func _build_objective() -> void:
	var panel := _panel(root, Vector2.ZERO, Vector2(348, 139))
	_anchor(panel, Vector2(1, 0), Vector2(-372, 24), Vector2(348, 139))
	_label(panel, "01  /  THE BORDER KEEP", Vector2(20, 13), 11, GOLD)
	_label(panel, "Claim Willow Keep", Vector2(19, 35), 25)
	objective_status = _label(panel, "Defeat the sentries · 3 remaining", Vector2(20, 76), 14)
	ownership = _label(panel, "DOG KINGDOM  ·  DEFENDED", Vector2(20, 112), 10, Color.WHITE)
	capture_bar = ProgressBar.new()
	capture_bar.position = Vector2(20, 103)
	capture_bar.max_value = 1.0
	capture_bar.show_percentage = false
	var track := StyleBoxFlat.new()
	track.bg_color = Color("334b43")
	track.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = GOLD
	fill.set_corner_radius_all(2)
	capture_bar.add_theme_stylebox_override("background", track)
	capture_bar.add_theme_stylebox_override("fill", fill)
	panel.add_child(capture_bar)
	capture_bar.size = Vector2(308, 4)


func _build_footer() -> void:
	var controls := _panel(root, Vector2.ZERO, Vector2(563, 44))
	_anchor(controls, Vector2(0, 1), Vector2(24, -68), Vector2(563, 44))
	_label(controls, "W A S D   Move     SPACE / LMB   Attack     ESC   Pause     R   Restart",
		Vector2(16, 12), 13, MUTED)
	var panel := _panel(root, Vector2.ZERO, Vector2(200, 176))
	_anchor(panel, Vector2.ONE, Vector2(-224, -200), Vector2(200, 176))
	_label(panel, "T H E   B O R D E R L A N D", Vector2(14, 11), 10, GOLD)
	map_display = Control.new()
	map_display.position = Vector2(12, 36)
	map_display.size = Vector2(176, 125)
	panel.add_child(map_display)
	map_display.draw.connect(_draw_map)


func _build_prompt() -> void:
	prompt = _panel(root, Vector2.ZERO, Vector2(410, 82))
	_anchor(prompt, Vector2(0.5, 1), Vector2(-205, -172), Vector2(410, 82))
	prompt_title = _label(prompt, "WILLOW KEEP", Vector2(20, 13), 19, GOLD)
	prompt_text = _label(prompt, "Defeat the sentries to claim this ground.", Vector2(20, 46), 14)
	prompt.hide()


func _build_intro() -> void:
	intro = Control.new()
	root.add_child(intro)
	_anchor(intro, Vector2(0.5, 0), Vector2(-190, 35), Vector2(380, 90))
	var title := _label(intro, "A BORDER WORTH KEEPING", Vector2.ZERO, 17, PAPER)
	title.size.x = 380
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_shadow_color", INK)
	title.add_theme_constant_override("shadow_offset_y", 2)
	var subtitle := _label(intro, "Follow the old road northeast.", Vector2(0, 30), 14, PAPER)
	subtitle.size.x = 380
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_shadow_color", INK)
	subtitle.add_theme_constant_override("shadow_offset_y", 2)


func _build_modal() -> void:
	modal = Control.new()
	root.add_child(modal)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.07, 0.08, 0.76)
	modal.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := _panel(modal, Vector2.ZERO, Vector2(500, 330))
	_anchor(panel, Vector2(0.5, 0.5), Vector2(-250, -165), Vector2(500, 330))
	_label(panel, "P R O J E C T   K I N G D O M", Vector2(32, 24), 11, GOLD)
	modal_title = _label(panel, "A moment's rest", Vector2(31, 57), 32)
	modal_text = _label(panel, "", Vector2(32, 112), 16, MUTED)
	modal_text.size = Vector2(435, 85)
	modal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resume_button = _button(panel, "Return to the march", Vector2(32, 220), Vector2(270, 44))
	resume_button.pressed.connect(func() -> void: pause_requested.emit())
	restart_button = _button(panel, "Start again", Vector2(316, 220), Vector2(152, 44))
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	_label(panel, "WASD to move · Hold Space or LMB to attack", Vector2(32, 290), 12, MUTED)
	modal.hide()


func _button(parent: Control, text: String, point: Vector2, size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = point
	button.size = size
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", PAPER)
	button.add_theme_stylebox_override("normal", _style(Color("34534b"), Color("71846a")))
	button.add_theme_stylebox_override("hover", _style(Color("48675a"), GOLD))
	button.add_theme_stylebox_override("pressed", _style(Color("243e3a"), GOLD))
	button.add_theme_stylebox_override("focus", _style(Color(0, 0, 0, 0), GOLD))
	parent.add_child(button)
	return button


func refresh(player: KingdomActor, castle: KingdomCastle) -> void:
	hero = player
	keep = castle
	faction_text.text = "%s  /  WARRIOR" % KingdomActor.faction_name(player.faction).to_upper()
	faction_text.modulate = KingdomActor.faction_color(player.faction)
	ownership.text = "%s  ·  %s" % [KingdomActor.faction_name(castle.owner_faction).to_upper(),
		"SECURED" if castle.state == KingdomCastle.State.CAPTURED else "DEFENDED"]
	ownership.modulate = KingdomActor.faction_color(castle.owner_faction)
	health_current = player.health.current
	health_maximum = player.health.maximum
	health_text.text = "%d / %d" % [health_current, health_maximum]
	health_display.queue_redraw()
	map_display.queue_redraw()
	capture_bar.value = castle.progress
	var remaining := castle.remaining_defenders()
	match castle.state:
		KingdomCastle.State.LOCKED:
			objective_status.text = "Defeat the sentries · %d remaining" % remaining
		KingdomCastle.State.READY:
			objective_status.text = "Stand in the circle to raise your banner."
		KingdomCastle.State.CAPTURING:
			objective_status.text = "Hold the ground · %d%%" % roundi(castle.progress * 100)
		KingdomCastle.State.CONTESTED:
			objective_status.text = "Enemy nearby · clear the capture circle."
		KingdomCastle.State.CAPTURED:
			objective_status.text = "Willow Keep belongs to the %s." % KingdomActor.faction_name(castle.owner_faction)
	var near_keep := player.global_position.distance_to(castle.capture_position()) < 225.0
	if near_keep:
		intro_time = 0.0
		intro.hide()
	prompt.visible = near_keep and mode == "playing"
	if castle.state == KingdomCastle.State.LOCKED:
		prompt_title.text = "%d SENTRIES STILL STAND" % remaining
		prompt_text.text = "Clear the defenders, then hold the circle."
	elif castle.state == KingdomCastle.State.CONTESTED:
		prompt_title.text = "THE GROUND IS CONTESTED"
		prompt_text.text = "Defeat nearby enemies before raising the banner."
	elif castle.state == KingdomCastle.State.CAPTURING:
		var banner_color := "RED" if player.faction == KingdomActor.Faction.CAT else "BLUE"
		prompt_title.text = "RAISING THE %s BANNER · %d%%" % [banner_color, roundi(castle.progress * 100)]
		prompt_text.text = "Stay inside the circle for five seconds."
	else:
		prompt_title.text = "THE KEEP IS UNGUARDED"
		prompt_text.text = "Enter the marked circle to claim Willow Keep."


func _process(delta: float) -> void:
	if mode == "playing":
		intro_time = maxf(0.0, intro_time - delta)
		intro.modulate.a = minf(1.0, intro_time / 1.5)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("restart"):
		restart_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause") and mode in ["playing", "paused"]:
		pause_requested.emit()
		get_viewport().set_input_as_handled()


func show_pause(paused: bool) -> void:
	mode = "paused" if paused else "playing"
	modal.visible = paused
	if paused:
		modal_title.text = "A moment's rest"
		modal_text.text = "The keep can wait.\nClear its three sentries, then hold the capture circle."
		resume_button.show()
		resume_button.grab_focus()


func show_result(won: bool) -> void:
	mode = "victory" if won else "defeat"
	intro.hide()
	prompt.hide()
	modal.show()
	resume_button.hide()
	modal_title.text = "The keep is yours." if won else "Your watch has ended."
	if won and is_instance_valid(hero):
		var banner_color := "red" if hero.faction == KingdomActor.Faction.CAT else "blue"
		modal_text.text = "The %s banner flies over Willow Keep.\nThe %s holds the border — for now." % [banner_color, KingdomActor.faction_name(hero.faction)]
	else:
		modal_text.text = "The dog sentries held their ground.\nWatch for their windup, strike, then move away."
	restart_button.position = Vector2(32, 220)
	restart_button.size.x = 436
	restart_button.text = "March again  ·  R"
	restart_button.grab_focus()


func _draw_health() -> void:
	var width := 196.0 / health_maximum
	for index in health_maximum:
		var rect := Rect2(index * width, 0, width - 4, 10)
		health_display.draw_rect(rect, Color("42564a"))
		if index < health_current:
			health_display.draw_rect(rect, Color("cd7866"))
			health_display.draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2)), Color("efa18a"))


func _map_point(point: Vector2) -> Vector2:
	return point / Vector2(KingdomMap.WORLD_SIZE) * map_display.size


func _draw_map() -> void:
	map_display.draw_rect(Rect2(Vector2.ZERO, map_display.size), Color("2a4849"))
	map_display.draw_rect(Rect2(_map_point(Vector2(128, 128)), _map_point(Vector2(2304, 1536))), Color("60764e"))
	var route := PackedVector2Array()
	for point: Vector2 in KingdomMap.ROAD:
		route.append(_map_point(point))
	map_display.draw_polyline(route, Color("b4b17b"), 2.0)
	map_display.draw_rect(Rect2(_map_point(Vector2(355, 1300)) - Vector2(3, 3), Vector2(6, 6)), KingdomActor.faction_color(KingdomActor.Faction.CAT))
	if is_instance_valid(keep):
		var point := _map_point(keep.capture_position())
		map_display.draw_circle(point, 6, GOLD, false, 1.0)
		map_display.draw_rect(Rect2(point - Vector2(2, 2), Vector2(4, 4)), GOLD)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is KingdomActor and not enemy.health.is_dead():
			map_display.draw_circle(_map_point(enemy.global_position), 2.5, KingdomActor.faction_color(enemy.faction))
	if is_instance_valid(hero):
		var point := _map_point(hero.global_position)
		map_display.draw_circle(point, 4, Color("eaf2d5"))
		map_display.draw_circle(point, 2.5, KingdomActor.faction_color(hero.faction))
		map_display.draw_line(point, point + hero.facing * 8, Color("cfe8e1"), 1.5)
