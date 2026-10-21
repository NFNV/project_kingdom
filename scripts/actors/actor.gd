class_name KingdomActor
extends CharacterBody2D

signal died(actor: KingdomActor)
enum Faction { DOG, CAT }

@export var faction: Faction = Faction.DOG
@export var player_controlled: bool = false
@export var hostile: bool = false
@export var maximum_health: int = 3
@export var movement_speed: float = 150.0
@export var display_name: String = ""
@export var is_guard: bool = false

var move_intent: Vector2 = Vector2.ZERO
var facing: Vector2 = Vector2.RIGHT
var knockback: Vector2 = Vector2.ZERO
var stun_time: float = 0.0
var alert: bool = false
var death_elapsed: float = 0.0
var flash_time: float = 0.0
@onready var health: KingdomHealth = $Health
@onready var melee: KingdomMelee = $Melee
@onready var visual: AnimatedSprite2D = $Visual


func _ready() -> void:
	add_to_group("actors")
	if hostile:
		add_to_group("enemies")
	health.maximum = maximum_health
	health.reset()
	health.died.connect(_on_death)
	visual.sprite_frames = _make_frames()
	# The generated atlases use a 320px logical frame, normalized to the
	# original knight's world size. Atlas margins anchor each pose at its feet.
	visual.scale = Vector2(0.4, 0.4)
	visual.position = Vector2(0, -51.2)
	visual.play("guard" if is_guard else "idle")
	if hostile:
		melee.reach = 74.0
		melee.windup = 0.32
		melee.duration = 0.52
		melee.recovery = 0.7


func _make_frames() -> SpriteFrames:
	var species := "dog" if faction == Faction.DOG else "cat"
	return load("res://resources/characters/%s_warrior.tres" % species) as SpriteFrames


static func faction_name(value: Faction) -> String:
	return "Dog Kingdom" if value == Faction.DOG else "Cat Kingdom"


static func faction_color(value: Faction) -> Color:
	return Color("6baed3") if value == Faction.DOG else Color("df8b7b")


static func faction_building_color(value: Faction) -> String:
	return "Blue" if value == Faction.DOG else "Red"


func _physics_process(delta: float) -> void:
	if health.is_dead():
		death_elapsed += delta
		visual.modulate.a = maxf(0.0, 1.0 - death_elapsed * 1.8)
		visual.rotation = minf(0.65, death_elapsed * 2.0)
		if death_elapsed > 0.65 and not player_controlled:
			queue_free()
		return
	stun_time = maxf(0.0, stun_time - delta)
	flash_time = maxf(0.0, flash_time - delta)
	melee.advance(delta)
	var movement := move_intent.limit_length()
	if stun_time > 0.0:
		movement = Vector2.ZERO
	if not movement.is_zero_approx() and not melee.attacking:
		facing = movement.normalized()
	var speed_factor := 0.35 if melee.attacking else 1.0
	velocity = movement * movement_speed * speed_factor + knockback
	knockback = knockback.move_toward(Vector2.ZERO, 1100.0 * delta)
	move_and_slide()
	if absf(facing.x) > 0.1:
		visual.flip_h = facing.x < 0.0
	var animation := "idle"
	if is_guard:
		animation = "guard"
	elif melee.attacking:
		animation = "attack"
	elif movement.length_squared() > 0.01:
		animation = "run"
	if visual.animation != animation:
		visual.play(animation, 0.625 if animation == "attack" and hostile else 1.0)
	visual.self_modulate = Color(2.5, 2.0, 1.5) if flash_time > 0.0 else Color.WHITE
	if health.invulnerability > 0.0 and player_controlled:
		visual.modulate.a = 0.55 if fmod(health.invulnerability, 0.12) < 0.06 else 1.0
	else:
		visual.modulate.a = 1.0
	queue_redraw()


func try_attack(aim: Vector2) -> bool:
	if melee.try_start(aim):
		facing = melee.direction
		visual.play("attack", 0.625 if hostile else 1.0)
		visual.set_frame_and_progress(0, 0.0)
		return true
	return false


func receive_hit(amount: int, direction: Vector2) -> bool:
	var grace := 0.55 if player_controlled else 0.16
	if not health.take_damage(amount, grace):
		return false
	melee.cancel()
	knockback = direction * 235.0
	stun_time = 0.16
	flash_time = 0.09
	_show_damage(amount)
	return true


func _show_damage(amount: int) -> void:
	var label := Label.new()
	label.text = "−%d" % amount
	label.position = Vector2(-14, -110)
	label.add_theme_font_size_override("font_size", 23)
	label.add_theme_color_override("font_color", Color("fff0bc"))
	label.add_theme_color_override("font_shadow_color", Color("222b30"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", -142.0, 0.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(label.queue_free)


func _on_death() -> void:
	melee.cancel()
	move_intent = Vector2.ZERO
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	visual.stop()
	died.emit(self)
	queue_redraw()


func _draw() -> void:
	if health == null or health.is_dead():
		return
	var font := ThemeDB.fallback_font
	if is_in_group("player"):
		draw_arc(Vector2(0, -4), 20, 0, TAU, 28, Color(faction_color(faction), 0.8), 1.5)
	if hostile and (alert or health.current < health.maximum):
		draw_style_box(_bar_style(Color("243531")), Rect2(-24, -102, 48, 7))
		draw_rect(Rect2(-22, -100, 44.0 * health.current / health.maximum, 3), Color("df7962"))
	if alert and melee.attacking and melee.elapsed < melee.windup:
		draw_string(font, Vector2(-4, -115), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("ffe29a"))
	if is_guard:
		var width := font.get_string_size(display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string(font, Vector2(-width / 2.0, -105), display_name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("d6e5cd"))


func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(2)
	return style
