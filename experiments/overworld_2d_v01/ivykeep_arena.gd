extends Node2D

signal return_requested
signal loot_claimed

const Boss := preload("res://experiments/overworld_2d_v01/stoneback.gd")
const Fighter := preload("res://experiments/anime_hub_demo_v07/tools/actor.gd")
const RenderSettings := preload("res://experiments/anime_hub_demo_v07/tools/render_settings.gd")
const TreasureChest := preload("res://experiments/anime_hub_demo_v07/assets/loot/treasure_chest.tscn")
const BACKDROP := "res://experiments/overworld_2d_v01/art/boss/ivykeep_courtyard.png"
const BOSS_FEET := Vector2(960, 610)
const GROUND_SCALE := Vector2(25, 15)
const FLOOR_CENTER := Vector2(960, 675)
const FLOOR_RADIUS := Vector2(730, 255)
const START := Vector2(960, 820)
const CHEST_REACH := 104.0

class DuelState extends RefCounted:
	var maximum_health := Boss.HEARTS
	var health := Boss.HEARTS
	var gear := {"weapon": "travel_sword", "shield": "trail_shield"}
	var attributes := {"attack": 1, "wind": 3, "guard": 1.0, "speed": 1.0, "recharge": 6.0}

	func equipped_id(slot: String) -> String:
		return gear.get(slot, "")

	func stats() -> Dictionary:
		return attributes

class QuietAudio extends RefCounted:
	func footsteps(_actor: Node2D, _distance: float, _running: bool) -> void:
		pass

	func play_event(_event: String, _at: Vector2, _gain: float) -> void:
		pass

class Guardian extends Node2D:
	var boss: Boss
	var hit_feedback := ""
	var feedback_left := 0.0
	var active: bool:
		get: return boss.fighting()

	func receive_hit(_heading: Vector2, damage: int, _force := 170.0) -> bool:
		var landed := boss.take_damage(damage)
		hit_feedback = "−%d HP" % damage if landed else "Shielded · Strike during the windup or recovery"
		feedback_left = 0.85
		return landed

	func receive_parry() -> void:
		boss.set_phase("recover", Boss.RECOVERY)

var boss: Boss
var actor_tint := Color.WHITE
var transitioning := true
var damage_flash := 0.0
var player: CharacterBody2D
var guardian: Guardian
var boss_body: StaticBody2D
var chest: Node2D
var loot_message := ""
var journey_state: Node
var hud: Node2D
var backdrop: Texture2D
var state := DuelState.new()
var audio = QuietAudio.new()
var world: Node2D
var dogs: Array = []
var zone := "ivykeep"
var paused := false
var shopping := false
var title_active := false
var peaceful_mode: bool:
	get: return not boss.fighting()

func _ready() -> void:
	scale = Vector2.ONE * RenderSettings.SCALE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	backdrop = load(BACKDROP)
	world = self
	if not InputMap.has_action("hub_run"):
		InputMap.add_action("hub_run")
		var shift := InputEventKey.new()
		shift.physical_keycode = KEY_SHIFT
		InputMap.action_add_event("hub_run", shift)
	build_collisions()
	guardian = Guardian.new()
	guardian.position = BOSS_FEET
	guardian.boss = boss
	guardian.draw.connect(func(): boss.draw_sprite(guardian, Vector2.ZERO, 32.0, actor_tint))
	add_child(guardian)
	dogs.append(guardian)
	chest = TreasureChest.instantiate()
	chest.position = BOSS_FEET
	chest.modulate = actor_tint
	add_child(chest)
	hud = Node2D.new()
	hud.z_index = 3
	hud.draw.connect(draw_hud)
	add_child(hud)
	retry()

func retry() -> void:
	for wave in get_tree().get_nodes_in_group("wind_slashes"):
		if wave.get_parent() == self:
			remove_child(wave)
			wave.queue_free()
	if is_instance_valid(player):
		remove_child(player)
		player.queue_free()
	boss.challenge()
	boss_body.collision_layer = 4
	guardian.show()
	chest.hide()
	chest.reset()
	loot_message = ""
	state.health = state.maximum_health
	damage_flash = 0.0
	guardian.feedback_left = 0
	player = Fighter.new()
	player.hub = self
	player.controlled = true
	player.automated = true
	player.position = START
	player.facing = Vector2.UP
	add_child(player)
	player.collision_mask |= 4
	player.sprite.heading_angle = -PI / 2
	player.sprite.set_pose("idle", "n", 0)
	player.enter_combat()

func build_collisions() -> void:
	var wall := StaticBody2D.new()
	var edge := CollisionPolygon2D.new()
	edge.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
	var points := PackedVector2Array()
	for i in 64:
		points.append(FLOOR_CENTER + Vector2.from_angle(TAU * i / 64) * FLOOR_RADIUS)
	edge.polygon = points
	wall.add_child(edge)
	add_child(wall)
	boss_body = StaticBody2D.new()
	boss_body.position = BOSS_FEET
	var feet := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 28
	feet.shape = circle
	boss_body.add_child(feet)
	add_child(boss_body)

func clear_line(_from: Vector2, _to: Vector2) -> bool:
	return true

func actor_yielded(_actor: Node2D) -> void:
	boss.phase = "idle"
	player.weapon.sync_pose()
	player.shield.sync_pose()

func attack_hit(damage: int) -> void:
	var direction := Fighter.ground_vector(player.position - guardian.position).normalized()
	if player.receive_hit(direction, damage, 170.0, guardian):
		damage_flash = 0.35

func input_direction() -> Vector2:
	return Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	).limit_length()

func _physics_process(delta: float) -> void:
	if transitioning:
		return
	player.intent = input_direction() if boss.phase != "idle" else Vector2.ZERO
	player.set_guard(boss.fighting() and Input.is_physical_key_pressed(KEY_F))
	if boss.fighting():
		if player.combat_left <= delta:
			player.enter_combat()
		boss.tick(delta, Boss.SITE + (player.position - BOSS_FEET) / GROUND_SCALE, attack_hit)
	if boss.phase == "defeated" and not chest.visible:
		guardian.hide()
		boss_body.collision_layer = 0
		chest.show()
	guardian.z_index = 1 if player.position.y < BOSS_FEET.y else 0
	chest.z_index = guardian.z_index
	damage_flash = maxf(0.0, damage_flash - delta)
	guardian.feedback_left = maxf(0.0, guardian.feedback_left - delta)
	guardian.queue_redraw()
	hud.queue_redraw()
	queue_redraw()

func near_chest() -> bool:
	return Fighter.ground_vector(player.position - chest.position).length() <= CHEST_REACH

func open_reward() -> void:
	if boss.phase != "defeated" or not chest.visible or chest.opened or not near_chest():
		return
	if is_instance_valid(journey_state) and journey_state.stoneback_stage == journey_state.StonebackStage.ACCEPTED:
		if not journey_state.collect_stoneback_relic():
			loot_message = "Could not take the seal · Press E to try again"
			return
		chest.open()
		loot_message = "Ivykeep Seal collected · Return to Rowan at Windsong Mill"
		audio.play_event("coin", chest.position, -7)
		loot_claimed.emit()
	else:
		chest.open()
		loot_message = "The chest is empty"

func _draw() -> void:
	draw_texture_rect(backdrop, Rect2(Vector2.ZERO, Vector2(1920, 1080)), false, actor_tint)
	if boss.phase in ["warning", "sweep"]:
		draw_attack_area()

func draw_attack_area() -> void:
	var pattern := boss.attack()
	var fill := Color(1, .22, .1, .36 if boss.phase == "sweep" else .22)
	var outline := Color("ff995c")
	if pattern.width > 0.0:
		var side := boss.heading.orthogonal() * float(pattern.width)
		var end := boss.heading * float(pattern.range)
		var corners := PackedVector2Array()
		for offset: Vector2 in [side, end + side, end - side, -side]:
			corners.append(BOSS_FEET + offset * GROUND_SCALE)
		draw_colored_polygon(corners, fill)
		corners.append(corners[0])
		draw_polyline(corners, outline, 3, true)
		return
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in 65:
		var radial := Vector2.from_angle(TAU * i / 64) * GROUND_SCALE
		outer.append(BOSS_FEET + radial * float(pattern.range))
		inner.append(BOSS_FEET + radial * float(pattern.inner))
	if pattern.inner > 0.0:
		for i in 64:
			draw_colored_polygon(PackedVector2Array([outer[i], outer[i + 1], inner[i + 1], inner[i]]), fill)
		draw_polyline(inner, outline, 3, true)
	else:
		draw_colored_polygon(outer.slice(0, 64), fill)
	draw_polyline(outer, outline, 3, true)

func draw_hud() -> void:
	var font := ThemeDB.fallback_font
	if damage_flash > 0.0:
		hud.draw_rect(Rect2(0, 0, 1920, 1080), Color(0.65, 0.09, 0.05, damage_flash * 0.45))
	if boss.phase == "idle":
		hud.draw_rect(Rect2(0, 0, 1920, 1080), Color(0.04, 0.08, 0.07, .48))
		hud.draw_rect(Rect2(620, 442, 680, 154), Color("203e36"))
		hud.draw_string(font, Vector2(620, 504), "Stoneback defeated you", HORIZONTAL_ALIGNMENT_CENTER, 680, 34, Color("f6edcf"))
		hud.draw_string(font, Vector2(620, 553), "R  Retry the duel     ·     F or Esc  Return to the Greenshire", HORIZONTAL_ALIGNMENT_CENTER, 680, 21, Color("f6edcf"))
		return
	var title := "IVYKEEP RUINS   /   STONEBACK"
	if boss.fighting() and boss.enraged(): title += "   ·   ENRAGED"
	if boss.phase == "defeated": title += "   ·   VICTORY"
	var cue: String = {
		"guard": "Shield raised", "warning": "%s incoming · Shield open" % boss.attack().name,
		"sweep": boss.attack().name, "recover": "Open to attack",
		"defeated": "Victory",
	}[boss.phase]
	if boss.phase == "defeated":
		cue = loot_message if not loot_message.is_empty() else "Victory · Walk to the chest"
		if not chest.opened and near_chest() and loot_message.is_empty():
			cue = "Victory · E Open chest"
	hud.draw_rect(Rect2(625, 22, 670, 106 if boss.fighting() else 81), Color("203e36"))
	hud.draw_string(font, Vector2(648, 53), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("f6edcf"))
	hud.draw_string(font, Vector2(648, 83), cue, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("f6edcf"))
	if boss.fighting():
		hud.draw_rect(Rect2(648, 101, 624, 8), Color("513d31"))
		hud.draw_rect(Rect2(648, 101, 624.0 * boss.health / Boss.HEALTH, 8), Color("e2965b"))
	if boss.fighting() and guardian.feedback_left > 0:
		hud.draw_string(font, Vector2(625, 153), guardian.hit_feedback, HORIZONTAL_ALIGNMENT_CENTER, 670, 19, Color("fff1c6"))
	hud.draw_rect(Rect2(395, 992, 1130, 65), Color("203e36"))
	var wind := "ready" if player.skill_cooldown <= 0 else "%.1fs" % player.skill_cooldown
	hud.draw_string(font, Vector2(419, 1017), "Hearts %d / %d    ·    Stamina %d    ·    Wind Slash %s" % [player.health, player.maximum_health, int(player.stamina), wind], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f6edcf"))
	var controls := "WASD Move   ·   Space Strike   ·   F Guard / Parry   ·   V Roll   ·   Q Wind Slash   ·   Esc Leave"
	if boss.phase == "defeated":
		controls = "WASD Move" + ("" if chest.opened else "   ·   E Open chest")
		controls += "   ·   R Rematch   ·   F or Esc Return to the Greenshire"
	hud.draw_string(font, Vector2(419, 1042), controls, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f6edcf"))

func _unhandled_key_input(event: InputEvent) -> void:
	if transitioning or not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_ESCAPE, KEY_F:
			if event.physical_keycode == KEY_F and boss.fighting():
				player.set_guard(true)
				return
			transitioning = true
			return_requested.emit()
		KEY_R:
			if boss.phase in ["idle", "defeated"]:
				retry()
		KEY_E:
			open_reward()
		KEY_SPACE:
			player.try_attack()
		KEY_V, KEY_CTRL:
			player.intent = input_direction()
			player.try_roll()
		KEY_Q:
			player.try_skill()
		_:
			return
	get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not transitioning and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if player.try_attack(get_local_mouse_position() - player.position):
			get_viewport().set_input_as_handled()
